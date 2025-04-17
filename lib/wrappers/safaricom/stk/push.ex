defmodule Wrappers.Payment.Gateways.Safaricom.STK.Push do
  require Logger
  alias Wrappers.Payment.Gateways.Safaricom.Token

  @url "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"

  def request(
        %{
          amount: _amount,
          msisdn: _msisdn,
          account_reference: _account_reference,
          transaction_desc: _transaction_desc,
          gateway: gateway,
          token: token
        } = params
      ) do
    case token do
      nil -> Token.get(gateway["token_credentials"])
      _ -> {:ok, token}
    end
    |> execute(params)
  end

  defp execute({:ok, token}, params) do
    payload =
      Jason.encode!(%{
        "BusinessShortCode" => params.gateway["shortcode"],
        "Password" => params.gateway["password"],
        "Timestamp" => params.gateway["timestamp"],
        "TransactionType" => params.gateway["transaction_type"],
        "Amount" => params.amount,
        "PartyA" => params.msisdn,
        "PartyB" => params.gateway["party_b"],
        "PhoneNumber" => params.msisdn,
        "CallBackURL" => Application.get_env(:wrappers, :stk_callback_url),
        "AccountReference" => params.account_reference,
        "TransactionDesc" => params.transaction_desc
      })

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    request = Finch.build(:post, @url, headers, payload)

    case Finch.request(request, Ims.Finch, receive_timeout: 20_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Logger.info("MPESA raw response #{inspect(body)}")

        case Jason.decode!(body) do
          %{"CheckoutRequestID" => checkout_request_id, "ResponseCode" => "0"} ->
            {:ok, checkout_request_id}

          %{"ResponseCode" => error} ->
            {:error, error}
        end

      {:ok, %Finch.Response{status: status_code, body: response_body}} ->
        Logger.info("MPESA response: #{inspect(response_body)}")
        {:error, status_code: status_code}

      {:error, error} ->
        Logger.error("Finch error: #{inspect(error)}")
        {:error, reason: error}

      error ->
        Logger.error("Unknown Finch error: #{inspect(error)}")
        {:error, "Unable to initiate"}
    end
  end

  defp execute({:error, _}, _params), do: {:error, "Unable to Obtain Token"}
end
