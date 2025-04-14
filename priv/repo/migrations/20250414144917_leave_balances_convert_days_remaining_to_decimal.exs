defmodule Ims.Repo.Migrations.LeaveBalancesConvertDaysRemainingToDecimal do
  use Ecto.Migration

  def change do
    alter table(:leave_balances) do
      modify :remaining_days, :decimal, null: false, default: 0.0
    end

    # Optionally, you can add a check constraint to ensure that remaining_days is non-negative
    execute(
      "ALTER TABLE leave_balances ADD CONSTRAINT check_remaining_days_non_negative CHECK (remaining_days >= 0)"
    )
  end
end
