defmodule ImsWeb.RoleLive.Index do
  use ImsWeb, :live_view

  alias Ims.Repo
  alias Ims.Accounts.Role
  alias Ims.Accounts.Permission


  @impl true
  def mount(_params, _session, socket) do
    permissions = list_permissions()

    # Group permissions by the first part of their name (before the ".")
    grouped_permissions =
      Enum.group_by(permissions, fn perm ->
        String.split(perm.name, ".") |> List.first()
      end)

    roles = Role.list_roles(page: 1) 

    {:ok,
     socket
     |> assign(:permissions, permissions)
     |> assign(:grouped_permissions, grouped_permissions)
     |> assign(:roles, roles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # defp apply_action(socket, :new, _params) do
  #   socket
  #   |> assign(:page_title, "New Role")
  #   |> assign(:role, %Role{permissions: []})
  #   |> assign(:permissions, list_permissions()) # Pass permissions
  # end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Role")
    |> assign(:permissions, list_permissions())
    |> assign(:role, %Role{permissions: []})
  end

  # defp apply_action(socket, :edit, %{"id" => id}) do
  #   role = Role |> Repo.get!(id) |> Repo.preload(:permissions)

  #   socket
  #   |> assign(:page_title, "Edit Role")
  #   |> assign(:roles, Role.list_roles([page: 1]))
  #   # Pass permissions
  #   |> assign(:permissions, list_permissions())
  #   |> assign(:role, role)

  # end

  defp apply_action(socket, :edit, %{"id" => id}) do
    role = Repo.get!(Role, id) |> Repo.preload(:permissions)
    permissions = list_permissions()
    roles = Role.list_roles([page: 1])

    socket
    |> assign(:page_title, "Edit Role")
    |> assign(:roles, roles)
    |> assign(:permissions, permissions)
    |> assign(:role, role)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Roles")
    |> assign(:roles, Role.list_roles(page: 1))
    |> assign(:current_role, nil)
  end

  @impl true
  def handle_info({ImsWeb.RoleLive.FormComponent, {:saved, _role}}, socket) do
    roles = Role.list_roles(page: 1)

    {:noreply,
     socket
     |> assign(:roles, roles)
     |> assign(:current_role, nil)
    }
  end

  @impl true
  def handle_event("edit" <> id, _, socket) do
    role = Repo.get(Role, id) |> Repo.preload(:permissions)

    {:noreply,
     assign(socket,
       page_title: "Edit Role",
       role: role,
       permissions: list_permissions(),
       live_action: :edit

     )}

  end

  @impl true
  def handle_event("delete" <> id, _, socket) do
    case Repo.get(Role, id) do
      nil ->
        {:noreply, socket |> put_flash(:error, "Role not found")}

      role ->
        case Repo.delete(role) do
          {:ok, _role} ->
            {:noreply,
             socket
             |> assign(:roles, list_roles())
             |> put_flash(:info, "Role deleted successfully")}

          {:error, _reason} ->
            {:noreply, socket |> put_flash(:error, "Failed to delete role")}
        end
    end
  end

  def handle_event("add_permissions", %{"permission_ids" => permission_ids}, socket) do
    role = socket.assigns.current_role
    Role.add_permissions(role, Enum.map(permission_ids, &String.to_integer/1))

    {:noreply,
     assign(socket,
       current_role: Role |> Repo.get!(role.id) |> Repo.preload(:permissions)
     )}
  end

  defp list_roles do
    Role |> Repo.all() |> Repo.preload(:permissions)
  end

  defp list_permissions do
    Permission.all()
  end
end

# defimpl Canada.Can, for: Hrmis.SystemUser do
#   @doc """
#   Delegate check to an Enum.any? on each of the user's roles
#   """

#   def can?(subject, action, resource) do
#     Enum.any?(subject.roles, fn role ->
#       Canada.Can.can?(role, action, resource)
#     end)
#   end
# end

# defimpl Canada.Can, for: Hrmis.Role do
#   alias Hrmis.Role

#   defguard as_strings?(actions, resource)
#            when (is_list(actions) or is_binary(actions)) and is_binary(resource)

#   def can?(%Role{permissions: []} = _role, _actions, _resource), do: false

#   def can?(%Role{permissions: [_ | _]} = role, actions, resource) do
#     role.permissions
#     |> Enum.any?(fn permission ->
#       Canada.Can.can?(permission, actions, {role, resource})
#     end)
#     |> Kernel.or(has_permission?(role.permissions))
#   end

#   # Allow system admin permission access to everything
#   defp has_permission?([_ | _] = permissions) do
#     permissions
#     |> Enum.any?(&(&1.slug in ["admin-all-access", "system-admin"]))
#   end

#   # Todo: Possibly handle access to HR and Admin contexts here
# end

# defimpl Canada.Can, for: Hrmis.Permission do
#   alias Hrmis.Permission

#   def can?(
#         %Permission{slug: slug},
#         actions,
#         {role, resource}
#       ) do
#     permission_can?({slug, role}, actions, resource)
#   end

#   # TODO Add more cans here
#   def permission_can?({permission, _role}, _actions, _resource)
#       when permission in ["admin-all-access"],
#       do: true

#   def permission_can?({permission, _role}, actions, resource)
#       when is_list(actions) and is_binary(resource) do
#     with [res, action] <- String.split(permission, "."),
#          true <- action in actions,
#          true <- res == resource do
#       true
#     else
#       _ -> false
#     end
#   end

#   # Not an employee or admin
#   def permission_can?({_permission, _role}, _actions, _resource), do: false
# end
