defmodule ImsWeb.LeaveBalanceLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query

  alias Ims.Repo
  alias Ims.Leave
  alias Ims.Leave.LeaveType
  alias Ims.Accounts
  alias Decimal
  require Logger

  # If you rely on Routes.* helpers (Phoenix < 1.7 style)
  alias ImsWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_defaults(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    live_action = socket.assigns[:live_action] || :index

    # Keep your original columns = names
    leave_types = Repo.all(from lt in LeaveType, select: lt.name)

    case live_action do
      :edit ->
        user_id = params["id"]
        user = Accounts.get_user!(user_id)

        {:noreply,
         socket
         |> assign(:page_title, "Edit Leave Balances")
         |> assign(:user, user)
         |> assign(:all_leave_types, leave_types)
         |> assign(:visible_leave_types, leave_types)
         |> assign(:columns, leave_types)
         |> assign(:live_action, :edit)}

      :index ->
        page = Leave.paginated_leave_balances(params)

        {:noreply,
         socket
         |> assign(:rows, page)
         |> assign(:columns, leave_types)
         |> assign(:all_leave_types, leave_types)
         |> assign(:search, Map.get(params, "search", ""))
         |> assign(:selected_type, Map.get(params, "leave_type", ""))
         |> assign(:params, params)
         |> assign(:page_title, "Leave Balances")
         |> assign(:user, nil)
         |> assign(:show_manage_modal, false)
         |> assign(:live_action, :index)}
    end
  end

  defp assign_defaults(socket) do
    assign(socket,
      search: "",
      selected_type: nil,
      show_manage_modal: false
    )
  end

  ## ===== Modal open/close + table controls =====

  # Open the Manage Balances modal when the top button is clicked
  @impl true
  def handle_event("update_leave_balance", _params, socket) do
    {:noreply, assign(socket, :show_manage_modal, true)}
  end

  # Close modal (overlay/✕ inside the component sends this to parent)
  def handle_event("close_manage_balances", _params, socket) do
    {:noreply, assign(socket, :show_manage_modal, false)}
  end

  @impl true
  def handle_event("render_page", %{"page" => page}, socket) do
    current_page = String.to_integer(Map.get(socket.assigns.params, "page", "1"))

    new_page =
      case page do
        "next" -> current_page + 1
        "previous" -> max(current_page - 1, 1)
        _ -> String.to_integer(page)
      end

    params = Map.put(socket.assigns.params, "page", Integer.to_string(new_page))
    page_data = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> assign(:params, params)
     |> assign(:rows, page_data)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    params =
      socket.assigns.params
      |> Map.put("page_size", size)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page_size, size)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  def handle_event("open_update_modal", %{"id" => user_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.leave_balances_index_path(socket, :edit, user_id),
       replace: true
     )}
  end

  # Matches your filter/search controls in index.html.heex
  def handle_event("filter_leave_type", %{"leave_type" => lt}, socket) do
    params =
      socket.assigns.params
      |> Map.put("leave_type", lt)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:selected_type, lt)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  def handle_event("search_user", %{"search" => search}, socket) do
    params =
      socket.assigns.params
      |> Map.put("search", search)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  @impl true
  def handle_event("export_excel", _params, socket) do
    params = socket.assigns.params || %{}
    leave_types = socket.assigns.all_leave_types || []
    headers = ["Personal Number", "First Name", "Last Name"] ++ leave_types

    rows =
      gather_all_balances(params)
      |> Enum.map(fn row ->
        base = [row.personal_number, row.first_name, row.last_name]
        balances = Enum.map(leave_types, fn lt -> Map.get(row, lt, 0) end)
        base ++ balances
      end)

    csv_iodata =
      [headers | rows]
      |> Enum.map(&csv_line/1)
      |> Enum.intersperse("\r\n")

    filename = "leave_balances_#{Date.utc_today()}.csv"

    {:noreply,
     Phoenix.LiveView.send_download(
       socket,
       {:binary, IO.iodata_to_binary(csv_iodata)},
       filename: filename,
       content_type: "text/csv"
     )}
  end

  # Pull every page matching current filters
  defp gather_all_balances(params) do
    base = params |> Map.put_new("page_size", "500") |> Map.put("page", "1")
    page = Ims.Leave.paginated_leave_balances(base)

    entries =
      Enum.reduce((page.page_number + 1)..page.total_pages, page.entries, fn p, acc ->
        more =
          base
          |> Map.put("page", Integer.to_string(p))
          |> Ims.Leave.paginated_leave_balances()
          |> Map.get(:entries)

        acc ++ more
      end)

    entries
  end

  # Minimal CSV escaping
  defp csv_line(list) do
    list
    |> Enum.map(&csv_cell/1)
    |> Enum.intersperse(",")
  end

  defp csv_cell(nil), do: "\"\""

  defp csv_cell(v) do
    s =
      v
      |> to_string()
      |> String.replace("\"", "\"\"")

    ["\"", s, "\""]
  end

  ## ===== Messages from the ManageComponent =====
  # ManageComponent calls: send(self(), {:flash, :info, "Leave balances updated."})
  @impl true
  def handle_info({:flash, level, msg}, socket) when level in [:info, :error, :warning] do
    # Refresh the table after an update, keep the modal open so they can continue editing
    params = socket.assigns.params || %{}
    page = Leave.paginated_leave_balances(params)
    {:noreply, socket |> put_flash(level, msg) |> assign(:rows, page)}
  end

  @impl true
  def handle_info(:close_manage_balances, socket) do
    {:noreply, assign(socket, :show_manage_modal, false)}
  end

  # Ignore anything else
  def handle_info(_msg, socket), do: {:noreply, socket}
end
