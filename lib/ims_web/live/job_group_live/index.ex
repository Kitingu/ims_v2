defmodule ImsWeb.JobGroupLive.Index do
  use ImsWeb, :live_view

  alias Ims.Accounts
  alias Ims.Accounts.JobGroup

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :job_groups, Accounts.list_job_groups())}
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
    {:noreply, stream_insert(socket, :job_groups, job_group)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job_group = Accounts.get_job_group!(id)
    {:ok, _} = Accounts.delete_job_group(job_group)

    {:noreply, stream_delete(socket, :job_groups, job_group)}
  end
end
