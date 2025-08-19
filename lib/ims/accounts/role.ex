defmodule Ims.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  use Ims.RepoHelpers, repo: Ims.Repo

  alias Ims.Repo.Audited, as: Repo
  alias Ims.Accounts.Permission

  alias Ims.Accounts.{User, UserRole, Permission}

  schema "roles" do
    field :name, :string
    field :description, :string
    belongs_to :created_by, User

    # Association with Users
    many_to_many :users, User, join_through: UserRole

    # Many-to-many association with Permissions through a join table
    many_to_many :permissions, Permission,
      join_through: "role_permissions",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc """
  A role changeset for registration.
  """
  def registration_changeset(role, attrs, opts \\ []) do
    role
    |> cast(attrs, [:name, :description, :created_by_id])
    |> validate_name(opts)
  end

  defp validate_name(changeset, opts) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 160)
    |> maybe_validate_unique_name(opts)
  end

  defp maybe_validate_unique_name(changeset, opts) do
    if opts[:validate_name] != false do
      validate_unique(changeset, :name)
    else
      changeset
    end
  end

  def validate_unique(changeset, field) do
    unique_constraint(changeset, [field], name: "unique_#{field}")
  end

  def create(attrs) do
    Repo.transaction(fn ->
      with {:ok, role} <- Repo.insert(registration_changeset(%__MODULE__{}, attrs)),
           :ok <- Permission.assign_basic_permissions_to_role(role) do
        {:ok, role}
      else
        {:error, changeset} ->
          Repo.rollback(changeset)

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  ## Permissions Management

  # Add permissions to a role
  def add_permissions(role, permission_ids) do
    role
    |> Repo.preload(:permissions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:permissions, load_permissions(permission_ids))
    |> Repo.update()
  end

  defp load_permissions(permission_ids) do
    from(p in Permission, where: p.id in ^permission_ids) |> Repo.all()
  end

  # Remove permissions from a role
  def remove_permissions(role, permission_ids) do
    role
    |> Repo.preload(:permissions)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(
      :permissions,
      filter_permissions(role.permissions, permission_ids)
    )
    |> Repo.update()
  end

  defp filter_permissions(current_permissions, remove_ids) do
    Enum.filter(current_permissions, fn perm -> perm.id not in remove_ids end)
  end

  # Check if the role has a specific permission for a given action and resource
  def has_permission?(role, action, resource) do
    query =
      from p in Permission,
        join: rp in "role_permissions",
        on: rp.permission_id == p.id,
        where: rp.role_id == ^role.id and p.action == ^action and p.resource == ^resource,
        select: p.id

    Repo.exists?(query)
  end

  # List all permissions assigned to a role
  def list_permissions(role) do
    role
    |> Repo.preload(:permissions)
    |> Map.get(:permissions)
  end

  # def change_setting(%Setting{} = setting, attrs \\ %{}) do
  #   Setting.changeset(setting, attrs)
  # end

  def change_role(%__MODULE__{} = role, attrs \\ %{}) do
    registration_changeset(role, attrs)
  end

  def update(%__MODULE__{} = role, attrs) do
    role
    |> change_role(attrs)
    |> Repo.update()
  end

  # def update_with_permissions(%__MODULE__{} = role, attrs, permission_ids) do
  #   role
  #   |> change_role(attrs)
  #   |> add_permissions(permission_ids)
  # end

  def update_with_permissions(%__MODULE__{} = role, attrs, permission_ids) do
    # Define the list of permitted fields for changes
    permitted_fields = [:name, :description]

    # Cast the string-keyed attrs to atom keys
    changeset =
      role
      |> Ecto.Changeset.cast(attrs, permitted_fields)
      |> Ecto.Changeset.put_assoc(
        :permissions,
        Repo.all(from p in Permission, where: p.id in ^permission_ids)
      )

    Repo.update(changeset)
  end

  # def create_with_permissions(attrs, permission_ids) do
  #   %__MODULE__{}
  #   |> registration_changeset(attrs)
  #   |> Ecto.Changeset.put_assoc(:permissions, Repo.all(from p in Permission, where: p.id in ^permission_ids))
  #   |> Repo.insert()
  # end
  # def create_with_permissions(attrs, permission_ids) do
  #   changeset = registration_changeset(%__MODULE__{}, attrs)

  #   Repo.transaction(fn ->
  #     case Repo.insert(changeset) do
  #       {:ok, role} ->
  #         permissions = Repo.all(from p in Permission, where: p.id in ^permission_ids)
  #         role
  #         |> Ecto.Changeset.change()
  #         |> Ecto.Changeset.put_assoc(:permissions, permissions)
  #         |> Repo.update()

  #       {:error, changeset} ->
  #         Repo.rollback(changeset)
  #     end
  #   end)
  # end

  def create_with_permissions(attrs, permission_ids) do
    changeset = registration_changeset(%__MODULE__{}, attrs)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, role} ->
          # Preload permissions for the role
          role = Repo.preload(role, :permissions)

          permissions = Repo.all(from p in Permission, where: p.id in ^permission_ids)

          role
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:permissions, permissions)
          |> Repo.update()

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def list_roles(opts) do
    Repo.all(__MODULE__)
    |> Repo.preload(:permissions)
    |> Repo.paginate(opts)
  end

  def get_role!(id) do
    Repo.get!(__MODULE__, id)
  end
end

# <input
# type="checkbox"
# id={"permission_#{permission.id}"}
# name="role[permission_ids][]"
# value={permission.id}
# checked={Enum.member?(@selected_permission_ids, permission.id)}
# class="h-5 w-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
# />
