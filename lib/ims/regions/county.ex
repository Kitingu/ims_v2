defmodule Ims.Regions.County do
  use Ecto.Schema
  import Ecto.Changeset

  schema "counties" do
    field :name, :string
    field :code, :string
    has_many :constituencies, Ims.Regions.Constituency
    timestamps()
  end

  def changeset(county, attrs) do
    county
    |> cast(attrs, [:name, :code])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :counties_name_index)
    |> unique_constraint(:code, name: :counties_code_index)
  end
end
