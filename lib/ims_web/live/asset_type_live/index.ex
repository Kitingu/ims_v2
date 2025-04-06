defmodule ImsWeb.AssetTypeLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.AssetType

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]


  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:asset_types, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset type")
    |> assign(:asset_type, Inventory.get_asset_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset type")
    |> assign(:asset_type, %AssetType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Asset types")
    |> assign(:asset_type, nil)
  end

  @impl true
  def handle_info({ImsWeb.AssetTypeLive.FormComponent, {:saved, _device}}, socket) do
    asset_types =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset type saved successfully")
     |> assign(:asset_types, asset_types)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset_type = Inventory.get_asset_type!(id)
    {:ok, _} = Inventory.delete_asset_type(asset_type)

    {:noreply, stream_delete(socket, :asset_types, asset_type)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = AssetType.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
