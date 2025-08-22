defmodule Ims.Regions.Ward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wards" do
    field :name, :string
    belongs_to :constituency, Ims.Regions.Constituency
    timestamps()
  end

  def changeset(ward, attrs) do
    ward
    |> cast(attrs, [:name, :constituency_id])
    |> validate_required([:name, :constituency_id])
    |> assoc_constraint(:constituency)
    |> unique_constraint([:constituency_id, :name], name: :wards_constituency_name_ux)
  end
end
