defmodule ImsWeb.EventTypeLive.Show do
  use ImsWeb, :live_view

  alias Ims.Welfare

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:event_type, Welfare.get_event_type!(id))}
  end

  defp page_title(:show), do: "Show Event type"
  defp page_title(:edit), do: "Edit Event type"
end
