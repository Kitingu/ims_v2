defmodule ImsWeb.AssetLogLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.AssetLog

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{"action" => "assigned"}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      # for active tab UI
      |> assign(:current_tab, "assigned")
      |> assign(:asset_logs, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset log")
    |> assign(:asset_log, Inventory.get_asset_log!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset log")
    |> assign(:asset_log, %AssetLog{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Asset logs")
    |> assign(:asset_log, nil)
  end

  def handle_info({ImsWeb.AssetLogLive.FormComponent, {:saved, _device}}, socket) do
    asset_logs =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Action recorded successfully")
     |> assign(:asset_logs, asset_logs)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    filters = Map.put(socket.assigns.filters, "action", tab) |> IO.inspect(label: "tumeitanananana")

    asset_logs =
      fetch_records(filters, @paginator_opts)
      |> IO.inspect(label: "asset_logs")

    {:noreply,
     socket
     |> assign(:current_tab, tab)
     |> assign(:filters, filters)
     |> assign(:asset_logs, asset_logs)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    asset_logs =
      fetch_records(socket.assigns.filters, page_size: String.to_integer(size)) |> IO.inspect()

    {:noreply, assign(socket, asset_logs: asset_logs)}
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
    asset_logs = fetch_records(socket.assigns.filters, opts)

    socket =
      socket
      |> assign(:asset_logs, asset_logs)

    # No need for String.to_integer here
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset_log = Inventory.get_asset_log!(id)
    {:ok, _} = Inventory.delete_asset_log(asset_log)

    {:noreply, stream_delete(socket, :asset_logs, asset_log)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    filters = atomize_keys(filters)
    query = AssetLog.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end

  defp atomize_keys(map) do
    for {k, v} <- map, into: %{} do
      {maybe_atom(k), v}
    end
  end

  defp maybe_atom(k) when is_binary(k), do: String.to_existing_atom(k)
  defp maybe_atom(k), do: k
end
