defmodule ImsWeb.AssetNameLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset_name records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset_name-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:category_id]}
          type="select"
          label="Category"
          options={@categories}
          prompt="Select a category"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Asset name</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset_name: asset_name} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:categories, Inventory.list_categories() |> Enum.map(&{&1.name, &1.id}))
     |> assign_new(:form, fn ->
       to_form(Inventory.change_asset_name(asset_name))
     end)}
  end

  @impl true
  def handle_event("validate", %{"asset_name" => asset_name_params}, socket) do
    changeset = Inventory.change_asset_name(socket.assigns.asset_name, asset_name_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset_name" => asset_name_params}, socket) do
    save_asset_name(socket, socket.assigns.action, asset_name_params)
  end

  defp save_asset_name(socket, :edit, asset_name_params) do
    case Inventory.update_asset_name(socket.assigns.asset_name, asset_name_params) do
      {:ok, asset_name} ->
        notify_parent({:saved, asset_name})

        {:noreply,
         socket
         |> put_flash(:info, "Asset name updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset_name(socket, :new, asset_name_params) do
    case Inventory.create_asset_name(asset_name_params) do
      {:ok, asset_name} ->
        notify_parent({:saved, asset_name})

        {:noreply,
         socket
         |> put_flash(:info, "Asset name created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
