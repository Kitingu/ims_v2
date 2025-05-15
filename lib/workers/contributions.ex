defmodule Ims.Workers.ProcessContributionsWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.{Repo, Welfare.Contribution, Accounts.User, Welfare.Event}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"file_path" => path}}) do
    # Parse the Excel file with xlsxir
    {:ok, table_id} = Xlsxir.multi_extract(path, 0) |> IO.inspect(label: "Table ID")
    # {:ok, _} = Xlsxir.get_table_info(table_id) |> IO.inspect(label: "Table Info")
    rows = Xlsxir.get_list(table_id) |> IO.inspect(label: "Rows from Excel")
    Xlsxir.close(table_id)

    IO.inspect(rows, label: "Rows from Excel")

    Logger.info("Processing contributions from file: #{path}")

    Logger.info("Rows: #{inspect(rows)}")

    # Assume first row is headers, rest are data
    [headers | data_rows] = rows |> IO.inspect(label: "Data Rows")

    header_map =
      Enum.with_index(headers, fn h, i -> {h, i} end)
      |> Map.new()
      |> IO.inspect(label: "Header Map")

    # Process each data row
    data_rows
    |> Enum.each(fn row ->
      with {:ok, event_id} <- parse_event_id(get_cell(row, header_map, "event_id")),
           {:ok, event} <- find_event(event_id),
           {:ok, user} <- find_user(get_cell(row, header_map, "personal_number")),
           {:ok, amount} <- parse_amount(get_cell(row, header_map, "amount paid")),
           {:ok, paid_at} <- parse_date(get_cell(row, header_map, "date paid")) do
        ensure_member_exists(user, event)

        attrs = %{
          amount: amount,
          payment_reference: get_cell(row, header_map, "payment reference") || "N/A",
          source: "MPESA",
          user_id: user.id,
          event_id: event.id,
          date_paid: paid_at
        }

        %Contribution{}
        |> Contribution.changeset(attrs)
        |> Repo.insert!()
      else
        {:error, reason} ->
          Logger.error("Failed to process row: #{inspect(row)}. Reason: #{reason}")
      end
    end)

    File.rm!(path)
    :ok
  rescue
    e in File.Error ->
      Logger.error("Failed to read file: #{path}. Error: #{inspect(e)}")
      {:error, :file_read_error}

    e ->
      Logger.error("Unexpected error processing file: #{path}. Error: #{inspect(e)}")
      {:error, :processing_error}
  end

  defp get_cell(row, header_map, column) do
    case Map.get(header_map, column) do
      nil -> nil
      index -> Enum.at(row, index)
    end
  end

  defp find_event(event_id) do
    case Repo.get(Event, event_id) do
      nil -> {:error, "Event not found"}
      event -> {:ok, event}
    end
  end

  defp parse_event_id(nil), do: {:error, "Missing event_id"}
  defp parse_event_id(""), do: {:error, "Empty event_id"}
  defp parse_event_id(event_id) when is_integer(event_id), do: {:ok, event_id}

  defp parse_event_id(event_id) do
    case Integer.parse(event_id) do
      {id, _} -> {:ok, id}
      :error -> {:error, "Invalid event_id format"}
    end
  end

  defp find_user(personal_number) do
    IO.inspect(personal_number, label: "Personal Number")
    personal_number = to_string(personal_number) |> String.trim()

    case Repo.get_by(User, personal_number: personal_number) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  defp parse_amount(nil), do: {:error, "Missing amount"}
  defp parse_amount(""), do: {:error, "Empty amount"}
  defp parse_amount(amount) when is_number(amount), do: {:ok, Decimal.new(amount)}

  defp parse_amount(amount_str) do
    case Decimal.parse(amount_str) do
      {:ok, amount} -> {:ok, amount}
      _ -> {:error, "Invalid amount format"}
    end
  end

  defp parse_date(nil), do: {:ok, DateTime.utc_now()}
  defp parse_date(""), do: {:ok, DateTime.utc_now()}

  defp parse_date(date_str) do
    case Timex.parse(date_str, "{D}-{M}-{YYYY}") do
      {:ok, datetime} -> {:ok, datetime}
      _ -> {:ok, DateTime.utc_now()}
    end
  end

  defp ensure_member_exists(user, event) do
    alias Ims.Welfare.Member

    case Repo.get_by(Member, user_id: user.id) do
      nil ->
        # No member found, create new welfare member
        entry_date = event.inserted_at |> DateTime.to_date()

        member_attrs = %{
          user_id: user.id,
          entry_date: entry_date,

          amount_paid: Decimal.new(0),
          amount_due: Decimal.new(0),
          eligibility: true,
          status: "active"
        } |> IO.inspect()

        %Member{}
        |> Member.changeset(member_attrs)
        |> Repo.insert!()

        Logger.info("Created new welfare member for user_id=#{user.id}")

      _member ->
        # Member already exists, nothing to do
        :ok
    end
  end
end
