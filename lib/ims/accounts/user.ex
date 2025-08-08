defmodule Ims.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Repo
  import Ecto.Query
  alias Ims.Accounts.{Role, Departments, JobGroup}
  alias Ims.Leave.{LeaveBalance, LeaveType}
  use Ims.RepoHelpers, repo: Repo

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :first_name, :string
    field :last_name, :string
    field :id_number, :string
    field :msisdn, :string
    belongs_to :department, Departments
    field :personal_number, :string
    field :designation, :string
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    # New field
    field :password_reset_required, :boolean, default: true
    # New gender field
    field :gender, :string
    field :sys_user, :boolean, default: false

    many_to_many :roles, Role,
      join_through: "user_roles",
      on_replace: :delete

    has_many :leave_balances, LeaveBalance
    belongs_to :job_group, JobGroup
    # many_to_many :roles, Role, join_through: UserRole

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :designation,
      :personal_number,
      :msisdn,
      :department_id,
      :job_group_id,
      :gender,
      :id_number,
      :sys_user,
      :password_reset_required
    ])
    |> cast_assoc(:department)
    |> validate_required([
      :email,
      # :password,
      # :password_confirmation,
      :first_name,
      :last_name,
      :department_id,
      :msisdn,
      :designation,
      :job_group_id,
      :gender
    ])
    |> validate_email(opts)
    |> validate_msisdn()
    |> validate_inclusion(:gender, ["Male", "Female"])
    |> unique_constraint(:msisdn, name: "unique_msisdn")
    |> unique_constraint(:email, name: "unique_email")
    |> unique_constraint(:personal_number, name: "unique_personal_number")
    |> unique_constraint(:id_number)
    |> validate_password(opts)

    # |> validate_password_confirmation()
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :personal_number,
      :designation,
      :department_id,
      :msisdn
    ])
    |> validate_required([:email, :first_name, :last_name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_msisdn()
    |> unique_constraint(:msisdn, name: "unique_msisdn")
    |> validate_length(:personal_number, min: 6, max: 8)
    |> put_change(:sys_user, false)
  end

  def staff_member_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :msisdn,
      :personal_number,
      :designation,
      :gender,
      :department_id,
      :job_group_id,
      :password_reset_required,
      :id_number,
      :sys_user
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :personal_number,
      :designation,
      :gender,
      :department_id,
      :job_group_id
    ])
    |> unique_constraint(:id_number)
    |> unique_constraint(:personal_number)
    |> put_change(:sys_user, false)
  end

  def role_changeset(role, permissions) do
    role
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:permissions, permissions)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  def validate_msisdn(changeset) do
    msisdn = get_change(changeset, :msisdn)

    case Ims.Helpers.validate_phone_number(msisdn) do
      true -> changeset
      false -> add_error(changeset, :msisdn, "is not a valid phone number")
    end
  end

  def validate_personal_number(changeset) do
    changeset
    |> validate_length(:personal_number, min: 6, max: 8)
    |> validate_format(:personal_number, ~r/^[0-9]+$/, message: "must be a number")
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp validate_password_confirmation(changeset) do
    password = get_change(changeset, :password)
    password_confirmation = get_change(changeset, :password_confirmation)

    if password && password_confirmation && password != password_confirmation do
      add_error(changeset, :password_confirmation, "Passwords do not match")
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Ims.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Ims.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def assign_role(user, role) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:roles, [role])
    |> Repo.update()
  end

  def default_leave_balances do
    leave_types = Repo.all(LeaveType)

    Enum.map(leave_types, fn leave_type ->
      %LeaveBalance{leave_type_id: leave_type.id, remaining_days: 0}
    end)
  end

  def search(queryable \\ __MODULE__, filters) do
    IO.inspect(filters, label: "Filters for search")
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :first_name ->
            from(u in accum_query, where: ilike(u.first_name, ^"%#{v}%"))

          k == :last_name ->
            from(u in accum_query, where: ilike(u.last_name, ^"%#{v}%"))

          k == :personl_number ->
            from(u in accum_query, where: ilike(u.personl_number, ^"%#{v}%"))

          k == :query ->
            IO.inspect(v, label: "Query for search")
            from(u in accum_query, where: ilike(u.first_name, ^"%#{v}%") or
              ilike(u.last_name, ^"%#{v}%") or
              ilike(u.personal_number, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)

    from(q in query, preload: [:department, :job_group, :roles])
  end

  def is_staff_member_query() do
    from u in __MODULE__,
      where: is_nil(u.hashed_password) and u.password_reset_required == true
  end
end
