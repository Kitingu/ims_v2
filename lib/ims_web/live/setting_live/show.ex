defmodule ImsWeb.SettingLive.Show do
  use ImsWeb, :live_view

  alias Ims.Settings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:setting, Settings.get_setting!(id))}
  end

  defp page_title(:show), do: "Show Setting"
  defp page_title(:edit), do: "Edit Setting"
end
