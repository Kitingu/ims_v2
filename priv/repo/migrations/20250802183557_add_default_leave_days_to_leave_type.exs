defmodule Ims.Repo.Migrations.AddDefaultLeaveDaysToLeaveType do
  use Ecto.Migration

  def change do
    alter table(:leave_types) do
      add :default_days, :integer, default: 0, null: false
    end

    # Ensure existing leave types have a default value of 0 for default_days
    execute("UPDATE leave_types SET default_days = 0 WHERE default_days IS NULL")
  end
end
