defmodule Ims.Accounts.Departments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :name, :string
    field :created_by_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(departments, attrs) do
    departments
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
