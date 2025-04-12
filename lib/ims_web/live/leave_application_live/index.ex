defmodule ImsWeb.LeaveApplicationLive.Index do
  use ImsWeb, :live_view

  alias Ims.Leave
  alias Ims.Leave.LeaveApplication

  @paginator_opts [order_by: [desc: :id], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    filters = %{}
    leave_applications = fetch_records(filters, @paginator_opts)

    is_admin = Canada.Can.can?(socket.assigns.current_user, ["manage"], "hr_dashboard")

    {:ok,
     socket
     |> assign(
       :leave_applications,
       leave_applications
     )
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:is_admin, is_admin)
     |> assign(:page_title, "Listing Leave applications")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    params =
      Map.take(params, ["status", "user_id"])
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})

    filters =
      case Canada.Can.can?(socket.assigns.current_user, ["list_all"], "leave_applications") do
        true -> params
        false -> Map.put(params, "user_id", socket.assigns.current_user.id)
      end

    leave_applications = fetch_records(filters, @paginator_opts)

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:leave_applications, leave_applications)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Leave application")
    |> assign(:leave_application, Leave.get_leave_application!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Leave application")
    |> assign(:leave_application, %LeaveApplication{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Leave applications")
    |> assign(:leave_application, nil)
  end

  @impl true
  def handle_info(
        {ImsWeb.LeaveApplicationLive.FormComponent, {:saved, _leave_application}},
        socket
      ) do
    leave_applications = fetch_records(socket.assigns.filters, @paginator_opts)

    {:noreply,
     socket
     |> assign(:leave_applications, leave_applications)
     |> redirect(to: "/leave_applications")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    leave_application = Leave.get_leave_application!(id)
    {:ok, _} = Leave.delete_leave_application(leave_application)

    {:noreply, stream_delete(socket, :leave_applications, leave_application)}
  end

  def handle_event("approve" <> id, _params, socket) do
    case LeaveApplication.approve_leave_application(id) do
      {:ok, _leave_application} ->
        socket =
          socket
          |> assign(:leave_applications, fetch_records(socket.assigns.filters, @paginator_opts))

        {:noreply, socket |> put_flash(:info, "Leave application approved successfully")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to approve leave application: #{reason}")}
    end
  rescue
    e in RuntimeError ->
      {:noreply, socket |> put_flash(:error, "Failed to approve leave application: #{e.message}")}
  end

  def handle_event("reject" <> id, _params, socket) do
    case LeaveApplication.reject_leave_application(id) do
      {:ok, _leave_application} ->
        socket =
          socket
          |> assign(:leave_applications, fetch_records(socket.assigns.filters, @paginator_opts))

        {:noreply, socket |> put_flash(:info, "Leave application rejected successfully")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to reject leave application: #{reason}")}
    end
  end

  def fetch_records(filters, opts) do
    query = LeaveApplication.search(filters)
    opts = Keyword.merge(@paginator_opts, opts)

    query
    |> Ims.Repo.paginate(opts)
  end
end
