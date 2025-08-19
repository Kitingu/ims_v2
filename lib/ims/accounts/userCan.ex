defimpl Canada.Can, for: Ims.Accounts.User do
  @doc """
  Checks if a user has the required permissions for the given action and resource.
  Dynamically fetches roles and permissions since they cannot be preloaded.
  """
  alias Ims.Repo.Audited, as: Repo
  alias Ims.Accounts.Role
  alias Ims.Accounts.Permission
  import Ecto.Query

  def can?(%Ims.Accounts.User{id: user_id}, actions, resource) do
    roles = fetch_roles_with_permissions(user_id)

    Enum.any?(roles, fn role ->
      Canada.Can.can?(role, actions, resource)
    end)
  end

  def can?(_, _, _), do: false

  # Fetch roles with permissions dynamically
  defp fetch_roles_with_permissions(user_id) do
    from(
      r in Role,
      join: ur in "user_roles",
      # Use ^user_id in the correct clause
      on: ur.role_id == r.id and ur.user_id == ^user_id,
      join: p in assoc(r, :permissions),
      preload: [permissions: p]
    )
    |> Repo.all()
  end

  defimpl Canada.Can, for: Ims.Accounts.Role do
    @doc """
    Checks if a role has permissions for the given action and resource.
    """
    defguard as_strings?(actions, resource)
             when (is_list(actions) or is_binary(actions)) and is_binary(resource)

    def can?(%Role{name: role_name} = _role, _actions, _resource) when role_name in ["super_admin", "system-admin"], do: true


    def can?(%Role{permissions: []} = _role, _actions, _resource), do: false

    def can?(%Role{permissions: [_ | _]} = role, actions, resource) do
      role.permissions
      |> Enum.any?(fn permission ->
        Canada.Can.can?(permission, actions, {role, resource})
      end)
      |> Kernel.or(has_permission?(role.permissions))
    end

    defp has_permission?([_ | _] = permissions) do
      permissions
      |> Enum.any?(&(&1.name in ["admin-all-access", "system-admin"]))
    end
  end

  defimpl Canada.Can, for: Ims.Accounts.Permission do
    @doc """
    Checks if a permission grants the required access to an action and resource.
    """

    def can?(
          %Permission{name: name},
          actions,
          {role, resource}
        ) do
      permission_can?({name, role}, actions, resource)
    end

    def can?(_, _, _), do: false

    def permission_can?({permission, _role}, actions, resource)
        when is_list(actions) and is_binary(resource) do
      with [res, action] <- String.split(permission, "."),
           true <- action in actions,
           true <- res == resource do
        true
      else
        _ -> false
      end
    end
  end
end
