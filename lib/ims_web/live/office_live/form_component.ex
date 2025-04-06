defmodule ImsWeb.OfficeLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage office records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="office-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <%!-- <.input field={@form[:building]} type="text" label="Building" /> --%>
        <.input
          field={@form[:location_id]}
          type="select"
          label="Location"
          options={@locations}
          prompt="Select a location"
          />
        <.input field={@form[:floor]} type="text" label="Floor" />
        <.input field={@form[:door_name]} type="text" label="Door name" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Office</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{office: office} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:locations, Inventory.list_locations() |> Enum.map(&{&1.name, &1.id}))
     |> assign_new(:form, fn ->
       to_form(Inventory.change_office(office))
     end)}
  end

  @impl true
  def handle_event("validate", %{"office" => office_params}, socket) do
    changeset = Inventory.change_office(socket.assigns.office, office_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"office" => office_params}, socket) do
    save_office(socket, socket.assigns.action, office_params)
  end

  defp save_office(socket, :edit, office_params) do
    case Inventory.update_office(socket.assigns.office, office_params) do
      {:ok, office} ->
        notify_parent({:saved, office})

        {:noreply,
         socket
         |> put_flash(:info, "Office updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_office(socket, :new, office_params) do
    case Inventory.create_office(office_params) do
      {:ok, office} ->
        notify_parent({:saved, office})

        {:noreply,
         socket
         |> put_flash(:info, "Office created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
