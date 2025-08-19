defmodule Ims.Inventory.AssetType do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  schema "asset_types" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset_type, attrs) do
    asset_type
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end

  def search(queryable \\ __MODULE__, filters) do
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(a in accum_query, where: ilike(a.name, ^"%#{v}%"))

          k == :description ->
            from(a in accum_query, where: ilike(a.description, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)
  end
end
