defmodule Ims.FileTracker.GoogleSheets do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://sheets.googleapis.com/v4/spreadsheets"
  plug Tesla.Middleware.JSON

  alias Goth.Token

  @spreadsheet_id "1-uikR63FbltrfpRwI21sAsAPG33UE4aKfJF9qD1rs50"
  @sheet_name "File Movement"

  def append_row([ref_no, scan_url, folder_no, office]) do
    {:ok, %{token: token}} = Token.for_scope("https://www.googleapis.com/auth/spreadsheets")
    IO.inspect(token, label: "token")

    row = [ref_no, scan_url, folder_no, office, DateTime.utc_now() |> DateTime.to_string()]
    body = %{values: [row]}

    encoded_sheet = URI.encode(@sheet_name)

    post(
      "/#{@spreadsheet_id}/values/#{encoded_sheet}!A1:append",
      body,
      query: [valueInputOption: "USER_ENTERED"],
      headers: [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]
    )
  end
end
