defmodule ImsWeb.FileLive.Index do
  use ImsWeb, :live_view

  alias Ims.Files
  alias Ims.Files.File
    @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]


  @impl true
  def mount(_params, _session, socket) do
    filters = %{}
    files = fetch_records(filters, @paginator_opts)

    socket =
      socket
      |> assign(:page_title, "Listing Files")
      |> assign(:files, files)
      |> assign(:current_user, socket.assigns.current_user)


    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit File")
    |> assign(:file, Files.get_file!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New File")
    |> assign(:file, %File{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Files")
    |> assign(:file, nil)
  end

  @impl true
  def handle_info({ImsWeb.FileLive.FormComponent, {:saved, file}}, socket) do
    {:noreply, stream_insert(socket, :files, file)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    file = Files.get_file!(id)
    {:ok, _} = Files.delete_file(file)

    {:noreply, stream_delete(socket, :files, file)}
  end

  def fetch_records(filters, opts) do
    
    query = File.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)
    query |> Ims.Repo.paginate(opts)
  end
end
