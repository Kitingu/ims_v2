defmodule ImsWeb.DashboardLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query
  alias Ims.Repo

  # Schemas
  alias Ims.Accounts.User
  alias Ims.Inventory
  alias Ims.Welfare.{Member, Contribution, Event}
  alias Ims.HR.AwayRequest
  alias Ims.Interns.InternAttachee
  alias Ims.Leave.{LeaveBalance, LeaveType}

  @tabs [:welfare, :hr, :ict]

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    visible_tabs = Enum.filter(@tabs, &can_view_tab?(current_user, &1))
    has_dashboard = can_view_dashboard?(current_user)

    # only set an active tab if there is at least one visible
    active_tab = List.first(visible_tabs)
    loading? = not is_nil(active_tab)

    {:ok,
     assign(socket,
       visible_tabs: visible_tabs,
       active_tab: active_tab,     # nil when no tab rights
       has_dashboard?: has_dashboard,
       loading?: loading?,
       welfare: nil,
       hr: nil,
       ict: nil
     )}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    with {:ok, tab_atom} <- to_tab(tab),
         true <- tab_atom in socket.assigns.visible_tabs do
      send(self(), {:load_tab, tab_atom})
      {:noreply, assign(socket, active_tab: tab_atom, loading?: true)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    case socket.assigns.active_tab do
      nil ->
        # no tab rights; stop loading and show placeholders
        {:noreply, assign(socket, loading?: false)}

      tab ->
        send(self(), {:load_tab, tab})
        {:noreply, assign(socket, loading?: true)}
    end
  end

  @impl true
  def handle_info({:load_tab, :welfare}, socket) do
    {:noreply, assign(socket, welfare: load_welfare(), loading?: false)}
  end

  def handle_info({:load_tab, :hr}, socket) do
    {:noreply, assign(socket, hr: load_hr(), loading?: false)}
  end

  def handle_info({:load_tab, :ict}, socket) do
    {:noreply, assign(socket, ict: load_ict(), loading?: false)}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard?tab=#{tab}")}
  end

  # ---------- Data loaders ----------

  defp load_welfare do
    eligible =
      from(m in Member, where: m.eligibility == true)
      |> Repo.aggregate(:count, :id)

    ineligible =
      from(m in Member, where: m.eligibility == false)
      |> Repo.aggregate(:count, :id)

    total_contributions = Repo.aggregate(Contribution, :sum, :amount) || Decimal.new(0)

    last5_events =
      from(e in Event,
        order_by: [desc: e.inserted_at],
        limit: 5,
        left_join: c in Contribution, on: c.event_id == e.id,
        group_by: e.id,
        select: %{
          id: e.id,
          title: e.title,
          description: e.description,
          inserted_at: e.inserted_at,
          total_contributed: coalesce(sum(c.amount), 0)
        }
      )
      |> Repo.all()

    %{
      eligible: eligible,
      ineligible: ineligible,
      total_contributions: total_contributions,
      last5_events: last5_events
    }
  end

  defp load_hr do
    %{
      total_employees: Repo.aggregate(User, :count, :id),
      out_of_office: Repo.aggregate(AwayRequest, :count, :id),
      total_interns: Repo.aggregate(InternAttachee, :count, :id),
      leave_by_type:
        from(lb in LeaveBalance,
          join: lt in LeaveType, on: lb.leave_type_id == lt.id,
          group_by: lt.name,
          select: {lt.name, sum(lb.remaining_days)}
        )
        |> Repo.all()
    }
  end

  defp load_ict do
    counts =
      Inventory.get_status_counts()
      |> Map.merge(%{lost: 0, available: 0, assigned: 0, revoked: 0, decommissioned: 0}, fn _k, v, _ -> v end)

    %{
      asset_counts: counts,
      top_departments: Inventory.get_top_departments(),
      top_users: Inventory.get_top_users()
    }
  end

  # ---------- Helpers ----------

  # show a tab only when the user explicitly has that tab right
  defp can_view_tab?(user, :welfare),
    do: Canada.Can.can?(user, ["view"], "dashboard_welfare")

  defp can_view_tab?(user, :hr),
    do: Canada.Can.can?(user, ["view"], "dashboard_hr")

  defp can_view_tab?(user, :ict),
    do: Canada.Can.can?(user, ["view"], "dashboard_ict")

  defp can_view_dashboard?(user),
    do: Canada.Can.can?(user, ["view"], "dashboard")

  def tab_label(:welfare), do: "Welfare"
  def tab_label(:hr), do: "HR"
  def tab_label(:ict), do: "ICT"

  defp to_tab(tab) when is_binary(tab) do
    case String.downcase(tab) do
      "welfare" -> {:ok, :welfare}
      "hr" -> {:ok, :hr}
      "ict" -> {:ok, :ict}
      _ -> :error
    end
  end
end
