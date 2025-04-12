defmodule ImsWeb.DashboardLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory

  @impl true
  def mount(_params, _session, socket) do
    # Trigger data loading when the LiveView is connected
    if connected?(socket), do: send(self(), :load_data)

    # Initialize assigns with default values
    {:ok,
     assign(socket,
       inventory_counts: %{lost: 0, available: 0, assigned: 0, pending_requisition: 0, temporarily_assigned: 0},
       inventory_items: [],
       category_stats: [],
       top_departments: [],
       top_users: [],
       search: ""
     )}
  end

  @impl true
  def handle_info(:load_data, socket) do
    # Fetch inventory counts from the database
    inventory_counts =
      Inventory.get_status_counts()
      |> Map.merge(%{lost: 0, available: 0, assigned: 0}, fn _key, v1, _v2 -> v1 end)

    category_stats = Inventory.get_category_stats()
    top_departments = Inventory.get_top_departments()
    top_users = Inventory.get_top_users()

    {:noreply,
     assign(socket,
       inventory_counts: inventory_counts,
       category_stats: category_stats,
       top_departments: top_departments,
       top_users: top_users
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    # Implement search functionality (if applicable)
    {:noreply, assign(socket, search: search)}
  end
end
