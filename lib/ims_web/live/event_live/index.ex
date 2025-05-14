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

  def handle_params(params, _uri, socket) do
    live_action =
      case params["live_action"] do
        "upload_contributions" -> :upload_contributions
        "new" -> :new
        "edit" -> :edit
        _ -> :index
      end

    socket = assign(socket, live_action: live_action)

    socket =
      case live_action do
        :upload_contributions ->
          assign(socket, page_title: "Upload Contributions")

        :new ->
          assign(socket, event: %Event{}, page_title: "New Event")

        :edit ->
          if id = params["id"] do
            event = Welfare.get_event!(id)
            assign(socket, event: event, page_title: "Edit Event")
          else
            socket
          end

        _ ->
          socket
      end

    {:noreply, socket}
  end




  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, Welfare.get_event!(id))
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
    events =
      fetch_records(socket.assigns.filters, @paginator_opts)

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
