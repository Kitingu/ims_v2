defmodule Ims.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
      add :description, :string
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:permissions, [:created_by_id])
    create unique_index(:permissions, [:name], name: :uidx_permissions_name)
  end
end
