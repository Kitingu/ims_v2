defmodule ImsWeb.AssetLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Asset
  alias Ims.Accounts
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
      |> assign(:show_modal, false)
      |> assign(:users, Ims.Accounts.list_users())
      |> assign(:departments, Accounts.list_departments())
      |> assign(:asset_names, Inventory.list_device_names())
      |> assign(:assets, fetch_records(filters, @paginator_opts))
      |> assign(:categories, Inventory.list_categories())
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  # @impl true
  # def handle_params(params, _url, socket) do
  #   {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  # end

  @impl true
  def handle_params(params, _url, socket) do
    params =
      Map.take(params, ["name", "status", "category_id", "assigned_user_id", "department_id"])
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    filters =
      case Canada.Can.can?(socket.assigns.current_user, ["list_all"], "devices") do
        true -> params
        false -> Map.put(params, "assigned_user_id", socket.assigns.current_user.id)
      end

    devices = fetch_records(filters, @paginator_opts)

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:devices, devices)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assets")
    |> assign(:asset, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Ims.Inventory.Asset{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Ims.Inventory.get_asset!(id))
  end

  defp apply_action(socket, :assign, params) do
    IO.inspect(params, label: "params")
    id = params["id"]

    socket
    |> assign(:page_title, "Assign Asset")
    |> assign(:asset, Ims.Inventory.get_asset!(id))
    |> assign(:live_action, :assign)
  end

  @impl true
  def handle_info(
    {ImsWeb.AssetLogLive.FormComponent, {:saved, %Ims.Inventory.AssetLog{} = asset_log}},
    socket
  ) do
    assets = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset log saved successfully")
     |> assign(:assets, assets)}
  end

  @impl true
  # {:saved, %Ims.Inventory.AssetLog{}}
  def handle_info({:saved, %Ims.Inventory.AssetLog{}}, socket) do
    assets =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset saved successfully")
     |> assign(:assets, assets)}
  end

  @impl true
  def handle_info({ImsWeb.AssetLive.FormComponent, {:saved, _device}}, socket) do
    assets =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset saved successfully")
     |> assign(:assets, assets)}
  end

  @impl true
  def handle_event("assign_device" <> id, _, socket) do
    IO.inspect(id, label: "id")
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Assign Asset")
     |> assign(:live_action, :assign_device)}
  end

  @impl true
  def handle_event("return_device" <> id, _, socket) do
    IO.inspect(id, label: "id")
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Return Asset")
     |> assign(:live_action, :return_device)}
  end

  @impl true
  def handle_event("mark_as_lost" <> id, _, socket) do
    IO.inspect(id, label: "id")
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Mark Asset as Lost")
     |> assign(:live_action, :mark_as_lost)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset = Inventory.get_asset!(id)
    {:ok, _} = Inventory.delete_asset(asset)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    filters = atomize_keys(filters)
    query = Asset.search(filters)
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
