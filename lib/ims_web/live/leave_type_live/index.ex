defmodule ImsWeb.LeaveTypeLive.Index do
  use ImsWeb, :live_view

  alias Ims.Leave
  alias Ims.Leave.LeaveType

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :leave_types, Leave.list_leave_types())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Leave type")
    |> assign(:leave_type, Leave.get_leave_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Leave type")
    |> assign(:leave_type, %LeaveType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Leave types")
    |> assign(:leave_type, nil)
  end

  @impl true
  def handle_info({ImsWeb.LeaveTypeLive.FormComponent, {:saved, leave_type}}, socket) do
    {:noreply, stream_insert(socket, :leave_types, leave_type)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    leave_type = Leave.get_leave_type!(id)
    {:ok, _} = Leave.delete_leave_type(leave_type)

    {:noreply, stream_delete(socket, :leave_types, leave_type)}
  end
end
