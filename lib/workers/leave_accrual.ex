defmodule Ims.Workers.LeaveAccrualWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Ims.Repo
  alias Ims.Leave.{LeaveBalance, LeaveType}
  import Ecto.Query
  require Logger


  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "monthly"}}) do
    Logger.info("Leave Accrual Worker: Monthly accrual job started")
    accrue_annual_leave()
  end

  def perform(%Oban.Job{args: %{"type" => "year_end"}}) do
    Logger.info("Leave Accrual Worker: Year-end reset job started")
    year_end_reset()
  end

  defp accrue_annual_leave do
    with %LeaveType{id: type_id} <- Repo.get_by(LeaveType, name: "Annual Leave") do
      from(lb in LeaveBalance, where: lb.leave_type_id == ^type_id)
      |> Repo.update_all(inc: [remaining_days: 1.75])
    end

    :ok
  end

  defp year_end_reset do
    with %LeaveType{id: type_id} <- Repo.get_by(LeaveType, name: "Annual Leave") do
      balances =
        Repo.all(from lb in LeaveBalance, where: lb.leave_type_id == ^type_id)

      Enum.each(balances, fn lb ->
        carry_forward = Decimal.new(lb.remaining_days) |> Decimal.div(2) |> Decimal.round(1)

        LeaveBalance
        |> Repo.get!(lb.id)
        |> Ecto.Changeset.change(remaining_days: carry_forward)
        |> Repo.update()
      end)
    end

    :ok
  end
end
