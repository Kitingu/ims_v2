defmodule Ims.Workers.LeaveAccrualWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Ims.Repo.Audited, as: Repo
  alias Ims.Leave.{AnnualLeave, LeaveBalance, LeaveType}
  import Ecto.Query
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "year_start"}}) do
    Logger.info("Leave Accrual Worker: Financial year start job triggered")
    reset_all_leave_balances()
  end

  defp reset_all_leave_balances do
    leave_types = Repo.all(LeaveType)

    results =
      Enum.flat_map(leave_types, fn leave_type ->
        if leave_type.name == "Annual Leave" do
          renew_annual_leave(leave_type.id)
        else
          reset_other_leave(leave_type)
          []
        end
      end)

    case results do
      [] -> :ok
      errors -> {:error, {:annual_leave_renewals_failed, errors}}
    end
  end

  defp renew_annual_leave(type_id) do
    user_ids =
      Repo.all(from b in LeaveBalance, where: b.leave_type_id == ^type_id, select: b.user_id)

    Enum.flat_map(user_ids, fn user_id ->
      case AnnualLeave.renew(user_id, type_id) do
        {:ok, _balance} -> []
        {:error, reason} -> [{user_id, reason}]
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
