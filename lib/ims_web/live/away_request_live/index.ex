defmodule ImsWeb.AwayRequestLive.Index do
  use ImsWeb, :live_view

  alias Ims.HR
  alias Ims.HR.AwayRequest
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:csrf_token, csrf_token)
      |> assign(:away_requests, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
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
    away_requests = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Away request saved successfully")
     |> assign(:away_requests, away_requests)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    away_requests =
      fetch_records(socket.assigns.filters, page_size: String.to_integer(size)) |> IO.inspect()

    {:noreply, assign(socket, away_requests: away_requests)}
  end

  def handle_event("render_page", %{"page" => page}, socket) do
    IO.inspect("page: #{page}")

    new_page =
      case page do
        "next" -> socket.assigns.page + 1
        "previous" -> socket.assigns.page - 1
        # Convert string to integer for other cases
        _ -> String.to_integer(page)
      end

    IO.inspect("new_page: #{new_page}")

    opts = Keyword.merge(@paginator_opts, page: new_page)
    away_requests = fetch_records(socket.assigns.filters, opts)

    socket =
      socket
      |> assign(:away_requests, away_requests)

    # No need for String.to_integer here
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    away_request = HR.get_away_request!(id)
    {:ok, _} = HR.delete_away_request(away_request)

    {:noreply, stream_delete(socket, :away_requests, away_request)}
  end

  defp fetch_records(filters, opts) do
    filters = atomize_keys(filters)
    query = AwayRequest.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)
    query |> Ims.Repo.paginate(opts)
  end

  defp atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      {maybe_atom(k), v}
    end
  end

  defp maybe_atom(k) when is_binary(k), do: String.to_existing_atom(k)
  defp maybe_atom(k), do: k
end
