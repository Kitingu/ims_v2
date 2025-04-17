defmodule Ims.Safaricom.STK.Query do
  require Logger

  alias Ims.Safaricom.Token

  @url Application.compile_env(:ims, :stk_query_url)

  def request(%{checkout_request_id: _checkout_request_id, gateway: gateway} = params) do
    Token.get(gateway["token_credentials"])
    |> execute(params)
  end

  def execute({:ok, token}, params) do
    payload =
      Poison.encode!(%{
        "BusinessShortCode" => params.gateway["shortcode"],
        "Password" => params.gateway["password"],
        "Timestamp" => params.gateway["timestamp"],
        "CheckoutRequestID" => params.checkout_request_id
      })

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    request = Finch.build(:post, @url, headers, payload)

    case Finch.request(request, MyApp.Finch, receive_timeout: 20_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Poison.decode!(body)}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, status_code: status_code}

      {:error, error} ->
        Logger.error("Finch error: #{inspect(error)}")
        {:error, reason: error}
    end
  end

  def execute({:error, _}, _params), do: {:error, "Unable to Obtain Token"}
end
