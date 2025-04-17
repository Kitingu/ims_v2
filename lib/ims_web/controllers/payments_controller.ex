defmodule ImsWeb.PaymentsController do
  def api_mpesa_payment_callback(conn, _params) do
  end

  def api_send_stk_push(conn, %{"phone_number" => phone_number}) do
  end

  def api_mpesa_payment_status(conn, %{"transaction_id" => transaction_id}) do
  end
end
