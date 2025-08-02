defmodule Ims.Repo.Migrations.CreateFileMovements do
  use Ecto.Migration

  def change do
    create table(:file_movements) do
      add :remarks, :string
      add :file_id, references(:files, on_delete: :nothing)
      add :from_office_id, references(:offices, on_delete: :nothing)
      add :to_office_id, references(:offices, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:file_movements, [:file_id])
    create index(:file_movements, [:from_office_id])
    create index(:file_movements, [:to_office_id])
    create index(:file_movements, [:user_id])
  end
end
