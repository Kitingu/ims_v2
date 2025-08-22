defmodule Ims.Regions do
  import Ecto.Query, warn: false
  alias Ims.Repo
  alias Ims.Regions.{County, Constituency, Ward}

  # --- helpers ---

  defp norm(nil), do: ""
  defp norm(v) when is_binary(v), do: String.trim(v)
  defp norm(v), do: v |> to_string() |> String.trim()

  defp with_prefix(queryable, nil), do: queryable
  defp with_prefix(queryable, prefix) do
    q = Ecto.Queryable.to_query(queryable)
    %{q | prefix: prefix}
  end

  defp prefix_opt(opts), do: Keyword.get(opts, :prefix)

  # --- upserts (no conflict_target anywhere) ---

  @doc """
  Upsert county by name. If `code` is given, update it after insert-or-fetch.
  Accepts opts like [prefix: "public"].
  """
  def upsert_county!(name, code \\ nil, opts \\ []) when is_binary(name) do
    prefix = prefix_opt(opts)
    name = norm(name)
    attrs = %{name: name, code: code}

    case Repo.insert(County.changeset(%County{}, attrs),
           on_conflict: :nothing,   # IMPORTANT: no conflict_target
           returning: [:id],
           prefix: prefix
         ) do
      {:ok, %County{id: id} = c} when not is_nil(id) ->
        c

      {:ok, %County{id: nil}} ->
        c = Repo.get_by!(with_prefix(County, prefix), name: name)

        if code && c.code != code do
          {:ok, c2} =
            c
            |> County.changeset(%{code: code})
            |> Repo.update(prefix: prefix)

          c2
        else
          c
        end

      {:error, cs} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: cs
    end
  end

  @doc "Upsert constituency by (county_id, name)."
  def upsert_constituency!(county_id, name, opts \\ [])
      when is_integer(county_id) and is_binary(name) do
    prefix = prefix_opt(opts)
    name = norm(name)

    case Repo.insert(
           Constituency.changeset(%Constituency{}, %{name: name, county_id: county_id}),
           on_conflict: :nothing,
           returning: [:id],
           prefix: prefix
         ) do
      {:ok, %Constituency{id: id} = c} when not is_nil(id) ->
        c

      {:ok, %Constituency{id: nil}} ->
        Repo.get_by!(with_prefix(Constituency, prefix), county_id: county_id, name: name)

      {:error, cs} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: cs
    end
  end

  @doc "Upsert ward by (constituency_id, name)."
  def upsert_ward!(constituency_id, name, opts \\ [])
      when is_integer(constituency_id) and is_binary(name) do
    prefix = prefix_opt(opts)
    name = norm(name)

    case Repo.insert(
           Ward.changeset(%Ward{}, %{name: name, constituency_id: constituency_id}),
           on_conflict: :nothing,
           returning: [:id],
           prefix: prefix
         ) do
      {:ok, %Ward{id: id} = w} when not is_nil(id) ->
        w

      {:ok, %Ward{id: nil}} ->
        Repo.get_by!(with_prefix(Ward, prefix), constituency_id: constituency_id, name: name)

      {:error, cs} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: cs
    end
  end

  # --- queries ---

  def list_counties(opts \\ []) do
    County |> with_prefix(prefix_opt(opts)) |> order_by(asc: :name) |> Repo.all()
  end

  def list_constituencies(county_id, opts \\ []) when is_integer(county_id) do
    Constituency
    |> with_prefix(prefix_opt(opts))
    |> where([c], c.county_id == ^county_id)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def list_wards(constituency_id, opts \\ []) when is_integer(constituency_id) do
    Ward
    |> with_prefix(prefix_opt(opts))
    |> where([w], w.constituency_id == ^constituency_id)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def search_counties(term, opts \\ []) when is_binary(term) do
    t = "%" <> term <> "%"
    County
    |> with_prefix(prefix_opt(opts))
    |> where([c], ilike(c.name, ^t))
    |> order_by(asc: :name)
    |> Repo.all()
  end
end
