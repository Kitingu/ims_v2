defmodule ImsWeb.AssetLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <%!-- add category type to filter asset names. its not a field--%>

          <.input
            field={@form[:category_id]}
            type="select"
            label="Category"
            options={@categories}
            phx-change="category_changed"
            phx-target={@myself}
          />

          <.input
            field={@form[:asset_name_id]}
            type="select"
            label="Asset name"
            options={@asset_names}
          />

          <.input field={@form[:serial_number]} type="text" label="Serial number" />
          <.input field={@form[:tag_number]} type="text" label="Tag number" />


          <.input
            field={@form[:condition]}
            type="select"
            label="Condition"
            options={@condition_options}
          />

          <.input field={@form[:original_cost]} type="number" label="Original cost" step="any" />
          <.input field={@form[:purchase_date]} type="date" label="Purchase date"  max={Date.utc_today()} />

          <.input field={@form[:warranty_expiry]} type="date" label="Warranty expiry" />
          <.input field={@form[:status]} type="hidden" value="available"/>
        </div>

        <:actions>
          <.button class="mt-4" phx-disable-with="Saving...">💾 Save Asset</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    categories = Inventory.list_categories() |> Enum.map(&{&1.name, &1.id})

    default_category_id =
      case Map.get(asset, :category_id) do
        nil ->
          case categories do
            [{_, id} | _] -> id
            _ -> nil
          end

        id ->
          id
      end

    asset_names =
      if default_category_id do
        Inventory.list_asset_names_by_category(default_category_id)
        |> Enum.map(&{&1.name, &1.id})
      else
        []
      end

    changeset = Inventory.change_asset(asset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:categories, categories)
     |> assign(:asset_names, asset_names)
     |> assign(:status_options, [
       {"Available", "available"},
       {"Assigned", "assigned"},
       {"Revoked", "revoked"},
       {"Lost", "lost"},
       {"Decommissioned", "decommissioned"}
     ])
     |> assign(:condition_options, [
       {"New", "new"},
       {"Damaged", "damaged"},
       {"Good", "good"},
       {"Worn", "worn"},
       {"Obsolete", "obsolete"}
     ])
     |> assign_new(:form, fn -> to_form(changeset) end)}
  end

  def handle_event("category_changed", %{"asset" => %{"category_id" => category_id}}, socket) do
    category_id = String.to_integer(category_id)

    # Fetch filtered asset names
    asset_names =
      Inventory.list_asset_names_by_category(category_id)
      |> Enum.map(&{&1.name, &1.id})

    # Rebuild the form with the current data
    changeset =
      Inventory.change_asset(socket.assigns.asset, %{"category_id" => category_id})

    {:noreply,
     socket
     |> assign(asset_names: asset_names)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset = Inventory.change_asset(socket.assigns.asset, asset_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    case Inventory.update_asset(socket.assigns.asset, asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :new, asset_params) do
    case Inventory.create_asset(asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
