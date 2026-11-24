defmodule Ims.Leave.AnnualLeave do
  import Ecto.Query

  alias Ims.Accounts.User
  alias Ims.Leave.{AnnualLeaveEntry, LeaveApplication, LeaveBalance, LeaveType}
  alias Ims.Repo.Audited, as: Repo

  @entitlement 30
  @carryover_limit 15

  def today do
    DateTime.utc_now()
    |> DateTime.add(3, :hour)
    |> DateTime.to_date()
  end

  def period_start(%Date{year: year, month: month}) do
    Date.new!(if(month < 7, do: year - 1, else: year), 7, 1)
  end

  def history(user_id) do
    user_id
    |> entries()
    |> Repo.preload(application: :submitted_by)
    |> running_history()
  end

  def running_history(entries) do
    entries
    |> Enum.sort_by(fn entry ->
      priority = if entry.kind in ["opening", "entitlement"], do: 0, else: 1
      {Date.to_gregorian_days(entry.effective_on), priority, entry.id}
    end)
    |> Enum.reduce({[], nil, nil}, &roll_entry/2)
    |> elem(0)
    |> Enum.reverse()
  end

  defp roll_entry(entry, {rows, period, balance}) do
    entry_period = period_start(entry.effective_on)
    carry_source = if period && period.year + 1 == entry_period.year, do: balance
    balance = if period == entry_period, do: balance

    case entry.kind do
      "entitlement" ->
        carry = (carry_source || Decimal.new(0)) |> Decimal.max(0) |> Decimal.min(@carryover_limit)
        total = Decimal.add(entry.days, carry)
        grant = history_row(entry, entry.days, entry.days)
        rolled = history_row(%{entry | kind: "carryover"}, carry, total)
        {[rolled, grant | rows], entry_period, total}

      "opening" ->
        {[history_row(entry, entry.days, entry.days) | rows], entry_period, entry.days}

      kind when kind in ["legacy_leave", "recorded_leave"] ->
        row = history_row(entry, entry.days, nil)
        {[row | rows], entry_period, balance}

      _ ->
        total = if balance, do: Decimal.add(balance, entry.days)
        {[history_row(entry, entry.days, total) | rows], entry_period, total}
    end
  end

  defp history_row(entry, change, balance),
    do: %{entry: entry, change: change, balance: balance}

  def renew(user_id, type_id) do
    with_employee(user_id, fn ->
      ensure_period(user_id, today())
      sync_balance(user_id, type_id)
    end)
  end

  def adjust(user_id, attrs, %User{} = actor) do
    with {:ok, date} <- parse_date(attrs["effective_on"]),
         {:ok, days} <- parse_days(attrs["days"]),
         {:ok, reason} <- parse_reason(attrs["reason"]),
         true <- Date.compare(date, today()) != :gt,
         %LeaveType{id: type_id} <- Repo.get_by(LeaveType, name: "Annual Leave") do
      with_employee(user_id, fn ->
        ensure_period(user_id, today())
        require_period(user_id, date)
        insert_entry(user_id, "adjustment", date, days, actor, reason)
        sync_balance(user_id, type_id)
      end)
    else
      false -> {:error, "The effective date must be today or earlier."}
      nil -> {:error, "Annual Leave is not configured."}
      {:error, _} = error -> error
    end
  end

  def open_period(user_id, attrs, %User{} = actor) do
    with {:ok, date} <- parse_date(attrs["effective_on"]),
         {:ok, days} <- parse_days(attrs["days"], true),
         {:ok, reason} <- parse_reason(attrs["reason"]),
         true <- date == period_start(date) && Date.compare(date, period_start(today())) == :lt,
         %LeaveType{id: type_id} <- Repo.get_by(LeaveType, name: "Annual Leave") do
      with_employee(user_id, fn ->
        ensure_period(user_id, today())

        if period_balance(running_history(entries(user_id)), date) do
          Repo.rollback("This financial year already has an opening balance.")
        end

        insert_entry(user_id, "opening", date, days, actor, reason)
        sync_balance(user_id, type_id)
      end)
    else
      false -> {:error, "Enter 1 July of an earlier financial year."}
      nil -> {:error, "Annual Leave is not configured."}
      {:error, _} = error -> error
    end
  end

  def import_balance(user_id, type_id, target, actor) do
    with_employee(user_id, fn ->
      date = today()
      ensure_period(user_id, date)
      current = period_balance(running_history(entries(user_id)), date)
      difference = Decimal.sub(target, current)

      if Decimal.compare(difference, 0) != :eq do
        insert_entry(user_id, "adjustment", date, difference, actor, "Imported annual leave balance")
      end

      sync_balance(user_id, type_id)
    end)
  end

  def record_past(user_id, attrs, %User{} = actor) do
    with {:ok, from} <- parse_date(attrs["start_date"]),
         {:ok, to} <- parse_date(attrs["end_date"]),
         {:ok, reason} <- parse_reason(attrs["reason"]),
         true <- Date.compare(from, to) != :gt && Date.compare(to, today()) == :lt,
         %LeaveType{id: type_id} <- Repo.get_by(LeaveType, name: "Annual Leave") do
      with_employee(user_id, fn ->
        # The full request is charged to the financial year in which leave starts.
        if Date.diff(to, from) > 366, do: Repo.rollback("The leave period is too long.")
        check_overlap(user_id, from, to, nil)
        previously_deducted = attrs["already_deducted"] == "true"

        changeset =
          LeaveApplication.historical_changeset(%LeaveApplication{}, %{
            user_id: user_id,
            leave_type_id: type_id,
            comment: reason,
            start_date: from,
            end_date: to,
            status: "approved"
          })
          |> Ecto.Changeset.change(%{
            submitted_by_id: actor.id,
            decided_by_id: actor.id,
            decided_at: DateTime.utc_now(:second)
          })

        application = write(Repo.insert(changeset))

        if previously_deducted do
          insert_entry(user_id, "recorded_leave", from, 0, actor, reason, application.id)
        else
          charge(application, actor, reason)
        end

        application
      end)
    else
      false -> {:error, "Enter a past date range with the end date on or after the start date."}
      nil -> {:error, "Annual Leave is not configured."}
      {:error, _} = error -> error
    end
  end

  # Called inside the approval transaction, which holds the application lock.
  def approve(%LeaveApplication{} = application, actor) do
    lock_employee(application.user_id)
    check_overlap(application.user_id, application.start_date, application.end_date, application.id)
    charge(application, actor, application.comment)
  end

  defp charge(application, actor, reason) do
    ensure_period(application.user_id, today())

    date = application.start_date

    if Date.compare(period_start(date), period_start(today())) == :gt do
      Repo.rollback("Approve this request once its financial year starts.")
    end

    require_period(application.user_id, date)

    insert_entry(application.user_id, "leave", date, -application.days_requested, actor, reason, application.id)
    sync_balance(application.user_id, application.leave_type_id)
  end

  defp require_period(user_id, date) do
    opening = period_start(date)

    unless Repo.exists?(from e in AnnualLeaveEntry,
             where: e.user_id == ^user_id and e.effective_on == ^opening and
                      e.kind in ["opening", "entitlement"]
           ) do
      Repo.rollback("Set an opening balance for this financial year or mark the leave as already deducted.")
    end
  end

  defp ensure_period(user_id, date) do
    start = period_start(date)
    last_start =
      Repo.one(from e in AnnualLeaveEntry,
        where: e.user_id == ^user_id and e.kind in ["opening", "entitlement"],
        select: max(e.effective_on)
      )

    first_year = if last_start, do: last_start.year + 1, else: start.year

    if first_year <= start.year do
      Enum.each(first_year..start.year, fn year ->
        insert_entry(user_id, "entitlement", Date.new!(year, 7, 1), @entitlement, nil,
          "Financial-year entitlement")
      end)
    end
  end

  defp sync_balance(user_id, type_id) do
    rows = running_history(entries(user_id))

    if Enum.any?(rows, fn row -> row.balance && Decimal.compare(row.balance, 0) == :lt end) do
      Repo.rollback("This action would make the annual leave balance negative.")
    end

    days = period_balance(rows, today())
    write(LeaveBalance.upsert_leave_balance(%{
      user_id: user_id, leave_type_id: type_id, remaining_days: days
    }))
  end

  defp period_balance(rows, date) do
    start = period_start(date)

    rows
    |> Enum.reverse()
    |> Enum.find_value(fn row ->
      if period_start(row.entry.effective_on) == start, do: row.balance
    end)
  end

  defp check_overlap(user_id, from, to, application_id) do
    query =
      from a in LeaveApplication,
        where: a.user_id == ^user_id and a.status == "approved" and
          a.start_date <= ^to and a.end_date >= ^from

    query = if application_id, do: where(query, [a], a.id != ^application_id), else: query

    if Repo.exists?(query), do: Repo.rollback("The employee already has approved leave on these dates.")
  end

  defp entries(user_id) do
    Repo.all(from e in AnnualLeaveEntry, where: e.user_id == ^user_id)
  end

  defp insert_entry(user_id, kind, date, days, actor, reason, application_id \\ nil) do
    {actor_id, label} = case actor do
      %User{} ->
        name = String.trim("#{actor.first_name} #{actor.last_name}")
        {actor.id, if(name == "", do: "User", else: String.slice(name, 0, 255))}
      nil -> {nil, "System"}
    end

    write(Repo.insert(%AnnualLeaveEntry{
      user_id: user_id, kind: kind, effective_on: date, days: Decimal.new(days),
      actor_id: actor_id, actor_label: label, reason: reason, application_id: application_id
    }))
  end

  defp lock_employee(user_id) do
    Repo.one!(from u in User, where: u.id == ^user_id, select: u.id, lock: "FOR UPDATE")
  end

  defp with_employee(user_id, fun) do
    Repo.transaction(fn ->
      lock_employee(user_id)
      fun.()
    end)
  end

  defp write({:ok, record}), do: record
  defp write({:error, reason}), do: Repo.rollback(reason)

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} when date.year >= 1900 -> {:ok, date}
      _ -> {:error, "Enter valid dates."}
    end
  end

  defp parse_date(_), do: {:error, "Enter valid dates."}

  defp parse_days(value, opening \\ false)

  defp parse_days(value, opening) when is_binary(value) do
    case Decimal.parse(value) do
      {%Decimal{coef: coef} = days, ""} when is_integer(coef) ->
        cond do
          opening && Decimal.compare(days, 0) != :lt && Decimal.compare(days, 45) != :gt ->
            {:ok, days}

          opening ->
            {:error, "Enter an opening balance between 0 and 45 days."}

          Decimal.compare(Decimal.abs(days), 365) != :gt && Decimal.compare(days, 0) != :eq ->
            {:ok, days}

          true ->
            {:error, "Enter a non-zero adjustment between −365 and 365 days."}
        end

      _ -> {:error, "Enter a valid number of days."}
    end
  end

  defp parse_days(_, _), do: {:error, "Enter a valid number of days."}

  defp parse_reason(value) when is_binary(value) do
    case String.trim(value) do
      "" -> {:error, "Enter a reason or an approval reference."}
      reason -> {:ok, reason}
    end
  end

  defp parse_reason(_), do: {:error, "Enter a reason or an approval reference."}
end
