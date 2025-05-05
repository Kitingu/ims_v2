defmodule ImsWeb.EventLive.Show do
  use ImsWeb, :live_view
  alias Ims.Welfare
  alias Ims.Welfare.Contribution
  alias Ims.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, 1)
     |> assign(:per_page, 10)
     |> assign(:contributions, [])
     |> assign(:total_contributions, Decimal.new(0))
     |> assign(:progress_percentage, Decimal.new(0))}
  end

  @impl true
  def handle_params(%{"id" => id, "page" => page}, _, socket) do
    page = String.to_integer(page)
    handle_params(%{"id" => id}, %{}, assign(socket, :page, page))
  end

  def handle_params(%{"id" => id}, _, socket) do
    event = Welfare.get_event!(id) |> Repo.preload([:event_type, :user])

    # Fetch paginated contributions using fetch_records
    %{entries: contributions, metadata: meta} =
      fetch_records(%{event_id: id}, page: socket.assigns.page, per_page: socket.assigns.per_page)

    # Calculate total contributions (not just paginated ones)
    total_contributions = Contribution.total_contributions_for_event(id)
    progress_percentage = calculate_progress(event, total_contributions)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:event, event)
     |> assign(:contributions, contributions)
     |> assign(:total_contributions, total_contributions)
     |> assign(:progress_percentage, progress_percentage)
     |> assign(:page_metadata, meta)}
  end

  defp page_title(:show), do: "Show Event"
  defp page_title(:edit), do: "Edit Event"

  defp fetch_records(filters, opts) do
    query = Contribution.search(filters)
    # Merge with default pagination options if needed
    opts = Keyword.merge([page: 1, per_page: 10], opts)
    query
    |> Ims.Repo.paginate(opts)
  end

  defp calculate_progress(event, total) do
    if event.target_amount && Decimal.compare(event.target_amount, Decimal.new(0)) == :gt do
      Decimal.mult(Decimal.div(total, event.target_amount), 100)
      |> Decimal.round(2)
    else
      Decimal.new(0)
    end
  end

  @impl true
  def handle_event("verify", %{"id" => id}, socket) do
    contribution = Contribution.get!(id)

    case Welfare.verify_contribution(contribution) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contribution verified successfully")
         |> push_patch(to: Routes.event_show_path(socket, :show, socket.assigns.event.id, page: socket.assigns.page))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to verify contribution")}
    end
  end
end
