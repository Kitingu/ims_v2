defmodule Ims.Safaricom.STK.IPN do
  defmacro __using__(_) do
    quote do
      def parse(
            %{
              "Body" => %{
                "stkCallback" => %{
                  "MerchantRequestID" => _,
                  "CheckoutRequestID" => checkout_request_id,
                  "ResultCode" => 0,
                  "ResultDesc" => _,
                  "CallbackMetadata" => %{
                    "Item" => items
                  }
                }
              }
            } = params
          ) do
        params =
          items
          |> formulate_response
          |> Map.put(:name, "Unknown MPESA User")
          |> Map.put(:currency, "KES")
          |> Map.put(:ref_no, checkout_request_id)
          |> Map.put(:slug, "mpesa")
          |> Map.put(:gateway, "mpesa")
          |> Map.put(:payment_gateway_id, 1)
          |> Map.put(:details, params)
          |> Map.put(:external_session, "true")
          |> Map.put(:source_ip_address, params["source_ip_address"])

        {:ok, params}
      end

      def parse(
            %{
              "Body" => %{
                "stkCallback" => %{
                  "MerchantRequestID" => _,
                  "CheckoutRequestID" => checkout_request_id,
                  "ResultCode" => _,
                  "ResultDesc" => "Request cancelled by user"
                }
              }
            } = _params
          ),
          do: {:error, "Ignore Failed Checkout"}

      def parse(
            %{
              "Body" => %{
                "stkCallback" => %{
                  "MerchantRequestID" => _,
                  "CheckoutRequestID" => checkout_request_id,
                  "ResultCode" => _,
                  "ResultDesc" => desc
                }
              }
            } = _params
          )
          when desc in [
                 "DS timeout user cannot be reached",
                 #  "System internal error.",
                 "The initiator information is invalid."
               ],
          do: {:stk_failed, %{checkout_request_id: checkout_request_id}}

      def parse(
            %{
              "Body" => %{
                "stkCallback" => %{
                  "MerchantRequestID" => _,
                  "CheckoutRequestID" => checkout_request_id,
                  "ResultCode" => _,
                  "ResultDesc" => _other
                }
              }
            } = _params
          ),
          do: {:error, "Unknown error"}

      defp formulate_response(response, map \\ %{}) do
        case response do
          [head | tail] ->
            case head do
              %{"Name" => "Amount", "Value" => value} ->
                formulate_response(tail, Map.put(map, :amount, to_string(value)))

              %{"Name" => "MpesaReceiptNumber", "Value" => value} ->
                formulate_response(tail, Map.put(map, :gateway_transaction_id, value))

              %{"Name" => "Balance"} ->
                formulate_response(tail, map)

              %{"Name" => "TransactionDate", "Value" => value} ->
                formulate_response(
                  tail,
                  Map.put(
                    map,
                    :gateway_transaction_date,
                    value |> to_string()|> Timex.parse!("%Y%m%d%H%M%S", :strftime)
                  )
                )

              %{"Name" => "PhoneNumber", "Value" => value} ->
                formulate_response(tail, Map.put(map, :source, "#{value}"))

              _ ->
                map
            end

          [] ->
            map
        end
      end
    end
  end
end
