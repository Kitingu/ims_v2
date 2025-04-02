defmodule Ims.Repo.Migrations.AlterTableRolePermissionsSetDefaultTimestamps do
  use Ecto.Migration

  def change do
    alter table(:role_permissions) do
      modify :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
      modify :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    alter table(:user_roles) do
      modify :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
      modify :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

  end
end
