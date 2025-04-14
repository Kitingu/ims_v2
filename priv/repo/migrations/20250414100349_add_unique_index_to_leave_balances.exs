defmodule Ims.Repo.Migrations.AddUniqueIndexToLeaveBalances do
  use Ecto.Migration

  def change do
    create unique_index(:leave_balances, [:user_id, :leave_type_id], name: :unique_user_leave_type_balance)
  end
end
