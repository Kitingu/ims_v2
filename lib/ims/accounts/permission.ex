defmodule Ims.Accounts.Permission do
  use Ecto.Schema
  use Ims.RepoHelpers, repo: Ims.Repo

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  #   alias Ims.SystemUserRole
  #   alias Ims.SystemUser

  alias Ims.Repo

  @type t :: %__MODULE__{name: String.t(), approval_levels: Integer.t()}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "permissions" do
    field(:name, :string)
    field(:approval_levels, :integer, default: 0)
    belongs_to(:created_by, Ims.Accounts.User)
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :approval_levels])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :uidx_permissions_name)
  end

  def new(params \\ %{}) do
    changeset(%__MODULE__{}, params)
  end

  def create(params) do
    changeset(%__MODULE__{}, params)
    |> Repo.insert()
  end

  @spec update(Ecto.Changeset.t()) :: {:ok, Permission.t()} | {:error, Ecto.Changeset.t()}
  def update(changeset) do
    Repo.insert_or_update(changeset)
  end

  @spec get_by_name!(String.t()) :: {:ok, t}
  def get_by_name!(name) do
    from(n in __MODULE__, select: n, where: n.name == ^name)
    |> Repo.one()
  end

  @spec get_all_permissions(Map.t()) :: {:ok, t}
  def get_all_permissions(permissions_list) do
    from(p in __MODULE__, select: p, where: p.id in ^permissions_list)
    |> Repo.all()
  end

  def get_basic_permissions() do
    global_perms = admin_permissions() |> Enum.map(& &1.name)

    from(
      p in __MODULE__,
      where: p.name not in ^global_perms
    )
    |> Repo.all()
  end

  def su_permissions() do
    global_perms = admin_permissions() |> Enum.map(& &1.name)

    from(p in __MODULE__, where: p.name in ^global_perms)
    |> Repo.all()
  end

  def get_permissions() do
    admin_permissions() ++ basic_permissions()
  end

  @doc """
  Permission names that apply at a global level
  """
  def admin_permissions() do
    [
      %{name: "admin-all-access"},
      %{name: "system-admin"},
      %{name: "roles.list_all"},
      %{name: "roles.edit"},
      %{name: "roles.new"},

      # Permissions
      %{name: "permissions.new"},
      %{name: "permissions.index"},
      %{name: "permissions.edit"},
      %{name: "permissions.view"},
      %{name: "permissions.list_all"},
      %{name: "users.new"},
      %{name: "users.update"},
      %{name: "users.view"},
      %{name: "users.list_all"},

      # Categories
      %{name: "asset_types.new"},
      %{name: "asset_types.index"},
      %{name: "asset_types.edit"},
      %{name: "asset_types.view"},

      # Assets
      %{name: "assets.new"},
      %{name: "assets.update"},
      %{name: "assets.view"},
      %{name: "assets.index"},
      %{name: "assets.list_all"},
      %{name: "assets.assign"},
      %{name: "assets.unassign"},
      %{name: "assets.list_lost_assets"},
      %{name: "assets.list_assigned_assets"},
      %{name: "assets.list_available_assets"},
      %{name: "assets.list_all_assets"},



      # asset actions
      %{name: "assets.mark_as_lost"},
      %{name: "assets.return"},
      %{name: "assets.decommission"},
      %{name: "assets.revoke"},
      %{name: "assets.assign"},

      # asset_names
      %{name: "asset_names.new"},
      %{name: "asset_names.index"},
      %{name: "asset_names.edit"},
      %{name: "asset_names.view"},



      # requests
      %{name: "requests.edit"},
      %{name: "requests.view"},
      %{name: "requests.list_all"},
      %{name: "requests.approve"},
      %{name: "requests.reject"},

      # leave_applications
      %{name: "leave_applications.edit"},
      %{name: "leave_applications.view"},
      %{name: "leave_applications.list_all"},
      %{name: "leave_applications.approve"},
      %{name: "leave_applications.reject"},

      # leave_types
      %{name: "leave_types.edit"},
      %{name: "leave_types.view"},
      %{name: "leave_types.new"},
      %{name: "leave_types.index"},
      %{name: "leave_types.list_all"},

      # admin
      %{name: "admin_panel.manage"},
      %{name: "hr_dashboard.manage"},
      %{name: "welfare_dashboard.manage"},
      # dash
      %{name: "dashboard.view"},

      # dashboards
      %{name: "dashboard_welfare.view"},
      %{name: "dashboard_hr.view"},
      %{name: "dashboard_ict.view"},


      # main sidebar
      %{name: "welfare.index"},

      # settingspUploadUsersWorker
      %{name: "settings.new"},
      %{name: "settings.index"},
      %{name: "settings.edit"},
      %{name: "settings.view"},

      # # training_applications
      %{name: "training_applications.new"},
      %{name: "training_applications.index"},
      %{name: "training_applications.edit"},
      %{name: "training_applications.view"},
      # # events
      %{name: "events.new"},
      %{name: "events.index"},
      %{name: "events.edit"},
      %{name: "events.view"},
      # # event_types
      %{name: "event_types.new"},
      %{name: "event_types.index"},
      %{name: "event_types.edit"},
      %{name: "event_types.view"},

      # ethnicities
      %{name: "ethnicities.new"},
      %{name: "ethnicities.index"},
      %{name: "ethnicities.edit"},
      %{name: "ethnicities.view"},

      # departments
      %{name: "departments.new"},
      %{name: "departments.index"},
      %{name: "departments.edit"},
      %{name: "departments.view"},

      # locations
      %{name: "locations.new"},
      %{name: "locations.index"},
      %{name: "locations.edit"},
      %{name: "locations.view"},

      # offices
      %{name: "offices.new"},
      %{name: "offices.index"},
      %{name: "offices.edit"},
      %{name: "offices.view"},
      # designations

      # job groups
      %{name: "job_groups.new"},
      %{name: "job_groups.index"},
      %{name: "job_groups.edit"},
      %{name: "job_groups.view"}
    ]
  end

  @doc """
  Permissions that apply at merchant role level

  Have them in the format resource.access-level, e.g user.read.
  Accepted access-levels are reead, new and full-access
  """
  def basic_permissions() do
    [
      %{name: "roles.index"},
      %{name: "roles.view"},

      # Users

      %{name: "users.index"},

      # Devices

      %{name: "devices.index"},
      %{name: "devices.mark_as_lost"},
      %{name: "devices.mark_as_found"},

      # User Assignments
      %{name: "user_assignments.new"},
      %{name: "user_assignments.index"},

      # requests
      %{name: "requests.new"},
      %{name: "requests.index"},

      # lost_assets
      %{name: "lost_assets.new"},
      %{name: "lost_assets.index"},

      # returned_assets
      %{name: "returned_assets.new"},
      %{name: "returned_assets.index"},

      # leave_applications
      %{name: "leave_applications.new"},
      %{name: "leave_applications.index"},

      # leave_types
      %{name: "leave_types.new"},
      %{name: "leave_types.index"}

      # ÷admin
      # Restrict access to all routes in this scope
      # plug ImsWeb.Plugs.EnsureAuthorizedPlug, actions: ["manage"], resource: "admin_panel"
    ]
  end

  @doc """
  Split a list of permissions into admin and basic permissions
  """
  def split_into_admin_and_basic(permissions) do
    basic_permission_names = Enum.map(basic_permissions(), & &1.name)

    {admin, basic} =
      Enum.split_with(permissions, fn perm ->
        perm.name not in basic_permission_names
      end)

    %{admin: admin, basic: basic}
  end

  def get_permissions_by_resource(resource) do
    from(p in __MODULE__, where: ilike(p.name, ^"%#{resource}%"))
    |> Repo.all()
    |> Kernel.++(su_permissions())
  end

  #   def get_users_from_resource(resource) do
  #     resource
  #     |> get_permissions_by_resource
  #     |> RolePermission.get_by_permission_ids()
  #     |> SystemUserRole.get_users_from_roles()
  #     |> SystemUser.get_by_system_user_ids()
  #   end

  def insert_permissions do
    permissions = basic_permissions() ++ admin_permissions()

    Enum.each(permissions, fn perm ->
      %__MODULE__{}
      |> changeset(perm)
      |> Repo.insert(
        on_conflict: [set: [updated_at: NaiveDateTime.utc_now()]],
        conflict_target: :name
      )
    end)
  end

  def assign_permissions_to_role(role, permissions) do
    Enum.each(permissions, fn permission ->
      case Repo.get_by(Ims.Accounts.RolePermission,
             role_id: role.id,
             permission_id: permission.id
           ) do
        nil ->
          %Ims.Accounts.RolePermission{}
          |> Ims.Accounts.RolePermission.changeset(%{
            role_id: role.id,
            permission_id: permission.id
          })
          |> Repo.insert()

        _existing ->
          :ok
      end
    end)
  end

  def assign_basic_permissions_to_role(role) do
    # Get the list of basic permission names
    permission_names = Enum.map(basic_permissions(), & &1.name)

    # Fetch the corresponding permission records from the database
    permissions =
      from(p in __MODULE__, where: p.name in ^permission_names)
      |> Repo.all()

    case permissions do
      [] ->
        {:error, "No basic permissions found in the database"}

      _ ->
        assign_permissions_to_role(role, permissions)
    end
  end
end
