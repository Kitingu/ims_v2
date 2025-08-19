defmodule Ims.Inventory.Location do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  schema "locations" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end

  def search(queryable \\ __MODULE__, filters) do
    Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
      cond do
        v in ["", nil] ->
          accum_query

        k == :name ->
          from(l in accum_query, where: ilike(l.name, ^"%#{v}%"))

        k == :description ->
          from(l in accum_query, where: ilike(l.description, ^"%#{v}%"))

        true ->
          accum_query
      end
    end)
  end
end
