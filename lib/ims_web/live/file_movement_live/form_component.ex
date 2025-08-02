defmodule ImsWeb.FileMovementLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Files

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage file_movement records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="file_movement-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:remarks]} type="text" label="Remarks" />
        <:actions>
          <.button phx-disable-with="Saving...">Save File movement</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{file_movement: file_movement} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Files.change_file_movement(file_movement))
     end)}
  end

  @impl true
  def handle_event("validate", %{"file_movement" => file_movement_params}, socket) do
    changeset = Files.change_file_movement(socket.assigns.file_movement, file_movement_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"file_movement" => file_movement_params}, socket) do
    save_file_movement(socket, socket.assigns.action, file_movement_params)
  end

  defp save_file_movement(socket, :edit, file_movement_params) do
    case Files.update_file_movement(socket.assigns.file_movement, file_movement_params) do
      {:ok, file_movement} ->
        notify_parent({:saved, file_movement})

        {:noreply,
         socket
         |> put_flash(:info, "File movement updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_file_movement(socket, :new, file_movement_params) do
    case Files.create_file_movement(file_movement_params) do
      {:ok, file_movement} ->
        notify_parent({:saved, file_movement})

        {:noreply,
         socket
         |> put_flash(:info, "File movement created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
