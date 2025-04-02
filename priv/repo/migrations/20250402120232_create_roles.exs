defmodule Ims.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string
      add :description, :string
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:roles, [:created_by_id])
    create unique_index(:roles, [:name], name: :uidx_roles_name)
  end
end
