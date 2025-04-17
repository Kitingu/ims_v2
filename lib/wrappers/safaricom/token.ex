defmodule Ims.Safaricom.Token do
  require Logger
  # alias Wrappers.Helper.Cache

  @url "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
  #  "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
  # @token_key "safaricom_access_token"

  def get(credentials \\ Application.get_env(:ims, :mpesa_token_credentials)) do
    IO.inspect(credentials, label: "credentials")

    headers = [{"authorization", "Basic #{credentials}"}]
    request = Finch.build(:get, @url, headers)

    case Finch.request(request, Ims.Finch) |> IO.inspect(label: "this is the plug ss") do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)["access_token"]}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, status_code: status_code}

      {:error, error} ->
        Logger.error("Finch error: #{inspect(error)}")
        {:error, reason: error}
    end
  end
end
