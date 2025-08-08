defmodule ImsWeb.LeaveBalancesLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Leave
  alias Ims.Leave.LeaveBalance

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 bg-black bg-opacity-50 flex justify-center items-center">
      <div class="bg-white p-6 rounded-lg shadow-lg w-full max-w-lg">
        <h2 class="text-lg font-semibold mb-4">
          Update Leave Balances for {@user.first_name} {@user.last_name}
        </h2>

        <.form id="leave-balance-form" phx-target={@myself} phx-submit="save">
          <%= for {balance_id, %{leave_type_name: type, remaining_days: value}} <- @balance_map do %>
            <div class="mb-4">
              <label class="block text-sm font-medium mb-1">{type}</label>
              <input
                type="number"
                name={"leave_balances[#{balance_id}]"}
                value={value}
                step="0.1"
                min="0"
                class="w-full border p-2 rounded"
              />
            </div>
          <% end %>

          <div class="flex justify-end gap-2">
            <.link patch={@return_to} class="bg-gray-300 px-4 py-2 rounded">Cancel</.link>
            <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded">Save</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    balances = Leave.get_user_leave_balances(user.id)

    # Create map like %{balance_id => %{type: "Annual", days: 10.0}}
    balance_map =
      balances
      |> Enum.into(%{}, fn balance ->
        {
          balance.id,
          %{
            leave_type_name: balance.leave_type.name,
            remaining_days: Decimal.to_float(balance.remaining_days)
          }
        }
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:balances, balances)
     |> assign(:balance_map, balance_map)}
  end

  @impl true
  def handle_event("save", %{"leave_balances" => form_data}, socket) do
    results =
      Enum.map(form_data, fn {balance_id_str, days_str} ->
        id = String.to_integer(balance_id_str)
        new_days = String.to_float(days_str)

        case Leave.get_leave_balance!(id) do
          %LeaveBalance{} = balance ->
            Leave.update_leave_balance(balance, %{remaining_days: new_days})

          _ ->
            {:error, "Balance not found"}
        end
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      send(self(), {:saved, :leave_balances})
      {:noreply, push_patch(socket, to: socket.assigns.return_to)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Failed to update some balances")}
    end
  end
end
