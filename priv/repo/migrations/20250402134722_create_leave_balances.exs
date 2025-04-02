defmodule Ims.Repo.Migrations.CreateLeaveBalances do
  use Ecto.Migration

  def change do
    create table(:leave_balances) do
      add :remaining_days, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :leave_type_id, references(:leave_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:leave_balances, [:user_id])
    create index(:leave_balances, [:leave_type_id])
  end
end
