defmodule Ims.Regions.Constituency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "constituencies" do
    field :name, :string
    belongs_to :county, Ims.Regions.County
    has_many :wards, Ims.Regions.Ward
    timestamps()
  end

  def changeset(constituency, attrs) do
    constituency
    |> cast(attrs, [:name, :county_id])
    |> validate_required([:name, :county_id])
    |> assoc_constraint(:county)
    |> unique_constraint([:county_id, :name], name: :constituencies_county_name_ux)
  end
end
