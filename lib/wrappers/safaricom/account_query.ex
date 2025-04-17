defmodule Wrappers.Payment.Safaricom.AccountQuery do
  require Logger

  alias Ims.Safaricom.Token

  @url Application.compile_env(:ims, :mpesa_account_request_url)
  @business_shortcode Application.compile_env(:ims, :business_shortcode)

  @mpesa_initiator Application.compile_env(:ims, :mpesa_initiator)
  @mpesa_security_credential Application.compile_env(:ims, :mpesa_security_credential)
  @mpesa_account_timeout_url Application.compile_env(:ims, :mpesa_account_timeout_url)
  @mpesa_account_result_url Application.compile_env(:ims, :mpesa_account_result_url)

  def request(%{remarks: _remarks} = params) do
    Token.get()
    |> execute(params)
  end

  def execute({:ok, token}, params) do
    payload =
      Jason.encode!(%{
        "Initiator" => @mpesa_initiator,
        "SecurityCredential" => @mpesa_security_credential,
        "CommandID" => "AccountBalance",
        "PartyA" => @business_shortcode,
        "IdentifierType" => "4",
        "Remarks" => params.remarks,
        "QueueTimeOutURL" => @mpesa_account_timeout_url,
        "ResultURL" => @mpesa_account_result_url
      })

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    request = Finch.build(:post, @url, headers, payload)

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

  def execute({:error, _}, _params) do
    {:error, "Unable to Obtain Token"}
  end
end
