defmodule Ims.Demographics.Ethnicity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ethnicities" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ethnicity, attrs) do
    ethnicity
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
