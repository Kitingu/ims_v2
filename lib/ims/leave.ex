defmodule Ims.Leave do
  @moduledoc """
  The Leave context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Leave.LeaveType

  @doc """
  Returns the list of leave_types.

  ## Examples

      iex> list_leave_types()
      [%LeaveType{}, ...]

  """
  def list_leave_types do
    Repo.all(LeaveType)
  end

  @doc """
  Gets a single leave_type.

  Raises `Ecto.NoResultsError` if the Leave type does not exist.

  ## Examples

      iex> get_leave_type!(123)
      %LeaveType{}

      iex> get_leave_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_leave_type!(id), do: Repo.get!(LeaveType, id)

  @doc """
  Creates a leave_type.

  ## Examples

      iex> create_leave_type(%{field: value})
      {:ok, %LeaveType{}}

      iex> create_leave_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_leave_type(attrs \\ %{}) do
    %LeaveType{}
    |> LeaveType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a leave_type.

  ## Examples

      iex> update_leave_type(leave_type, %{field: new_value})
      {:ok, %LeaveType{}}

      iex> update_leave_type(leave_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_leave_type(%LeaveType{} = leave_type, attrs) do
    leave_type
    |> LeaveType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a leave_type.

  ## Examples

      iex> delete_leave_type(leave_type)
      {:ok, %LeaveType{}}

      iex> delete_leave_type(leave_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_leave_type(%LeaveType{} = leave_type) do
    Repo.delete(leave_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking leave_type changes.

  ## Examples

      iex> change_leave_type(leave_type)
      %Ecto.Changeset{data: %LeaveType{}}

  """
  def change_leave_type(%LeaveType{} = leave_type, attrs \\ %{}) do
    LeaveType.changeset(leave_type, attrs)
  end

  alias Ims.Leave.LeaveBalance

  @doc """
  Returns the list of leave_balances.

  ## Examples

      iex> list_leave_balances()
      [%LeaveBalance{}, ...]

  """
  def list_leave_balances do
    Repo.all(LeaveBalance)
  end

  @doc """
  Gets a single leave_balance.

  Raises `Ecto.NoResultsError` if the Leave balance does not exist.

  ## Examples

      iex> get_leave_balance!(123)
      %LeaveBalance{}

      iex> get_leave_balance!(456)
      ** (Ecto.NoResultsError)

  """
  def get_leave_balance!(id), do: Repo.get!(LeaveBalance, id)

  def get_leave_balance(user_id, leave_type_id) do
    case Repo.get_by(Ims.Leave.LeaveBalance, user_id: user_id, leave_type_id: leave_type_id) do
      nil ->
        0

      %Ims.Leave.LeaveBalance{remaining_days: remaining_days} ->
        Decimal.to_float(remaining_days)
    end
  end

  @doc """
  Creates a leave_balance.

  ## Examples

      iex> create_leave_balance(%{field: value})
      {:ok, %LeaveBalance{}}

      iex> create_leave_balance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_leave_balance(attrs \\ %{}) do
    %LeaveBalance{}
    |> LeaveBalance.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a leave_balance.

  ## Examples

      iex> update_leave_balance(leave_balance, %{field: new_value})
      {:ok, %LeaveBalance{}}

      iex> update_leave_balance(leave_balance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_leave_balance(%LeaveBalance{} = leave_balance, attrs) do
    leave_balance
    |> LeaveBalance.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a leave_balance.

  ## Examples

      iex> delete_leave_balance(leave_balance)
      {:ok, %LeaveBalance{}}

      iex> delete_leave_balance(leave_balance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_leave_balance(%LeaveBalance{} = leave_balance) do
    Repo.delete(leave_balance)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking leave_balance changes.

  ## Examples

      iex> change_leave_balance(leave_balance)
      %Ecto.Changeset{data: %LeaveBalance{}}

  """
  def change_leave_balance(%LeaveBalance{} = leave_balance, attrs \\ %{}) do
    LeaveBalance.changeset(leave_balance, attrs)
  end

  alias Ims.Leave.LeaveApplication

  @doc """
  Returns the list of leave_applications.

  ## Examples

      iex> list_leave_applications()
      [%LeaveApplication{}, ...]

  """
  def list_leave_applications do
    Repo.all(LeaveApplication)
  end

  @doc """
  Gets a single leave_application.

  Raises `Ecto.NoResultsError` if the Leave application does not exist.

  ## Examples

      iex> get_leave_application!(123)
      %LeaveApplication{}

      iex> get_leave_application!(456)
      ** (Ecto.NoResultsError)

  """
  def get_leave_application!(id) do
    Repo.get!(LeaveApplication, id)
    |> Repo.preload(:leave_type)
  end

  @doc """
  Creates a leave_application.

  ## Examples

      iex> create_leave_application(%{field: value})
      {:ok, %LeaveApplication{}}

      iex> create_leave_application(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_leave_application(attrs \\ %{}) do
    %LeaveApplication{}
    |> LeaveApplication.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a leave_application.

  ## Examples

      iex> update_leave_application(leave_application, %{field: new_value})
      {:ok, %LeaveApplication{}}

      iex> update_leave_application(leave_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_leave_application(%LeaveApplication{} = leave_application, attrs) do
    leave_application
    |> LeaveApplication.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a leave_application.

  ## Examples

      iex> delete_leave_application(leave_application)
      {:ok, %LeaveApplication{}}

      iex> delete_leave_application(leave_application)
      {:error, %Ecto.Changeset{}}

  """
  def delete_leave_application(%LeaveApplication{} = leave_application) do
    Repo.delete(leave_application)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking leave_application changes.

  ## Examples

      iex> change_leave_application(leave_application)
      %Ecto.Changeset{data: %LeaveApplication{}}

  """
  def change_leave_application(%LeaveApplication{} = leave_application, attrs \\ %{}) do
    LeaveApplication.changeset(leave_application, attrs)
  end

  # Get leave balance for a user and type
  def get_leave_by_user_and_type(user_id, leave_type_id) do
    Repo.get_by(LeaveApplication, user_id: user_id, leave_type_id: leave_type_id)
  end

  # Insert a new leave balance if not found
  def insert_leave_days(user_id, leave_type_id, days_remaining) do
    changeset =
      %LeaveApplication{}
      |> LeaveApplication.changeset(%{
        user_id: user_id,
        leave_type_id: leave_type_id,
        remaining_days: days_remaining
      })

    Repo.insert(changeset)
  end

  def get_user_leave_balances(user_id) do
    from(l in LeaveBalance,
      where: l.user_id == ^user_id,
      preload: [:leave_type]
    )
    |> Repo.all()
  end

  def get_all_leave_balances do
    # Fetch all leave balances group by user_id and leave_type_id
    from(l in LeaveBalance,
      group_by: [l.user_id, l.leave_type_id],
      select: %{
        user_id: l.user_id,
        leave_type_id: l.leave_type_id,
        remaining_days: sum(l.remaining_days)
      }
    )
    |> Repo.all()
    |> Enum.map(fn leave_balance ->
      %{
        user_id: leave_balance.user_id,
        leave_type_id: leave_balance.leave_type_id,
        remaining_days: Decimal.to_integer(leave_balance.remaining_days)
      }
    end)
  end

  def paginated_leave_balances(params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = Map.get(params, "page_size", "10") |> String.to_integer()

    # First get all users with pagination
    user_query =
      from u in Ims.Accounts.User,
        select: %{
          id: u.id,
          personal_number: u.personal_number,
          first_name: u.first_name,
          last_name: u.last_name
        }

    user_page = Ims.Repo.paginate(user_query, page: page, page_size: page_size)

    # Get all leave types
    leave_types = Repo.all(from lt in Ims.Leave.LeaveType, select: lt.name)

    # Get leave balances for these users
    balances_query =
      from lb in Ims.Leave.LeaveBalance,
        join: u in assoc(lb, :user),
        join: lt in assoc(lb, :leave_type),
        where: u.id in ^Enum.map(user_page.entries, & &1.id),
        select: %{
          user_id: u.id,
          leave_type: lt.name,
          remaining_days: lb.remaining_days
        }

    balances = Repo.all(balances_query)

    # Build the result with all leave types for each user
    entries =
      user_page.entries
      |> Enum.map(fn user ->
        user_balances =
          Enum.filter(balances, &(&1.user_id == user.id))
          |> Enum.map(fn b -> {b.leave_type, Decimal.to_float(b.remaining_days)} end)
          |> Enum.into(%{})

        # Merge with default 0 values for all leave types
        complete_balances =
          leave_types
          |> Enum.map(&{&1, 0.0})
          |> Enum.into(%{})
          |> Map.merge(user_balances)

        Map.merge(user, complete_balances)
      end)

    %{user_page | entries: entries}
  end

  def group_balances(entries) do
    entries
    |> Enum.group_by(&{&1.personal_number, &1.first_name, &1.last_name})
    |> Enum.map(fn {{pn, fnm, lnm}, list} ->
      Map.merge(
        %{
          personal_number: pn,
          first_name: fnm,
          last_name: lnm
        },
        Enum.into(list, %{}, fn row -> {row.leave_type, row.remaining_days} end)
      )
    end)
  end

  def get_leave_balances_matrix do
    leave_types = Repo.all(from lt in Ims.Leave.LeaveType, select: {lt.name, lt.id})

    Ims.Repo.all(
      from lb in Ims.Leave.LeaveBalance,
        join: u in assoc(lb, :user),
        join: lt in assoc(lb, :leave_type),
        preload: [user: u, leave_type: lt]
    )
    |> build_matrix(leave_types)
  end

  def build_matrix(balances, leave_types) do
    # Convert leave_types to a map of name => default 0 value
    default_leave_days =
      leave_types
      |> Enum.map(fn {name, _id} -> {name, 0.0} end)
      |> Enum.into(%{})

    balances
    |> Enum.group_by(& &1.user.id)
    |> Enum.map(fn {_user_id, user_balances} ->
      user = hd(user_balances).user

      leave_days =
        user_balances
        |> Enum.map(fn b ->
          {b.leave_type.name, Decimal.to_float(b.remaining_days)}
        end)
        |> Enum.into(%{})
        # Merge with defaults to ensure all leave types are present
        |> Map.merge(default_leave_days, fn _k, v1, _v2 -> v1 end)

      Map.merge(
        %{
          personal_number: user.personal_number,
          first_name: user.first_name,
          last_name: user.last_name
        },
        leave_days
      )
    end)
  end

  
end
