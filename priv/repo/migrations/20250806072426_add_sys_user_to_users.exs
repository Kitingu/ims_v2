defmodule Ims.Repo.Migrations.AddSysUserToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :sys_user, :boolean, default: false, null: false
      modify :email, :citext, null: true
      modify :hashed_password, :string, null: true
    end
  end

  def down do
    alter table(:users) do
      remove :sys_user
      modify :email, :citext, null: false
      modify :hashed_password, :string, null: false
    end
  end
end
