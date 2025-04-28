defmodule Ims.Repo.Migrations.CreateInternAttachees do
  use Ecto.Migration

  def change do
    create table(:intern_attachees) do
      add :full_name, :string
      add :id_number, :string
      add :email, :string
      add :phone, :string
      add :school, :string
      add :program, :string
      add :start_date, :date
      add :end_date, :date
      add :duration, :string
      add :next_of_kin_name, :string
      add :next_of_kin_phone, :string
      add :department_id, references(:departments, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:intern_attachees, [:department_id])
    create unique_index(:intern_attachees, [:id_number], name: :unique_intern_attachee_id_number)
  end
end
