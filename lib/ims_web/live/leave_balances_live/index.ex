defmodule ImsWeb.LeaveBalanceLive.Index do
  use ImsWeb, :live_view
  import Ecto.Query

  alias Ims.Repo.Audited, as: Repo
  alias Ims.Leave
  alias Ims.Leave.LeaveType
  alias Ims.Accounts
  require Logger

  alias Ims.Leave.Workers.LeaveBalanceUploadWorker
  alias Oban
  alias Oban.Job

  alias ImsWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:balances,
        # LiveView 1.0.9: accept lowercase ext or MIME
        accept: ~w(.xlsx),
        max_entries: 1,
        auto_upload: true,
        max_file_size: 10_000_000,
        progress: &handle_upload_progress/3
      )
      |> assign(:import_job_id, nil)
      |> assign(:import_status, nil)

    {:ok, assign_defaults(socket)}
  end

  # LV 1.0.9: consume_uploaded_entries/3 -> returns a LIST (not {list, socket})
  defp handle_upload_progress(:balances, entry, socket) do
    Logger.debug("upload balances=#{inspect(entry.client_name)} done?=#{entry.done?}")

    if entry.done? do
      paths =
        consume_uploaded_entries(socket, :balances, fn %{path: path}, entry ->
          dest_dir = Path.join(:code.priv_dir(:ims), "uploads")
          File.mkdir_p!(dest_dir)

          dest = Path.join(dest_dir, "#{entry.uuid}-#{Path.basename(entry.client_name)}")
          File.cp!(path, dest)
          {:ok, dest}
        end)

      case paths do
        [xlsx_path | _] ->
          Logger.debug("enqueue oban job for path=#{xlsx_path}")

          case Oban.insert(LeaveBalanceUploadWorker.new(%{"xlsx_path" => xlsx_path})) do
            {:ok, %Job{id: jid}} ->
              Process.send_after(self(), {:poll_job, jid}, 500)

              {:noreply,
               socket
               |> put_flash(:info, "Import queued.")
               |> assign(:import_job_id, jid)
               |> assign(:import_status, "queued")
               |> assign(:show_manage_modal, false)}

            {:error, reason} ->
              Logger.error("failed to queue oban job: #{inspect(reason)}")
              {:noreply, put_flash(socket, :error, "Failed to queue job: #{inspect(reason)}")}
          end

        [] ->
          Logger.error("consume_uploaded_entries returned no paths")
          {:noreply, put_flash(socket, :error, "No file received.")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    live_action = socket.assigns[:live_action] || :index
    leave_types = Repo.all(from lt in LeaveType, select: lt.name)

    case live_action do
      :edit ->
        user_id = params["id"]
        user = Accounts.get_user!(user_id)

        {:noreply,
         socket
         |> assign(:page_title, "Edit Leave Balances")
         |> assign(:user, user)
         |> assign(:all_leave_types, leave_types)
         |> assign(:visible_leave_types, leave_types)
         |> assign(:columns, leave_types)
         |> assign(:live_action, :edit)}

      :index ->
        page = Leave.paginated_leave_balances(params)

        {:noreply,
         socket
         |> assign(:rows, page)
         |> assign(:columns, leave_types)
         |> assign(:all_leave_types, leave_types)
         |> assign(:search, Map.get(params, "search", ""))
         |> assign(:selected_type, Map.get(params, "leave_type", ""))
         |> assign(:params, params)
         |> assign(:page_title, "Leave Balances")
         |> assign(:user, nil)
         |> assign(:show_manage_modal, false)
         |> assign(:live_action, :index)}
    end
  end

  defp assign_defaults(socket) do
    assign(socket,
      search: "",
      selected_type: nil,
      show_manage_modal: false
    )
  end

  # ===== Search & table controls =====

  @impl true
  def handle_event("update_leave_balance", _params, socket) do
    {:noreply, assign(socket, :show_manage_modal, true)}
  end

  def handle_event("close_manage_balances", _params, socket) do
    {:noreply, assign(socket, :show_manage_modal, false)}
  end

  def handle_event("search_user", %{"search" => search}, socket) do
    params =
      socket.assigns.params
      |> Map.put("search", search)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  @impl true
  def handle_event("render_page", %{"page" => page}, socket) do
    current_page = String.to_integer(Map.get(socket.assigns.params, "page", "1"))

    new_page =
      case page do
        "next" -> current_page + 1
        "previous" -> max(current_page - 1, 1)
        _ -> String.to_integer(page)
      end

    params = Map.put(socket.assigns.params, "page", Integer.to_string(new_page))
    page_data = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> assign(:params, params)
     |> assign(:rows, page_data)}
  end

  def handle_event("resize_table", %{"size" => size}, socket) do
    params =
      socket.assigns.params
      |> Map.put("page_size", size)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:page_size, size)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  def handle_event("open_update_modal", %{"id" => user_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: Routes.leave_balances_index_path(socket, :edit, user_id),
       replace: true
     )}
  end

  def handle_event("filter_leave_type", %{"leave_type" => lt}, socket) do
    params =
      socket.assigns.params
      |> Map.put("leave_type", lt)
      |> Map.put("page", "1")

    page = Leave.paginated_leave_balances(params)

    {:noreply,
     socket
     |> assign(:selected_type, lt)
     |> assign(:params, params)
     |> assign(:rows, page)}
  end

  @impl true
  def handle_event("export_excel", _params, socket) do
    params = socket.assigns.params || %{}
    leave_types = socket.assigns.all_leave_types || []
    headers = ["Personal Number", "First Name", "Last Name"] ++ leave_types

    rows =
      gather_all_balances(params)
      |> Enum.map(fn row ->
        base = [row.personal_number, row.first_name, row.last_name]
        balances = Enum.map(leave_types, fn lt -> Map.get(row, lt, 0) end)
        base ++ balances
      end)

    csv_iodata =
      [headers | rows]
      |> Enum.map(&csv_line/1)
      |> Enum.intersperse("\r\n")

    filename = "leave_balances_#{Date.utc_today()}.csv"

    {:noreply,
     Phoenix.LiveView.send_download(
       socket,
       {:binary, IO.iodata_to_binary(csv_iodata)},
       filename: filename,
       content_type: "text/csv"
     )}
  end

  @impl true
  def handle_event("noop", _params, socket), do: {:noreply, socket}

  # ===== Job polling =====

  @impl true
  def handle_info({:poll_job, job_id}, socket) do
    case get_job_state(job_id) do
      nil ->
        Logger.debug("job #{job_id} not found; stopping poll")

        {:noreply,
         socket
         |> assign(%{import_status: nil, import_job_id: nil})}

      state when state in ~w(completed discarded cancelled) ->
        Logger.debug("job #{job_id} finished state=#{state}")

        params = socket.assigns.params || %{}
        page = Leave.paginated_leave_balances(params)

        {flash_level, flash_msg} =
          case state do
            "completed" -> {:info, "Import finished."}
            "discarded" -> {:error, "Import failed. Check logs."}
            "cancelled" -> {:warning, "Import cancelled."}
          end

        # 🧹 Try to clean up the uploaded file
        case Repo.get(Job, job_id) do
          %Job{args: %{"xlsx_path" => path}} ->
            Logger.debug("cleaning up uploaded file #{path}")
            _ = File.rm(path)

          _ ->
            :ok
        end

        Process.send_after(self(), :clear_status, 5_000)

        {:noreply,
         socket
         |> put_flash(flash_level, flash_msg)
         |> assign(%{
           rows: page,
           import_status: state,
           import_job_id: nil
         })}

      state ->
        Process.send_after(self(), {:poll_job, job_id}, 800)

        {:noreply,
         socket
         |> assign(%{import_status: state})}
    end
  end

  @impl true
  def handle_info(:clear_status, socket) do
    {:noreply, assign(socket, :import_status, nil)}
  end

  @impl true
  def handle_info({:flash, level, msg}, socket) when level in [:info, :error, :warning] do
    params = socket.assigns.params || %{}
    page = Leave.paginated_leave_balances(params)
    {:noreply, socket |> put_flash(level, msg) |> assign(:rows, page)}
  end

  @impl true
  def handle_info(:close_manage_balances, socket) do
    {:noreply, assign(socket, :show_manage_modal, false)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # ===== Helpers =====

  defp get_job_state(job_id) do
    case Repo.get(Job, job_id) do
      nil -> nil
      %Job{state: state} -> to_string(state)
    end
  end

  defp gather_all_balances(params) do
    base = params |> Map.put_new("page_size", "500") |> Map.put("page", "1")
    page = Ims.Leave.paginated_leave_balances(base)

    Enum.reduce((page.page_number + 1)..page.total_pages, page.entries, fn p, acc ->
      more =
        base
        |> Map.put("page", Integer.to_string(p))
        |> Ims.Leave.paginated_leave_balances()
        |> Map.get(:entries)

      acc ++ more
    end)
  end

  defp csv_line(list), do: list |> Enum.map(&csv_cell/1) |> Enum.intersperse(",")
  defp csv_cell(nil), do: "\"\""
  defp csv_cell(v), do: ["\"", v |> to_string() |> String.replace("\"", "\"\""), "\""]
end
