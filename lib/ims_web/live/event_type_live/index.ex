defmodule ImsWeb.EventTypeLive.Index do
  use ImsWeb, :live_view

  alias Ims.Welfare
  alias Ims.Welfare.EventType

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:event_types, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event type")
    |> assign(:event_type, Welfare.get_event_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event type")
    |> assign(:event_type, %EventType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Event types")
    |> assign(:event_type, nil)
  end

  @impl true
  def handle_info({ImsWeb.EventTypeLive.FormComponent, {:saved, event_type}}, socket) do
    event_types =
      fetch_records(socket.assigns.filters, @paginator_opts)
      |> Map.put(:page_number, socket.assigns.page)

    {:noreply,
     socket
     |> put_flash(:info, "Event Type saved successfully")
     |> assign(:event_types, event_types)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    event_type = Welfare.get_event_type!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Event type",
       event_type: event_type,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event_type = Welfare.get_event_type!(id)
    {:ok, _} = Welfare.delete_event_type(event_type)

    event_types =
      fetch_records(socket.assigns.filters, @paginator_opts)
      |> Map.put(:page_number, socket.assigns.page)

    {:noreply,
     socket
     |> put_flash(:info, "Event Type deleted successfully")
     |> assign(:event_types, event_types)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = EventType.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
