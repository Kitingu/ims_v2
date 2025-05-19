defmodule ImsWeb.EventLive.Index do
  use ImsWeb, :live_view

  alias Ims.Welfare
  alias Ims.Welfare.Event

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:events, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    IO.inspect(socket.assigns.live_action)
    IO.inspect(params["live_action"], label: "params")

    live_action =
      case socket.assigns.live_action do
        "upload_contributions" ->
          :upload_contributions

        :new ->
          :new

        "edit" ->
          :edit

        _ ->
          case params["live_action"] |> IO.inspect() do
            "upload_contributions" -> :upload_contributions
            _ -> :index
          end
      end
      |> IO.inspect()

    socket = assign(socket, live_action: live_action)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, Welfare.get_event!(id))
  end

  defp apply_action(socket, :upload_contributions, _) do
    socket
    |> assign(:page_title, "Upload Contributions")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Event{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({ImsWeb.EventLive.FormComponent, {:saved, _event}}, socket) do
    events = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Event saved successfully")
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("edit" <> id, _, socket) do
    event = Welfare.get_event!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Edit Event")
     |> assign(:event, event)
     |> assign(:live_action, :edit)}
  end

  @impl true
  def handle_event("new", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/welfare/events/new")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Welfare.get_event!(id)
    {:ok, _} = Welfare.delete_event(event)
    events = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Event deleted successfully")
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/welfare/events/#{id}")}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = Event.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
