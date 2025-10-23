defmodule ImsWeb.InternAttacheeLive.Index do
  use ImsWeb, :live_view

  alias Ims.Interns
  alias Ims.Interns.InternAttachee
  @paginator_opts [order_by: [desc: :id], page_size: 15]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:intern_attachees, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Intern attachee")
    |> assign(:intern_attachee, Interns.get_intern_attachee!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Intern attachee")
    |> assign(:intern_attachee, %InternAttachee{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Intern attachees")
    |> assign(:intern_attachee, nil)
  end

  @impl true
  def handle_info({ImsWeb.InternAttacheeLive.FormComponent, {:saved, _intern_attachee}}, socket) do
    intern_attachees = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Intern attachee saved successfully")
     |> assign(:intern_attachees, intern_attachees)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    intern_attachee = Interns.get_intern_attachee!(id)
    {:ok, _} = Interns.delete_intern_attachee(intern_attachee)

    {:noreply, stream_delete(socket, :intern_attachees, intern_attachee)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    intern_attacheesççç =
      fetch_records(socket.assigns.filters, page_size: String.to_integer(size)) |> IO.inspect()

    {:noreply, assign(socket, intern_attacheesççç: intern_attacheesççç)}
  end

  def handle_event("render_page", %{"page" => page}, socket) do
    IO.inspect("page: #{page}")
    current_page = socket.assigns.page |> IO.inspect(label: "Current Page")

    # Determine new page number based on the action

    new_page =
      case page do
        "next" -> current_page + 1
        "previous" -> max(current_page - 1, 1)
        _ -> String.to_integer(page)
      end

    opts = Keyword.merge(@paginator_opts, page: new_page)
    intern_attachees = fetch_records(socket.assigns.filters, opts)

    socket =
      socket
      |> assign(:intern_attachees, intern_attachees)
      |> assign(:page, new_page)

    # No need for String.to_integer here
    {:noreply, socket}
  end

  def fetch_records(filters, opts) do
    opts = Keyword.merge(opts, @paginator_opts)

    InternAttachee.search(filters)
    |> Ims.Repo.paginate(opts)
    |> IO.inspect(label: "InternAttachee.search(filters)")
  end
end
