# lib/ims_web/controllers/leave_balance_export_controller.ex
defmodule ImsWeb.LeaveBalanceExportController do
  use ImsWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Ims.Repo
  alias Ims.Leave
  alias Ims.Leave.LeaveType

  def export(conn, params) do
    leave_types =
      from(lt in LeaveType, order_by: [asc: lt.name], select: lt.name)
      |> Repo.all()

    headers = ["Personal Number", "First Name", "Last Name"] ++ leave_types

    rows =
      gather_all_balances(params)
      |> Enum.map(fn row ->
        base = [row.personal_number, row.first_name, row.last_name]
        balances = Enum.map(leave_types, fn lt -> Map.get(row, lt, 0) end)
        base ++ balances
      end)

    csv =
      [headers | rows]
      |> Enum.map(&csv_line/1)
      |> Enum.intersperse("\r\n")
      |> IO.iodata_to_binary()

    Phoenix.Controller.send_download(
      conn,
      {:binary, csv},
      filename: "leave_balances_#{Date.utc_today()}.csv",
      content_type: "text/csv"
    )
  end

  # Pull every page matching current filters
  defp gather_all_balances(params) do
    base = params |> Map.put_new("page_size", "500") |> Map.put("page", "1")
    page = Leave.paginated_leave_balances(base)

    Enum.reduce((page.page_number + 1)..page.total_pages, page.entries, fn p, acc ->
      more =
        base
        |> Map.put("page", Integer.to_string(p))
        |> Leave.paginated_leave_balances()
        |> Map.get(:entries)

      acc ++ more
    end)
  end

  # Basic CSV escaping: quote everything
  defp csv_line(list), do: list |> Enum.map(&csv_cell/1) |> Enum.intersperse(",")

  defp csv_cell(nil), do: "\"\""
  defp csv_cell(v) do
    s = v |> to_string() |> String.replace("\"", "\"\"")
    ["\"", s, "\""]
  end
end
