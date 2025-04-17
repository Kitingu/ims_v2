defmodule Wrappers.Payment.Gateways.Safaricom.B2C.Request do
  require Logger

  alias Ims.Safaricom.Token

  def execute(
        %{
          amount: _amount,
          account_reference: _account_reference,
          remarks: _remarks,
          gateway: gateway
        } = params
      ) do
    Token.get(gateway["token_credentials"])
    |> do_request(params)
  end

  defp do_request({:ok, token}, params) do
    payload =
      Jason.encode!(%{
        "InitiatorName" => params.gateway["initiator"],
        "SecurityCredential" => params.gateway["security_credential"],
        "CommandID" => "BusinessPayment",
        "Amount" => params.amount,
        "PartyA" => params.gateway["shortcode"],
        "PartyB" => params.account_reference,
        "Remarks" => params.remarks,
        "QueueTimeOutURL" => params.gateway["mpesa_b2c_callback_url"],
        "ResultURL" => params.gateway["mpesa_b2c_callback_url"],
        "Occassion" => params.remarks
      })

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    url = params.gateway["mpesa_b2c_url"]
    request = Finch.build(:post, url, headers, payload)

    case Finch.request(request, Ims.Finch, receive_timeout: 20_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        body = Jason.decode!(body)

        case body do
          %{"ResponseCode" => "0"} = body ->
            {:ok,
             %{
               gateway_conversation_id: body["ConversationID"],
               gateway_transaction_id: body["OriginatorConversationID"]
             }}

          _ ->
            {:error, reason: body}
        end

      {:ok, %Finch.Response{status: status_code, body: response_body}} ->
        Logger.info(
          "[Wrappers.Payment.Gateways.Safaricom.B2C.Request] bad response: #{inspect(response_body)}"
        )

        {:error, status_code: status_code}

      {:error, %Mint.TransportError{reason: :timeout} = e} ->
        Logger.error("Timeout Error: #{inspect(e)}")
        {:recon, "Timeout during processing."}

      {:error, %Mint.TransportError{reason: :nxdomain}} ->
        {:error, reason: "connection failed"}

      {:error, error} ->
        Logger.error("Finch error: #{inspect(error)}")
        {:error, reason: error}
    end
  end

  defp do_request({:error, [reason: :nxdomain]}, _params) do
    {:error, reason: "connection failed"}
  end

  def execute({:error, _}, _params) do
    {:error, "Unable to Obtain Token"}
  end
end
