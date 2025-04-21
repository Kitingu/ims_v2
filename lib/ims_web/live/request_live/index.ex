defmodule ImsWeb.RequestLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Request
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:requests, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
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
  def handle_info({ImsWeb.RequestLive.FormComponent, {:saved, _request}}, socket) do
    requests =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Request saved successfully")
     |> assign(:requests, requests)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    request = Inventory.get_request!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Asset type",
       request: request,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/requests/#{id}")}
  end

  def handle_event("approve" <> id, _params, socket) do
    request = Inventory.get_request!(id)

    {:noreply,
     assign(socket,
       page_title: "Approve Request",
       request: request,
       live_action: :approve
     )}
  end

  def handle_event("reject" <> id, _params, socket) do
    user_id = socket.assigns.current_user.id

    case Inventory.decline_request(id, user_id) |> IO.inspect() do
      {:ok, _request} ->
        requests =
          fetch_records(socket.assigns.filters, @paginator_opts)

        socket =
          socket
          |> assign(:requests, requests)
          |> put_flash(:info, "Request declined successfully.")

        {:noreply, socket}

      _ ->
        requests =
          fetch_records(socket.assigns.filters, @paginator_opts)

        socket =
          socket
          |> assign(:requests, requests)
          |> put_flash(:error, "Request decline failed try again.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Inventory.get_request!(id)
    {:ok, _} = Inventory.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = Request.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
