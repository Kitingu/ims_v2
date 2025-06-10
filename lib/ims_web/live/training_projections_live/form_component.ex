defmodule ImsWeb.TrainingProjectionsLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Trainings
  alias Ims.Demographics

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 px-4 py-10">
      <div class="max-w-2xl mx-auto bg-white shadow-xl rounded-2xl overflow-hidden">
        <!-- Header -->
        <div class="bg-indigo-600 p-8 text-white flex flex-col items-center text-center gap-4">
          <img src="/images/logo.png" alt="Logo" class="h-28 w-auto  shadow-lg" />

          <div>
            <h1 class="text-3xl font-bold">ODP Training Projections Form</h1>
            <p class="text-base text-indigo-200 mt-1">
              FY 2025/26 TRAINING PROJECTIONS - Fill the form only once.
            </p>
            <p class="text-sm mt-1 font-medium">
              EXECUTIVE OFFICE OF THE DEPUTY PRESIDENT
            </p>
          </div>
        </div>

    <!-- Form -->
        <div class="p-6">
          <.simple_form
            for={@form}
            id="training_projections-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <.input
              field={@form[:full_name]}
              type="text"
              label="Indicate your name in full"
              class="w-full"
            />
            <.input
              field={@form[:gender]}
              type="select"
              label="Gender"
              class="w-full"
              options={[
                {"Male", "Male"},
                {"Female", "Female"}
              ]}
            />

            <.input
              field={@form[:personal_number]}
              type="text"
              label="Personal Number"
              class="w-full"
            />
            <.input
              field={@form[:designation]}
              type="text"
              label="Designation / Job Title"
              class="w-full"
            />
            <.input field={@form[:department]} type="text" label="Department" class="w-full" />
            <.input
              field={@form[:job_group]}
              type="select"
              label="Job Group"
              class="w-full"
              options={[
                {"C", "C"},
                {"D", "D"},
                {"E", "E"},
                {"F", "F"},
                {"G", "G"},
                {"H", "H"},
                {"J", "J"},
                {"K", "K"},
                {"L", "L"},
                {"N", "N"},
                {"P", "P"},
                {"R", "R"},
                {"S", "S"},
                {"T", "T"},
                {"U", "U"},
                {"V", "V"}
              ]}
            />

            <div class="relative" phx-update="ignore" id="select_ethinity_container">
              <.input
                field={@form[:ethnicity_id]}
                type="select"
                id="select_ethinity_id"
                phx-hook="select2JS"
                options={@ethnicities}
                data-phx-event="select_changed"
                data-placeholder="Select ethinity"
                label="Select your Ethnicity"
                class="w-full hidden"
              />
            </div>

            <div class="w-full">
              <label class="block text-sm font-bold text-gray-700 mb-1">
                Disability <span class="text-red-500">*</span>
              </label>
              <div class="flex gap-6">
                <label class="inline-flex items-center">
                  <input
                    type="radio"
                    name="training_projections[disability]"
                    value="true"
                    required
                    phx-change="toggle_disability"
                    phx-target={@myself}
                    checked={@form[:disability].value in [true, "true"]}
                    class="form-radio text-indigo-600"
                  />
                  <span class="ml-2">Yes</span>
                </label>
                <label class="inline-flex items-center">
                  <input
                    type="radio"
                    name="training_projections[disability]"
                    value="false"
                    required
                    phx-change="toggle_disability"
                    phx-target={@myself}
                    checked={@form[:disability].value in [false, "false", nil]}
                    class="form-radio text-indigo-600"
                  />
                  <span class="ml-2">No</span>
                </label>
              </div>
            </div>

            <%= if @show_disability_details do %>
              <.input field={@form[:disability_details]} type="text" label="Disability Details" />
            <% end %>

            <.input
              field={@form[:qualification]}
              type="text"
              label="Indicate your highest Academic/Professional Qualification"
              class="w-full"
            />

            <.input
              field={@form[:program_title]}
              type="text"
              label="What program would you like to be trained in the financial year 2025/26? (Do not indicate a bachelor's degree)"
              class="w-full"
            />
            <.input
              field={@form[:institution]}
              type="text"
              label="Training Venue / Institution"
              class="w-full"
            />

            <.input
              field={@form[:financial_year]}
              type="hidden"
              readonly
              value="2025/26"
              class="w-full"
            />

            <%!-- <.input
              field={@form[:quarter]}
              type="select"
              options={["Q1", "Q2", "Q3", "Q4"]}
              label="Quarter"
            /> --%>
            <%!-- <div class="flex items-center gap-4 mt-4">
              <.input
                field={@form[:disability]}
                type="checkbox"
                label="Disability"
                phx-change="toggle_disability"
                phx-target={@myself}
                checked={@form[:disability].value == true || @form[:disability].value == "true"}
              />
            </div> --%>

            <.input
              field={@form[:period_input]}
              type="select"
              label="Approximate duration of the program? Select as appropriate"
              options={study_period_options()}
            />

            <.input
              field={@form[:costs]}
              type="number"
              label="Approximate Cost (KES)"
              step="any"
              class="w-full"
            />
            <.input field={@form[:status]} type="hidden" class="w-full" />

            <:actions>
              <div class="pt-4 flex justify-end">
                <.button
                  phx-disable-with="Saving..."
                  class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-6 py-2 rounded shadow"
                >
                  Save Projection
                </.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{training_projections: training_projections} = assigns, socket) do
    show_disability_details =
      case training_projections do
        nil -> false
        _ -> training_projections.disability in [true, "true"]
      end

    training_projections =
      Map.put(
        training_projections,
        :period_input,
        period_input_from_days(training_projections.period_input)
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(ethnicities: Enum.map(Demographics.list_ethnicities(), &{&1.name, &1.id}))
     |> assign(:show_disability_details, show_disability_details)
     |> assign(:selected_ethnicity, nil)
     |> assign_new(:form, fn ->
       to_form(Trainings.change_training_projections(training_projections))
     end)}
  end

  @impl true
  def handle_event("validate", %{"training_projections" => params}, socket) do
    changeset = Trainings.change_training_projections(socket.assigns.training_projections, params)
    IO.inspect(changeset, label: "Changeset in validate event")

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"training_projections" => params}, socket) do
    IO.inspect(params, label: "Training Projections Params")

    save_training_projections(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_event(
        "select_changed",
        %{
          "select_id" => "select_ethinity_id",
          "training_projections[ethnicity_id]" => ethnicity_id
        },
        socket
      ) do
    IO.inspect(ethnicity_id, label: "Selected ethnicity_id")

    updated_params =
      socket.assigns.form.params
      |> Map.put("ethnicity_id", ethnicity_id)

    changeset =
      socket.assigns.training_projections
      |> Trainings.change_training_projections(updated_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_ethnicity, ethnicity_id)}
  end

  @impl true
  def handle_event(
        "toggle_disability",
        %{"training_projections" => %{"disability" => disability}},
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

  defp save_training_projections(socket, :edit, params) do
    case Trainings.update_training_projections(socket.assigns.training_projections, params) do
      {:ok, training_projections} ->
        notify_parent({:saved, training_projections})

        {:noreply,
         socket
         |> put_flash(:info, "Training projection updated successfully")
         |> redirect(to: "/training_projections/success")}

      #  |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_training_projections(socket, :new, params) do
    case Trainings.create_training_projections(params) do
      {:ok, training_projections} ->
        notify_parent({:saved, training_projections})

        {:noreply,
         socket
         |> put_flash(:info, "Training projection created successfully")
         #  |> push_patch(to: socket.assigns.patch)
         |> redirect(to: "/training_projections/success")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp study_period_options do
    days = Enum.map(1..6, &{"#{&1} Day#{if &1 > 1, do: "s", else: ""}", "#{&1}_days"})
    # days = Enum.map(1..6, &{"#{&1} Days", "#{&1}_days"})
    weeks = Enum.map(1..3, &{"#{&1} Week#{if &1 > 1, do: "s", else: ""}", "#{&1}_weeks"})
    months = Enum.map(1..11, &{"#{&1} Month#{if &1 > 1, do: "s", else: ""}", "#{&1}_months"})
    years = Enum.map(1..5, &{"#{&1} Year#{if &1 > 1, do: "s", else: ""}", "#{&1}_years"})

    days ++ weeks ++ months ++ years
  end

  defp period_input_from_days(nil), do: nil

  defp period_input_from_days(days) when is_integer(days) do
    cond do
      rem(days, 365) == 0 -> "#{div(days, 365)}_years"
      rem(days, 30) == 0 -> "#{div(days, 30)}_months"
      rem(days, 7) == 0 -> "#{div(days, 7)}_weeks"
      true -> "#{days}_days"
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
