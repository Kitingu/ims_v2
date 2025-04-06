defmodule Ims.Inventory.Category do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  use Ims.RepoHelpers, repo: Repo

  schema "categories" do
    field :name, :string
    belongs_to :asset_type, Ims.Inventory.AssetType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :asset_type_id])
    |> validate_required([:name, :asset_type_id])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(l in accum_query, where: ilike(l.name, ^"%#{v}%"))

          k == :asset_type_id ->
            from(l in accum_query, where: l.asset_type_id == ^v)

          k == :asset_type_name ->
            from(l in accum_query,
              join: at in Ims.Inventory.AssetType,
              on: l.asset_type_id == at.id,
              where: ilike(at.name, ^"%#{v}%")
            )

          true ->
            accum_query
        end
      end)
  end
end
