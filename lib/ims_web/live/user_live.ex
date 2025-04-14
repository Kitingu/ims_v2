defmodule ImsWeb.UserLive do
  use ImsWeb, :live_view

  alias Ims.Accounts
  @paginator_opts [order_by: [desc: :inserted_at], page_size: 10]

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:users, Accounts.list_users() |> Ims.Repo.paginate(@paginator_opts))
      |> assign(:roles, Accounts.Role.all())
      |> assign(:message, nil)
      |> assign(:show_modal, false)
      |> assign(:modal_user_id, nil)
      |> assign(:selected_role_id, nil)
      |> assign(:job_groups, Accounts.list_job_groups())
      |> assign(:current_user, socket.assigns.current_user)
      # Handle embedded live view actions
      |> assign(:live_action, nil)
      |> assign(:live_params, nil)

    {:ok, socket}

    # if connected?(socket), do: send(self(), :load_users)
    # roles = Accounts.Role.all()
    # {:ok, assign(socket, users: [], roles: roles, message: nil)}
  end

  def handle_info(:load_users, socket) do
    users = Accounts.list_users() |> Ims.Repo.paginate(@paginator_opts)
    {:noreply, assign(socket, users: users)}
  end

  def handle_event("show_modal", %{"user-id" => user_id}, socket) do
    {:noreply, assign(socket, show_modal: true, modal_user_id: String.to_integer(user_id))}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, live_action: nil, live_params: nil)}
  end

  # def handle_event("close_modal", _, socket) do
  #   {:noreply, assign(socket, show_modal: false, modal_user_id: nil)}
  # end

  def handle_event("clear_flash", _params, socket) do
    {:noreply, assign(socket, :message, nil)}
  end

  def handle_event("assign_role", params, socket) do
    case Accounts.update_user_role(params["user_id"], params["role"]) do
      {:ok, _user} ->
        send(self(), :load_users)

        {:noreply,
         assign(socket,
           message: "Role updated successfully!",
           show_modal: false,
           modal_user_id: nil
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, message: "Failed to update role: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event("assign_role" <> id, _params, socket) do
    {:noreply, assign(socket, show_modal: true, modal_user_id: String.to_integer(id))}
  end

  def handle_event("edit" <> id, _params, socket) do
    user = Accounts.get_user!(String.to_integer(id))

    socket =
      socket
      |> assign(:live_action, "UserRegistrationLive")
      |> assign(:live_params, %{"user_id" => user.id})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800 mb-6">User Management</h1>

        <.link href={~p"/admin/users/register"}>
          <.button class="bg-blue-600 text-white px-5 py-2 rounded-lg shadow-md hover:bg-blue-700">
            Add User
          </.button>
        </.link>
      </div>

      <%= if @message do %>
        <div class="mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded flex justify-between items-center">
          <p>{@message}</p>
          <button
            phx-click="clear_flash"
            class="ml-4 text-green-700 hover:text-green-900 font-bold rounded"
          >
            ✕
          </button>
        </div>
      <% end %>

      <.table
        id="users"
        rows={@users}
        current_user={@current_user}
        resource="users"
        actions={["edit", "assign_role"]}
      >
        <:col :let={user} label="ID">
          {user.id}
        </:col>

        <:col :let={user} label="Staff Number">
          {user.personal_number}
        </:col>
        <:col :let={user} label=" Name">
          {user.first_name} {user.last_name}
        </:col>

        <:col :let={user} label="Phone">
          {user.msisdn}
        </:col>

        <:col :let={user} label="Designation">
          {user.designation}
        </:col>

        <:col :let={user} label="Department">
          {user.department.name}
        </:col>

        <:col :let={user} label="Role">
          <%= if Enum.empty?(user.roles) do %>
            No Role
          <% else %>
            {Enum.map(user.roles, & &1.name) |> Enum.join(", ")}
          <% end %>
        </:col>
      </.table>

      <%= if @live_action == "UserRegistrationLive" do %>
        <div
          class="fixed inset-0 z-50 bg-black bg-opacity-40 flex items-center justify-center"
          phx-click="close_modal"
        >
          <div
            phx-click-away="close_modal"
            phx-window-keydown="close_modal"
            phx-key="escape"
            class="relative bg-white w-full max-w-3xl rounded-lg shadow-xl overflow-y-auto max-h-[90vh] p-6"
            phx-capture-click
          >
            {live_render(@socket, ImsWeb.UserRegistrationLive,
              id: "user-registration-#{@live_params["user_id"] || "new"}",
              session: %{"user_id" => @live_params["user_id"]},
              container: {:div, class: "w-full"}
            )}
          </div>
        </div>
      <% end %>

      <%= if @show_modal do %>
        <div class="fixed inset-0 bg-gray-800 bg-opacity-50 flex justify-center items-center z-50">
          <div class="bg-white rounded-lg shadow-lg p-6 w-96">
            <h2 class="text-lg font-bold mb-4">Assign Role</h2>
            <form phx-submit="assign_role">
              <input type="hidden" name="user_id" value={@modal_user_id} />

              <div class="mb-4">
                <label for="role" class="block text-sm font-medium text-gray-700">Role</label>
                <select name="role" id="role" class="w-full px-3 py-2 border rounded">
                  <%= for role <- @roles do %>
                    <option value={role.id}>
                      {role.name}
                    </option>
                  <% end %>
                </select>
              </div>

              <div class="flex justify-end">
                <button
                  type="button"
                  phx-click="close_modal"
                  class="mr-2 px-3 py-1 bg-gray-300 text-gray-700 rounded"
                >
                  Cancel
                </button>
                <button type="submit" class="px-3 py-1 bg-blue-500 text-white rounded">
                  Update
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # def render(assigns) do
  #   ~H"""
  #   <div class="container mx-auto mt-10">
  #     <h1 class="text-xl font-semibold mb-4">User Management</h1>
  #     <%= if @message do %>
  #       <p class="text-green-500 mb-4"><%= @message %></p>
  #     <% end %>
  #     <table class="table-auto w-full border-collapse border border-gray-800">
  #       <thead>
  #         <tr class="bg-gray-800 text-white">
  #           <th class="border border-gray-600 px-4 py-2">Name</th>
  #           <th class="border border-gray-600 px-4 py-2">Email</th>
  #           <th class="border border-gray-600 px-4 py-2">Role</th>
  #           <th class="border border-gray-600 px-4 py-2">Actions</th>
  #         </tr>
  #       </thead>
  #       <tbody>
  #         <%= for user <- @users do %>
  #           <tr class="hover:bg-gray-200">
  #             <td class="border border-gray-600 px-4 py-2"><%= user.first_name %></td>
  #             <td class="border border-gray-600 px-4 py-2"><%= user.email %></td>
  #             <td class="border border-gray-600 px-4 py-2">
  #               <%= if Enum.empty?(user.roles) do %>
  #                 No Role
  #               <% else %>
  #                 <%= Enum.map(user.roles, & &1.name) |> Enum.join(", ") %>
  #               <% end %>
  #             </td>
  #             <td class="border border-gray-600 px-4 py-2">
  #               <form phx-submit="assign_role">
  #                 <input type="hidden" name="user_id" value={user.id} />
  #                 <select name="role" class="px-3 py-1">
  #                   <%= for role <- @roles do %>
  #                     <option value={role.id} selected={Enum.any?(user.roles, &(&1.id == role.id))}>
  #                       <%= role.name %>
  #                     </option>
  #                   <% end %>
  #                 </select>
  #                 <button type="submit" class="ml-2 px-3 py-1 bg-blue-500 text-white rounded">
  #                   Update
  #                 </button>
  #               </form>
  #             </td>
  #           </tr>
  #         <% end %>
  #       </tbody>
  #     </table>
  #   </div>
  #   """
  # end
end
