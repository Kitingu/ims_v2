defmodule Ims.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Accounts.{User, Role, Departments, UserToken, UserNotifier}
  alias Ims.Leave.LeaveBalance

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user_by_personal_number(personal_number) do
    case Repo.get_by(User, personal_number: personal_number) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user_by_personal_number!(personal_number) do
    Repo.get_by!(User, personal_number: personal_number)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload([:roles, :department, :job_group])
  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, attrs))
    |> Ecto.Multi.run(:leave_balances, fn _repo, %{user: user} ->
      set_default_leave_balances(user.id)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}

      {:error, :leave_balances, _error, _} ->
        {:error,
         Ecto.Changeset.change(%User{})
         |> Ecto.Changeset.add_error(:base, "User created but failed to set leave balances")}
    end
  end

  def set_default_leave_balances(user_id) do
    user = Repo.get!(Ims.Accounts.User, user_id)
    leave_types = Repo.all(Ims.Leave.LeaveType)

    results =
      Enum.map(leave_types, fn leave_type ->
        skip =
          case {String.downcase(user.gender), String.downcase(leave_type.name)} do
            {"male", "maternity leave"} -> true
            {"female", "paternity leave"} -> true
            _ -> false
          end

        unless skip do
          %Ims.Leave.LeaveBalance{}
          |> Ims.Leave.LeaveBalance.changeset(%{
            user_id: user_id,
            leave_type_id: leave_type.id,
            remaining_days: 0
          })
          |> Repo.insert()
        else
          {:skipped, leave_type.name}
        end
      end)

    case Enum.all?(results, fn
           {:ok, _} -> true
           {:skipped, _} -> true
           _ -> false
         end) do
      true -> {:ok, results}
      false -> {:error, :some_failed}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  def update_user(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def list_users do
    Repo.all(User)
    # Preload the role association and department association
    |> Repo.preload([:roles, :department, :job_group])
  end

  def update_user_role(user_id, role_id) do
    # Fetch the user and preload the roles association
    user =
      Repo.get!(User, user_id)
      |> Repo.preload(:roles)

    # Fetch the role
    role = Repo.get!(Role, role_id)

    # Build the changeset to associate the new role
    changeset =
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:roles, [role])

    # Persist the changeset
    case Repo.update(changeset) do
      {:ok, updated_user} -> {:ok, updated_user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_leave_balance(user_id, leave_type_id) do
    from(lb in LeaveBalance, where: lb.user_id == ^user_id and lb.leave_type_id == ^leave_type_id)
    |> Repo.one()
  end

  def get_user_with_leave_balances(user_id) do
    from(u in User, where: u.id == ^user_id)
    |> Repo.preload([:roles, :department])
    |> Repo.preload(leave_balances: :leave_type)
    |> Repo.one()
  end

  alias Ims.Accounts.JobGroup

  @doc """
  Returns the list of job_groups.

  ## Examples

      iex> list_job_groups()
      [%JobGroup{}, ...]

  """
  def list_job_groups do
    Repo.all(JobGroup)
  end

  @doc """
  Gets a single job_group.

  Raises `Ecto.NoResultsError` if the Job group does not exist.

  ## Examples

      iex> get_job_group!(123)
      %JobGroup{}

      iex> get_job_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_group!(id), do: Repo.get!(JobGroup, id)

  @doc """
  Creates a job_group.

  ## Examples

      iex> create_job_group(%{field: value})
      {:ok, %JobGroup{}}

      iex> create_job_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job_group(attrs \\ %{}) do
    %JobGroup{}
    |> JobGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a job_group.

  ## Examples

      iex> update_job_group(job_group, %{field: new_value})
      {:ok, %JobGroup{}}

      iex> update_job_group(job_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job_group(%JobGroup{} = job_group, attrs) do
    job_group
    |> JobGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a job_group.

  ## Examples

      iex> delete_job_group(job_group)
      {:ok, %JobGroup{}}

      iex> delete_job_group(job_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job_group(%JobGroup{} = job_group) do
    Repo.delete(job_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job_group changes.

  ## Examples

      iex> change_job_group(job_group)
      %Ecto.Changeset{data: %JobGroup{}}

  """
  def change_job_group(%JobGroup{} = job_group, attrs \\ %{}) do
    JobGroup.changeset(job_group, attrs)
  end

  def list_departments do
    Repo.all(Ims.Accounts.Departments)
  end

  def change_departments(%Ims.Accounts.Departments{} = departments, attrs \\ %{}) do
    Ims.Accounts.Departments.changeset(departments, attrs)
  end

  def get_departments!(id) do
    Repo.get!(Ims.Accounts.Departments, id)
  end

  @doc """
  Creates a department.

  ## Examples

      iex> create_department(%{field: value})
      {:ok, %Departments{}}

      iex> create_department(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_departments(attrs \\ %{}) do
    %Departments{}
    |> Departments.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a department.

  ## Examples

      iex> update_department(department, %{field: new_value})
      {:ok, %Departments{}}

      iex> update_department(department, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_departments(%Departments{} = department, attrs) do
    department
    |> Departments.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a department.

  ## Examples

      iex> delete_department(department)
      {:ok, %Departments{}}

      iex> delete_department(department)
      {:error, %Ecto.Changeset{}}

  """
  def delete_departments(%Departments{} = department) do
    Repo.delete(department)
  end

  def generate_upload_template do
    departments = list_departments() |> Enum.map(&{&1.name, &1.id})
    job_groups = list_job_groups() |> Enum.map(&{&1.name, &1.id})

    headers = [
      "Email*",
      "First Name*",
      "Last Name*",
      "Phone Number*",
      "Personal Number",
      "Designation",
      "Gender* (Male/Female)",
      "Department ID*",
      "Job Group ID*",
      "Annual Leave",
      "Maternity Leave",
      "Paternity Leave",
      "Sick Leave",
      "Terminal Leave"
    ]

    user_sheet = %Elixlsx.Sheet{
      name: "Users",
      rows: [headers]
    }

    ref_sheet = %Elixlsx.Sheet{
      name: "Reference",
      rows:
        [
          ["Department Name", "Department ID"]
          | Enum.map(departments, fn {name, id} -> [name, id] end)
        ] ++
          [[]] ++
          [
            ["Job Group Name", "Job Group ID"]
            | Enum.map(job_groups, fn {name, id} -> [name, id] end)
          ]
    }

    workbook = %Elixlsx.Workbook{sheets: [user_sheet, ref_sheet]}

    path = Path.join(System.tmp_dir(), "user_upload_template.xlsx")
    Elixlsx.write_to(workbook, path)

    File.read!(path)
  end

  defp format_options(options) do
    options
    |> Enum.map(fn {name, id} -> "#{name} (#{id})" end)
    |> Enum.join(", ")
  end
end
