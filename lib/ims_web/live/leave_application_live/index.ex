defmodule ImsWeb.LeaveApplicationLive.Index do
  use ImsWeb, :live_view

  alias Ims.Leave
  alias Ims.Leave.LeaveApplication

  @paginator_opts [order_by: [desc: :id], page_size: 10]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Listing Leave applications")}
  end

  @impl true
  def handle_params(params, url, socket) do
    user = socket.assigns.current_user
    can_list_all = Canada.Can.can?(user, ["list_all"], "leave_applications")
    path = URI.parse(url).path

    with {:ok, report_filters} <- report_filters(params) do
      filters =
        if can_list_all, do: report_filters, else: Map.put(report_filters, "user_id", user.id)

      page_size = report_page_size(params["size"])
      paginator_opts = [page: report_page(params["page"]), page_size: page_size]
      report_query = Map.take(params, ["from", "to", "status", "user_id"])
      page = fetch_records(filters, paginator_opts)

      socket =
        assign(socket,
          report_path: path,
          can_email_report: can_list_all && is_binary(user.email) && user.email != "",
          report_form: to_form(params, as: :report),
          report_error: nil,
          filters: filters,
          leave_applications: page,
          paginator_opts: paginator_opts,
          report_query: report_query
        )

      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    else
      {:error, reason} ->
        {:noreply,
         assign(socket,
           report_path: path,
           can_email_report: false,
           report_form: to_form(params, as: :report),
           report_error: reason,
           leave_applications: []
         )}
    end
  end

  defp report_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {number, ""} when number > 0 and number <= 1_000_000 -> number
      _ -> 1
    end
  end

  defp report_page(_), do: 1

  defp report_page_size(value) when value in ["10", "20", "50", "100"],
    do: String.to_integer(value)

  defp report_page_size(_), do: @paginator_opts[:page_size]

  defp paginate_report(socket, page, size) do
    query =
      socket.assigns.report_query
      |> Map.filter(fn {_key, value} -> is_binary(value) end)
      |> Map.merge(%{"page" => page, "size" => size})
      |> URI.encode_query()

    {:noreply, push_patch(socket, to: socket.assigns.report_path <> "?" <> query)}
  end

  defp report_filters(params) do
    with {:ok, from} <- parse_report_date(params["from"]),
         {:ok, to} <- parse_report_date(params["to"]),
         true <- is_nil(from) || is_nil(to) || Date.compare(from, to) != :gt do
      filters =
        Map.take(params, ["status", "user_id"])
        |> Map.filter(fn {_key, value} -> is_binary(value) end)
        |> Map.merge(%{"from" => from, "to" => to})
      {:ok, filters}
    else
      false -> {:error, "The end of the reporting period must be on or after the start."}
      :error -> {:error, "Enter valid reporting dates."}
    end
  end

  defp parse_report_date(value) when value in ["", nil], do: {:ok, nil}

  defp parse_report_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _reason} -> :error
    end
  end

  defp parse_report_date(_), do: :error

  defp apply_action(socket, :edit, %{"id" => id}) do
    if Canada.Can.can?(socket.assigns.current_user, ["edit"], "leave_applications") do
      socket
      |> assign(:page_title, "Edit Leave application")
      |> assign(:leave_application, Leave.get_leave_application!(id))
    else
      socket
      |> put_flash(:error, "You do not have permission to edit leave.")
      |> push_navigate(to: ~p"/hr/leave_applications")
    end
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
    leave_applications = fetch_records(socket.assigns.filters, socket.assigns.paginator_opts)

    {:noreply,
     socket
     |> assign(:leave_applications, leave_applications)
     |> redirect(to: "/leave_applications")}
  end

  @impl true
  def handle_event("filter_report", %{"report" => params}, socket) do
    query =
      params
      |> Map.take(["from", "to", "status", "user_id"])
      |> Map.filter(fn {_key, value} -> is_binary(value) end)
      |> URI.encode_query()
    {:noreply, push_patch(socket, to: socket.assigns.report_path <> "?" <> query)}
  end

  def handle_event("render_page", %{"page" => direction}, socket)
      when direction in ["previous", "next"] do
    page = socket.assigns.leave_applications
    next = if direction == "next", do: page.page_number + 1, else: page.page_number - 1
    paginate_report(socket, max(1, min(page.total_pages, next)), page.page_size)
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    paginate_report(socket, 1, report_page_size(size))
  end

  def handle_event("email_report", _, %{assigns: %{can_email_report: true}} = socket) do
    user = socket.assigns.current_user

    result =
      if Canada.Can.can?(user, ["list_all"], "leave_applications") do
        Leave.ApplicationReport.deliver(user.email, socket.assigns.filters)
      else
        {:error, :unauthorized}
      end

    case result do
      {:ok, _receipt} -> {:noreply, put_flash(socket, :info, "Leave summary submitted for delivery.")}
      {:error, _reason} -> {:noreply, put_flash(socket, :error, "The leave summary could not be emailed.")}
    end
  end

  def handle_event("email_report", _, socket), do: {:noreply, socket}

  def handle_event("delete", %{"id" => id}, socket) do
    if Canada.Can.can?(socket.assigns.current_user, ["delete"], "leave_applications") do
      case Leave.delete_leave_application(Leave.get_leave_application!(id)) do
        {:ok, _} ->
          {:noreply, assign(socket, :leave_applications, fetch_records(socket.assigns.filters, socket.assigns.paginator_opts))}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, reason)}
      end
    else
      {:noreply, put_flash(socket, :error, "You do not have permission to delete leave.")}
    end
  end

  def handle_event("approve" <> id, _params, socket) do
    actor = socket.assigns.current_user

    result =
      if Canada.Can.can?(actor, ["approve"], "leave_applications") do
        LeaveApplication.approve_leave_application(id, actor)
      else
        {:error, "You do not have permission to approve leave."}
      end

    case result do
      {:ok, _leave_application} ->
        socket =
          socket
          |> assign(:leave_applications, fetch_records(socket.assigns.filters, socket.assigns.paginator_opts))

        {:noreply, socket |> put_flash(:info, "Leave application approved successfully")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to approve leave application: #{reason}")}
    end
  rescue
    e in RuntimeError ->
      {:noreply, socket |> put_flash(:error, "Failed to approve leave application: #{e.message}")}
  end

  def handle_event("reject" <> id, _params, socket) do
    actor = socket.assigns.current_user

    result =
      if Canada.Can.can?(actor, ["reject"], "leave_applications") do
        LeaveApplication.reject_leave_application(id, actor)
      else
        {:error, "You do not have permission to reject leave."}
      end

    case result do
      {:ok, _leave_application} ->
        socket =
          socket
          |> assign(:leave_applications, fetch_records(socket.assigns.filters, socket.assigns.paginator_opts))

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
