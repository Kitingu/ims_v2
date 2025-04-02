defmodule ImsWeb.UserRegistrationLive do
  alias Ims.Accounts
  use ImsWeb, :live_view

  alias Ims.Accounts.{User, Departments, JobGroup}
  alias Ims.Repo

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl p-8 sm:p-10 bg-white rounded-2xl shadow-lg border border-gray-100">
  <.header class="text-center mb-8">
    <h2 class="text-3xl font-bold text-gray-800">
      <%= if @edit_mode, do: "Edit Account", else: "Register for an Account..." %>
    </h2>
  </.header>

  <.simple_form
    for={@form}
    id="registration_form"
    phx-submit="save"
    phx-change="validate"
    phx-trigger-action={@trigger_submit || false}
    action={~p"/users/log_in?_action=registered"}
    method="post"
    class="space-y-8"
  >
    <.error :if={@check_errors} class="text-red-600 text-sm font-medium bg-red-50 p-4 rounded-md border border-red-200">
      Oops, something went wrong! Please check the errors below.
    </.error>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Left Column -->
      <div class="space-y-5">
        <.input
          field={@form[:first_name]}
          type="text"
          label="First name"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          field={@form[:last_name]}
          type="text"
          label="Last name"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          :if={!@edit_mode}
          field={@form[:password]}
          type="password"
          label="Password"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          :if={!@edit_mode}
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm Password"
          required
          class="input-field"
          label_class="input-label"
        />
      </div>

      <!-- Right Column -->
      <div class="space-y-5">
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          field={@form[:personal_number]}
          type="text"
          label="Personal Number"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          field={@form[:msisdn]}
          type="text"
          label="Phone Number"
          required
          class="input-field"
          label_class="input-label"
        />

        <.input
          field={@form[:designation]}
          type="text"
          label="Designation"
          required
          class="input-field"
          label_class="input-label"
        />
      </div>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
      <.input
        field={@form[:department_id]}
        type="select"
        label="Department"
        options={@departments}
        required
        class="input-field"
        label_class="input-label"
      />

      <.input
        field={@form[:job_group_id]}
        type="select"
        label="Job Group"
        options={@job_groups}
        required
        class="input-field"
        label_class="input-label"
      />
    </div>

    <:actions>
      <.button
        phx-disable-with={@disable_text}
        class="w-full py-3 px-4 text-white bg-brand rounded-md hover:bg-brand-dark focus:outline-none focus:ring-2 focus:ring-brand transition-all font-semibold"
      >
        {@button_text}
      </.button>
    </:actions>
  </.simple_form>
</div>


    """
  end

  def mount(_params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    user = Repo.get(User, user_id) || %User{}
    changeset = Accounts.change_user_registration(user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:form, changeset)
     |> assign(:trigger_submit, false)
     |> assign(:edit_mode, true)}
  end

  def mount(params, _session, socket) do
    # Ensure `user` and `form` initialization
    user =
      case params do
        %{"user_id" => user_id} -> Repo.get!(User, user_id)
        _ -> %User{}
      end

    changeset = Accounts.change_user_registration(user)
    departments = Repo.all(Departments) |> Enum.map(&{&1.name, &1.id})

    job_groups =
      Accounts.list_job_groups() |> Enum.map(&{&1.name, &1.id}) |> IO.inspect(label: "Job Groups")

    socket =
      socket
      |> assign(
        edit_mode: Map.has_key?(params, "user_id"),
        button_text:
          if(Map.has_key?(params, "user_id"), do: "Save Changes", else: "Create an Account"),
        disable_text:
          if(Map.has_key?(params, "user_id"), do: "Saving...", else: "Creating account..."),
        trigger_submit: false,
        check_errors: false,
        departments: departments,
        job_groups: job_groups
      )
      |> assign_form(changeset)

    {:ok, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case socket.assigns.edit_mode do
      true ->
        # Editing an existing user
        case Accounts.update_user(socket.assigns.form.data, user_params) do
          {:ok, _user} ->
            {:noreply, assign(socket, trigger_submit: true)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      false ->
        # Creating a new user
        case Accounts.register_user(user_params) do
          {:ok, user} ->
            {:ok, _} =
              Accounts.deliver_user_confirmation_instructions(
                user,
                &url(~p"/users/confirm/#{&1}")
              )

            {:noreply, assign(socket, trigger_submit: true)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(socket.assigns.form.data, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
