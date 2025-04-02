defmodule ImsWeb.RoleLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Accounts.Role

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto bg-gray-50 p-6 rounded-lg shadow-md">
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage role records and assign permissions.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="role-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <!-- Name Field -->
        <.input field={@form[:name]} type="text" label="Name" class="w-full" />
        <!-- Description Field -->
        <.input field={@form[:description]} type="text" label="Description" class="w-full" />
        <!-- Permissions Section -->
        <div>
          <label class="block text-lg font-semibold text-gray-700 mb-2">Permissions</label>
          <div class="space-y-4">
            <%= for {module, permissions} <- @grouped_permissions do %>
              <!-- Collapsible Group -->
              <div x-data="{ open: false }" class="bg-white rounded-lg shadow">
                <!-- Group Header -->
                <div
                  @click="open = !open"
                  class="cursor-pointer p-4 bg-blue-100 rounded-t-lg flex justify-between items-center"
                >
                  <h4 class="text-lg font-bold text-blue-600"><%= module %></h4>
                  <svg
                    x-bind:class="{ 'transform rotate-180': open }"
                    class="h-5 w-5 text-blue-600 transition-transform"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19 9l-7 7-7-7"
                    />
                  </svg>
                </div>
                <!-- Permissions -->
                <div
                  x-show="open"
                  class="p-4 border-t border-blue-200"
                  x-transition:enter="transition ease-out duration-300"
                  x-transition:enter-start="opacity-0 transform -translate-y-2"
                  x-transition:enter-end="opacity-100 transform translate-y-0"
                  x-transition:leave="transition ease-in duration-200"
                  x-transition:leave-start="opacity-100 transform translate-y-0"
                  x-transition:leave-end="opacity-0 transform -translate-y-2"
                >
                  <div class="grid grid-cols-2 gap-4">
                    <%= for permission <- permissions do %>
                      <div class="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={"permission_#{module}_#{permission.id}"}
                          name="role[permission_ids][]"
                          value={permission.id}
                          checked={Enum.member?(@selected_permission_ids, permission.id)}
                          class="h-5 w-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                        />
                        <label for={"permission_#{module}_#{permission.id}"} class="text-gray-800">
                          <%= permission.name %>
                        </label>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="bg-blue-600 text-white px-4 py-2 rounded shadow hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Save Role
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # @impl true
  # def update(%{role: role} = assigns, socket) do
  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_new(:form, fn ->
  #      to_form(Role.change_role(role))
  #    end)}
  # end

  @impl true
  def update(%{role: role, permissions: permissions} = assigns, socket) do
    selected_permission_ids = Enum.map(role.permissions, & &1.id)

    {:ok,
     socket
     # Assign all incoming data
     |> assign(assigns)
     |> assign(:permissions, permissions)
     |> assign(:selected_permission_ids, selected_permission_ids)
     |> assign_new(:form, fn ->
       to_form(Role.change_role(role))
     end)}
  end

  # Add a catch-all clause for cases where permissions are not explicitly passed:
  def update(%{role: _role} = assigns, socket) do
    permissions = assigns[:permissions] || []

    update(Map.put(assigns, :permissions, permissions), socket)
  end

  @impl true
  def handle_event("validate", %{"role" => role_params}, socket) do
    changeset = Role.change_role(socket.assigns.role, role_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"role" => role_params}, socket) do
    save_role(socket, socket.assigns.action, role_params)
  end

  defp save_role(socket, :new, role_params) do
    permission_ids =
      Map.get(role_params, "permission_ids", [])
      |> Enum.map(&String.to_integer/1)

    case Role.create_with_permissions(role_params, permission_ids) do
      {:ok, {:ok, role}} ->
        notify_parent({:saved, role})

        {:noreply,
         socket
         |> put_flash(:info, "Role created successfully")
         |> redirect(to: "/admin/roles")}

      {:error, {:error, changeset}} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_role(socket, :edit, role_params) do
    permission_ids =
      Map.get(role_params, "permission_ids", [])
      |> Enum.map(&String.to_integer/1)

    case Role.update_with_permissions(socket.assigns.role, role_params, permission_ids) do
      {:ok, role} ->
        notify_parent({:saved, role})

        {:noreply,
         socket
         |> put_flash(:info, "Role updated successfully")
         |> redirect(to: "/admin/roles")
      }

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
