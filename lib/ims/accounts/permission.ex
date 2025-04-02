defmodule Ims.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :description, :string
    field(:approval_levels, :integer, default: 0)
    belongs_to :created_by, Ims.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description, :created_by_id])
    |> validate_required([:name, :description])
    |> unique_constraint(:name, name: :uidx_permissions_name)
  end
end
