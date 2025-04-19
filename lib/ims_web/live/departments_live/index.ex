defmodule ImsWeb.DepartmentsLive.Index do
  use ImsWeb, :live_view

  alias Ims.Accounts
  alias Ims.Accounts.Departments

  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do

    departments = Accounts.list_departments() |> Ims.Repo.paginate(@paginator_opts)
    |> IO.inspect(label: "departments")


    socket =
      socket
      |> assign(:all_departments, departments)
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:page, 1)
      |> assign(:csrf_token, Plug.CSRFProtection.get_csrf_token())

    {:ok, socket}
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
  def handle_info({ImsWeb.DepartmentsLive.FormComponent, {:saved, _departments}}, socket) do
    departments = Accounts.list_departments() |> Ims.Repo.paginate(@paginator_opts)

    {:noreply,
     socket
     |> put_flash(:info, "Departments updated successfully")
     |> assign(:all_departments, departments)}
  end

  @impl true
  def handle_event("edit" <> id, _params, socket) do
    departments = Accounts.get_departments!(id)

    {:noreply,
     assign(socket,
       page_title: "Edit Department",
       departments: departments,
       live_action: :edit
     )}
  end

  @impl true
  def handle_event("view" <> id, _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/departments/#{id}")}
  end


  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    departments = Accounts.get_departments!(id)
    {:ok, _} = Accounts.delete_departments(departments)

    {:noreply, stream_delete(socket, :departments_collection, departments)}
  end
end
