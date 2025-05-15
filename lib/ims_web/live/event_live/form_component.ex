defmodule ImsWeb.EventLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Welfare

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage event records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:event_type_id]} type="select" label="Event type" options={@event_types} />
        <div class="relative" phx-update="ignore" id="select_user_container">
          <.input
            label="Welfare Member affected"
            field={@form[:user_id]}
            type="select"
            id="select_user_id"
            phx-hook="select2JS"
            options={@users}
            data-phx-event="select_changed"
            data-placeholder="Select User"
            class="w-full hidden"
          />
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Event</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{event: event} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:users, Ims.Accounts.list_users() |> Enum.map(&{&1.first_name, &1.id}))
     |> assign(:event_types, Ims.Welfare.list_event_types() |> Enum.map(&{&1.name, &1.id}))
     |> assign_new(:form, fn ->
       to_form(Welfare.change_event(event))
     end)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Welfare.change_event(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event(
        "select_changed",
        %{
          "select_id" => "select_user_id",
          "event[user_id]" => user_id
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
      socket.assigns.event
      |> Welfare.change_event(updated_params)
      # socket.assigns.training_application
      # |> Trainings.change_training_application(updated_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:selected_user, user_id)}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.action, event_params)
  end

  defp save_event(socket, :edit, event_params) do
    case Welfare.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_event(socket, :new, event_params) do
    case Welfare.create_event(event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
