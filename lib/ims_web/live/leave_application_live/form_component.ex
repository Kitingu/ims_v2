defmodule ImsWeb.LeaveApplicationLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Leave
  alias Ims.Leave.LeaveApplication
  alias Ims.Repo.Audited, as: Repo

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
          <%!-- <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input
              field={@form[:leave_type_id]}
              type="select"
              label="Leave Type"
              options={@leave_types}
              class="w-full"
            />

            <%= if @is_admin do %>
              <.input
                field={@form[:user_id]}
                type="select"
                label="Select User"
                phx-change="user_change"
                options={@users}
                class="w-full"
              />
            <% end %>
          </div> --%>

          <form
            phx-change="update_user_leave_type"
            phx-target={@myself}
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
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
          </form>
          <div class="text-sm text-gray-600 mt-2">
            Leave Balance: <span class="font-bold">{@leave_balance || "N/A"} days</span>
          </div>

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
            <label for="proof_document_upload" class="block text-sm font-medium text-gray-700">
              Proof Document (PDF/Image)
            </label>
            <div class="mt-2 flex items-center justify-center w-full border-2 border-dashed border-gray-300 rounded-lg bg-gray-50 p-4 hover:border-blue-500">
              <input
                id="proof_document_upload"
                type="file"
                accept=".pdf,image/*"
                phx-hook="Phoenix.LiveFileUpload"
                phx-change="validate_file"
                class="hidden"
              />
              <label for="proof_document_upload" class="cursor-pointer flex flex-col items-center">
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

          <p class="text-gray-500 text-xs mt-1">Allowed formats: PDF, JPG, PNG, GIF</p>

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
        <%= if @uploaded_files do %>
          <p class="mt-2 text-sm text-green-600">Uploaded file: {@uploaded_files}</p>
        <% end %>
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
      leave_application.leave_type_id || leave_types |> List.first() |> then(& &1.id)

    user_id = leave_application.user_id || current_user.id

    # Check if the selected leave type is maternity leave
    is_maternity_leave = if leave_type_id, do: is_maternity_leave?(leave_type_id), else: false

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
     |> assign(:uploaded_files, nil)
     |> assign(:selected_user, user_id)
     |> assign(:selected_leave_type, leave_type_id)
     |> assign(:is_maternity_leave, is_maternity_leave)
     |> assign(:leave_balance, leave_balance)
     |> assign(:is_admin, is_admin)
     |> allow_upload(:proof_document,
       accept: ~w(.pdf .jpg .jpeg .png .gif),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> IO.inspect()
     |> assign_new(:form, fn ->
       changeset = Leave.change_leave_application(leave_application)
       to_form(changeset)
     end)}
  end

  # @impl true
  # def update(%{leave_application: leave_application} = assigns, socket) do
  #   IO.inspect(assigns, label: "🔥 Running update with assigns")
  #   leave_types = Leave.list_leave_types()
  #   options = Enum.map(leave_types, fn type -> {type.name, type.id} end)

  #   leave_type_id =
  #     leave_application.leave_type_id ||
  #       leave_types |> List.first() |> then(& &1.id)

  #   user_id = leave_application.user_id || assigns.current_user.id
  #   is_maternity_leave = if leave_type_id, do: is_maternity_leave?(leave_type_id), else: false

  #   leave_balance =
  #     if leave_type_id, do: Leave.get_leave_balance(user_id, leave_type_id), else: nil

  #   is_admin = Canada.Can.can?(assigns.current_user, ["manage"], "hr_dashboard")
  #   users = Ims.Accounts.list_users()

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign(:leave_types, options)
  #    |> assign(:uploaded_files, nil)
  #    |> assign(:selected_user, user_id)
  #    |> assign(:selected_leave_type, leave_type_id)
  #    |> assign(:is_maternity_leave, is_maternity_leave)
  #    |> assign(:leave_balance, leave_balance)
  #    |> assign(
  #      :users,
  #      Enum.map(users, fn user -> {"#{user.first_name} - #{user.personal_number}", user.id} end)
  #    )
  #    |> assign(:is_admin, is_admin)
  #    |> allow_upload(:proof_document,
  #      accept: ~w(.pdf .jpg .jpeg .png .gif),
  #      max_entries: 1,
  #      max_file_size: 5_000_000
  #    )
  #    |> assign_new(:form, fn ->
  #      changeset = Leave.change_leave_application(leave_application)
  #      to_form(changeset)
  #    end)}
  # end

  @impl true
  def handle_event("update_user_leave_type", %{"leave_application" => params}, socket) do
    user_id =
      Map.get(params, "user_id") ||
        socket.assigns.current_user.id |> to_string()

    leave_type_id =
      Map.get(params, "leave_type_id") ||
        socket.assigns.selected_leave_type |> to_string()

    is_maternity_leave =
      if leave_type_id != "",
        do: is_maternity_leave?(String.to_integer(leave_type_id)),
        else: false

    leave_balance =
      if user_id != "" and leave_type_id != "" do
        Leave.get_leave_balance(String.to_integer(user_id), String.to_integer(leave_type_id))
      else
        nil
      end

    updated =
      socket.assigns.leave_application
      |> Leave.change_leave_application(%{
        "user_id" => user_id,
        "leave_type_id" => leave_type_id
      })

    {:noreply,
     socket
     |> assign(:form, to_form(updated, action: :validate))
     |> assign(:leave_application, updated.data)
     |> assign(:leave_balance, leave_balance)
     |> assign(:selected_user, String.to_integer(user_id))
     |> assign(:selected_leave_type, String.to_integer(leave_type_id))
     |> assign(:is_maternity_leave, is_maternity_leave)}
  end

  @impl true
  def handle_event("user_change", %{"leave_application" => %{"user_id" => user_id}}, socket) do
    user_id = String.to_integer(user_id)
    leave_type_id = socket.assigns.selected_leave_type

    leave_balance = Leave.get_leave_balance(user_id, leave_type_id)

    leave_application =
      %LeaveApplication{socket.assigns.leave_application | user_id: user_id}

    {:noreply,
     socket
     |> assign(:leave_balance, leave_balance)
     |> assign(:selected_user, user_id)
     |> assign(:leave_application, leave_application)}
  end

  # @impl true
  # def handle_event("user_change", %{"leave_application" => %{"user_id" => user_id}}, socket) do
  #   # Assign the selected user and trigger update/2
  #   {:noreply,
  #    update(%{leave_application: %{socket.assigns.leave_application | user_id: user_id}}, socket)}
  # end

  @impl true
  def handle_event("validate", %{"leave_application" => leave_application_params}, socket) do
    leave_type_id = Map.get(leave_application_params, "leave_type_id")
    user_id = Map.get(leave_application_params, "user_id", socket.assigns.current_user.id)

    is_maternity_leave =
      if leave_type_id && leave_type_id != "", do: is_maternity_leave?(leave_type_id), else: false

    leave_balance =
      if leave_type_id && leave_type_id != "",
        do: Leave.get_leave_balance(user_id, leave_type_id),
        else: nil

    # Compute end date only for Maternity Leave
    updated_params =
      if is_maternity_leave do
        start_date = Map.get(leave_application_params, "start_date")

        if start_date && start_date != "" do
          end_date = compute_maternity_end_date(start_date)
          Map.put(leave_application_params, "end_date", end_date)
        else
          leave_application_params
        end
      else
        leave_application_params
      end

    changeset =
      socket.assigns.leave_application
      |> Leave.change_leave_application(updated_params)
      |> LeaveApplication.compute_days_requested()
      |> LeaveApplication.compute_resumption_date()
      |> LeaveApplication.validate_future_dates()

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))
     |> assign(:is_maternity_leave, is_maternity_leave)
     |> assign(:leave_balance, leave_balance)}
  end

  @impl true
  def handle_event("validate_file", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"leave_application" => leave_application_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :proof_document, fn %{path: path}, _entry ->
        dest = Path.join(["priv/static/uploads", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, "/uploads/" <> Path.basename(dest)}
      end)

    updated_params =
      Map.put(leave_application_params, "proof_document", Enum.join(uploaded_files, ","))

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

  # Compute the End Date for Maternity Leave (90 days from start date)
  defp is_maternity_leave?(nil), do: false

  defp is_maternity_leave?(leave_type_id) do
    case Repo.get(Ims.Leave.LeaveType, leave_type_id) do
      %Ims.Leave.LeaveType{name: "Maternity Leave"} -> true
      _ -> false
    end
  end

  # Compute the End Date for Maternity Leave (90 days from start date)
  defp compute_maternity_end_date(nil), do: nil

  defp compute_maternity_end_date(start_date) do
    case Date.from_iso8601(start_date) do
      {:ok, date} -> Date.add(date, 90) |> Date.to_string()
      _ -> nil
    end
  end

  # defp update_form_user(form, user_id) do
  #   # Get the underlying changeset from the form
  #   changeset = form.source

  #   # Update the changeset with the new user_id
  #   updated_changeset = Ecto.Changeset.change(changeset, %{user_id: user_id})

  #   # Convert the updated changeset back to a form
  #   to_form(updated_changeset)
  # end

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
