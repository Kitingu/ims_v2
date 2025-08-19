defmodule Ims.Repo.Audited do
  @moduledoc """
  Wraps Repo write ops and emits audit logs. Read ops (incl. paginate) delegate to `Ims.Repo`.

  Notes:
    * We intentionally **do not audit** `UserToken` operations (login/session).
    * Bulk audit payloads are scrubbed to be JSON-safe (no non-UTF8 binaries).
    * Single-row audits pass real structs so `Ims.Audit` can compute PKs & diffs.
    * For Ecto.Multi, we do **not** log per-step rows or transaction.begin; we emit a single
      aggregated `transaction.commit` with actual changes (and only if effective changes occurred).
  """

  alias Ims.{Repo, Audit}

  # ===================================================================
  # Single-row writes (changesets & structs)
  # ===================================================================

  def insert(term, opts \\ [])

  def insert(%Ecto.Changeset{} = cs, opts) do
    case Repo.insert(cs, opts) do
      {:ok, struct} ->
        maybe_log_insert(preload_all(struct))
        {:ok, struct}
      other -> other
    end
  end

  def insert(struct, opts) when is_struct(struct) do
    case Repo.insert(struct, opts) do
      {:ok, struct} ->
        maybe_log_insert(preload_all(struct))
        {:ok, struct}
      other -> other
    end
  end

  def update(%Ecto.Changeset{} = cs, opts \\ []) do
    schema = cs.data.__struct__
    id = Map.get(cs.data, :id)
    assocs = associations(schema)

    before =
      if id, do: Repo.get!(schema, id) |> Repo.preload(assocs),
      else: Repo.preload(cs.data, assocs)

    case Repo.update(cs, opts) do
      {:ok, struct} ->
        if map_size(cs.changes) > 0 do
          maybe_log_update(before, Repo.preload(struct, assocs))
        end
        {:ok, struct}
      other -> other
    end
  end

  def delete(struct, opts \\ []) do
    struct_p = preload_all(struct)

    case Repo.delete(struct, opts) do
      {:ok, deleted} ->
        maybe_log_delete(struct_p)
        {:ok, deleted}
      other -> other
    end
  end

  # -------------------------------------------------------------------
  # Bang variants
  # -------------------------------------------------------------------

  def insert!(term, opts \\ [])

  def insert!(%Ecto.Changeset{} = cs, opts) do
    struct = Repo.insert!(cs, opts)
    maybe_log_insert(preload_all(struct))
    struct
  end

  def insert!(struct, opts) when is_struct(struct) do
    struct = Repo.insert!(struct, opts)
    maybe_log_insert(preload_all(struct))
    struct
  end

  def update!(%Ecto.Changeset{} = cs, opts \\ []) do
    schema = cs.data.__struct__
    assocs = associations(schema)
    before = Repo.preload(cs.data, assocs)

    struct = Repo.update!(cs, opts)

    if map_size(cs.changes) > 0 do
      maybe_log_update(before, Repo.preload(struct, assocs))
    end

    struct
  end

  def delete!(struct, opts \\ []) do
    struct_p = preload_all(struct)
    deleted = Repo.delete!(struct, opts)
    maybe_log_delete(struct_p)
    deleted
  end

  # ===================================================================
  # Bulk writes
  # ===================================================================

  def insert_all(schema_or_source, entries, opts \\ []) do
    result = Repo.insert_all(schema_or_source, entries, opts)
    {count, _} = result

    Audit.log_event(
      "insert_all",
      source_name(schema_or_source),
      nil,
      %{"count" => count, "entries_preview" => scrub_for_audit(preview(entries))}
    )

    result
  end

  def update_all(queryable, updates, opts \\ []) do
    {count, _} = result = Repo.update_all(queryable, updates, opts)

    Audit.log_event(
      "update_all",
      source_name(queryable),
      nil,
      %{"count" => count, "updates" => inspect(updates)}
    )

    result
  end

  def delete_all(queryable, opts \\ []) do
    {count, _} = result = Repo.delete_all(queryable, opts)

    Audit.log_event(
      "delete_all",
      source_name(queryable),
      nil,
      %{"count" => count}
    )

    result
  end

  # ===================================================================
  # Transactions
  # ===================================================================

  def transaction(arg, opts \\ [])

  # Ecto.Multi: no per-step rows; no transaction.begin; aggregate changes at commit
  def transaction(%Ecto.Multi{} = multi, opts) do
    started_at = System.monotonic_time()
    ops = Ecto.Multi.to_list(multi)

    # Capture "before" snapshots for update/delete
    befores =
      Enum.reduce(ops, %{}, fn {name, op}, acc ->
        case op do
          {:update, %Ecto.Changeset{} = cs, _} ->
            Map.put(acc, name, preload_all(cs.data))
          {:delete, %Ecto.Changeset{} = cs, _} ->
            Map.put(acc, name, preload_all(cs.data))
          {:delete, struct, _} when is_struct(struct) ->
            Map.put(acc, name, preload_all(struct))
          _ -> acc
        end
      end)

    case Repo.transaction(multi, opts) do
      {:ok, res_map} ->
        # Build a compact summary of actual changes
        summary =
          Enum.reduce(ops, %{inserts: [], updates: [], deletes: [], bulk: []}, fn {name, op}, acc ->
            case op do
              {:insert, _term, _} ->
                case Map.get(res_map, name) do
                  %_{} = struct ->
                    case resource(struct) do
                      "UserToken" -> acc
                      res ->
                        after_s = preload_all(struct)
                        add_insert(acc, res, pk(after_s), %{"after" => short_dump(after_s)})
                    end
                  _ -> acc
                end

              {:update, %Ecto.Changeset{} = cs, _} ->
                if map_size(cs.changes) > 0 do
                  before = Map.get(befores, name)
                  case Map.get(res_map, name) do
                    %_{} = struct ->
                      case resource(struct) do
                        "UserToken" -> acc
                        res ->
                          after_s = preload_all(struct)
                          add_update(acc, res, pk(after_s), diff_from_changes(before, after_s, Map.keys(cs.changes)))
                      end
                    _ -> acc
                  end
                else
                  acc
                end

              {:delete, _term, _} ->
                before = Map.get(befores, name)
                if match?(%_{}, before) do
                  case resource(before) do
                    "UserToken" -> acc
                    res -> add_delete(acc, res, pk(before), %{"before" => short_dump(before)})
                  end
                else
                  acc
                end

              {:insert_all, queryable, entries, _} ->
                add_bulk(acc, %{
                  "op" => "insert_all",
                  "source" => source_name(queryable),
                  "count" => case Map.get(res_map, name) do {count, _} -> count; _ -> nil end,
                  "entries_preview" => scrub_for_audit(preview(entries))
                })

              {:update_all, queryable, updates, _} ->
                add_bulk(acc, %{
                  "op" => "update_all",
                  "source" => source_name(queryable),
                  "count" => case Map.get(res_map, name) do {count, _} -> count; _ -> nil end,
                  "updates" => inspect(updates)
                })

              {:delete_all, queryable, _} ->
                add_bulk(acc, %{
                  "op" => "delete_all",
                  "source" => source_name(queryable),
                  "count" => case Map.get(res_map, name) do {count, _} -> count; _ -> nil end
                })

              _ ->
                acc
            end
          end)

        effective? =
          summary.inserts != [] or summary.updates != [] or summary.deletes != [] or summary.bulk != []

        # Only log commit if there were effective changes
        if effective? do
          Audit.log_event(
            "transaction.commit",
            "repo",
            nil,
            %{
              "type" => "multi",
              "duration_ms" => monotonic_diff_ms(started_at),
              "inserts" => Enum.reverse(summary.inserts),
              "updates" => Enum.reverse(summary.updates),
              "deletes" => Enum.reverse(summary.deletes),
              "bulk" => Enum.reverse(summary.bulk)
            }
          )
        end

        {:ok, res_map}

      {:error, failed_name, failed_val, changes_so_far} ->
        # Rollback is still logged (no begin/commit)
        Audit.log_event(
          "transaction.rollback",
          "repo",
          nil,
          %{
            "type" => "multi",
            "duration_ms" => monotonic_diff_ms(started_at),
            "failed_step" => step_label(failed_name),
            "completed_steps" => Enum.map(Map.keys(changes_so_far), &step_label/1)
          },
          error_meta(failed_val)
        )

        {:error, failed_name, failed_val, changes_so_far}
    end
  end

  # Function transaction: also skip begin; still log commit and rollback
  def transaction(fun, opts) when is_function(fun, 0) or is_function(fun, 1) do
    started_at = System.monotonic_time()

    case Repo.transaction(fun, opts) do
      {:ok, res} ->
        Audit.log_event("transaction.commit", "repo", nil, %{
          "type" => "fun",
          "duration_ms" => monotonic_diff_ms(started_at)
        })
        {:ok, res}

      {:error, reason} ->
        Audit.log_event(
          "transaction.rollback",
          "repo",
          nil,
          %{"type" => "fun", "duration_ms" => monotonic_diff_ms(started_at)},
          %{"reason" => inspect(reason)}
        )
        {:error, reason}
    end
  end

  def rollback(reason), do: Repo.rollback(reason)

  # ===================================================================
  # Read & utility delegates
  # ===================================================================

  defdelegate all(q, opts \\ []),                     to: Repo
  defdelegate one(q, opts \\ []),                     to: Repo
  defdelegate one!(q, opts \\ []),                    to: Repo
  defdelegate get(schema, id, opts \\ []),            to: Repo
  defdelegate get!(schema, id, opts \\ []),           to: Repo
  defdelegate get_by(queryable, clauses, opts \\ []), to: Repo
  defdelegate aggregate(q, agg, field, opts \\ []),   to: Repo
  defdelegate exists?(q, opts \\ []),                 to: Repo
  defdelegate preload(data, preloads, opts \\ []),    to: Repo
  defdelegate paginate(queryable, opts \\ []),        to: Repo

  # ===================================================================
  # Helpers
  # ===================================================================

  defp maybe_log_insert(struct) do
    case resource(struct) do
      "UserToken" -> :ok
      res -> Audit.log_insert(res, struct)
    end
  end

  defp maybe_log_update(before, later) do
    case resource(later) do
      "UserToken" -> :ok
      res -> Audit.log_update(res, before, later)
    end
  end

  defp maybe_log_delete(struct) do
    case resource(struct) do
      "UserToken" -> :ok
      res -> Audit.log_delete(res, struct)
    end
  end

  defp resource(struct),
    do: struct.__struct__ |> Module.split() |> List.last()

  defp associations(schema) do
    if function_exported?(schema, :__schema__, 1), do: schema.__schema__(:associations), else: []
  end

  defp preload_all(struct) do
    schema = struct.__struct__
    Repo.preload(struct, associations(schema))
  end

  defp source_name(%Ecto.Query{from: %{source: {source, _}}}), do: to_string(source)
  defp source_name(%Ecto.Query{from: %{source: source}}),      do: to_string(source)
  defp source_name({source, _}),                                do: to_string(source)
  defp source_name(source) when is_atom(source),                do: source |> Module.split() |> List.last()
  defp source_name(source),                                     do: to_string(source)

  # ---- Multi commit aggregation helpers ----

  defp add_insert(acc, res, id, payload),
    do: put_in(acc, [:inserts], [%{"resource" => res, "id" => id, "payload" => payload} | acc.inserts])

  defp add_update(acc, res, id, changed),
    do: put_in(acc, [:updates], [%{"resource" => res, "id" => id, "changed" => changed} | acc.updates])

  defp add_delete(acc, res, id, payload),
    do: put_in(acc, [:deletes], [%{"resource" => res, "id" => id, "payload" => payload} | acc.deletes])

  defp add_bulk(acc, entry),
    do: put_in(acc, [:bulk], [entry | acc.bulk])

  # Diff only for fields the changeset touched
  defp diff_from_changes(before, after_s, changed_keys) do
    Enum.reduce(changed_keys, %{}, fn key, acc ->
      vb = get_field(before, key)
      va = get_field(after_s, key)
      if vb == va do
        acc
      else
        Map.put(acc, to_string(key), %{"before" => encode_simple(vb), "after" => encode_simple(va)})
      end
    end)
  end

  defp get_field(%_{} = s, k) when is_atom(k), do: Map.get(s, k)
  defp get_field(%_{} = s, k) when is_binary(k), do: Map.get(s, String.to_existing_atom(k))
  defp get_field(%{} = m, k), do: Map.get(m, k)

  defp short_dump(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
    |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, to_string(k), encode_simple(v)) end)
  end

  # Minimal JSON-safe encoder
  defp encode_simple(%Ecto.Association.NotLoaded{}), do: nil
  defp encode_simple(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp encode_simple(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp encode_simple(%Date{} = d), do: Date.to_iso8601(d)
  defp encode_simple(%Time{} = t), do: Time.to_iso8601(t)
  defp encode_simple(%{__struct__: mod} = s) when is_atom(mod) do
    if function_exported?(mod, :__schema__, 1), do: Map.get(s, :id),
      else: s |> Map.from_struct() |> Map.new(fn {k, v} -> {to_string(k), encode_simple(v)} end)
  end
  defp encode_simple({a, b}), do: [encode_simple(a), encode_simple(b)]
  defp encode_simple(t) when is_tuple(t), do: t |> Tuple.to_list() |> Enum.map(&encode_simple/1)
  defp encode_simple(list) when is_list(list), do: Enum.map(list, &encode_simple/1)
  defp encode_simple(%{} = m), do: Map.new(m, fn {k, v} -> {to_string(k), encode_simple(v)} end)
  defp encode_simple(bin) when is_binary(bin), do: if String.valid?(bin), do: bin, else: "[REDACTED_BINARY]"
  defp encode_simple(other), do: other

  defp pk(%{id: id}) when not is_nil(id), do: to_string(id)
  defp pk(_), do: nil

  # ---- shared util helpers ----

  defp preview(list) when is_list(list) do
    list
    |> Enum.take(3)
    |> Enum.map(fn
      m when is_map(m) -> Map.take(m, Enum.take(Map.keys(m), 5))
      other -> other
    end)
  end
  defp preview(other), do: other

  defp scrub_for_audit(term) when is_struct(term) do
    term
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Map.new(fn {k, v} -> {k, scrub_for_audit(v)} end)
  end
  defp scrub_for_audit(%Ecto.Association.NotLoaded{}), do: :not_loaded
  defp scrub_for_audit(map) when is_map(map), do: Map.new(map, fn {k, v} -> {k, scrub_for_audit(v)} end)
  defp scrub_for_audit(list) when is_list(list), do: Enum.map(list, &scrub_for_audit/1)
  defp scrub_for_audit(bin) when is_binary(bin), do: if String.valid?(bin), do: bin, else: "[REDACTED_BINARY]"
  defp scrub_for_audit(other), do: other

  defp step_label(name), do: inspect(name, limit: :infinity, pretty: false)

  defp monotonic_diff_ms(started_at) do
    System.convert_time_unit(System.monotonic_time() - started_at, :native, :millisecond)
  end

  defp error_meta(%Ecto.Changeset{} = cs),
    do: %{"errors" => readable_changeset_errors(cs)}
  defp error_meta(other),
    do: %{"reason" => inspect(other)}

  defp readable_changeset_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
