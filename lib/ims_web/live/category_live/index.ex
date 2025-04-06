defmodule ImsWeb.CategoryLive.Index do
  use ImsWeb, :live_view

  alias Ims.Inventory
  alias Ims.Inventory.Category
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:categories, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:category, Inventory.get_category!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:category, %Category{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Categories")
    |> assign(:category, nil)
  end

  @impl true
  def handle_info({ImsWeb.CategoryLive.FormComponent, {:saved, _category}}, socket) do
    categories =
      fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Category saved successfully")
     |> assign(:categories, categories)}
  end

  def handle_event("edit" <> id, _params, socket) do
    case Inventory.get_category!(id) do
      nil ->
        {:noreply, assign(socket, error: "Category not found")}

      category ->
        {:noreply,
         assign(socket,
           live_action: :edit,
           category: category
         )}
    end
  end

  @impl true
  def handle_event("delete" <> id, _params, socket) do
    category = Inventory.get_category!(id)
    {:ok, _} = Inventory.delete_category(category)

    {:noreply, stream_delete(socket, :categories, category)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = Inventory.Category.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
