defmodule ImsWeb.DepartmentsLive.Index do
  use ImsWeb, :live_view

  alias Ims.Accounts
  alias Ims.Accounts.Departments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :departments_collection, Accounts.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Departments")
    |> assign(:departments, Accounts.get_departments!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Departments")
    |> assign(:departments, %Departments{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Departments")
    |> assign(:departments, nil)
  end

  @impl true
  def handle_info({ImsWeb.DepartmentsLive.FormComponent, {:saved, departments}}, socket) do
    {:noreply, stream_insert(socket, :departments_collection, departments)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    departments = Accounts.get_departments!(id)
    {:ok, _} = Accounts.delete_departments(departments)

    {:noreply, stream_delete(socket, :departments_collection, departments)}
  end
end
