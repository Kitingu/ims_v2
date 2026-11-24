defmodule ImsWeb.LeaveApplicationLive.Show do
  use ImsWeb, :live_view

  alias Ims.Leave

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    application = Leave.get_leave_application!(id)

    if socket.assigns.live_action == :edit &&
         (application.status != "pending" ||
            !Canada.Can.can?(socket.assigns.current_user, ["edit"], "leave_applications")) do
      {:noreply, push_patch(socket, to: ~p"/hr/leave_applications/#{application}")}
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:leave_application, application)}
    end
  end

  defp page_title(:show), do: "Show Leave application"
  defp page_title(:edit), do: "Edit Leave application"
end
