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



  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")

    filter_params =
      params
      |> Map.take([
        "name",
        "status",
        "category_id",
        "user_id",
        "department_id",
        "assigned_user_id"
      ])
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    filters =
      case Canada.Can.can?(socket.assigns.current_user, ["list_all"], "devices") do
        true -> filter_params
        false -> Map.put(filter_params, "assigned_user_id", socket.assigns.current_user.id)
      end

    socket =
      socket
      |> assign(:page, page)
      |> assign(:filters, filters)
      |> assign(:assets, fetch_records(filters, Keyword.put(@paginator_opts, :page, page)))

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
  def handle_info({:saved, %Ims.Inventory.AssetLog{}}, socket) do
    assets = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset saved successfully")
     |> assign(:assets, assets)}
  end

  @impl true
  def handle_info({ImsWeb.AssetLive.FormComponent, {:saved, _device}}, socket) do
    assets = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Asset saved successfully")
     |> assign(:assets, assets)}
  end

  def handle_event("department_id", %{"department_id" => department_id}, socket) do
    # apply filters to the asset list

    filters = socket.assigns.filters
    filters = Map.put(filters, "department_id", department_id)

    # fetch_records(filters, @paginator_opts)
    # assets = fetch_records(filters, @paginator_opts)

    {:noreply,
     socket
     |> assign(:filters, filters)}
  end

  @impl true
  def handle_event("assign_device" <> id, _, socket) do
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
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)
    IO.inspect("Marking as lost")
    IO.inspect(asset, label: "Asset")

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Mark Asset as Lost")
     |> assign(:live_action, :mark_as_lost)}
  end

  @impl true
  def handle_event("revoke_device" <> id, _, socket) do
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)
    IO.inspect("Revoke assets")
    IO.inspect(asset, label: "Asset")

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Revoke Asset")
     |> assign(:live_action, :revoke_device)}
  end

  @impl true
  def handle_event("decommission_device" <> id, _, socket) do
    asset = Inventory.get_asset!(id) |> Ims.Repo.preload(:asset_name)

    {:noreply,
     socket
     |> assign(:asset, asset)
     |> assign(:show_modal, true)
     |> assign(:page_title, "Decommission Asset")
     |> assign(:live_action, :decommission_device)}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    asset_logs = get_asset_logs_by_asset_id(id)
    {:noreply, push_navigate(socket, to: ~p"/assets/#{id}")}
  end

  # @impl true
  # def handle_event("select_changed", %{"department_id" => department_id}, socket) do
  #   # apply filters to the asset list
  #   filters = socket.assigns.filters
  #   filters = Map.put(filters, "department_id", department_id)

  #   {:noreply,
  #    socket
  #    |> assign(:filters, filters)}
  # end

  # @impl true
  # def handle_event("select_changed", %{"user_id" => user_id}, socket) do
  #   # apply filters to the asset list
  #   filters = socket.assigns.filters
  #   filters = Map.put(filters, "user_id", user_id)

  #   {:noreply,
  #    socket
  #    |> assign(:filters, filters)}
  # end

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

  @impl true
  def handle_event("apply_filters", %{} = filter_params, socket) do
    IO.inspect(filter_params, label: "Filter Params")

    filters =
      filter_params
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    filters =
      if Canada.Can.can?(socket.assigns.current_user, ["list_all"], "devices") do
        filters
      else
        Map.put(filters, "assigned_user_id", socket.assigns.current_user.id)
      end

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:assets, fetch_records(filters, Keyword.put(@paginator_opts, :page, 1)))}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(:assets, fetch_records(%{}, @paginator_opts))}
  end

  defp fetch_records(filters, opts) do
    filters = atomize_keys(filters)
    query = Asset.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)
    query |> Ims.Repo.paginate(opts)
  end

  def get_asset_logs_by_asset_id(asset_id) do
    Inventory.get_asset_logs_by_asset_id(asset_id)
  end

  defp atomize_keys(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      key =
        cond do
          is_binary(k) ->
            try do
              String.to_existing_atom(k)
            rescue
              ArgumentError -> k
            end

          true ->
            k
        end

      Map.put(acc, key, v)
    end)
  end

  defp maybe_atom(k) when is_binary(k), do: String.to_existing_atom(k)
  defp maybe_atom(k), do: k
end
