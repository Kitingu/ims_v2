defmodule ImsWeb.AssetTypeLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset_type records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset_type-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Asset type</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset_type: asset_type} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_asset_type(asset_type))
     end)}
  end

  @impl true
  def handle_event("validate", %{"asset_type" => asset_type_params}, socket) do
    changeset = Inventory.change_asset_type(socket.assigns.asset_type, asset_type_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset_type" => asset_type_params}, socket) do
    save_asset_type(socket, socket.assigns.action, asset_type_params)
  end

  defp save_asset_type(socket, :edit, asset_type_params) do
    case Inventory.update_asset_type(socket.assigns.asset_type, asset_type_params) do
      {:ok, asset_type} ->
        notify_parent({:saved, asset_type})

        {:noreply,
         socket
         |> put_flash(:info, "Asset type updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset_type(socket, :new, asset_type_params) do
    case Inventory.create_asset_type(asset_type_params) do
      {:ok, asset_type} ->
        notify_parent({:saved, asset_type})

        {:noreply,
         socket
         |> put_flash(:info, "Asset type created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
