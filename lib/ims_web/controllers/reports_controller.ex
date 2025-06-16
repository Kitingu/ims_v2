defmodule ImsWeb.ReportsController do
  use ImsWeb, :controller

  alias Ims.Inventory.Asset
  alias Ims.Trainings.TrainingApplication

  def index(conn, params) do
    filters = Map.take(params, ["name", "status", "category_id", "assigned_user_id"])
    devices = Asset.search(filters)

    render(conn, "index.html", devices: devices, filters: filters)
  end

  def download_report(conn, %{"filters" => filters_json}) do
    filters = Jason.decode!(filters_json)

    case Asset.generate_report(filters) do
      {:ok, file_path} ->
        conn
        |> put_resp_content_type(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        |> put_resp_header("content-disposition", "attachment; filename=\"devices_report.xlsx\"")
        |> send_file(200, file_path)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to generate the report.")
        |> redirect(to: "/reports")
    end
  end

  def export_training_applications(conn, %{"filters" => filters_json}) do
    filters = Jason.decode!(filters_json)

    case Ims.Trainings.TrainingApplication.generate_report(:excel, filters) do
      {:ok, binary_content} ->
        conn
        |> put_resp_content_type(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"training_applications.xlsx\""
        )
        |> send_resp(200, binary_content)

      {:error, reason} ->
        IO.inspect(reason, label: "Excel export failed reason")

        conn
        |> put_flash(:error, "Failed to generate Excel report")
        |> redirect(to: ~p"/hr/training_applications")
    end
  end

  # 🆕 Add this clause for requests without filters
  def export_training_applications(conn, _params) do
    case Ims.Trainings.TrainingApplication.generate_report(:excel) do
      {:ok, binary_content} ->
        conn
        |> put_resp_content_type(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"training_applications.xlsx\""
        )
        |> send_resp(200, binary_content)

      {:error, reason} ->
        IO.inspect(reason, label: "Excel export failed reason")

        conn
        |> put_flash(:error, "Failed to generate Excel report")
        |> redirect(to: ~p"/hr/training_applications")
    end
  end

  def export_training_projections(conn, _params) do
    case Ims.Trainings.TrainingProjections.generate_report(:excel) do
      {:ok, binary} when is_binary(binary) ->
        conn
        |> put_resp_content_type(
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"training_projections.xlsx\""
        )
        |> send_resp(200, binary)

      {:error, reason} ->
        IO.inspect(reason, label: "Excel export failed")

        conn
        |> put_flash(:error, "Failed to generate Excel report")
        |> redirect(to: ~p"/hr/training_projections")
    end
  end
end
