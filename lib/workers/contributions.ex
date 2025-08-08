defmodule Ims.Workers.ProcessContributionsWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.{Repo, Welfare.Contribution, Accounts, Accounts.User, Welfare.Event}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"file_path" => path}}) do
    # Parse the Excel file with xlsxir
    {:ok, table_id} = Xlsxir.multi_extract(path, 0)
    rows = Xlsxir.get_list(table_id)
    Xlsxir.close(table_id)

    Logger.info("Processing contributions from file: #{path}")

    # Assume first row is headers, rest are data
    [headers | data_rows] = rows

    header_map =
      Enum.with_index(headers, fn h, i -> {h, i} end)
      |> Map.new()

    # Process each data row
    data_rows
    |> Enum.each(fn row ->
      with {:ok, event_id} <- parse_event_id(get_cell(row, header_map, "event_id")),
           {:ok, event} <- find_event(event_id),
           {:ok, user} <- find_user(get_cell(row, header_map, "personal_number")),
           {:ok, amount} <- parse_amount(get_cell(row, header_map, "amount paid")),
           {:ok, paid_at} <- parse_date(get_cell(row, header_map, "date paid")) do
        ensure_member_exists(user, event)

        # Check if payment_reference is provided, otherwise generate a unique one
        payment_reference =
          case get_cell(row, header_map, "payment reference") do
            nil -> generate_payment_reference(user.id, event.id)
            "" -> generate_payment_reference(user.id, event.id)
            reference -> reference
          end

        # Check if the payment reference already exists
        case Repo.get_by(Contribution, payment_reference: payment_reference) do
          nil ->
            attrs = %{
              amount: amount,
              payment_reference: payment_reference,
              source: "MPESA",
              user_id: user.id,
              event_id: event.id,
              date_paid: paid_at
            }

            # Insert the contribution
            %Contribution{}
            |> Contribution.changeset(attrs)
            |> Repo.insert!()

            # Update the event's total amount_paid
            update_event_amount_paid(event, amount)

          _existing_contribution ->
            # Log and skip the contribution if the payment reference exists
            Logger.info(
              "Payment reference #{payment_reference} already exists. Skipping this contribution."
            )
        end
      else
        {:error, reason} ->
          Logger.error("Failed to process row: #{inspect(row)}. Reason: #{reason}")
      end
    end)

    File.rm!(path)
    :ok
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
    personal_number =
      to_string(personal_number)
      |> String.trim()

    case Ims.Accounts.get_user_by_personal_number(personal_number) do
      {:error, _} ->
        Logger.error("User with personal_number #{personal_number} not found.")
        {:error, "User not found"}

      {:ok, user} ->
        # Safely access the :id field
        user_id = Map.get(user, :id)

        if user_id do
          {:ok, user}
        else
          Logger.error("User ID is missing for personal_number #{personal_number}")
          {:error, "User ID missing"}
        end
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

    # Log the result of the query with a proper label
    Repo.get_by(Member, user_id: user.id)

    case Repo.get_by(Member, user_id: user.id) do
      nil ->
        # No member found, create new welfare member
        entry_date = event.inserted_at |> DateTime.to_date()

        member_attrs = %{
          user_id: user.id,
          entry_date: entry_date,
          amount_paid: Decimal.new(0),
          amount_due: Decimal.new(0),
          eligibility: false,
          status: "active"
        }

        %Member{}
        |> Member.changeset(member_attrs)
        |> Repo.insert!()

        Logger.info("Created new welfare member for user_id=#{user.id}")

      _member ->
        # Member already exists, nothing to do
        :ok
    end
  end

  def generate_payment_reference(user_id, event_id) do
    # Combine user_id and event_id into a single string for hashing
    input_string = "#{user_id}-#{event_id}"

    # Generate a SHA256 hash from the input string
    hash = :crypto.hash(:sha256, input_string) |> Base.encode16()

    # Use the first 16 characters of the hash as the payment reference
    payment_reference = String.slice(hash, 0, 16)

    # Ensure uniqueness by checking if the reference already exists in the database
    case Repo.get_by(Contribution, payment_reference: payment_reference) do
      nil ->
        # If unique, return the generated reference
        payment_reference

      _existing_contribution ->
        # If the reference already exists, regenerate with a timestamp or counter
        "#{payment_reference}-#{DateTime.utc_now() |> DateTime.to_unix()}"
    end
  end

  defp update_event_amount_paid(event, amount) do
    new_amount = Decimal.add(event.amount_paid, amount)

    event
    |> Event.changeset(%{amount_paid: new_amount})
    |> Repo.update!()

    Logger.info("Updated event amount_paid to #{new_amount} for event #{event.id}")
  end
end

