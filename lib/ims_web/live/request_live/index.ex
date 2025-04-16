defmodule ImsWeb.RequestLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Request

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :requests, Inventory.list_requests())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, Inventory.get_request!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, %Request{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Requests")
    |> assign(:request, nil)
  end

  @impl true
  def handle_info({ImsWeb.RequestLive.FormComponent, {:saved, request}}, socket) do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Inventory.get_request!(id)
    {:ok, _} = Inventory.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end
end
