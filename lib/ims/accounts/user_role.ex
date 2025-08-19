defmodule Ims.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  schema "user_roles" do
    belongs_to :user, Ims.Accounts.User
    belongs_to :role, Ims.Accounts.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ims.Repo.insert()
  end
end
