defmodule Ims.Welfare do
  @moduledoc """
  The Welfare context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  # alias Ims.Welfare.EventType
  alias Ims.Accounts

  alias Ims.Welfare.{Member, Event, EventType, Contribution}



  @doc """
  Returns the list of event_types.

  ## Examples

      iex> list_event_types()
      [%EventType{}, ...]

  """
  def list_event_types do
    Repo.all(EventType)
  end

  @doc """
  Gets a single event_type.

  Raises `Ecto.NoResultsError` if the Event type does not exist.

  ## Examples

      iex> get_event_type!(123)
      %EventType{}

      iex> get_event_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_type!(id), do: Repo.get!(EventType, id)

  @doc """
  Creates a event_type.

  ## Examples

      iex> create_event_type(%{field: value})
      {:ok, %EventType{}}

      iex> create_event_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_type(attrs \\ %{}) do
    %EventType{}
    |> EventType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_type.

  ## Examples

      iex> update_event_type(event_type, %{field: new_value})
      {:ok, %EventType{}}

      iex> update_event_type(event_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_type(%EventType{} = event_type, attrs) do
    event_type
    |> EventType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event_type.

  ## Examples

      iex> delete_event_type(event_type)
      {:ok, %EventType{}}

      iex> delete_event_type(event_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_type(%EventType{} = event_type) do
    Repo.delete(event_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_type changes.

  ## Examples

      iex> change_event_type(event_type)
      %Ecto.Changeset{data: %EventType{}}

  """
  def change_event_type(%EventType{} = event_type, attrs \\ %{}) do
    EventType.changeset(event_type, attrs)
  end

  alias Ims.Welfare.Event

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  defp get_event(id) do
    case Ims.Welfare.get_event!(id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def create_event_ex(attrs) do
    with {:ok, event} <- Ims.Welfare.create_event(attrs) |> IO.inspect() do
      # Trigger dispatch to refresh all members in batches
      %{job_type: "dispatch"}
      |> Ims.Workers.Welfare.MemberRefreshWorkers.new()
      |> Oban.insert()

      {:ok, event}
    end
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def parse_bill_reference(billref) do
    IO.inspect(billref, label: "Parsing Bill Reference")

    case String.split(billref, "-") do
      [event_part, personal_number] ->
        event_id =
          event_part
          |> String.replace_prefix("e", "")
          |> String.to_integer()

        {:ok, event_id, personal_number}

      _ ->
        {:error, :invalid_billref_format}
    end
  end

  def create_contribution(attrs \\ %{}) do
    IO.inspect(attrs, label: "Creating Contribution")

    with {:ok, event_id, personal_number} <- parse_bill_reference(attrs.ref_no),
         {:ok, event} <- get_event(event_id),
         {:ok, user} <- Accounts.get_user_by_personal_number(personal_number),
         amount <- Decimal.new(attrs.details["TransAmount"] || "0") do
      Repo.transaction(fn ->
        # Create the contribution
        contribution_attrs = %{
          event_id: event.id,
          user_id: user.id,
          amount: amount,
          payment_reference: attrs.details["TransID"],
          payment_gateway_id: attrs.payment_gateway_id,
          source: attrs.source,
          verified: true
        }

        case Contribution.create(contribution_attrs) do
          {:ok, contribution} ->
            # Update the event amount paid
            new_amount = Decimal.add(event.amount_paid, amount)
            {:ok, _} = update_event(event, %{amount_paid: new_amount})
            contribution

          {:error, changeset} ->
            IO.inspect(changeset, label: "Contribution Creation Error")
            Repo.rollback(:contribution_creation_failed)
            {:error, changeset}
        end
      end)
      |> case do
        {:ok, _} -> {:ok, "Contribution created successfully"}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_billref_format} ->
        {:error, "Invalid bill reference format"}

      {:error, :event_not_found} ->
        {:error, "Event not found"}

      {:error, :user_not_found} ->
        {:error, "User not found"}
    end
  end

  def verify_contribution() do
    # This function is a placeholder for the actual implementation
    # You can add your logic here to verify contributions
    # For example, you might want to check if the contribution exists,
    # if it has been verified before, etc.
    {:ok, "Contribution verified successfully"}
  end

 defp dec0, do: Decimal.new(0)

  defp dec(value) when is_number(value), do: Decimal.new(value)
  defp dec(value) when is_binary(value), do: Decimal.new(value)
  defp dec(%Decimal{} = value), do: value
  defp dec(nil), do: dec0()

  @doc """
  Refreshes the member's balance based on their contributions and events.
  """

def refresh_member_balance(%Member{} = member) do
    # 1) Total payable across all non-archived events (sum of event_type.amount)
    total_payable =
      from(e in Event,
        join: et in assoc(e, :event_type),
        where: e.status != ^"archived",
        select: coalesce(sum(et.amount), 0)
      )
      |> Repo.one()
      |> dec()

    # 2) Member's total PAID toward those same events (only verified)
    total_paid =
      from(c in Contribution,
        join: e in Event, on: e.id == c.event_id,
        where:
          c.user_id == ^member.user_id and
          c.verified == true and
          e.status != ^"archived",
        select: coalesce(sum(c.amount), 0)
      )
      |> Repo.one()
      |> dec()

    # 3) Compute eligibility and amount_due
    eligibility = Decimal.cmp(total_paid, total_payable) != :lt
    amount_due =
      total_payable
      |> Decimal.sub(total_paid)
      |> (fn d -> if Decimal.cmp(d, 0) == :lt, do: Decimal.new(0), else: d end).()

    member
    |> Ecto.Changeset.change(
      amount_paid: total_paid,
      amount_due: amount_due,
      eligibility: eligibility
    )
    |> Repo.update!()
  end

  def list_members do
    Member
    |> where([m], m.status == "active")
    |> Repo.all()
  end

   def list_members(filters \\ %{}) when is_map(filters) do
    Member
    |> Member.search(filters)
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
  end

  def list_recent_events(limit \\ 5) do
    Event
    |> where([e], e.status == "active")
    |> order_by([e], desc: e.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_total_contributions do
    query =
      from c in Contribution,
        select: sum(c.amount)

    case Repo.one(query) do
      nil -> 0.0
      amount -> Decimal.to_float(amount)
    end
  end
end
