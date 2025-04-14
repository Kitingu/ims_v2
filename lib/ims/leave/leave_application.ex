defmodule Ims.Leave.LeaveApplication do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Leave.{LeaveBalance, LeaveType}
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo
  import Ecto.Query

  @holidays [
    # New Year
    {1, 1},
    # Labor Day
    {1, 5},
    # Madaraka Day
    {1, 6},
    # Utamaduni Day
    {10, 10},
    # Mashujaa Day
    {20, 10},
    # Christmas
    {25, 12},
    # Boxing Day
    {26, 12}
  ]

  schema "leave_applications" do
    field :comment, :string
    field :days_requested, :integer
    field :end_date, :date
    field :proof_document, :string
    field :resumption_date, :date
    field :start_date, :date
    field :status, :string, default: "pending"
    belongs_to :user, Ims.Accounts.User
    belongs_to :leave_type, LeaveType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leave_application, attrs) do
    leave_application
    |> cast(attrs, [
      :days_requested,
      :status,
      :comment,
      :start_date,
      :end_date,
      :resumption_date,
      :proof_document,
      :leave_type_id,
      :user_id
    ])
    |> validate_required([:status, :comment, :start_date, :end_date, :leave_type_id])
    |> validate_future_dates()
    |> validate_end_after_start()
    |> compute_days_requested()
    # Runs after computing `days_requested`
    |> validate_leave_type_specific_rules()
    |> validate_number(:days_requested,
      greater_than: 0,
      message: "Days requested must be positive"
    )
    |> validate_leave_limits()
    |> compute_resumption_date()
  end

  # Ensure dates are in the future
  def validate_future_dates(changeset) do
    today = Date.utc_today()

    # start_date = get_field(changeset, :start_date)
    # end_date = get_field(changeset, :end_date)

    changeset
    |> validate_change(:start_date, fn _, date ->
      if Date.compare(date, today) == :lt do
        [start_date: "Start date cannot be in the past"]
      else
        []
      end
    end)
    |> validate_change(:end_date, fn _, date ->
      if Date.compare(date, today) == :lt do
        [end_date: "End date cannot be in the past"]
      else
        []
      end
    end)
  end

  # Ensure `end_date` is after `start_date`
  defp validate_end_after_start(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "End date must be after start date")
    else
      changeset
    end
  end

  # Validate leave-specific rules
  defp validate_leave_type_specific_rules(changeset) do
    leave_type_id = get_field(changeset, :leave_type_id)

    # Ensure leave_type_id is present before querying
    if is_nil(leave_type_id) do
      add_error(changeset, :leave_type_id, "Leave type is required")
    else
      case Repo.get(LeaveType, leave_type_id) do
        nil ->
          add_error(changeset, :leave_type_id, "Invalid leave type selected")

        %LeaveType{name: "Maternity Leave"} ->
          changeset
          |> validate_number(:days_requested, less_than_or_equal_to: 90)
          |> validate_required([:proof_document],
            message: "Medical certificate required for maternity leave"
          )

        %LeaveType{name: "Paternity Leave"} ->
          changeset
          |> validate_number(:days_requested, less_than_or_equal_to: 10)
          |> validate_required([:proof_document],
            message: "Birth notification required for paternity leave"
          )

        %LeaveType{name: "Annual Leave"} ->
          changeset
          |> validate_number(:days_requested, less_than_or_equal_to: 30)
          |> validate_annual_leave()

        %LeaveType{name: "Sick Leave"} ->
          changeset
          |> validate_number(:days_requested, less_than_or_equal_to: 90)
          |> validate_required([:proof_document],
            message: "Medical certificate required for sick leave"
          )

        %LeaveType{name: "Terminal Leave"} ->
          changeset
          |> validate_number(:days_requested, less_than_or_equal_to: 30)

        _ ->
          changeset
      end
    end
  end

  # Validate Annual Leave Rules
  defp validate_annual_leave(changeset) do
    user_id = get_field(changeset, :user_id)
    days_requested = get_field(changeset, :days_requested) || 0
    leave_taken = get_annual_leave_taken(user_id) || 0

    if leave_taken + days_requested > 30 do
      add_error(changeset, :days_requested, "Cannot exceed 30 days of annual leave in a year")
    else
      changeset
    end
  end

  # Fetch the actual annual leave taken by the user
  defp get_annual_leave_taken(user_id) do
    query =
      from(la in Ims.Leave.LeaveApplication,
        where: la.user_id == ^user_id and la.leave_type_id == ^get_annual_leave_type_id(),
        select: sum(la.days_requested)
      )

    Repo.one(query) || 0
  end

  # Get the leave type ID for annual leave
  defp get_annual_leave_type_id() do
    case Repo.get_by(Ims.Leave.LeaveType, name: "Annual Leave") do
      %Ims.Leave.LeaveType{id: id} -> id
      _ -> nil
    end
  end

  # Validate against leave balance and leave type max days
  defp validate_leave_limits(changeset) do
    user_id = get_field(changeset, :user_id)
    leave_type_id = get_field(changeset, :leave_type_id)
    days_requested = get_field(changeset, :days_requested) |> IO.inspect(label: "days_requested")

    if user_id && leave_type_id && days_requested do
      leave_balance =
        get_leave_balance(user_id, leave_type_id)
        |> IO.inspect(label: "leave_balance")

      leave_type_max_days =
        get_leave_type_max_days(leave_type_id)

      changeset
      |> validate_change(:days_requested, fn _, _ ->
        cond do
          days_requested > leave_type_max_days ->
            [
              {:days_requested,
               "Cannot apply for more than #{leave_type_max_days} days for this leave type"}
            ]

          # days_requested > leave_balance
          days_requested > Decimal.to_integer(leave_balance) ->
            [{:days_requested, "Insufficient leave balance"}]

          true ->
            []
        end
      end)
    else
      changeset
    end
  end

  # Fetch leave balance for a user and leave type
  defp get_leave_balance(user_id, leave_type_id) do
    case Repo.get_by(LeaveBalance, user_id: user_id, leave_type_id: leave_type_id) do
      nil -> 0
      balance -> balance.remaining_days
    end
  end

  # Fetch max leave days for the given leave type
  defp get_leave_type_max_days(leave_type_id) do
    case Repo.get(LeaveType, leave_type_id) do
      nil -> 0
      leave_type -> leave_type.max_days
    end
  end

  def is_business_day?(date) when is_nil(date), do: false

  def is_business_day?(date) do
    Date.day_of_week(date) in 1..5 and not is_holiday?(date)
  end

  def is_weekend?(date) when is_nil(date), do: false
  def is_weekend?(date), do: Date.day_of_week(date) in [6, 7]

  def is_holiday?(date) when is_nil(date), do: false

  def is_holiday?(date) do
    # 1. Check hardcoded holidays (day/month tuples)
    hardcoded_match? =
      Enum.any?(@holidays, fn {day, month} ->
        date.day == day && date.month == month
      end)

    # 2. Check dynamic holidays from DB (comma-separated "DD-MM-YYYY")
    db_match? =
      case Ims.Settings.Setting.get_setting("holidays") do
        nil ->
          false

        holidays_string ->
          holidays_string
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.any?(fn date_str ->
            case parse_date(date_str) do
              {:ok, holiday_date} -> Date.compare(date, holiday_date) == :eq
              _ -> false
            end
          end)
      end

    hardcoded_match? or db_match?
  end

  # Helper to parse "DD-MM-YYYY" (returns {:ok, Date} or :error)
  defp parse_date(date_str) do
    case String.split(date_str, "-") do
      [day, month, year] ->
        with {day, ""} <- Integer.parse(day),
             {month, ""} <- Integer.parse(month),
             {year, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year, month, day) do
          {:ok, date}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def compute_days_requested(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date do
      num_days = num_business_days(start_date, end_date)
      put_change(changeset, :days_requested, num_days)
    else
      changeset
    end
  end

  def compute_resumption_date(changeset) do
    end_date = get_field(changeset, :end_date)

    if end_date do
      resumption_date = next_business_day(end_date)
      put_change(changeset, :resumption_date, resumption_date)
    else
      changeset
    end
  end

  defp num_business_days(start_date, end_date) do
    Enum.count(Date.range(start_date, end_date), &is_business_day?/1)
  end

  defp next_business_day(nil), do: nil

  defp next_business_day(date) do
    next_date = Date.add(date, 1)

    if is_business_day?(next_date) do
      next_date
    else
      next_business_day(next_date)
    end
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == "status" ->
            from(q in accum_query, where: q.status == ^v)

          k == "user_id" ->
            from(q in accum_query, where: q.user_id == ^v)

          k == "leave_type_id" ->
            from(q in accum_query, where: q.leave_type_id == ^v)

          k == "department_id" ->
            from(q in accum_query,
              join: u in assoc(q, :user),
              join: d in assoc(u, :department),
              where: d.id == ^v
            )

          true ->
            accum_query
        end
      end)

    from(q in query, preload: [:user, :leave_type])
  end

  @doc """
  Approves a leave application and deducts the requested leave days from the user's balance.
  """
  def approve_leave_application(leave_application_id) do
    Repo.transaction(fn ->
      with %__MODULE__{
             user_id: user_id,
             leave_type_id: leave_type_id,
             days_requested: days_requested,
             status: "pending"
           } = leave_application <-
             get(leave_application_id),
           %LeaveBalance{remaining_days: remaining_days} = leave_balance <-
             Repo.get_by(LeaveBalance, user_id: user_id, leave_type_id: leave_type_id) do

        # Convert all values to Decimal for safe comparison
        requested_days = Decimal.new(days_requested)
        current_balance = Decimal.new(remaining_days)

        # Validate sufficient balance
        if Decimal.compare(current_balance, requested_days) == :lt do
          Repo.rollback("Insufficient leave balance")
        end

        # Calculate new balance (as Decimal)
        new_balance = Decimal.sub(current_balance, requested_days)

        # Update leave balance (storing as decimal)
        leave_balance
        |> Ecto.Changeset.change(%{remaining_days: new_balance})
        |> Repo.update!()

        # Approve the leave application
        leave_application
        |> Ecto.Changeset.change(%{status: "approved"})
        |> Repo.update!()

        {:ok, leave_application}
      else
        nil -> Repo.rollback("Leave application not found")
        _ -> Repo.rollback("Invalid leave application status")
      end
    end)
  end

  def reject_leave_application(leave_application_id) do
    Repo.transaction(fn ->
      with %__MODULE__{status: "pending"} = leave_application <- get(leave_application_id) do
        leave_application
        |> Ecto.Changeset.change(%{status: "rejected"})
        |> Repo.update!()

        {:ok, leave_application}
      else
        nil -> {:error, "Leave application not found"}
        _ -> {:error, "Invalid leave application status"}
      end
    end)
  end
end
