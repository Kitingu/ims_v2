defmodule Ims.Audit do
  @moduledoc """
  System-wide audit helpers: track actor & request metadata and write audit rows.

  Stores JSON-safe payloads:
    - Ecto schema struct -> its primary key value
    - Non-ecto struct -> converted to map then encoded recursively
    - Lists of structs -> list of primary keys (for ecto structs)
    - Association diffs -> %{ "added" => [...], "removed" => [...] }

  Note: We intentionally drop :inserted_at and :updated_at from diffs to avoid noise.
  """

  alias Ims.Repo
  alias Ims.Audit.AuditLog

  @actor_key :ims_audit_actor
  @meta_key  :ims_audit_meta

  @drop_fields [:__meta__, :inserted_at, :updated_at]

  # -- Actor management -------------------------------------------------------

  def set_actor(%{id: id}) when not is_nil(id),
    do: Process.put(@actor_key, %{id: id, type: "user"})

  def set_actor(:system),
    do: Process.put(@actor_key, %{id: nil, type: "system"})

  def get_actor,
    do: Process.get(@actor_key, %{id: nil, type: "system"})

  # -- Request/job metadata ---------------------------------------------------

  def put_metadata(%{} = meta),
    do: Process.put(@meta_key, Map.merge(get_metadata(), meta))

  def get_metadata,
    do: Process.get(@meta_key, %{})

  # -- Public logging API -----------------------------------------------------

  def log_event(action, resource_type, resource_id \\ nil, changes \\ %{}, extra_meta \\ %{}) do
    actor = get_actor()
    meta  = Map.merge(get_metadata(), extra_meta)

    %AuditLog{}
    |> AuditLog.changeset(%{
      actor_id: actor.id,
      actor_type: actor.type,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id && to_string(resource_id),
      changes: changes,
      metadata: meta
    })
    |> Repo.insert()
  end

  def log_insert(resource_type, struct, extra_meta \\ %{}) do
    log_event("insert", resource_type, pk(struct), %{"after" => dump(struct)}, extra_meta)
  end

  def log_update(resource_type, before_struct, after_struct, extra_meta \\ %{}) do
    log_event("update", resource_type, pk(after_struct), diff(before_struct, after_struct), extra_meta)
  end

  def log_delete(resource_type, struct, extra_meta \\ %{}) do
    log_event("delete", resource_type, pk(struct), %{"before" => dump(struct)}, extra_meta)
  end

  # -- Internal helpers -------------------------------------------------------

  defp pk(%{id: id}) when not is_nil(id), do: to_string(id)
  defp pk(_), do: nil

  # JSON-safe encoder for any value:
  # - Ecto.Association.NotLoaded -> nil
  # - Ecto schema struct -> primary key
  # - Other struct -> convert to map then encode recursively
  # - Date/Time types -> ISO-8601 string
  # - Tuple -> list
  # - List -> encode each element
  # - Map -> encode values recursively with string keys
  defp encode_value(%Ecto.Association.NotLoaded{}), do: nil

  defp encode_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp encode_value(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)
  defp encode_value(%Date{} = d), do: Date.to_iso8601(d)
  defp encode_value(%Time{} = t), do: Time.to_iso8601(t)

  defp encode_value({a, b}) do
    [encode_value(a), encode_value(b)]
  end

  defp encode_value(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&encode_value/1)
  end

  defp encode_value(%{__struct__: mod} = struct) when is_atom(mod) do
    cond do
      function_exported?(mod, :__schema__, 1) ->
        Map.get(struct, :id)
      true ->
        struct
        |> Map.from_struct()
        |> encode_value()
    end
  end

  defp encode_value(list) when is_list(list) do
    list
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&is_nil/1)
  end

  defp encode_value(%{} = map) do
    map
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.put(acc, to_string(k), encode_value(v))
    end)
  end

  defp encode_value(other), do: other

  # Dump a struct/map to a flat map with JSON-safe values,
  # skipping NotLoaded assocs and dropped fields.
  defp dump(struct_or_map) do
    base =
      struct_or_map
      |> maybe_from_struct()
      |> Map.drop(@drop_fields)

    base
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      case v do
        %Ecto.Association.NotLoaded{} -> acc
        _ -> Map.put(acc, to_string(k), encode_value(v))
      end
    end)
  end

  defp maybe_from_struct(%{__struct__: _} = struct), do: Map.from_struct(struct)
  defp maybe_from_struct(map) when is_map(map), do: map

  # Build a JSON-safe diff:
  # Lists become set-diffs of encoded values (added/removed).
  # Scalars/maps show {"before","after"} if they differ.
  defp diff(before_struct, after_struct) do
    b = dump(before_struct)
    a = dump(after_struct)

    keys = Map.keys(Map.merge(b, a))

    changed =
      Enum.reduce(keys, %{}, fn k, acc ->
        vb = Map.get(b, k)
        va = Map.get(a, k)

        cond do
          vb == va ->
            acc

          is_list(vb) or is_list(va) ->
            lb = List.wrap(vb || [])
            la = List.wrap(va || [])
            added   = la -- lb
            removed = lb -- la

            if added == [] and removed == [] do
              acc
            else
              Map.put(acc, k, %{"added" => added, "removed" => removed})
            end

          true ->
            Map.put(acc, k, %{"before" => vb, "after" => va})
        end
      end)

    %{"changed" => changed}
  end
end
