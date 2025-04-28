defmodule ImsWeb.InternAttacheeLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Interns
  alias Ims.Interns.InternAttachee

  @durations [
    {"1 month", "1 month"},
    {"3 months", "3 months"},
    {"6 months", "6 months"},
    {"1 year", "1 year"}
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage intern_attachee records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="intern_attachee-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:full_name]} type="text" label="Full name" />
          <.input field={@form[:email]} type="text" label="Email" />

          <.input field={@form[:phone]} type="text" label="Phone" />
          <.input field={@form[:id_number]} type="text" label="ID number" />

          <.input field={@form[:school]} type="text" label="School" />
          <.input
            field={@form[:program]}
            type="select"
            options={[
              {"Internship", "Internship"},
              {"Attachment", "Attachment"},
              {"Industrial Attachment", "Industrial Attachment"}
            ]}
            label="Program"
          />

          <.input
            field={@form[:department_id]}
            type="select"
            label="Department"
            options={@departments}
            prompt="Select department"
          />

          <.input field={@form[:start_date]} type="date" label="Start date" />

          <.input field={@form[:duration]} type="select" label="Duration" options={@durations} />
          <.input field={@form[:end_date]} type="date" label="End date" disabled />

          <.input field={@form[:next_of_kin_name]} type="text" label="Next of kin name" />
          <.input field={@form[:next_of_kin_phone]} type="text" label="Next of kin phone" />
        </div>

        <:actions>
          <div class="flex justify-end mt-4">
            <.button phx-disable-with="Saving...">Save Intern attachee</.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end


  @impl true
  def update(%{intern_attachee: intern_attachee} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:durations, @durations)
     |> assign(:departments, Ims.Accounts.list_departments() |> Enum.map(&{&1.name, &1.id}))
     |> assign_new(:form, fn ->
       to_form(Interns.change_intern_attachee(intern_attachee))
     end)}
  end

  @impl true
  def handle_event("validate", %{"intern_attachee" => intern_attachee_params}, socket) do
    intern_attachee_params = maybe_calculate_end_date(intern_attachee_params)

    changeset =
      Interns.change_intern_attachee(
        socket.assigns.intern_attachee,
        intern_attachee_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"intern_attachee" => intern_attachee_params}, socket) do
    intern_attachee_params = maybe_calculate_end_date(intern_attachee_params)

    save_intern_attachee(socket, socket.assigns.action, intern_attachee_params)
  end

  defp save_intern_attachee(socket, :edit, intern_attachee_params) do
    case Interns.update_intern_attachee(socket.assigns.intern_attachee, intern_attachee_params) do
      {:ok, intern_attachee} ->
        notify_parent({:saved, intern_attachee})

        {:noreply,
         socket
         |> put_flash(:info, "Intern attachee updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_intern_attachee(socket, :new, intern_attachee_params) do
    case Interns.create_intern_attachee(intern_attachee_params) do
      {:ok, intern_attachee} ->
        notify_parent({:saved, intern_attachee})

        {:noreply,
         socket
         |> put_flash(:info, "Intern attachee created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_calculate_end_date(params) do
    with %{"start_date" => start_date, "duration" => duration} <- params,
         {:ok, start_date} <- Date.from_iso8601(start_date),
         {:ok, months} <- duration_to_months(duration) do
      # Approximate month
      end_date = Date.add(start_date, months * 30)
      Map.put(params, "end_date", Date.to_iso8601(end_date))
    else
      _ -> params
    end
  end

  defp duration_to_months("1 month"), do: {:ok, 1}
  defp duration_to_months("3 months"), do: {:ok, 3}
  defp duration_to_months("6 months"), do: {:ok, 6}
  defp duration_to_months("1 year"), do: {:ok, 12}
  defp duration_to_months(_), do: :error

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
