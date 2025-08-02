defmodule ImsWeb.FileMovementLive.Show do
  use ImsWeb, :live_view

  alias Ims.Files

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:file_movement, Files.get_file_movement!(id))}
  end

  defp page_title(:show), do: "Show File movement"
  defp page_title(:edit), do: "Edit File movement"
end
