defmodule ImsWeb.AwayRequestLive.Index do
  use ImsWeb, :live_view

  alias Ims.HR
  alias Ims.HR.AwayRequest

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :away_requests, HR.list_away_requests())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Away request")
    |> assign(:away_request, HR.get_away_request!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Away request")
    |> assign(:away_request, %AwayRequest{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Away requests")
    |> assign(:away_request, nil)
  end

  @impl true
  def handle_info({ImsWeb.AwayRequestLive.FormComponent, {:saved, away_request}}, socket) do
    {:noreply, stream_insert(socket, :away_requests, away_request)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    away_request = HR.get_away_request!(id)
    {:ok, _} = HR.delete_away_request(away_request)

    {:noreply, stream_delete(socket, :away_requests, away_request)}
  end
end
