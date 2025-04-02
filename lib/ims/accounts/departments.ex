defmodule Ims.Accounts.Departments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :name, :string
    belongs_to :created_by, Ims.Accounts.User
    has_many :users, Ims.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(departments, attrs) do
    departments
    |> cast(attrs, [:name, :created_by_id])
    |> validate_required([:name])
  end
end
