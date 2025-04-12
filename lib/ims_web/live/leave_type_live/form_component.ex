defmodule ImsWeb.LeaveTypeLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Leave

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage leave_type records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="leave_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:max_days]} type="number" label="Max days" />
        <.input field={@form[:carry_forward]} type="checkbox" label="Carry forward" />
        <.input field={@form[:requires_approval]} type="checkbox" label="Requires approval" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Leave type</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{leave_type: leave_type} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Leave.change_leave_type(leave_type))
     end)}
  end

  @impl true
  def handle_event("validate", %{"leave_type" => leave_type_params}, socket) do
    changeset = Leave.change_leave_type(socket.assigns.leave_type, leave_type_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"leave_type" => leave_type_params}, socket) do
    save_leave_type(socket, socket.assigns.action, leave_type_params)
  end

  defp save_leave_type(socket, :edit, leave_type_params) do
    case Leave.update_leave_type(socket.assigns.leave_type, leave_type_params) do
      {:ok, leave_type} ->
        notify_parent({:saved, leave_type})

        {:noreply,
         socket
         |> put_flash(:info, "Leave type updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_leave_type(socket, :new, leave_type_params) do
    case Leave.create_leave_type(leave_type_params) do
      {:ok, leave_type} ->
        notify_parent({:saved, leave_type})

        {:noreply,
         socket
         |> put_flash(:info, "Leave type created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
