defmodule ImsWeb.TrainingApplicationLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Trainings
  alias Ims.Accounts
  alias Ims.Demographics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage training_application records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="training_application-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <h2 class="text-xl font-semibold text-gray-700 mb-6">Training Application Form</h2>

        <div class="relative" phx-update="ignore" id="select_user_container">
          <.input
            field={@form[:user_id]}
            type="select"
            id="select_user_id"
            phx-hook="select2JS"
            options={@user_options}
            data-phx-event="select_changed"
            data-placeholder="Select User"
            class="w-full hidden"
          />
        </div>

        <div class="relative" phx-update="ignore" id="select_ethinity_container">
          <.input
            field={@form[:ethnicity_id]}
            type="select"
            id="select_ethinity_id"
            phx-hook="select2JS"
            options={@ethnicities}
            data-phx-event="select_changed"
            data-placeholder="Select ethinity"
            class="w-full hidden"
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <.input field={@form[:course_approved]} type="text" label="Course Approved" />
          <.input field={@form[:institution]} type="text" label="Institution" />
          <.input field={@form[:program_title]} type="text" label="Program Title" />
          <.input
            field={@form[:financial_year]}
            type="select"
            options={financial_year_options()}
            label="Financial Year"
          />

          <.input
            field={@form[:quarter]}
            type="select"
            options={["Q1", "Q2", "Q3", "Q4"]}
            label="Quarter"
          />

          <.input
            field={@form[:period_of_study]}
            type="select"
            options={study_period_options()}
            label="Period of Study"
          />
          <.input field={@form[:costs]} type="number" label="Costs (KSH)" step="any" />
          <.input field={@form[:authority_reference]} type="text" label="Authority Reference" />
          <.input field={@form[:memo_reference]} type="text" label="Memo Reference" />
          <div class="flex items-center gap-4 mt-4">
            <.input
              field={@form[:disability]}
              type="checkbox"
              label="Disability"
              phx-change="toggle_disability"
              phx-target={@myself}
              checked={@form[:disability].value == true || @form[:disability].value == "true"}
            />
          </div>

          <%= if @show_disability_details do %>
            <.input field={@form[:disability_details]} type="text" label="Disability Details" />
          <% end %>
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-md transition duration-300 mt-6"
          >
            Save Training Application
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{training_application: training_application} = assigns, socket) do
    # Initialize show_disability_details based on the form's disability value
    show_disability_details =
      case training_application.disability do
        nil -> false
        value -> value in [true, "true"]
      end

    csrf_token = Plug.CSRFProtection.get_csrf_token()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:csrf_token, csrf_token)
     |> assign(:user_options, Enum.map(Accounts.list_users(), &{&1.first_name, &1.id}))
     |> assign(ethnicities: Enum.map(Demographics.list_ethnicities(), &{&1.name, &1.id}))
     |> assign(:show_disability_details, show_disability_details)
     |> assign(:selected_ethnicity, nil)
     |> assign_new(:form, fn ->
       to_form(Trainings.change_training_application(training_application))
     end)}
  end

  @impl true
  def handle_event("validate", %{"training_application" => training_application_params}, socket) do
    # Ensure period_of_study is converted before validation

    IO.inspect(training_application_params, label: "Training application params")

    training_application_params =
      Map.update(training_application_params, "period_of_study", nil, &convert_period_to_days/1)

    changeset =
      Trainings.change_training_application(
        socket.assigns.training_application,
        training_application_params
      )
      |> Map.put(:action, :validate)
      |> IO.inspect(label: "Changeset")

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event(
        "select_changed",
        %{
          "select_id" => "select_user_id",
          "training_application[user_id]" => user_id
        },
        socket
      ) do
    IO.inspect(user_id, label: "Selected user_id")

    # Merge into form params
    updated_params =
      socket.assigns.form.params
      |> Map.put("user_id", user_id)

    # Re-validate the changeset using updated params
    changeset =
      socket.assigns.training_application
      |> Trainings.change_training_application(updated_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_user, user_id)}
  end

  @impl true
  def handle_event(
        "select_changed",
        %{
          "select_id" => "select_ethinity_id",
          "training_application[ethnicity_id]" => ethnicity_id
        },
        socket
      ) do
    IO.inspect(ethnicity_id, label: "Selected ethnicity_id")

    updated_params =
      socket.assigns.form.params
      |> Map.put("ethnicity_id", ethnicity_id)

    changeset =
      socket.assigns.training_application
      |> Trainings.change_training_application(updated_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_ethnicity, ethnicity_id)}
  end

  @impl true
  def handle_event(
        "toggle_disability",
        %{"training_application" => %{"disability" => disability}},
        socket
      ) do
    # Convert the disability value to a boolean
    disability_boolean = disability in ["true", true]

    # Update the form state with the new disability value
    updated_form =
      socket.assigns.form
      |> Map.update!(:params, fn params -> Map.put(params, "disability", disability_boolean) end)

    # Update the socket with the new form state and show_disability_details
    {:noreply,
     socket
     |> assign(:show_disability_details, disability_boolean)
     |> assign(:form, updated_form)}
  end

  @impl true
  def handle_event("save", %{"training_application" => training_application_params}, socket) do
    training_application_params =
      Map.update(training_application_params, "period_of_study", nil, &convert_period_to_days/1)

    save_training_application(socket, socket.assigns.action, training_application_params)
  end

  defp save_training_application(socket, :edit, training_application_params) do
    case Trainings.update_training_application(
           socket.assigns.training_application,
           training_application_params
         ) do
      {:ok, training_application} ->
        notify_parent({:saved, training_application})

        {:noreply,
         socket
         |> put_flash(:info, "Training application updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_training_application(socket, :new, training_application_params) do
    case Trainings.create_training_application(training_application_params) do
      {:ok, training_application} ->
        notify_parent({:saved, training_application})

        {:noreply,
         socket
         |> put_flash(:info, "Training application created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp convert_period_to_days(value) when is_binary(value) do
    case String.split(value, "_") do
      [duration, "days"] -> String.to_integer(duration)
      [duration, "weeks"] -> String.to_integer(duration) * 7
      [duration, "months"] -> String.to_integer(duration) * 30
      [duration, "years"] -> String.to_integer(duration) * 365
      # Default fallback if format is incorrect
      _ -> 0
    end
  end

  defp study_period_options do
    days = Enum.map(1..6, &{"#{&1} Days", "#{&1}_days"})
    weeks = Enum.map(1..4, &{"#{&1} Week#{if &1 > 1, do: "s", else: ""}", "#{&1}_weeks"})
    months = Enum.map(1..12, &{"#{&1} Month#{if &1 > 1, do: "s", else: ""}", "#{&1}_months"})
    years = Enum.map(1..5, &{"#{&1} Year#{if &1 > 1, do: "s", else: ""}", "#{&1}_years"})

    days ++ weeks ++ months ++ years
  end

  defp financial_year_options do
    current_year = Date.utc_today().year

    # Start with previous year - current year
    previous_year = current_year - 1
    options = [{"#{previous_year}-#{current_year}", "#{previous_year}-#{current_year}"}]

    # Add current year - next year, then next 4 years
    options ++
      Enum.map(0..4, fn i ->
        start_year = current_year + i
        end_year = start_year + 1
        {"#{start_year}-#{end_year}", "#{start_year}-#{end_year}"}
      end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
