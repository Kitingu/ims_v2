defmodule ImsWeb.AssetLive.Show do
  use ImsWeb, :live_view

  alias Ims.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    asset = Inventory.get_asset!(id)

    asset_logs =
      Inventory.get_asset_logs_by_asset_id(asset.id)
      |> Ims.Repo.preload([:user, :office])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, asset)
     |> assign(:asset_logs, asset_logs)}
  end


  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"

  def list_asset_logs_for_asset(asset_id) do
    Inventory.get_asset_logs_by_asset_id(asset_id)
  end
end
