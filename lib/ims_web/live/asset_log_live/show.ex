defmodule ImsWeb.AssetLogLive.Show do
  use ImsWeb, :live_view

  alias Ims.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset_log, Inventory.get_asset_log!(id))}
  end

  defp page_title(:show), do: "Show Asset log"
  defp page_title(:edit), do: "Edit Asset log"
end
