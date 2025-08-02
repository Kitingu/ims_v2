defmodule ImsWeb.FileLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Files

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage file records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="file-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:folio_number]} type="text" label="Folio number" />
        <.input field={@form[:subject_matter]} type="text" label="Subject matter" />
        <.input field={@form[:ref_no]} type="text" label="Ref no" />
        <.input field={@form[:current_office_id]} type="select" label="Current office" options={@offices} />

        <:actions>
          <.button phx-disable-with="Saving...">Save File</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{file: file} = assigns, socket) do

    offices =
      Ims.Inventory.Office
      |> Ims.Repo.all()
      |> Enum.map(&{&1.name, &1.id})
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:offices, offices)
     |> assign_new(:form, fn ->
       to_form(Files.change_file(file))
     end)}
  end

  @impl true
  def handle_event("validate", %{"file" => file_params}, socket) do
    changeset = Files.change_file(socket.assigns.file, file_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"file" => file_params}, socket) do
    save_file(socket, socket.assigns.action, file_params)
  end

  defp save_file(socket, :edit, file_params) do
    case Files.update_file(socket.assigns.file, file_params) do
      {:ok, file} ->
        notify_parent({:saved, file})

        {:noreply,
         socket
         |> put_flash(:info, "File updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_file(socket, :new, file_params) do
    current_user = socket.assigns.current_user
    file_params = Map.put(file_params, "user_id", current_user.id)
    case Files.create_file(file_params) do
      {:ok, file} ->
        notify_parent({:saved, file})

        {:noreply,
         socket
         |> put_flash(:info, "File created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
