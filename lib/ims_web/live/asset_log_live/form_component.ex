defmodule ImsWeb.AssetLogLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory

  @impl true
  def mount(socket) do
    socket =
      socket
      |> allow_upload(:police_abstract_photo, accept: ~w(.jpg .jpeg .png .pdf), max_entries: 1)
      |> allow_upload(:photo_evidence, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> allow_upload(:evidence, accept: ~w(.jpg .jpeg .png), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def update(%{asset: asset, action: action, return_to: return_to} = assigns, socket) do
    # You'll want to create a changeset for the asset log record (not the asset itself)
    # changeset = Ims.Inventory.change_asset_log(%Ims.Inventory.AssetLog{})
    IO.inspect("tumefika kerichooo")
    IO.inspect(action, label: "action")
    IO.inspect(asset)

    users = Ims.Accounts.list_users() |> Enum.map(&{&1.first_name, &1.id}) |> IO.inspect()
    offices = Ims.Inventory.list_offices() |> Enum.map(&{&1.name, &1.id}) |> IO.inspect()
    asset_log = %Ims.Inventory.AssetLog{}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, "create log")
     |> assign(:action, action)
     |> assign(:users, users)
     |> assign(:asset_log, asset_log)
     |> assign(:offices, offices)
     |> assign(:current_user, assigns.current_user)
     |> assign(:assign_to, "user")
     |> assign_new(:form, fn ->
       to_form(Inventory.change_asset_log(%Ims.Inventory.AssetLog{}))
     end)}
  end

  @impl true
  def update(%{asset_log: asset_log} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_asset_log(asset_log))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- <.header>
        {@title}
        <:subtitle>Use this form to manage asset log actions.</:subtitle>
      </.header> --%>

      <.simple_form
        for={@form}
        id="asset_log-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:action]}
          type="hidden"
          value={
            case @action do
              :assign_device -> "assigned"
              :return_device -> "returned"
              :revoke_device -> "revoked"
              :decommission_device -> "decommissioned"
              :lost_device -> "lost"
              _ -> "assigned"
            end
          }
        />
        <%= if @action == :assign_device do %>
          <!-- Regular select input to control assignment -->
          <div class="mb-4">
            <label for="assign_to" class="block text-sm font-medium text-gray-700">Assign to</label>
            <select
              id="assign_to"
              name="assign_to"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
              phx-change="assign_to_changed"
              phx-target={@myself}
            >
              <option value="user" selected={@assign_to == "user"}>User</option>
              <option value="office" selected={@assign_to == "office"}>Office</option>
            </select>
          </div>

          <%= if @assign_to == "user" do %>
            <.input field={@form[:user_id]} type="select" label="User" options={@users} />
          <% else %>
            <.input field={@form[:office_id]} type="select" label="Office" options={@offices} />
          <% end %>

          <.input field={@form[:assigned_at]} type="hidden" value={now_naive()} />
          <.input field={@form[:performed_at]} type="hidden" value={now_naive()} />
          <.input field={@form[:status]} type="hidden" value="active" />
          <.input field={@form[:remarks]} type="textarea" label="Remarks" required />
        <% end %>

        <.input field={@form[:asset_id]} type="hidden" value={@asset.id} />

        <.input field={@form[:performed_by_id]} type="hidden" value={@current_user.id} />

        <%= if @action == :lost do %>
          <div>
            <label class="block font-semibold">Evidence (e.g., return photo)</label>
            <.live_file_input upload={@uploads.evidence} />
          </div>

          <div>
            <label class="block font-semibold">Other Photo Evidence</label>
            <.live_file_input upload={@uploads.photo_evidence} />
          </div>
        <% end %>

    <!-- Assign To: user or office -->

        <%= if @form[:action].value == "lost" do %>
          <.input field={@form[:abstract_number]} type="text" label="Abstract number" />
          <div>
            <label class="block font-semibold">Police Abstract Photo</label>
            <.live_file_input upload={@uploads.police_abstract_photo} />
          </div>
        <% end %>

        <%= if @form[:action].value == "revoked" do %>
          <.input field={@form[:revoke_type]} type="text" label="Revoke type" />
          <.input field={@form[:revoked_until]} type="date" label="Revoked until" />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Asset Log</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"asset_log" => asset_log_params}, socket) do
    changeset =
      Inventory.change_asset_log(socket.assigns.asset_log, asset_log_params)
      |> IO.inspect(label: "changeset")

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("assign_to_changed", %{"assign_to" => assign_to}, socket) do
    {:noreply, assign(socket, :assign_to, assign_to)}
  end

  @impl true
  def handle_event("save", %{"asset_log" => asset_log_params}, socket) do
    uploads = socket.assigns.uploads

    police_path =
      case uploads.police_abstract_photo.entries do
        [entry | _] -> consume_upload(socket, :police_abstract_photo, entry, "abstract")
        _ -> nil
      end

    photo_path =
      case uploads.photo_evidence.entries do
        [entry | _] -> consume_upload(socket, :photo_evidence, entry, "evidence")
        _ -> nil
      end

    evidence_path =
      case uploads.evidence.entries do
        [entry | _] -> consume_upload(socket, :evidence, entry, "return")
        _ -> nil
      end

    asset_log_params =
      asset_log_params
      |> Map.put("police_abstract_photo", police_path)
      |> Map.put("photo_evidence", photo_path)
      |> Map.put("evidence", evidence_path)

    save_asset_log(socket, socket.assigns.action, asset_log_params)
  end

  defp save_asset_log(socket, :edit, asset_log_params) do
    case Inventory.update_asset_log(socket.assigns.asset_log, asset_log_params) do
      {:ok, asset_log} ->
        notify_parent({:saved, asset_log})

        {:noreply,
         socket
         |> put_flash(:info, "Asset log updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket, form: to_form(changeset))
         |> put_flash(:error, "Update failed. Check the form.")}
    end
  end

  defp save_asset_log(socket, :assign_device, asset_log_params) do
    case Inventory.create_asset_log(asset_log_params) do
      {:ok, asset_log} ->
        notify_parent({:saved, asset_log})

        {:noreply,
         socket
         |> put_flash(:info, "Asset log created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket, form: to_form(changeset))
         |> put_flash(:error, "Save failed. Check the form.")}
    end
  end

  defp save_asset_log(socket, :new, asset_log_params) do
    case Inventory.create_asset_log(asset_log_params) do
      {:ok, asset_log} ->
        notify_parent({:saved, asset_log})

        {:noreply,
         socket
         |> put_flash(:info, "Asset log created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket, form: to_form(changeset))
         |> put_flash(:error, "Save failed. Check the form.")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp now_naive do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
  end

  defp consume_upload(socket, upload_key, entry, prefix) do
    Phoenix.LiveView.consume_uploaded_entry(socket, upload_key, entry, fn %{path: path} ->
      File.mkdir_p!("priv/static/uploads")

      dest = Path.join("priv/static/uploads", "#{prefix}_#{entry.client_name}")
      File.cp!(path, dest)
      {:ok, "/uploads/#{prefix}_#{entry.client_name}"}
    end)
  end
end
