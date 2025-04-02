defmodule Ims.Repo.Migrations.CreateJobGroups do
  use Ecto.Migration

  def change do
    create table(:job_groups) do
      add :name, :string
      add :description, :string
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:job_groups, [:created_by_id])
  end
end
