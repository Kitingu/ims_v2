defmodule Ims.Repo.Migrations.CreateWelfareMembers do
  use Ecto.Migration

  def change do
    create table(:welfare_members) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :status, :string, default: "active", null: false
      add :eligibility, :boolean, default: true, null: false

      add :entry_date, :date
      add :exit_date, :date

      add :amount_paid, :decimal, precision: 12, scale: 2, default: 0.0
      add :amount_due, :decimal, precision: 12, scale: 2, default: 0.0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:welfare_members, [:user_id])
  end
end
