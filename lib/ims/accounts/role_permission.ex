defmodule Ims.Accounts.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Repo.Audited, as: Repo
  alias Ims.Accounts.{Role, Permission}
  use Ims.RepoHelpers, repo: Repo


  schema "role_permissions" do
    belongs_to :role, Role
    belongs_to :permission, Permission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ims.Repo.insert()
  end
end
