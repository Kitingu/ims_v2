defmodule Ims.Repo.Migrations.CreateTrainingProjections do
  use Ecto.Migration

  def change do
    create table(:training_projections) do
      add :full_name, :string
      add :gender, :string
      add :personal_number, :string
      add :designation, :string
      add :department, :string
      add :job_group, :string
      add :qualification, :string
      add :institution, :string
      add :program_title, :string
      add :financial_year, :string
      add :quarter, :string
      add :disability, :boolean, default: false, null: false
      add :disability_details, :string
      add :period_of_study, :integer
      add :costs, :decimal
      add :status, :string
      add :ethnicity_id, references(:ethnicities, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:training_projections, [:ethnicity_id])
    create unique_index(:training_projections, [:personal_number], name: :training_projections_personal_number_index)

  end
end
