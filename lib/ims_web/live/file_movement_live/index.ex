defmodule ImsWeb.FileMovementLive.Index do
  use ImsWeb, :live_view

  alias Ims.Files
  alias Ims.Files.FileMovement

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :file_movements, Files.list_file_movements())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit File movement")
    |> assign(:file_movement, Files.get_file_movement!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New File movement")
    |> assign(:file_movement, %FileMovement{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing File movements")
    |> assign(:file_movement, nil)
  end

  @impl true
  def handle_info({ImsWeb.FileMovementLive.FormComponent, {:saved, file_movement}}, socket) do
    {:noreply, stream_insert(socket, :file_movements, file_movement)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    file_movement = Files.get_file_movement!(id)
    {:ok, _} = Files.delete_file_movement(file_movement)

    {:noreply, stream_delete(socket, :file_movements, file_movement)}
  end
end
