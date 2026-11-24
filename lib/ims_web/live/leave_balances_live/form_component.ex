defmodule ImsWeb.LeaveBalancesLive.ManageComponent do
  use ImsWeb, :live_component

  alias Ims.Repo.Audited, as: Repo
  import Ecto.Query, only: [from: 2]
  alias Ims.Accounts
  alias Ims.Leave.{AnnualLeave, LeaveType, LeaveBalance}
  alias Ecto.Changeset
  require Logger

  @impl true
  def update(assigns, %{assigns: %{leave_types: _}} = socket) do
    {:ok, assign(socket, assigns)}
  end

  def update(assigns, socket) do
    leave_types = list_leave_types()

    socket =
      socket
      |> assign(assigns)
      |> assign(:leave_types, leave_types)

    socket =
      case assigns.user do
        nil ->
          user_options =
            Accounts.list_users()
            |> Enum.sort_by(&{&1.first_name, &1.last_name})
            |> Enum.map(&{"#{&1.first_name} #{&1.last_name} (#{&1.personal_number})", &1.id})

          socket
          |> assign(:user_options, user_options)
          |> select_user(nil)

        user ->
          socket
          |> assign(:user_options, [])
          |> select_user(user)
      end

    {:ok, assign(socket, :annual_action, nil)}
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
            <h2 class="text-lg font-semibold">
              {if @mode == :view, do: "View Leave Balances", else: "Update Leave Balances"}
            </h2>
            <button
              phx-click="close_manage_balances"
              class="px-2 py-1 rounded hover:bg-gray-100"
              aria-label="Close"
            >
              ✕
            </button>
          </div>

          <p :if={@user} class="px-4 pt-4 font-medium">
            {@user.first_name} {@user.last_name} ({@user.personal_number})
          </p>

          <div :if={!@user} class="relative w-full px-4 py-3 mb-4" phx-update="ignore" id="select_user_container">
            <label class="block text-sm font-medium mb-1">Select a User</label>
            <select
              id="select_user_id"
              name="manage[user_id]"
              phx-hook="select2JS"
              phx-target={@myself}
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
            <form phx-submit={if @mode == :edit, do: "save"} phx-target={@myself} class="p-4 space-y-4">

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
                          <%= if @mode == :edit && lt.name != "Annual Leave" do %>
                            <input
                              type="number"
                              name={"balances[#{lt.id}]"}
                              value={row.remaining_days}
                              step="any"
                              min="0"
                              required
                              class="w-40 border rounded px-2 py-1"
                              aria-label={"Remaining days for #{lt.name}"}
                            />
                          <% else %>
                            {row.remaining_days}
                          <% end %>
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
                  {if @mode == :edit, do: "Cancel", else: "Close"}
                </button>
                <button :if={@mode == :edit && Enum.any?(@visible_leave_types, &(&1.name != "Annual Leave"))} type="submit" class="px-4 py-2 rounded bg-black text-white">Save</button>
              </div>
            </form>

            <section class="px-4 pb-6 space-y-4">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <h3 class="font-semibold">Annual Leave History</h3>
                <div :if={@mode == :edit} class="flex flex-wrap gap-2">
                  <button type="button" phx-click="annual_action" phx-value-action="record" phx-target={@myself} class="rounded border px-3 py-2">
                    Record past leave
                  </button>
                  <button type="button" phx-click="annual_action" phx-value-action="adjust" phx-target={@myself} class="rounded border px-3 py-2">
                    Adjust annual balance
                  </button>
                  <button type="button" phx-click="annual_action" phx-value-action="opening" phx-target={@myself} class="rounded border px-3 py-2">
                    Set prior-year opening
                  </button>
                </div>
              </div>

              <.form :if={@annual_action} for={@annual_form} id="annual-leave-action"
                phx-change="annual_change" phx-submit="save_annual" phx-target={@myself}
                class="rounded border p-3 space-y-3">
                <div :if={@annual_action == "record"} class="grid gap-3 sm:grid-cols-2">
                  <.input field={@annual_form[:start_date]} type="date" label="Leave started" required />
                  <.input field={@annual_form[:end_date]} type="date" label="Leave ended" required />
                  <label class="sm:col-span-2 flex items-center gap-2 text-sm">
                    <input type="checkbox" name="annual[already_deducted]" value="true"
                      checked={@annual_form[:already_deducted].value == "true"} />
                    These days were already deducted
                  </label>
                </div>
                <div :if={@annual_action != "record"} class="grid gap-3 sm:grid-cols-2">
                  <.input field={@annual_form[:effective_on]} type="date"
                    label={if @annual_action == "opening", do: "Financial year start (1 July)", else: "Effective date"}
                    required />
                  <.input field={@annual_form[:days]} type="number" step="any"
                    label={if @annual_action == "opening", do: "Opening balance in days", else: "Days to add or subtract"}
                    required />
                </div>
                <.input field={@annual_form[:reason]} type="text"
                  label={if @annual_action == "record", do: "Reason or approval reference", else: "Reason"}
                  required />
                <p :if={@annual_error} class="text-sm text-red-700" role="alert">{@annual_error}</p>
                <button type="submit" class="rounded bg-black px-3 py-2 text-white">
                  {if @annual_action == "record", do: "Record approved leave", else: "Save balance entry"}
                </button>
                <button type="button" phx-click="cancel_annual" phx-target={@myself} class="rounded border px-3 py-2">Cancel</button>
              </.form>

              <p :if={@annual_history == []} class="text-sm text-gray-600">No annual leave history is available yet.</p>
              <div :if={@annual_history != []} class="overflow-x-auto rounded border">
                <table class="w-full text-left text-sm">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="p-2">Effective dates</th>
                      <th class="p-2">Entry</th>
                      <th class="p-2">Change</th>
                      <th class="p-2">Balance</th>
                      <th class="p-2">Actioned by</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={row <- @annual_history} class="border-t align-top">
                      <td class="whitespace-nowrap p-2">
                        {row.entry.effective_on}
                        <span :if={row.entry.application && row.entry.application.end_date != row.entry.effective_on}>
                          to {row.entry.application.end_date}
                        </span>
                      </td>
                      <td class="p-2">
                        <div>{entry_label(row.entry)}</div>
                        <div :if={row.entry.reason} class="text-xs text-gray-600">{row.entry.reason}</div>
                        <div :if={row.entry.application && row.entry.application.submitted_by} class="text-xs text-gray-600">
                          Submitted by {employee_name(row.entry.application.submitted_by)}
                        </div>
                      </td>
                      <td class="whitespace-nowrap p-2">{display_days(row.change)}</td>
                      <td class="whitespace-nowrap p-2">{display_days(row.balance)}</td>
                      <td class="p-2">
                        <div>{row.entry.actor_label}<span :if={row.entry.actor_id}> (#{row.entry.actor_id})</span></div>
                        <div class="text-xs text-gray-600">{Calendar.strftime(DateTime.add(row.entry.inserted_at, 3, :hour), "%d %b %Y, %H:%M")} EAT</div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
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
  def handle_event(
        "select_changed",
        %{"select_id" => "select_user_id", "manage[user_id]" => user_id},
        %{assigns: %{user: nil, mode: :edit}} = socket
      ) do
    user =
      case Integer.parse(user_id) do
        {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 -> Repo.get(Accounts.User, id)
        _ -> nil
      end

    {:noreply, select_user(socket, user)}
  end

  def handle_event("select_changed", _, socket), do: {:noreply, socket}

  def handle_event("annual_action", %{"action" => action}, socket)
      when action in ["record", "adjust", "opening"] do
    if annual_edit?(socket) do
      {:noreply,
       assign(socket,
         annual_action: action,
         annual_form: to_form(%{"effective_on" => to_string(AnnualLeave.today())}, as: :annual),
         annual_error: nil
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_annual", _, socket), do: {:noreply, assign(socket, :annual_action, nil)}

  def handle_event("annual_change", %{"annual" => params}, socket) do
    {:noreply, assign(socket, annual_form: to_form(params, as: :annual), annual_error: nil)}
  end

  def handle_event("save_annual", %{"annual" => params}, socket) do
    if annual_edit?(socket) && socket.assigns.annual_action do
      %{selected_user_id: id, current_user: actor, annual_action: action} = socket.assigns

      result =
        case action do
          "record" -> AnnualLeave.record_past(id, params, actor)
          "adjust" -> AnnualLeave.adjust(id, params, actor)
          "opening" -> AnnualLeave.open_period(id, params, actor)
        end

      case result do
        {:ok, _} ->
          send(self(), {:flash, :info, "Annual leave history updated."})

          {:noreply,
           assign(socket,
             annual_action: nil,
             annual_history: AnnualLeave.history(id),
             balances_map: balances_map_for_user(id, socket.assigns.visible_leave_types)
           )}

        {:error, reason} ->
          {:noreply,
           assign(socket,
             annual_form: to_form(params, as: :annual),
             annual_error: annual_error(reason)
           )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("save", %{"balances" => params}, socket) when is_map(params) and map_size(params) > 0 do
    %{selected_user_id: id, mode: mode, current_user: actor, visible_leave_types: types} =
      socket.assigns

    if mode == :edit && id && Canada.Can.can?(actor, ["edit"], "leave_balances") do
      allowed_ids = for type <- types, type.name != "Annual Leave", do: to_string(type.id)
      balances = Map.take(params, allowed_ids)

      case upsert_balances(id, balances) do
        {:ok, _} ->
          send(self(), {:flash, :info, "Leave balances updated."})
          send(self(), :close_manage_balances)

        {:error, step, %Changeset{} = changeset, _} ->
          msg = changeset_errors_to_string(changeset) || "Failed at #{inspect(step)}."
          send(self(), {:flash, :error, msg})

        {:error, message} ->
          send(self(), {:flash, :error, message})
      end
    end

    {:noreply, socket}
  end

  defp annual_edit?(socket) do
    %{mode: mode, selected_user_id: id, current_user: user} = socket.assigns
    mode == :edit && not is_nil(id) && Canada.Can.can?(user, ["edit"], "leave_balances")
  end

  defp annual_error(%Changeset{} = changeset), do: changeset_errors_to_string(changeset)
  defp annual_error(reason) when is_binary(reason), do: reason
  defp annual_error(_), do: "Could not save the annual leave entry."

  defp display_days(nil), do: "—"
  defp display_days(days), do: days |> Decimal.normalize() |> Decimal.to_string(:normal)

  defp employee_name(user), do: String.trim("#{user.first_name} #{user.last_name}")

  defp entry_label(%{kind: "opening"}), do: "Opening balance"
  defp entry_label(%{kind: "entitlement"}), do: "Annual entitlement"
  defp entry_label(%{kind: "carryover"}), do: "Carried forward"
  defp entry_label(%{kind: "adjustment"}), do: "Balance adjustment"
  defp entry_label(%{kind: "recorded_leave"}), do: "Past leave already deducted"
  defp entry_label(%{kind: "legacy_leave"}), do: "Previously approved leave"
  defp entry_label(%{kind: "leave", application: %{days_requested: days}}), do: "Approved leave (#{days} days)"

  defp select_user(socket, nil) do
    assign(socket,
      selected_user_id: nil,
      visible_leave_types: [],
      balances_map: %{},
      annual_action: nil,
      annual_history: []
    )
  end

  defp select_user(socket, user) do
    types = filter_leave_types_by_gender(socket.assigns.leave_types, user.gender)

    assign(socket,
      selected_user_id: user.id,
      visible_leave_types: types,
      annual_action: nil,
      annual_history: AnnualLeave.history(user.id),
      balances_map: balances_map_for_user(user.id, types)
    )
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

        case Map.get(existing, lt_id) do
          nil ->
            cs =
              LeaveBalance.changeset(%LeaveBalance{}, %{
                user_id: user_id,
                leave_type_id: lt_id,
                remaining_days: val
              })

            Ecto.Multi.insert(m, {:insert, lt_id}, cs)

          %LeaveBalance{} = lb ->
            cs = LeaveBalance.changeset(lb, %{remaining_days: val})
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
