defmodule Ims.Accounts.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_permissions" do

    belongs_to :role, Ims.Accounts.Role
    belongs_to :permission, Ims.Accounts.Permission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [])
    |> validate_required([])
  end
end
