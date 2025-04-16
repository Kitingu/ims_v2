defmodule ImsWeb.AwayRequestLive.Show do
  use ImsWeb, :live_view

  alias Ims.HR

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:away_request, HR.get_away_request!(id))}
  end

  defp page_title(:show), do: "Show Away request"
  defp page_title(:edit), do: "Edit Away request"
end
