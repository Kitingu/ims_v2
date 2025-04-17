defmodule Ims.Safaricom.C2B.IPN do
  defmacro __using__(_) do
    quote do
      # Parse C2B Confirmation Requests
      def parse(params \\ :default)

      def parse(
            %{
              "TransactionType" => _,
              "TransID" => gateway_transaction_id,
              "TransTime" => trx_time,
              "TransAmount" => amount,
              "BusinessShortCode" => short_code,
              "BillRefNumber" => ref_no,
              "InvoiceNumber" => _,
              "OrgAccountBalance" => _,
              "ThirdPartyTransID" => _,
              "MSISDN" => source,
              "FirstName" => _,
              "MiddleName" => _,
              "LastName" => _
            } = params
          ) do
        {:ok,
         %{
           currency: "KES",
           amount: to_string(amount),
           ref_no: ref_no,
           gateway_transaction_id: gateway_transaction_id,
           gateway_transaction_date: parse_payment_date(trx_time),
           source: put_source(source, short_code),
           msisdn: source,
           details: params,
           trx_time: trx_time,
           payment_gateway_id:
             Application.get_env(:wrappers, String.to_atom("mpesa_code_#{short_code}")) || 1,
           gateway: "mpesa",
           name: "#{params["FirstName"]}  #{params["MiddleName"]}  #{params["LastName"]}",
           source_ip_address: params["source_ip_address"]
         }}
      end

      def parse(
            %{
              "Result" => %{
                "ResultType" => 0,
                "ResultCode" => 0,
                "ResultDesc" => desc,
                "OriginatorConversationID" => originator_conversation_id,
                "ConversationID" => conversation_id,
                "TransactionID" => trx_id,
                "ResultParameters" => %{
                  "ResultParameter" => items
                },
                "ReferenceData" => %{
                  "ReferenceItem" => %{
                    "Key" => "Occasion",
                    "Value" => ref_no
                  }
                }
              }
            } = params
          ) do
        result =
          items
          |> formulate_c2b_response
          |> Map.put(:ref_no, format_ref_no(ref_no))
          |> Map.put(:details, params)
          |> Map.put(:currency, "KES")
          |> Map.put(:payment_gateway_id, 1)
          |> Map.put(:gateway, "mpesa")
          |> Map.put(:slug, "mpesa")
          |> Map.put(:source_ip_address, params["source_ip_address"])
          |> case do
            %{transaction_status: "Completed"} = result -> {:ok, result}
            result -> {:error, result}
          end
      end

      def parse(
            %{
              "TransactionType" => _,
              "TransID" => gateway_transaction_id,
              "TransTime" => trx_time,
              "TransAmount" => amount,
              "BusinessShortCode" => short_code,
              "BillRefNumber" => ref_no,
              "InvoiceNumber" => _,
              "OrgAccountBalance" => _,
              "ThirdPartyTransID" => _,
              "MSISDN" => source,
              "FirstName" => _
            } = params
          ) do
        {:ok,
         %{
           currency: "KES",
           amount: to_string(amount),
           ref_no: ref_no,
           gateway_transaction_id: gateway_transaction_id,
           gateway_transaction_date: parse_payment_date(trx_time),
           source: put_source(source, short_code),
           msisdn: source,
           details: params,
           trx_time: trx_time,
           payment_gateway_id:
             Application.get_env(:wrappers, String.to_atom("mpesa_code_#{short_code}")),
           gateway: "mpesa",
           name: "#{params["FirstName"]}",
           source_ip_address: params["source_ip_address"]
         }}
      end

      def parse(
            %{
              "Result" => %{
                "ConversationID" => _,
                "OriginatorConversationID" => _,
                "ReferenceData" => reference_data,
                "ResultCode" => _,
                "ResultDesc" => error,
                "ResultType" => _,
                "TransactionID" => trx_id
              }
            } = params
          ) do
        IO.inspect("Wwe got an error")
        # Honeydew.async(
        #   {:fire_discord_warning,
        #    [
        #      ~s|Pesaflow is receiving the error #{inspect(error)}: Reference Data: #{inspect(reference_data)} & Transaction ID: #{inspect(trx_id)}. Please check|
        #    ]},
        #   :alerts_queue
        # )

        {:error, params}
      end

      defp format_ref_no(ref) when is_integer(ref) do
        ref |> Kernel.inspect()
      end

      defp format_ref_no(ref) do
        ref
      end

      def put_source(source, short_code) do
        if source in [nil, ""], do: short_code, else: source
      end

      def parse_payment_date(value) when is_binary(value) do
        if String.contains?(to_string(value), "%") do
          String.replace(value, "%", "")
          |> Timex.parse!("{YYYY}-{0M}-{D} {h24}:{m}:{s}")
          |> Timex.to_naive_datetime()
        else
          try do
            value
            |> to_string()
            |> Timex.parse!("{YYYY}-{0M}-{D} {h24}:{m}:{s}")
            |> Timex.to_naive_datetime()
          rescue
            e ->
              DateTime.truncate(DateTime.utc_now(), :second)
          end
        end
      end

      def parse_payment_date(value) when is_integer(value) do
        try do
          value
          |> to_string()
          |> String.replace(
            ~r/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/,
            "\\1-\\2-\\3 \\4:\\5:\\6"
          )
          |> Timex.parse!("{YYYY}-{0M}-{D} {h24}:{m}:{s}")
        rescue
          e ->
            DateTime.truncate(DateTime.utc_now(), :second)
        end
      end

      defp formulate_c2b_response(response, map \\ %{}) do
        case response do
          [head | tail] ->
            case head do
              %{"Key" => "DebitPartyName", "Value" => value} ->
                {source, name} = Integer.parse(value)
                name = String.trim(name, " - ")

                formulate_c2b_response(
                  tail,
                  Map.put(map, :source, "#{source}")
                  |> Map.put(:msisdn, "#{source}")
                  |> Map.put(:name, name)
                )

              %{"Key" => "CreditPartyName", "Value" => value} ->
                case String.split(value, " - ") do
                  [code | _tail] ->
                    formulate_c2b_response(
                      tail,
                      Map.put(
                        map,
                        :payment_gateway_id,
                        Application.get_env(:wrappers, String.to_atom("mpesa_code_#{code}"))
                      )
                    )

                  _ ->
                    formulate_c2b_response(
                      tail,
                      Map.put(
                        map,
                        :payment_gateway_id,
                        Application.get_env(:wrappers, String.to_atom("mpesa_code_#{value}"))
                      )
                    )
                end

              %{"Key" => "OriginatorConversationID"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "InitiatedTime"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "CreditPartyCharges"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "DebitAccountType"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "TransactionReason"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "ReasonType"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "TransactionStatus", "Value" => value} ->
                formulate_c2b_response(tail, Map.put(map, :transaction_status, value))

              %{"Key" => "ConversationID"} ->
                formulate_c2b_response(tail, map)

              %{"Key" => "Amount", "Value" => value} ->
                formulate_c2b_response(tail, Map.put(map, :amount, to_string(value)))

              %{"Key" => "ReceiptNo", "Value" => value} ->
                formulate_c2b_response(tail, Map.put(map, :gateway_transaction_id, value))

              %{"Key" => "FinalisedTime", "Value" => value} ->
                formulate_c2b_response(
                  tail,
                  Map.put(
                    map,
                    :gateway_transaction_date,
                    parse_payment_date(value)
                  )
                )

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
