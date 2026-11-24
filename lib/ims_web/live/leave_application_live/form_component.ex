defmodule ImsWeb.LeaveApplicationLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Leave

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-4">
      <div class="bg-white shadow-md rounded-lg p-6 max-w-3xl mx-auto">
        <.simple_form
          for={@form}
          id="leave_application-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="space-y-4"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:leave_type_id]}
              type="select"
              label="Leave Type"
              options={filtered_leave_types(@leave_types, @current_user.gender)}
              class="w-full"
            />

            <%= if @is_admin do %>
              <.input
                field={@form[:user_id]}
                type="select"
                label="Select User"
                options={@users}
                class="w-full"
              />
              <% else %>
              <.input field={@form[:user_id]} type="hidden" value={@current_user.id} class="w-full" />
            <% end %>
          </div>
          <div class="text-sm text-gray-600 mt-2">
            Leave Balance: <span class="font-bold">{@leave_balance || "N/A"} days</span>
          </div>

          <p class="text-sm text-gray-600">Enter the actual leave dates. You can select dates in the past.</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:start_date]}
              type="date"
              label="Start Date"
              class="datepicker w-full"
            />
            <.input field={@form[:end_date]} type="date" label="End Date" class="datepicker w-full" />
          </div>

          <.input
            field={@form[:days_requested]}
            type="number"
            label="Days Requested"
            class="w-full"
            readonly
          />
          <.input
            field={@form[:resumption_date]}
            type="date"
            label="Resumption Date"
            class="w-full"
            readonly
          />

          <div class="mb-4">
            <label for={@uploads.proof_document.ref} class="block text-sm font-medium text-gray-700">
              Proof Document (PDF/Image)
            </label>
            <div class="mt-2 flex items-center justify-center w-full border-2 border-dashed border-gray-300 rounded-lg bg-gray-50 p-4 hover:border-blue-500" phx-drop-target={@uploads.proof_document.ref}>
              <.live_file_input upload={@uploads.proof_document} class="sr-only" />
              <label for={@uploads.proof_document.ref} class="cursor-pointer flex flex-col items-center">
                <svg
                  class="w-12 h-12 text-gray-400 group-hover:text-blue-500"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M12 16v4m0 0H8m4 0h4M16 12h2a2 2 0 002-2V8a2 2 0 00-2-2h-2a2 2 0 00-2-2h-4a2 2 0 00-2 2H8a2 2 0 00-2 2v2a2 2 0 002 2h2"
                  >
                  </path>
                </svg>
                <span class="mt-2 text-sm text-gray-500">Click to upload or drag & drop</span>
                <span class="text-xs text-gray-400">PDF, JPG, PNG, GIF (Max 5MB)</span>
              </label>
            </div>
          </div>

          <div :for={entry <- @uploads.proof_document.entries} class="text-sm">
            {entry.client_name}
            <p :for={error <- upload_errors(@uploads.proof_document, entry)} class="text-red-700">
              {case error do
                :too_large -> "File exceeds 5 MB."
                :not_accepted -> "Select a PDF or supported image."
              end}
            </p>
          </div>

          <.input field={@form[:comment]} type="text" label="Comment" class="w-full" />

          <div class="flex justify-end mt-4">
            <.button
              phx-disable-with="Saving..."
              class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg"
            >
              Save Leave Application
            </.button>
          </div>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(
        %{leave_application: leave_application, current_user: current_user} = assigns,
        socket
      ) do
    # Fetch Leave Types and Users
    leave_types = Leave.list_leave_types()
    users = Ims.Accounts.list_users()

    # Determine the selected Leave Type and User
    leave_type_id =
      leave_application.leave_type_id || Enum.find_value(leave_types, & &1.id)

    user_id = leave_application.user_id || current_user.id

    # Fetch Leave Balance
    leave_balance =
      if leave_type_id do
        Leave.get_leave_balance(user_id, leave_type_id)
      else
        nil
      end

    # Check Admin Privileges
    is_admin = check_admin(current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:leave_types, Enum.map(leave_types, &{&1.name, &1.id}))
     |> assign(
       :users,
       Enum.map(users, fn u ->
         name =
           [u.first_name, u.last_name]
           |> Enum.reject(&is_nil/1)
           |> Enum.join(" ")
           |> String.trim()

         {"#{name} - #{to_string(u.personal_number)}", u.id}
       end)
     )
     |> assign(:leave_balance, leave_balance)
     |> assign(:is_admin, is_admin)
     |> allow_upload(:proof_document,
       accept: ~w(.pdf .jpg .jpeg .png .gif),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> assign_new(:form, fn ->
       changeset =
         Leave.change_leave_application(leave_application, %{
           user_id: user_id,
           leave_type_id: leave_type_id
         })
       to_form(changeset)
     end)}
  end

  @impl true
  def handle_event("validate", %{"leave_application" => leave_application_params}, socket) do
    params = application_params(socket, leave_application_params)
    changeset = Leave.change_leave_application(socket.assigns.leave_application, params)
    leave_type_id = Ecto.Changeset.get_field(changeset, :leave_type_id)
    user_id = Ecto.Changeset.get_field(changeset, :user_id)
    leave_balance = if user_id && leave_type_id, do: Leave.get_leave_balance(user_id, leave_type_id)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))
     |> assign(:leave_balance, leave_balance)}
  end

  def handle_event("save", %{"leave_application" => leave_application_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :proof_document, fn %{path: path}, _entry ->
        dest = Path.join(["priv/static/uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, "/uploads/" <> Path.basename(dest)}
      end)

    updated_params =
      case uploaded_files do
        [] -> Map.delete(leave_application_params, "proof_document")
        files -> Map.put(leave_application_params, "proof_document", Enum.join(files, ","))
      end
      |> then(&application_params(socket, &1))

    save_leave_application(socket, socket.assigns.action, updated_params)
  end

  defp save_leave_application(socket, :edit, leave_application_params) do
    case Leave.update_leave_application(
           socket.assigns.leave_application,
           leave_application_params
         ) do
      {:ok, leave_application} ->
        notify_parent({:saved, leave_application})

        {:noreply,
         socket
         |> put_flash(:info, "Leave application updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, reason} when is_binary(reason) ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp save_leave_application(socket, :new, leave_application_params) do
    case Leave.create_leave_application(leave_application_params) do
      {:ok, leave_application} ->
        notify_parent({:saved, leave_application})

        {:noreply,
         socket
         |> put_flash(:info, "Leave application created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp application_params(socket, params) do
    params = Map.drop(params, ["status", "days_requested", "resumption_date"])

    if socket.assigns.is_admin do
      params
    else
      Map.put(params, "user_id", socket.assigns.current_user.id)
    end
  end

  defp check_admin(user) do
    Canada.Can.can?(user, ["manage"], "hr_dashboard")
  end

  defp filtered_leave_types(leave_types, gender) do
    Enum.reject(leave_types, fn
      {"Maternity Leave", _} -> gender == "Male"
      {"Paternity Leave", _} -> gender == "Female"
      _ -> false
    end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
