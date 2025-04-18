defmodule ImsWeb.LocationLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Location

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:locations, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Location")
    |> assign(:location, Inventory.get_location!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Location")
    |> assign(:location, %Location{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Locations")
    |> assign(:location, nil)
  end

  @impl true
  def handle_info({ImsWeb.LocationLive.FormComponent, {:saved, _device}}, socket) do
    locations =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Location saved successfully")
     |> assign(:locations, locations)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    locations =
      fetch_records(socket.assigns.filters, page_size: String.to_integer(size)) |> IO.inspect()

    {:noreply, assign(socket, locations: locations)}
  end

  def handle_event("render_page", %{"page" => page}, socket) do
    IO.inspect("page: #{page}")

    new_page =
      case page do
        "next" -> socket.assigns.page + 1
        "previous" -> socket.assigns.page - 1
        # Convert string to integer for other cases
        _ -> String.to_integer(page)
      end

    IO.inspect("new_page: #{new_page}")

    opts = Keyword.merge(@paginator_opts, page: new_page)
    locations = fetch_records(socket.assigns.filters, opts)

    socket =
      socket
      |> assign(:locations, locations)

    # No need for String.to_integer here
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    location = Inventory.get_location!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Asset type",
       location: location,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/locations/#{id}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    location = Inventory.get_location!(id)
    {:ok, _} = Inventory.delete_location(location)

    {:noreply, stream_delete(socket, :locations, location)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = Inventory.Location.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
