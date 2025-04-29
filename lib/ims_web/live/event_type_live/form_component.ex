defmodule ImsWeb.EventTypeLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Welfare

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage event_type records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="event_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:amount]} type="number" label="Amount" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Event type</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{event_type: event_type} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Welfare.change_event_type(event_type))
     end)}
  end

  @impl true
  def handle_event("validate", %{"event_type" => event_type_params}, socket) do
    changeset = Welfare.change_event_type(socket.assigns.event_type, event_type_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"event_type" => event_type_params}, socket) do
    save_event_type(socket, socket.assigns.action, event_type_params)
  end

  defp save_event_type(socket, :edit, event_type_params) do
    case Welfare.update_event_type(socket.assigns.event_type, event_type_params) do
      {:ok, event_type} ->
        notify_parent({:saved, event_type})

        {:noreply,
         socket
         |> put_flash(:info, "Event type updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_event_type(socket, :new, event_type_params) do
    case Welfare.create_event_type(event_type_params) do
      {:ok, event_type} ->
        notify_parent({:saved, event_type})

        {:noreply,
         socket
         |> put_flash(:info, "Event type created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
