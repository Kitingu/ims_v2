defmodule ImsWeb.ReportsController do
  use ImsWeb, :controller

  alias Ims.Inventory.Device
  alias Ims.Trainings.TrainingApplication


  def index(conn, params) do
    filters = Map.take(params, ["name", "status", "category_id", "assigned_user_id"])
    devices = Device.search(filters)

    render(conn, "index.html", devices: devices, filters: filters)
  end


  def download_report(conn, %{"filters" => filters_json}) do
    filters = Jason.decode!(filters_json)

    case Device.generate_report(filters) do
      {:ok, file_path} ->
        conn
        |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        |> put_resp_header("content-disposition", "attachment; filename=\"devices_report.xlsx\"")
        |> send_file(200, file_path)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to generate the report.")
        |> redirect(to: "/reports")
    end
  end

  def export_training_applications(conn, _params) do
    case Ims.Trainings.TrainingApplication.generate_report(:excel) do
      {:ok, binary_content} ->
        conn
        |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        |> put_resp_header("content-disposition", "attachment; filename=\"training_applications.xlsx\"")
        |> send_resp(200, binary_content)

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to generate Excel report")
        |> redirect(to: Routes.training_application_index_path(conn, :index))
    end
  end

end
