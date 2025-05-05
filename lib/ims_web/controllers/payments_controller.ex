defmodule ImsWeb.PaymentsController do
  use ImsWeb, :controller
  use Ims.Safaricom.C2B.IPN

  def api_mpesa_payment_callback(conn, _params) do
  end

  def api_send_stk_push(conn, %{"phone_number" => phone_number}) do
  end

  def api_payment_validate(conn, params) do
    IO.inspect(parse(params), label: "Parsed Params")

    with {:ok, parsed_params} <- parse(params),
         {:ok, message} <- Ims.Welfare.create_contribution(parsed_params) do
      json(conn, %{
        status: "success",
        message: message,
        data: parsed_params
      })
    else
      {:error, reason} ->
        json(conn, %{
          status: "error",
          message: "Payment processing failed",
          error_details: inspect(reason)
        })
    end
  end

  def api_mpesa_payment_status(conn, %{"transaction_id" => transaction_id}) do
  end
end
