defmodule ImsWeb.LeaveApplicationLive.Show do
  use ImsWeb, :live_view

  alias Ims.Leave

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:leave_application, Leave.get_leave_application!(id))}
  end

  defp page_title(:show), do: "Show Leave application"
  defp page_title(:edit), do: "Edit Leave application"
end
