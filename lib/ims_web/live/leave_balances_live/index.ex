# lib/ims_web/live/leave_balance_live/index.ex

defmodule ImsWeb.LeaveBalanceLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query

  alias Ims.Leave
  alias Ims.Accounts

  def mount(_params, _session, socket) do
    balances = Leave.get_leave_balances_matrix()
    matrix = build_matrix(balances)
    leave_types = get_all_leave_types()

    {:ok, assign(socket, rows: matrix, columns: leave_types)}
  end

  defp build_matrix(balances), do: Ims.Leave.build_matrix(balances)

  defp get_all_leave_types do
    Ims.Repo.all(from lt in Ims.Leave.LeaveType, select: lt.name)
  end



  defp get_all_leave_balances do
    from(l in Ims.Leave.LeaveBalance,
      group_by: [l.user_id, l.leave_type_id],
      select: %{
        user_id: l.user_id,
        leave_type_id: l.leave_type_id,
        remaining_days: sum(l.remaining_days)
      }
    )
    |> Ims.Repo.all()
    |> Enum.map(fn lb ->
      %{
        user_id: lb.user_id,
        leave_type_id: lb.leave_type_id,
        remaining_days: Decimal.to_integer(lb.remaining_days)
      }
    end)
  end

  defp preload_users(balances) do
    user_ids = Enum.map(balances, & &1.user_id) |> Enum.uniq()

    Ims.Repo.all(
      from u in Ims.Accounts.User,
        where: u.id in ^user_ids,
        select: {u.id, fragment("? || ' ' || ?", u.first_name, u.last_name)}
    )
    |> Enum.into(%{})
  end
end
