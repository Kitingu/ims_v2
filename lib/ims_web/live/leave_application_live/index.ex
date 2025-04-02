defmodule ImsWeb.LeaveApplicationLive.Index do
  use ImsWeb, :live_view

  alias Ims.Leave
  alias Ims.Leave.LeaveApplication

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :leave_applications, Leave.list_leave_applications())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Leave application")
    |> assign(:leave_application, Leave.get_leave_application!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Leave application")
    |> assign(:leave_application, %LeaveApplication{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Leave applications")
    |> assign(:leave_application, nil)
  end

  @impl true
  def handle_info({ImsWeb.LeaveApplicationLive.FormComponent, {:saved, leave_application}}, socket) do
    {:noreply, stream_insert(socket, :leave_applications, leave_application)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    leave_application = Leave.get_leave_application!(id)
    {:ok, _} = Leave.delete_leave_application(leave_application)

    {:noreply, stream_delete(socket, :leave_applications, leave_application)}
  end
end
