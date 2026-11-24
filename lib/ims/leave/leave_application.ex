defmodule Ims.Leave.LeaveApplication do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Leave.{AnnualLeave, LeaveBalance, LeaveType}
  alias Ims.Repo.Audited, as: Repo
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
    belongs_to :submitted_by, Ims.Accounts.User
    belongs_to :decided_by, Ims.Accounts.User
    field :decided_at, :utc_datetime

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

  def historical_changeset(application, attrs) do
    application
    |> cast(attrs, [:user_id, :leave_type_id, :start_date, :end_date, :comment, :status])
    |> validate_required([:user_id, :leave_type_id, :start_date, :end_date, :comment, :status])
    |> validate_end_after_start()
    |> compute_days_requested()
    |> validate_number(:days_requested, greater_than: 0)
    |> compute_resumption_date()
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

  # Validate against leave balance and leave type max days
  defp validate_leave_limits(changeset) do
    user_id = get_field(changeset, :user_id)
    leave_type_id = get_field(changeset, :leave_type_id)
    days_requested = get_field(changeset, :days_requested)

    if user_id && leave_type_id && days_requested do
      leave_balance = get_leave_balance(user_id, leave_type_id)

      leave_type = Repo.get(LeaveType, leave_type_id)

      changeset
      |> validate_change(:days_requested, fn _, _ ->
        cond do
          match?(%LeaveType{name: "Annual Leave"}, leave_type) ->
            []

          leave_type && days_requested > leave_type.max_days ->
            [days_requested: "Cannot apply for more than #{leave_type.max_days} days for this leave type"]

          Decimal.compare(Decimal.new(days_requested), leave_balance) == :gt ->
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
      nil -> Decimal.new(0)
      balance -> balance.remaining_days
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

    if start_date && end_date && Date.compare(start_date, end_date) != :gt do
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

          k == "from" ->
            from(q in accum_query, where: q.end_date >= ^v)

          k == "to" ->
            from(q in accum_query, where: q.start_date <= ^v)

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

    from(q in query, preload: [:user, :leave_type, :submitted_by, :decided_by])
  end

  @doc """
  Approves a leave application and deducts the requested leave days from the user's balance.
  """
  def approve_leave_application(id, actor \\ nil) do
    decide(id, "approved", actor, fn application ->
      type = Repo.get!(LeaveType, application.leave_type_id)

      if type.name == "Annual Leave" do
        AnnualLeave.approve(application, actor)
      else
        deduct_balance(application)
      end
    end)
  end

  def reject_leave_application(id, actor \\ nil) do
    decide(id, "rejected", actor, fn _application -> :ok end)
  end

  defp decide(id, status, actor, before_decision) do
    Repo.transaction(fn ->
      case Repo.one(from a in __MODULE__, where: a.id == ^id, lock: "FOR UPDATE") do
        %__MODULE__{status: "pending"} = application ->
          before_decision.(application)

          application
          |> change(%{status: status, decided_by_id: actor && actor.id, decided_at: DateTime.utc_now(:second)})
          |> Repo.update!()

        nil ->
          Repo.rollback("Leave application not found.")

        _ ->
          Repo.rollback("This leave application has already been decided.")
      end
    end)
  end

  defp deduct_balance(application) do
    query =
      from b in LeaveBalance,
        where: b.user_id == ^application.user_id and b.leave_type_id == ^application.leave_type_id,
        lock: "FOR UPDATE"

    with %LeaveBalance{} = balance <- Repo.one(query),
         remaining = Decimal.sub(balance.remaining_days, application.days_requested),
         true <- Decimal.compare(remaining, 0) != :lt do
      balance |> change(remaining_days: remaining) |> Repo.update!()
    else
      _ -> Repo.rollback("Insufficient leave balance.")
    end
  end
end
