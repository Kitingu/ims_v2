# lib/ims_web/live/leave_balances_live/manage_component.ex
defmodule ImsWeb.LeaveBalancesLive.ManageComponent do
  use ImsWeb, :live_component

  alias Ims.Repo
  import Ecto.Query, only: [from: 2]
  alias Ims.Accounts
  # alias Ims.Accounts.User
  alias Ims.Leave.{LeaveType, LeaveBalance}
  alias Ecto.Changeset
  require Logger

  @impl true
  def update(assigns, socket) do
    user_options =
      Ims.Accounts.list_users()
      |> Enum.sort_by(&{&1.first_name, &1.last_name})
      |> Enum.map(fn u ->
        {"#{u.first_name} #{u.last_name} (#{u.personal_number})", u.id}
      end)

    leave_types = list_leave_types()

    # Provide a tiny form so the select has name="manage[user_id]"
    form = to_form(%{"user_id" => ""}, as: :manage)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_options, user_options)
     |> assign(:leave_types, leave_types)
     |> assign(:visible_leave_types, leave_types)
     |> assign(:selected_user_id, nil)
     |> assign(:balances_map, %{})
     |> assign(:form, form)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative">
      <!-- Overlay -->
      <div class="fixed inset-0 z-40 bg-black/40" phx-click="close_manage_balances"></div>

    <!-- Modal -->
      <div class="fixed inset-0 z-50 flex items-start justify-center p-6 overflow-auto">
        <div class="w-full max-w-3xl bg-white rounded shadow-lg">
          <div class="flex items-center justify-between p-4 border-b">
            <h2 class="text-lg font-semibold">Update Leave Balances</h2>
            <button
              phx-click="close_manage_balances"
              class="px-2 py-1 rounded hover:bg-gray-100"
              aria-label="Close"
            >
              ✕
            </button>
          </div>

    <!-- User selector -->
          <%!-- <form phx-change="select_user" phx-target={@myself} class="p-4 space-y-2">
            <label class="block text-sm font-medium">User</label>
            <select name="user_id" class="w-full border rounded px-3 py-2">
              <option value="">-- Select user --</option>
              <%= for {label, id} <- @user_options do %>
                <option value={id} selected={to_string(id) == to_string(@selected_user_id)}>
                  {label}
                </option>
              <% end %>
            </select>
          </form> --%>

          <div class="relative w-full px-4 py-3 mb-4" phx-update="ignore" id="select_user_container">
            <label class="block text-sm font-medium mb-1">Select a User</label>
            <select
              id="select_user_id"
              name="manage[user_id]"
              phx-hook="select2JS"
              data-phx-event="select_changed"
              data-placeholder="Search for a user..."
              class="hidden"
            >
              <option value="">-- Select user --</option>
              <%= for {label, id} <- @user_options do %>
                <option value={id} selected={to_string(id) == to_string(@selected_user_id)}>
                  {label}
                </option>
              <% end %>
            </select>
          </div>

          <%= if @selected_user_id do %>
            <form phx-submit="save" phx-target={@myself} class="p-4 space-y-4">
              <input type="hidden" name="user_id" value={@selected_user_id} />

              <div class="overflow-hidden rounded border">
                <table class="w-full text-left">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-3 py-2">Leave Type</th>
                      <th class="px-3 py-2">Remaining Days</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for lt <- @visible_leave_types do %>
                      <% row = Map.get(@balances_map, lt.id) || %{remaining_days: "0"} %>
                      <tr class="border-t">
                        <td class="px-3 py-2">{lt.name}</td>
                        <td class="px-3 py-2">
                          <input
                            type="number"
                            name={"balances[#{lt.id}]"}
                            value={row.remaining_days}
                            step="0.1"
                            min="0"
                            class="w-40 border rounded px-2 py-1"
                            aria-label={"Remaining days for #{lt.name}"}
                          />
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>

              <div class="flex justify-end gap-2">
                <button
                  type="button"
                  phx-click="close_manage_balances"
                  class="px-4 py-2 rounded border"
                >
                  Cancel
                </button>
                <button type="submit" class="px-4 py-2 rounded bg-black text-white">Save</button>
              </div>
            </form>
          <% else %>
            <p class="px-4 pb-4 text-gray-600">
              Select a user to view and edit their leave balances.
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_user", %{"user_id" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:selected_user_id, nil)
     |> assign(:visible_leave_types, socket.assigns.leave_types)
     |> assign(:balances_map, %{})}
  end

  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    id = String.to_integer(user_id)
    user = Accounts.get_user!(id)

    visible = filter_leave_types_by_gender(socket.assigns.leave_types, user.gender)
    map = balances_map_for_user(id, visible)

    {:noreply,
     socket
     |> assign(:selected_user_id, id)
     |> assign(:visible_leave_types, visible)
     |> assign(:balances_map, map)}
  end

  @impl true
  def handle_event(
        "select_changed",
        %{"select_id" => "select_user_id", "manage[user_id]" => user_id},
        socket
      ) do
    case user_id do
      "" ->
        {:noreply,
         socket
         |> assign(:selected_user_id, nil)
         |> assign(:visible_leave_types, socket.assigns.leave_types)
         |> assign(:balances_map, %{})}

      _ ->
        id = String.to_integer(user_id)
        user = Ims.Accounts.get_user!(id)

        visible = filter_leave_types_by_gender(socket.assigns.leave_types, user.gender)
        map = balances_map_for_user(id, visible)

        {:noreply,
         socket
         |> assign(:selected_user_id, id)
         |> assign(:visible_leave_types, visible)
         |> assign(:balances_map, map)}
    end
  end

  def handle_event("save", %{"user_id" => uid, "balances" => balances_params}, socket) do
    user_id = String.to_integer(uid)

    case upsert_balances(user_id, balances_params) do
      {:ok, _} ->
        new_map = balances_map_for_user(user_id, socket.assigns.visible_leave_types)
        send(self(), {:flash, :info, "Leave balances updated."})
        # <-- tell parent to close
        send(self(), :close_manage_balances)
        {:noreply, assign(socket, :balances_map, new_map)}

      {:error, step, %Changeset{} = cs, _} ->
        msg = changeset_errors_to_string(cs) || "Failed at #{inspect(step)}."
        send(self(), {:flash, :error, msg})
        {:noreply, socket}

      {:error, msg} ->
        send(self(), {:flash, :error, msg})
        {:noreply, socket}
    end
  end

  ## Data helpers

  defp list_leave_types do
    from(lt in LeaveType, order_by: [asc: lt.name]) |> Repo.all()
  end

  # %{lt_id => %{balance_id: id | nil, remaining_days: "decimal_str"}}
  defp balances_map_for_user(user_id, leave_types) do
    existing =
      from(lb in LeaveBalance,
        where: lb.user_id == ^user_id,
        select: {lb.leave_type_id, lb.id, lb.remaining_days}
      )
      |> Repo.all()
      |> Map.new(fn {lt_id, id, days} ->
        {lt_id, %{balance_id: id, remaining_days: decimal_to_string(days)}}
      end)

    Map.new(leave_types, fn lt ->
      {lt.id, Map.get(existing, lt.id, %{balance_id: nil, remaining_days: "0"})}
    end)
  end

  defp upsert_balances(user_id, balances_params) do
    existing =
      from(lb in LeaveBalance, where: lb.user_id == ^user_id, select: {lb.leave_type_id, lb})
      |> Repo.all()
      |> Map.new()

    multi =
      Enum.reduce(balances_params, Ecto.Multi.new(), fn {lt_id_str, val}, m ->
        lt_id = String.to_integer(lt_id_str)

        days =
          case Decimal.parse(String.trim(to_string(val))) do
            :error -> Decimal.new("0")
            {dec, _} -> dec
          end

        case Map.get(existing, lt_id) do
          nil ->
            cs =
              LeaveBalance.changeset(%LeaveBalance{}, %{
                user_id: user_id,
                leave_type_id: lt_id,
                remaining_days: days
              })

            Ecto.Multi.insert(m, {:insert, lt_id}, cs)

          %LeaveBalance{} = lb ->
            cs = LeaveBalance.changeset(lb, %{remaining_days: days})
            Ecto.Multi.update(m, {:update, lt_id}, cs)
        end
      end)

    case Repo.transaction(multi) do
      {:ok, res} ->
        {:ok, res}

      {:error, step, %Changeset{} = cs, _} ->
        {:error, step, cs, multi}

      {:error, _step, reason, _} ->
        Logger.error("Upsert balances failed: #{inspect(reason)}")
        {:error, "Could not save balances."}
    end
  end

  defp decimal_to_string(nil), do: "0"
  defp decimal_to_string(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  defp decimal_to_string(n) when is_integer(n) or is_float(n), do: to_string(n)

  defp changeset_errors_to_string(%Changeset{} = cs) do
    cs
    |> Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  defp filter_leave_types_by_gender(leave_types, gender) do
    g = normalize_gender(gender)

    Enum.reject(leave_types, fn lt ->
      case lt.name do
        "Paternity Leave" -> g == :female
        "Maternity Leave" -> g == :male
        _ -> false
      end
    end)
  end

  defp normalize_gender(nil), do: :other
  defp normalize_gender(g) when is_atom(g), do: normalize_gender(to_string(g))

  defp normalize_gender(g) when is_binary(g) do
    case String.downcase(String.trim(g)) do
      "m" -> :male
      "male" -> :male
      "f" -> :female
      "female" -> :female
      _ -> :other
    end
  end
end
