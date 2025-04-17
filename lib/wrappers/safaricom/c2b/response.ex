defmodule Ims.Safaricom.C2B.Response do
  defmacro __using__(_) do
    quote do
      def return(:success, "mpesa", trx_id),
        do: %{
          "ResultCode" => "0",
          "ResultDesc" => "The service was accepted successfully",
          "ThirdPartyTransID" => trx_id
        }

      def return(:failed, "mpesa"),
        do: %{
          "ResultCode" => "C2B00012",
          "ResultDesc" => "The service was accepted successfully",
          "ThirdPartyTransID" => ""
        }

      def return(:mpesa_error), do: %{"ResultCode" => "C2B00012", "ResultDesc" => "Rejected"}
    end
  end
end
