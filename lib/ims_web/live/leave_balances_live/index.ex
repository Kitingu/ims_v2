defmodule ImsWeb.LeaveBalanceLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query

  alias Ims.Leave
  alias Ims.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_defaults(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    IO.inspect("params: #{inspect(params)}")

    page = Leave.paginated_leave_balances(params)
    leave_types = Repo.all(from lt in Ims.Leave.LeaveType, select: lt.name)

    {:noreply,
     socket
     |> assign(:rows, page)
     |> assign(:columns, leave_types)
     |> assign(:all_leave_types, leave_types)
     |> assign(:search, Map.get(params, "search", ""))
     |> assign(:selected_type, Map.get(params, "leave_type", ""))
     |> assign(:params, params)
     |> assign(:live_action, socket.assigns[:live_action] || :index)}
  end

  defp assign_defaults(socket) do
    assign(socket, search: "", selected_type: nil)
  end

  def handle_event("render_page", %{"page" => page}, socket) do
    IO.inspect("page: #{page}")

    current_page = String.to_integer(Map.get(socket.assigns.params, "page", "1"))

    new_page =
      case page do
        "next" -> current_page + 1
        "previous" -> max(current_page - 1, 1)
        _ -> String.to_integer(page)
      end

    params =
      socket.assigns.params
      |> Map.put("page", Integer.to_string(new_page))

    page_data = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> assign(:params, params)
     |> assign(:rows, page_data)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    IO.inspect(size, label: "Resized table to")

    params =
      socket.assigns.params
      |> Map.put("page_size", size)
      # optional: reset page to 1 on resize
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page_size, size)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end
end
