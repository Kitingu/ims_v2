defmodule ImsWeb.LeaveApplicationLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Leave

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage leave_application records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="leave_application-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:days_requested]} type="number" label="Days requested" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:comment]} type="text" label="Comment" />
        <.input field={@form[:start_date]} type="date" label="Start date" />
        <.input field={@form[:end_date]} type="date" label="End date" />
        <.input field={@form[:resumption_date]} type="date" label="Resumption date" />
        <.input field={@form[:proof_document]} type="text" label="Proof document" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Leave application</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{leave_application: leave_application} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Leave.change_leave_application(leave_application))
     end)}
  end

  @impl true
  def handle_event("validate", %{"leave_application" => leave_application_params}, socket) do
    changeset = Leave.change_leave_application(socket.assigns.leave_application, leave_application_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"leave_application" => leave_application_params}, socket) do
    save_leave_application(socket, socket.assigns.action, leave_application_params)
  end

  defp save_leave_application(socket, :edit, leave_application_params) do
    case Leave.update_leave_application(socket.assigns.leave_application, leave_application_params) do
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

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
