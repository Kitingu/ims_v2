defmodule Ims.Leave.LeaveBalance do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  # import Ims.RepoHelpers, repo: Repo

  schema "leave_balances" do
    field :remaining_days, :decimal
    belongs_to :user, Ims.Accounts.User
    belongs_to :leave_type, Ims.Leave.LeaveType

    timestamps(type: :utc_datetime)
  end

  def changeset(leave_balance, attrs) do
    leave_balance
    |> cast(attrs, [:remaining_days, :user_id, :leave_type_id])
    |> validate_required([:remaining_days, :user_id, :leave_type_id])
    |> validate_number(:remaining_days,
      greater_than_or_equal_to: 0,
      message: "Remaining leave days cannot be negative"
    )
    |> unique_constraint([:user_id, :leave_type_id], name: :unique_user_leave_type_balance)
  end

  def create(attrs) do
    case get_leave_balance(attrs.user_id, attrs.leave_type_id) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      _existing_record ->
        {:error, "Leave balance for this leave type already exists"}
    end
  end

  def get_leave_balance(user_id, leave_type_id) do
    from(lb in __MODULE__,
      where: lb.user_id == ^user_id and lb.leave_type_id == ^leave_type_id,
      select: lb
    )
    |> Repo.one()
  end

  def update_leave_balance(user_id, leave_type_id, new_days) do
    case get_leave_balance(user_id, leave_type_id) do
      nil ->
        {:error, "Leave balance not found"}

      leave_balance ->
        leave_balance
        |> changeset(%{remaining_days: new_days})
        |> Repo.update()
    end
  end

  def list_user_leave_balances(user_id) do
    from(lb in __MODULE__,
      where: lb.user_id == ^user_id and is_nil(lb.deleted_at),
      select: lb
    )
    |> Repo.all()
  end

  def deduct_leave_days(user_id, leave_type_id, days) do
    case get_leave_balance(user_id, leave_type_id) do
      nil ->
        {:error, "Leave balance not found"}

      %__MODULE__{remaining_days: remaining} = leave_balance when remaining >= days ->
        leave_balance
        |> changeset(%{remaining_days: remaining - days})
        |> Repo.update()

      _ ->
        {:error, "Not enough leave balance"}
    end
  end

  def upsert_leave_balance(%{user_id: user_id, leave_type_id: leave_type_id, remaining_days: remaining_days}) do
    now = DateTime.utc_now(:second)

    insert = %__MODULE__{
      user_id: user_id,
      leave_type_id: leave_type_id,
      remaining_days: remaining_days,
      inserted_at: now,
      updated_at: now
    }

    Repo.insert(
      insert,
      on_conflict: [set: [remaining_days: remaining_days, updated_at: now]],
      conflict_target: [:user_id, :leave_type_id],
      returning: true
    )
  end
end
