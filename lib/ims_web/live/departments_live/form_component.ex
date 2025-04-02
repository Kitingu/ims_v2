defmodule ImsWeb.DepartmentsLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage departments records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="departments-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Departments</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{departments: departments} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_departments(departments))
     end)}
  end

  @impl true
  def handle_event("validate", %{"departments" => departments_params}, socket) do
    changeset = Accounts.change_departments(socket.assigns.departments, departments_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"departments" => departments_params}, socket) do
    save_departments(socket, socket.assigns.action, departments_params)
  end

  defp save_departments(socket, :edit, departments_params) do
    case Accounts.update_departments(socket.assigns.departments, departments_params) do
      {:ok, departments} ->
        notify_parent({:saved, departments})

        {:noreply,
         socket
         |> put_flash(:info, "Departments updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_departments(socket, :new, departments_params) do
    case Accounts.create_departments(departments_params) do
      {:ok, departments} ->
        notify_parent({:saved, departments})

        {:noreply,
         socket
         |> put_flash(:info, "Departments created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
