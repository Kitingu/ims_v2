defmodule ImsWeb.AssetLive.Show do
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
     |> assign(:asset, Inventory.get_asset!(id))}
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"
end
