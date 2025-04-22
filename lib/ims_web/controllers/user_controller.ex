# lib/ims_web/controllers/user_controller.ex
defmodule ImsWeb.UserController do
  use ImsWeb, :controller
  alias Ims.Accounts

  def download_template(conn, _params) do
    # template_data = Accounts.generate_upload_template()

    # # Generate temporary file path
    # tmp_path = Path.join(System.tmp_dir!(), "template_#{System.unique_integer([:positive])}.xlsx")

    # Generate the Excel file
    excel_content = Accounts.generate_upload_template()

    conn
    |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"user_upload_template.xlsx\""
    )
    |> send_resp(200, excel_content)
  end

  defp generate_excel_file(headers, path) do
    workbook = %Elixlsx.Workbook{
      sheets: [
        %Elixlsx.Sheet{
          name: "Users",
          # Header row
          rows: [headers]
        }
      ]
    }

    # Write to temporary file
    Elixlsx.write_to(workbook, path)
  end
end
