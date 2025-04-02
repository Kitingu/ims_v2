defmodule Ims.Repo.Migrations.CreateLeaveApplications do
  use Ecto.Migration

  def change do
    create table(:leave_applications) do
      add :days_requested, :integer
      add :status, :string
      add :comment, :text
      add :start_date, :date
      add :end_date, :date
      add :resumption_date, :date
      add :proof_document, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :leave_type_id, references(:leave_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:leave_applications, [:user_id])
    create index(:leave_applications, [:leave_type_id])
  end
end
