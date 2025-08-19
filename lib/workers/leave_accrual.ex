defmodule Ims.Workers.LeaveAccrualWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Ims.Repo.Audited, as: Repo
  alias Ims.Leave.{LeaveBalance, LeaveType}
  import Ecto.Query
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "year_start"}}) do
    Logger.info("Leave Accrual Worker: Financial year start job triggered")
    reset_all_leave_balances()
  end

  defp reset_all_leave_balances do
    leave_types = Repo.all(LeaveType)

    Enum.each(leave_types, fn leave_type ->
      if leave_type.name == "Annual Leave" do
        reset_annual_leave(leave_type)
      else
        reset_other_leave(leave_type)
      end
    end)

    Logger.info("Leave Accrual Worker: All leave types processed.")
    :ok
  end

  defp reset_annual_leave(%LeaveType{id: type_id}) do
    Logger.info("Resetting Annual Leave balances...")

    balances = Repo.all(from lb in LeaveBalance, where: lb.leave_type_id == ^type_id)

    Enum.each(balances, fn lb ->
      carry_forward =
        lb.remaining_days
        |> Decimal.new()
        |> Decimal.min(Decimal.new(15))
        |> Decimal.round(1)

      new_balance = Decimal.add(carry_forward, 30)

      lb
      |> Ecto.Changeset.change(remaining_days: new_balance)
      |> Repo.update()
      |> case do
        {:ok, _} ->
          Logger.info("User ##{lb.user_id} — Annual: Carry = #{carry_forward}, Total = #{new_balance}")

        {:error, reason} ->
          Logger.error("User ##{lb.user_id} — Failed to update Annual Leave: #{inspect(reason)}")
      end
    end)
  end

  defp reset_other_leave(%LeaveType{id: type_id, name: name, default_days: default}) do
    Logger.info("Resetting #{name} balances to default (#{default || 0} days)...")

    balances = Repo.all(from lb in LeaveBalance, where: lb.leave_type_id == ^type_id)

    Enum.each(balances, fn lb ->
      lb
      |> Ecto.Changeset.change(remaining_days: Decimal.new(default || 0))
      |> Repo.update()
      |> case do
        {:ok, _} ->
          Logger.info("User ##{lb.user_id} — #{name} set to #{default || 0} days")

        {:error, reason} ->
          Logger.error("User ##{lb.user_id} — Failed to reset #{name}: #{inspect(reason)}")
      end
    end)
  end
end
