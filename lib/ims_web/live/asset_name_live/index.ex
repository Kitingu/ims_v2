defmodule ImsWeb.AssetNameLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.AssetName
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:asset_names, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset name")
    |> assign(:asset_name, Inventory.get_asset_name!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset name")
    |> assign(:asset_name, %AssetName{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Asset names")
    |> assign(:asset_name, nil)
  end

  @impl true
  def handle_info({ImsWeb.AssetNameLive.FormComponent, {:saved, _device}}, socket) do
    asset_names =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset name saved successfully")
     |> assign(:asset_names, asset_names)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    asset_name = Inventory.get_asset_name!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Asset type",
       asset_name: asset_name,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/asset_names/#{id}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset_name = Inventory.get_asset_name!(id)
    {:ok, _} = Inventory.delete_asset_name(asset_name)

    {:noreply, stream_delete(socket, :asset_names, asset_name)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = AssetName.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
