defmodule Ims.Repo.Migrations.CreateRolePermissions do
  use Ecto.Migration

  def change do
    create table(:role_permissions) do
      add :permission_id, references(:permissions, on_delete: :delete_all)
      add :role_id, references(:permissions, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:role_permissions, [:role_id, :permission_id])
  end
end
