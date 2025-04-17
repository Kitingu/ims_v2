defmodule Wrappers.Payment.Gateways.Safaricom.C2B.Query do
  require Logger

  alias Ims.Safaricom.Token

  @url "https://sandbox.safaricom.co.ke/mpesa/transactionstatus/v1/query"
  # "https://api.safaricom.co.ke/mpesa/transactionstatus/v1/query"

  def request(%{gateway: gateway} = params) do
    Token.get(gateway["token_credentials"])
    |> execute(params)
  end

  def execute({:ok, token}, params) do
    payload =
      Jason.encode!(%{
        "Initiator" => params.gateway["initiator"],
        "SecurityCredential" => params.gateway["security_credential"],
        "CommandID" => "TransactionStatusQuery",
        "TransactionID" => params.transaction_id,
        "PartyA" => params.gateway["shortcode"],
        "IdentifierType" => "4",
        "OriginalConvesationID" => Timex.format!(Timex.now(), "%Y%m%d%H%M%S", :strftime),
        "ResultURL" =>
          params.gateway["callback_url"] || Application.get_env(:ims, :stk_callback_url),
        "QueueTimeOutURL" =>
          params.gateway["callback_url"] || Application.get_env(:ims, :stk_callback_url),
        "Remarks" => "Transaction Status",
        "Occasion" => params.account_reference
      })

    # Logger.info("Request params #{inspect(payload)}")
    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    url = @url
    body = Jason.encode!(payload)

    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, Ims.Finch, receive_timeout: 20_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, status_code: status_code}

      {:error, error} ->
        Logger.error("Finch error: #{inspect(error)}")
        {:error, reason: error}
    end
  end

  def execute_push_query({:error, _}, _params) do
    {:error, "Unable to Obtain Token"}
  end
end
