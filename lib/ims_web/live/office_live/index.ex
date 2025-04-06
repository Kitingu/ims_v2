defmodule ImsWeb.OfficeLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Office
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]


  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:offices, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Office")
    |> assign(:office, Inventory.get_office!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Office")
    |> assign(:office, %Office{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Offices")
    |> assign(:office, nil)
  end

  @impl true
  def handle_info({ImsWeb.OfficeLive.FormComponent, {:saved, _device}}, socket) do
    offices =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Office saved successfully")
     |> assign(:offices, offices)}
  end


  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    office = Inventory.get_office!(id)
    {:ok, _} = Inventory.delete_office(office)

    {:noreply, stream_delete(socket, :offices, office)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = Office.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
