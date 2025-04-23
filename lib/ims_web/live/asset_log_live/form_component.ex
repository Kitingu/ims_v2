defmodule ImsWeb.AssetLogLive.FormComponent do
  use ImsWeb, :live_component

  alias Ims.Inventory
  require Logger

  # 10MB limit
  @max_file_size 10_000_000
  @allowed_image_types ~w(.jpg .jpeg .png)
  @allowed_document_types ~w(.jpg .jpeg .png .pdf)

  @impl true
  def mount(socket) do
    IO.inspect(socket, label: "Mount socket")

    socket =
      socket
      |> allow_upload(:police_abstract_photo,
        accept: @allowed_document_types,
        max_entries: 1,
        max_file_size: @max_file_size
      )
      |> allow_upload(:photo_evidence,
        accept: @allowed_image_types,
        max_entries: 1,
        max_file_size: @max_file_size
      )
      |> allow_upload(:evidence,
        accept: @allowed_image_types,
        max_entries: 1,
        max_file_size: @max_file_size
      )

    {:ok, socket}
  end

  def update(
        %{action: _action, patch: _patch, request: request} = assigns,
        socket
      ) do
    IO.inspect(assigns, label: "Fallback Update Assigns")

    users = Ims.Accounts.list_users() |> Enum.map(&{&1.first_name, &1.id})
    offices = Ims.Inventory.list_offices() |> Enum.map(&{&1.name, &1.id})
    asset_log = %Ims.Inventory.AssetLog{}
    category_id = request.category_id
    assets = Inventory.get_available_assets(category_id) |> Enum.map(&{&1.asset_name.name, &1.id})

    {:ok,
     socket
     |> assign_new(:asset, fn -> nil end)
     |> assign(assigns)
     |> assign(:asset_log, asset_log)
     |> assign(:users, users)
     |> assign(:offices, offices)
     |> assign(:assets, assets)
     |> assign(:assign_to, "user")
     |> assign(:revoke_type, nil)
     |> assign_new(:form, fn ->
       to_form(Ims.Inventory.change_asset_log(asset_log))
     end)}
  end

  @impl true
  def update(%{asset: asset, action: action, return_to: return_to} = assigns, socket) do
    users = Ims.Accounts.list_users() |> Enum.map(&{&1.first_name, &1.id})
    offices = Ims.Inventory.list_offices() |> Enum.map(&{&1.name, &1.id})
    asset_log = %Ims.Inventory.AssetLog{}

    IO.inspect(assigns, label: "Update assigns")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, "create log")
     |> assign(:action, action)
     |> assign(:users, users)
     |> assign(:asset_log, asset_log)
     |> assign(:offices, offices)
     # Add this line
     |> assign(:revoke_type, nil)
     |> assign(:current_user, assigns.current_user)
     |> assign(:assign_to, "user")
     |> assign_new(:form, fn ->
       to_form(Inventory.change_asset_log(asset_log))
     end)}
  end

  @impl true
  def update(%{asset_log: asset_log} = assigns, socket) do
    IO.inspect(assigns, label: "Update assigns")

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
      <.header>
        <%= if @asset do %>
          <h2 class="text-lg font-semibold text-gray-900">
            {@asset.asset_name.name} - {@asset.category.name}
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            {@asset.serial_number} - {@asset.tag_number}
            <%= if @asset.user do %>
              <span class="text-gray-500">Assigned to: {@asset.user.first_name}</span>
            <% else %>
              <span class="text-gray-500">Available</span>
            <% end %>
          </p>
          <p class="mt-1 text-sm text-gray-500">
            <%= if @asset.office do %>
              <span class="text-gray-500">Office: {@asset.office.name}</span>
            <% else %>
              <span class="text-gray-500">No office assigned</span>
            <% end %>
          </p>
        <% end %>
      </.header>

      <.simple_form
        for={@form}
        id="asset_log-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        onsubmit={"return confirm('Are you sure you want to #{action_value(@action)} this asset?');"}
      >
        <.input field={@form[:action]} type="hidden" value={action_value(@action)} />

        <%= if @asset do %>
          <.input field={@form[:asset_id]} type="hidden" value={@asset.id} />
        <% end %>

        <.input field={@form[:performed_by_id]} type="hidden" value={@current_user.id} />

        {render_action_specific_fields(assigns)}

        <.input field={@form[:remarks]} type="textarea" label="Remarks" required />

        <:actions>
          <.button phx-disable-with="Saving...">Save Asset Log</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp action_value(:assign_device), do: "assigned"
  defp action_value(:return_device), do: "returned"
  defp action_value(:revoke_device), do: "revoked"
  defp action_value(:decommission_device), do: "decommissioned"
  defp action_value(:mark_as_lost), do: "lost"
  defp action_value(_), do: "assigned"

  defp render_action_specific_fields(%{action: :assign_device} = assigns) do
    ~H"""
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
    <.input field={@form[:status]} type="hidden" value="active" />
    """
  end

  defp render_action_specific_fields(%{action: :mark_as_lost} = assigns) do
    ~H"""
    <.input field={@form[:abstract_number]} type="text" label="Abstract number" />
    <%= if @asset do %>
      <.input field={@form[:performed_by_id]} type="hidden" value={@asset.user_id} />
      <.input field={@form[:user_id]} type="hidden" value={@asset.user_id} || nil />
      <.input field={@form[:office_id]} type="hidden" value={@asset.office_id} || nil />
    <% end %>
    <div>
      <label for="police_abstract_photo" class="block text-sm font-medium text-gray-700">
        Police abstract photo
      </label>
      <div class="mt-1">
        <.live_file_input
          upload={@uploads.police_abstract_photo}
          class="block w-full px-3 py-2 text-gray-900 border border-gray-300 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
      </div>
      <%= for entry <- @uploads.police_abstract_photo.entries do %>
        <div class="mt-2">
          <.live_img_preview entry={entry} class="h-20" />
          <button
            type="button"
            phx-click="remove-police_abstract_photo"
            phx-value-ref={entry.ref}
            class="text-red-600 hover:text-red-800 text-sm"
          >
            Remove
          </button>
        </div>
      <% end %>
    </div>

    <div>
      <label for="evidence" class="block text-sm font-medium text-gray-700">Evidence</label>
      <div class="mt-1">
        <.live_file_input
          upload={@uploads.evidence}
          class="block w-full px-3 py-2 text-gray-900 border border-gray-300 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
      </div>
      <%= for entry <- @uploads.evidence.entries do %>
        <div class="mt-2">
          <.live_img_preview entry={entry} class="h-20" />
          <button
            type="button"
            phx-click="remove-evidence"
            phx-value-ref={entry.ref}
            class="text-red-600 hover:text-red-800 text-sm"
          >
            Remove
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_action_specific_fields(%{action: :return_device} = assigns) do
    ~H"""
    <.input field={@form[:date_returned]} type="date" label="Date returned" max={Date.utc_today()} />
    <%= if @asset do %>
      <.input field={@form[:user_id]} type="hidden" value={@asset.user_id} || nil />
      <.input field={@form[:office_id]} type="hidden" value={@asset.office_id} || nil />
    <% end %>
    <div>
      <label for="evidence" class="block text-sm font-medium text-gray-700">Evidence</label>
      <div class="mt-1">
        <.live_file_input
          upload={@uploads.evidence}
          class="block w-full px-3 py-2 text-gray-900 border border-gray-300 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
      </div>
      <%= for entry <- @uploads.evidence.entries do %>
        <div class="mt-2">
          <.live_img_preview entry={entry} class="h-20" />
          <button
            type="button"
            phx-click="remove-evidence"
            phx-value-ref={entry.ref}
            class="text-red-600 hover:text-red-800 text-sm"
          >
            Remove
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_action_specific_fields(%{action: :decommission_device} = assigns) do
    ~H"""
    <div>
      <label for="evidence" class="block text-sm font-medium text-gray-700">Evidence</label>
      <div class="mt-1">
        <.live_file_input
          upload={@uploads.evidence}
          class="block w-full px-3 py-2 text-gray-900 border border-gray-300 rounded-lg shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
      </div>
      <%= for entry <- @uploads.evidence.entries do %>
        <div class="mt-2">
          <.live_img_preview entry={entry} class="h-20" />
          <button
            type="button"
            phx-click="remove-evidence"
            phx-value-ref={entry.ref}
            class="text-red-600 hover:text-red-800 text-sm"
          >
            Remove
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_action_specific_fields(%{action: :revoke_device} = assigns) do
    ~H"""
    <.input
      field={@form[:revoke_type]}
      type="select"
      label="Revoke type"
      options={[{"Permanent", "permanent"}, {"Temporary", "temporary"}]}
      phx-change="revoke_type_changed"
      phx-target={@myself}
    />

    <%= if @revoke_type == "temporary" || @form[:revoke_type].value == "temporary" do %>
      <.input field={@form[:revoked_until]} type="date" label="Revoked until" />
    <% end %>
    """
  end

  defp render_action_specific_fields(%{action: :approve} = assigns) do
    ~H"""
    <div>
    <h3> Approving  {@request.user.first_name} {@request.user.last_name} request. </h3>
    </div>
    <.input
      field={@form[:asset_id]}
      type="select"
      label="Asset"
      options={@assets}
      phx-target={@myself}
    />
    <.input field={@form[:user_id]} type="hidden" value={@request.user_id} />
    <.input field={@form[:request_id]} type="hidden" value={@request.id} />
    """
  end

  defp render_action_specific_fields(_assigns), do: nil

  @impl true
  def handle_event("validate", %{"asset_log" => asset_log_params}, socket) do
    IO.inspect(label: "Validate Event")
    changeset =
      Inventory.change_asset_log(socket.assigns.asset_log, asset_log_params) |> IO.inspect()

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # @impl true
  # def handle_event("revoke_type_changed", %{"revoke_type" => revoke_type}, socket) do
  #   {:noreply, assign(socket, :revoke_type, revoke_type)}
  # end

  @impl true
  def handle_event(
        "revoke_type_changed",
        %{"asset_log" => %{"revoke_type" => revoke_type}},
        socket
      ) do
    {:noreply, assign(socket, :revoke_type, revoke_type)}
  end

  @impl true
  def handle_event("assign_to_changed", %{"assign_to" => assign_to}, socket) do
    {:noreply, assign(socket, :assign_to, assign_to)}
  end

  @impl true
  def handle_event("remove-police-abstract", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :police_abstract_photo, ref)}
  end

  @impl true
  def handle_event("remove-evidence", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :evidence, ref)}
  end

  @impl true
  def handle_event("save", %{"asset_log" => asset_log_params}, socket) do
    save_asset_log(socket, socket.assigns.action, asset_log_params)
  end

  defp save_asset_log(socket, action, asset_log_params) do
    asset_log_params = process_uploads(socket, action, asset_log_params)

    case apply_save_action(action, socket, asset_log_params) do
      {:ok, asset_log} ->
        notify_parent({:saved, asset_log})

        {:noreply,
         socket
         |> put_flash(:info, "Asset assigned successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{errors: [user_id: {error_message, _}]}} ->
        # Handle device limit error - close form and show message
        {:noreply,
         socket
         |> put_flash(:error, error_message)
         |> push_patch(to: socket.assigns.return_to)}

      {:error, changeset} ->
        # Handle all other validation errors - keep form open
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, "Please check the form for errors")}
    end
  end

  # defp save_asset_log(socket, action, asset_log_params) do
  #   asset_log_params =
  #     process_uploads(socket, action, asset_log_params)
  #     |> IO.inspect(label: "Processed Asset Log Params")

  #   IO.inspect(action, label: "Action")

  #   case apply_save_action(action, socket, asset_log_params) |> IO.inspect() do
  #     {:ok, asset_log} ->
  #       notify_parent({:saved, asset_log})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Asset log #{save_message(action)} successfully")
  #        |> push_patch(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{errors: [user_id: {error_message, _}]}} ->
  #       # This matches the device limit error from check_device_limit
  #       {:noreply,
  #        socket
  #        |> put_flash(:error, error_message)
  #        |> push_patch(to: socket.assigns.return_to)}

  #     {:error, changeset} ->
  #       {:noreply,
  #        socket
  #        |> assign(form: to_form(changeset))
  #        |> put_flash(:error, "Save failed. Check the form.")}
  #   end
  # end

  defp apply_save_action(:edit, socket, params) do
    Inventory.update_asset_log(socket.assigns.asset_log, params)
  end

  defp apply_save_action(_action, socket, params) do
    Inventory.create_asset_log(params)
  end

  defp save_message(:edit), do: "updated"
  defp save_message(_), do: "created"

  defp process_uploads(socket, action, params) do
    case action do
      :return_device ->
        process_evidence_upload(socket, params)

      :mark_as_lost ->
        params = process_police_abstract_upload(params, socket)
        process_evidence_upload(socket, params)

      :decommission_device ->
        process_evidence_upload(socket, params)

      _ ->
        params
    end
  end

  defp process_evidence_upload(socket, params) do
    case uploaded_entries(socket, :evidence) do
      {[entry], []} ->
        case consume_upload(socket, :evidence, entry) do
          {:ok, path} -> Map.put(params, "evidence", path)
          _ -> params
        end

      _ ->
        params
    end
  end

  defp process_police_abstract_upload(params, socket) do
    case uploaded_entries(socket, :police_abstract_photo) do
      {[entry], []} ->
        case consume_upload(socket, :police_abstract_photo, entry) do
          {:ok, path} -> Map.put(params, "police_abstract_photo", path)
          _ -> params
        end

      _ ->
        params
    end
  end

  defp consume_upload(socket, field, entry) do
    ensure_uploads_folder_exists()

    consume_uploaded_entry(socket, entry, fn %{path: temp_path} ->
      extension = Path.extname(entry.client_name)
      unique_name = "#{Ecto.UUID.generate()}#{extension}"
      dest = Path.join([:code.priv_dir(:ims), "static/uploads", unique_name])

      case File.cp(temp_path, dest) do
        :ok ->
          {:ok, "/uploads/#{unique_name}"}

        {:error, reason} ->
          Logger.error("Failed to copy #{field} upload: #{reason}")
          {:error, "Failed to save file"}
      end
    end)
  end

  defp ensure_uploads_folder_exists do
    upload_path = Path.join(:code.priv_dir(:ims), "static/uploads")

    case File.mkdir_p(upload_path) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to create uploads directory: #{reason}")
        {:error, "Failed to create upload directory"}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp now_naive do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_naive()
  end
end
