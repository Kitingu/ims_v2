defmodule ImsWeb.LeaveBalanceLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query

  alias Ims.Leave
  alias Ims.Repo

  def mount(_params, _session, socket) do
    {:ok, assign_defaults(socket)}
  end

  def handle_params(params, _url, socket) do
    page = Leave.paginated_leave_balances(params)
    rows = Leave.group_balances(page.entries)
    leave_types = Repo.all(from lt in Ims.Leave.LeaveType, select: lt.name)

    {:noreply,
     socket
     |> assign(:rows, %{page | entries: rows})
     |> assign(:columns, leave_types)
     |> assign(:all_leave_types, leave_types)  # 🔥 THIS IS THE FIX
     |> assign(:search, Map.get(params, "search", ""))
     |> assign(:selected_type, Map.get(params, "leave_type", ""))}
  end


  defp assign_defaults(socket) do
    assign(socket, search: "", selected_type: nil)
  end

  defp static_leave_type_cols() do
    [
      "Annual Leave",
      "Sick Leave",
      "Maternity Leave",
      "Paternity Leave",
      "Terminal Leave"
    ]
  end
end
