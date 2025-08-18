defmodule Ims.Workers.ProcessContributionsWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Ims.{Repo, Welfare.Contribution, Accounts, Accounts.User, Welfare.Event}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"file_path" => path}}) do
    {:ok, table_id} = Xlsxir.multi_extract(path, 0)
    rows = Xlsxir.get_list(table_id)
    Xlsxir.close(table_id)

    Logger.info("Processing contributions from file: #{path}")

    [headers | data_rows] = rows

    header_map =
      Enum.with_index(headers, fn h, i -> {h, i} end)
      |> Map.new()

    data_rows
    |> Enum.each(fn row ->
      with {:ok, event_id} <- parse_event_id(get_cell(row, header_map, "event_id")),
           {:ok, event} <- find_event(event_id),
           {:ok, user} <- find_user(get_cell(row, header_map, "personal_number")),
           {:ok, amount} <- parse_amount(get_cell(row, header_map, "amount paid")),
           {:ok, paid_at} <- parse_date(get_cell(row, header_map, "date paid")) do
        ensure_member_exists(user, event)

        payment_reference =
          case get_cell(row, header_map, "payment reference") do
            nil -> generate_payment_reference(user.id, event.id)
            "" -> generate_payment_reference(user.id, event.id)
            reference -> reference
          end

        # ---------- INSERT with ON CONFLICT DO NOTHING ----------
        attrs = %{
          amount: amount,
          payment_reference: payment_reference,
          source: "MPESA",
          user_id: user.id,
          event_id: event.id,
          date_paid: paid_at
        }

        insert_result =
          Repo.insert(
            %Contribution{} |> Contribution.changeset(attrs),
            on_conflict: :nothing,
            conflict_target: [:user_id, :event_id]
          )

        case insert_result do
          {:ok, %Contribution{}} ->
            update_event_amount_paid(event, amount)
            Ims.Welfare.update_member_amount_paid(user.id, event.id, amount)

          {:error, changeset} ->
            # Handle other errors (e.g., payment_reference unique)
            Logger.error("Failed to insert contribution: #{inspect(changeset.errors)}")

          {:ok, nil} ->
            # Conflict hit (user already has a contribution for this event)
            Logger.info("User #{user.id} already contributed to event #{event.id}; skipping.")
        end

        # -------------------------------------------------------
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

    Repo.get_by(Member, user_id: user.id)

    case Repo.get_by(Member, user_id: user.id) do
      nil ->
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
        :ok
    end
  end

  def generate_payment_reference(user_id, event_id) do
    input_string = "#{user_id}-#{event_id}"
    hash = :crypto.hash(:sha256, input_string) |> Base.encode16()
    payment_reference = String.slice(hash, 0, 16)

    case Repo.get_by(Contribution, payment_reference: payment_reference) do
      nil -> payment_reference
      _existing_contribution -> "#{payment_reference}-#{DateTime.utc_now() |> DateTime.to_unix()}"
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
