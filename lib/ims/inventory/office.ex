defmodule Ims.Inventory.Office do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "offices" do
    field :name, :string
    field :floor, :string
    field :building, :string
    field :door_name, :string
    belongs_to :location, Ims.Inventory.Location
    # field :location_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(office, attrs) do
    office
    |> cast(attrs, [:name, :floor, :door_name, :location_id])
    |> validate_required([:name, :location_id, :floor, :door_name])
  end

  def search(queryable \\ __MODULE__, filters) do
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(o in accum_query, where: ilike(o.name, ^"%#{v}%"))

          k == :floor ->
            from(o in accum_query, where: ilike(o.floor, ^"%#{v}%"))

          k == :door_name ->
            from(o in accum_query, where: ilike(o.door_name, ^"%#{v}%"))

          k == :location_id ->
            from(o in accum_query, where: o.location_id == ^v)

          k == :location_name ->
            from(o in accum_query,
              join: l in Ims.Inventory.Location,
              on: o.location_id == l.id,
              where: ilike(l.name, ^"%#{v}%")
            )

          true ->
            accum_query
        end
      end)
  end
end
