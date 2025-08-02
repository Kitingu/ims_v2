defmodule Ims.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :folio_number, :string
      add :subject_matter, :string
      add :ref_no, :string
      add :current_office_id, references(:offices, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:files, [:current_office_id])
    create index(:files, [:user_id])
  end
end
