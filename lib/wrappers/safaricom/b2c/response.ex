defmodule Wrappers.Payment.Gateways.Safaricom.B2C.Response do
  alias Ims.Safaricom

  defmacro __using__(_) do
    quote do
      def parse(
            %{
              "Result" => %{
                "ResultType" => 0,
                "ResultCode" => 0,
                "ResultDesc" => desc,
                "OriginatorConversationId" => originator_conversation_id,
                "ConversationId" => conversation_id,
                "TransactionID" => trx_id
              }
            } = params
          ) do
        {:ok,
         %{
           gateway_conversation_id: originator_conversation_id,
           gateway_transaction_id: trx_id,
           status: "complete"
         }}
      end

      def parse(
            %{
              "Result" => %{
                "ResultType" => _,
                "ResultCode" => _,
                "ResultDesc" => "The balance is insufficient for the transaction.",
                "OriginatorConversationID" => originator_conversation_id,
                "ConversationID" => conversation_id,
                "TransactionID" => trx_id,
                "ReferenceData" => _params
              }
            } = params
          ) do
        IO.inspect("Safaricom B2C Response: The balance is insufficient for the transaction.")
        # Honeydew.async(
        #   {:fire_discord_warning,
        #    [
        #      "B2C Paybill error: The balance is insufficient for the transaction."
        #    ]},
        #   :alerts_queue
        # )

        {:ok,
         %{
           gateway_conversation_id: conversation_id,
           gateway_transaction_id: trx_id,
           status: "failed",
           status_desc: "The balance is insufficient for the transaction.",
           payload: params
         }}
      end

      def parse(
            %{
              "Result" => %{
                "ResultType" => _,
                "ResultCode" => _,
                "ResultDesc" => desc,
                "OriginatorConversationID" => originator_conversation_id,
                "ConversationID" => conversation_id,
                "TransactionID" => trx_id,
                "ReferenceData" => _params
              }
            } = params
          ) do
        {:ok,
         %{
           gateway_conversation_id: conversation_id,
           gateway_transaction_id: trx_id,
           status: "failed",
           status_desc: desc,
           payload: params
         }}
      end
    end
  end
end
