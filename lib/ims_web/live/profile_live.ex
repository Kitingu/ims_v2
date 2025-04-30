defmodule ImsWeb.UserProfileLive do
  # alias Ims.Inventory
  use ImsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Mock Data
    current_user = socket.assigns.current_user |> Ims.Repo.preload([:department, leave_balances: :leave_type])

    annual_remaining_days =
    case Enum.find(current_user.leave_balances, fn balance ->
      balance.leave_type.name == "annual"
    end) do
      nil -> Decimal.new("0.00") # Default value if no annual leave balance is found
      annual_balance -> annual_balance.remaining_days
    end

    user_info = %{
      avatar_url: "https://via.placeholder.com/150",
      name: "#{current_user.first_name}",
      department: "#{current_user.department.name}",
      email: "#{current_user.email}",
      phone: "#{current_user.msisdn}",
      leave_days: annual_remaining_days,


      assignments:
        Ims.Inventory.get_assigned_assets(socket.assigns.current_user),


      leave_days: annual_remaining_days,


    }

    {:ok, assign(socket, user_info: user_info)}
  end

  @impl true
  def handle_event("apply_for_leave", _params, socket) do
    {:noreply, push_navigate(socket, to: "/leave_applications/new")}
  end

  @impl true
  def handle_event("request_for_device", _params, socket) do
    {:noreply, push_navigate(socket, to: "/requests/new")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8 max-w-5xl bg-white rounded-lg shadow-md">
      <div class="flex items-center mb-6">
        <div>
          <h1 class="text-3xl font-bold text-gray-800">User Profile</h1>
          <p class="text-lg text-gray-600">Welcome back, <strong><%= @user_info.name %></strong>!</p>
        </div>
      </div>
      <!-- Personal Information -->
      <div class="bg-gray-50 p-6 rounded-lg mb-6 shadow">
        <div class="flex justify-between items-start">
          <div>
            <h2 class="text-2xl font-semibold text-gray-700 mb-4">Personal Information</h2>
            <p class="text-gray-800 mb-2"><strong>Name:</strong> <%= @user_info.name %></p>
            <p class="text-gray-800 mb-2">
              <strong>Department:</strong> <%= @user_info.department %>
            </p>
            <p class="text-gray-800 mb-2"><strong>Email:</strong> <%= @user_info.email %></p>
            <p class="text-gray-800 mb-4"><strong>Phone:</strong> <%= @user_info.phone %></p>
          </div>
          <div class="ml-6 p-4 bg-gray-100 rounded-lg shadow">
            <h3 class="text-xl font-semibold text-gray-700 mb-4">Leave Details</h3>
            <p class="text-gray-800 mb-4">
              <strong>Available Leave Days:</strong> <%= @user_info.leave_days %>
            </p>
            <button
              class="bg-blue-500 text-white px-6 py-2 rounded-lg shadow hover:bg-blue-600"
              phx-click="apply_for_leave"
            >
              Apply for Leave
            </button>
          </div>
        </div>
      </div>
      <!-- Assignments -->
      <div class="bg-gray-50 p-6 rounded-lg mb-6 shadow">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-semibold text-gray-700">Assigned Assets</h2>
          <button
            class="bg-blue-500 text-white px-6 py-2 rounded-lg shadow hover:bg-blue-600"
            phx-click="request_for_device"
          >
          Request for Device
          </button>

        </div>
        <table class="w-full table-auto border-collapse rounded-lg overflow-hidden">
          <thead>
            <tr class="bg-gray-200">
              <th class="border px-4 py-2 text-left">Device ID</th>
              <th class="border px-4 py-2 text-left">Device Name</th>
              <th class="border px- 4 py-2 text-left">Serial Number</th>
            </tr>
          </thead>
          <tbody>
            <%= for assignment <- @user_info.assignments do %>
              <tr class="hover:bg-gray-100">
                <td class="border px-4 py-2 text-center"><%= assignment.id %></td>
                <td class="border px-4 py-2"><%= assignment.asset_name.name %></td>
                <td class="border px-4 py-2"><%= assignment.serial_number %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      <!-- Returned Devices -->

      <!-- Lost Devices -->

    </div>
    """
  end
end
