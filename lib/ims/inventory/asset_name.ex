defmodule Ims.Inventory.AssetName do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  use Ims.RepoHelpers, repo: Repo

  schema "asset_names" do
    field :name, :string
    field :description, :string
    belongs_to :category, Ims.Inventory.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset_name, attrs) do
    asset_name
    |> cast(attrs, [:name, :description, :category_id])
    |> validate_required([:name, :category_id])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(l in accum_query, where: ilike(l.name, ^"%#{v}%"))

          k == :description ->
            from(l in accum_query, where: ilike(l.description, ^"%#{v}%"))

          k == :category_id ->
            from(l in accum_query, where: l.category_id == ^v)

          k == :category_name ->
            from(l in accum_query,
              join: c in Ims.Inventory.Category,
              on: l.category_id == c.id,
              where: ilike(c.name, ^"%#{v}%")
            )

          true ->
            accum_query
        end
      end)
  end
end
