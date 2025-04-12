defmodule Ims.Repo.Migrations.CreateTrainingApplications do
  use Ecto.Migration

  def change do
    create table(:training_applications) do
      add :course_approved, :string
      add :institution, :string
      add :program_title, :string
      add :financial_year, :string
      add :quarter, :string
      add :disability, :boolean, default: false, null: false
      add :period_of_study, :string
      add :costs, :decimal
      add :authority_reference, :string
      add :memo_reference, :string
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :ethnicity_id, references(:ethnicities, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:training_applications, [:user_id])
    create index(:training_applications, [:ethnicity_id])
  end
end
