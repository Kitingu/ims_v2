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

# sample response

# {
# 2
#   "OriginatorConversationID": "5fbd-4f1c-b3c1-b463d28d74d2319275",
# 3
#   "ConversationID": "AG_20250418_20106e53ef0eca41ba1b",
# 4
#   "ResponseCode": "0",
# 5
#   "ResponseDescription": "Accept the service request successfully."
# 6
# }

# sample result
#   {
#     "Result": {
#     "ConversationID":"AG_20180223_0000493344ae97d86f75",
#     "OriginatorConversationID":"3213-416199-2",
#     "ReferenceData":
#   {
#      "ReferenceItem":
#   {
#      "Key":"Occasion",
#    }
#    },
#      "ResultCode": 0
#       "ResultDesc":"The service request is processed successfully.",
#      "ResultParameters":
#    {
#        "ResultParameter":
#   [
#   {
#      "Key":"DebitPartyName",
#      "Value":"600310 - Safaricom333",
#   },
#   {
#      "Key":"DebitPartyName",
#      "Value":"254708374149 - John Doe",
#   },
#   {
#      "Key":"OriginatorConversationID",
#      "Value":"3211-416020-3",
#   },
#   {
#    "Key":"InitiatedTime",
#      "Value":"20180223054112",
#   },
#   {
#      "Key":"DebitAccountType",
#      "Value":"Utility Account",
#   },
#   {
#      "Key":"DebitPartyCharges",
#      "Value":"Fee For B2C Payment|KES|22.40",
#   },
#   {
#      "Key":"TransactionReason",
#   },
#   {
#      "Key":"ReasonType",
#      "Value":"Business Payment to Customer via API",
#   },
#   {
#      "Key":"TransactionStatus",
#     "Value":"Completed",
#   },
#   {
#      "Key":"FinalisedTime",
#      "Value":"20180223054112",
#     },
#   {
#      "Key":"Amount",
#      "Value":"300",
#   },
#   {
#      "Key":"ConversationID",
#      "Value":"AG_20180223_000041b09c22e613d6c9",
#   },
#   {
#      "Key":"ReceiptNo",
#      "Value":"MBN31H462N",
#   }
#   ]
#   },
#      "ResultType":0,
#      "TransactionID":"MBN0000000",
#   }
#  }
