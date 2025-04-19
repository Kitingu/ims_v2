defmodule ImsWeb.JobGroupLive.Index do
  use ImsWeb, :live_view

  alias Ims.Accounts
  alias Ims.Accounts.JobGroup
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]


  @impl true
  def mount(_params, _session, socket) do
    filters = %{}

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> assign(:job_groups, fetch_records(filters, @paginator_opts))
      |> assign(:current_user, socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Job group")
    |> assign(:job_group, Accounts.get_job_group!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Job group")
    |> assign(:job_group, %JobGroup{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Job groups")
    |> assign(:job_group, nil)
  end

  @impl true
  def handle_info({ImsWeb.JobGroupLive.FormComponent, {:saved, job_group}}, socket) do
    job_groups =
    fetch_records(socket.assigns.filters, @paginator_opts)


    {:noreply,
     socket
     |> put_flash(:info, "Job Group saved successfully")
     |> assign(:job_groups, job_groups)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    job_group = Accounts.get_job_group!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Asset type",
       job_group: job_group,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/job_groups/#{id}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job_group = Accounts.get_job_group!(id)
    {:ok, _} = Accounts.delete_job_group(job_group)

    {:noreply, stream_delete(socket, :job_groups, job_group)}
  end

  defp fetch_records(filters, opts) do
    IO.inspect(opts, label: "opts")
    query = JobGroup.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
