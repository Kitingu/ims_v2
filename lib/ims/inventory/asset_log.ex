defmodule Ims.Inventory.AssetLog do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "asset_logs" do
    field :status, :string, default: "pending"

    field :action, Ecto.Enum,
      values: [
        :assigned,
        :returned,
        :revoked,
        :lost,
        :decommissioned
      ]

    field :remarks, :string
    field :performed_at, :utc_datetime
    field :assigned_at, :utc_datetime
    field :date_returned, :date
    field :evidence, :string
    field :abstract_number, :string
    field :police_abstract_photo, :string
    field :photo_evidence, :string
    field :revoke_type, :string
    field :revoked_until, :date
    belongs_to :asset, Ims.Inventory.Asset
    belongs_to :user, Ims.Accounts.User
    belongs_to :approved_by, Ims.Accounts.User
    belongs_to :performed_by, Ims.Accounts.User
    belongs_to :office, Ims.Inventory.Office


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset_log, attrs) do
    asset_log
    |> cast(attrs, [
      :action,
      :remarks,
      :status,
      :performed_at,
      :assigned_at,
      :date_returned,
      :evidence,
      :abstract_number,
      :police_abstract_photo,
      :photo_evidence,
      :revoke_type,
      :revoked_until,
      :asset_id,
      :user_id,
      :approved_by_id,
      :performed_by_id
    ])
    |> validate_required([
      :action,
      :performed_by_id,
      :asset_id,
    ])
  end

  def search(queryable \\ __MODULE__, filters) do

    IO.inspect(filters, label: "filters")
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        IO.inspect({k, v}, label: "filter")
        cond do
          v in ["", nil] ->
            accum_query

          k == :action ->
            IO.inspect(v, label: "action")
            from(a in accum_query, where: a.action == ^v)

          k == :status ->
            from(a in accum_query, where: a.status == ^v)

          k == :remarks ->
            from(a in accum_query, where: ilike(a.remarks, ^"%#{v}%"))

          k == :performed_at ->
            from(a in accum_query, where: a.performed_at == ^v)

          k == :assigned_at ->
            from(a in accum_query, where: a.assigned_at == ^v)

          k == :date_returned ->
            from(a in accum_query, where: a.date_returned == ^v)

          k == :evidence ->
            from(a in accum_query, where: ilike(a.evidence, ^"%#{v}%"))

          k == :abstract_number ->
            from(a in accum_query, where: ilike(a.abstract_number, ^"%#{v}%"))

          k == :police_abstract_photo ->
            from(a in accum_query, where: ilike(a.police_abstract_photo, ^"%#{v}%"))

          k == :photo_evidence ->
            from(a in accum_query, where: ilike(a.photo_evidence, ^"%#{v}%"))

          k == :revoke_type ->
            from(a in accum_query, where: ilike(a.revoke_type, ^"%#{v}%"))

          k == :revoked_until ->
            from(a in accum_query, where: a.revoked_until == ^v)

          k == :asset_id ->
            from(a in accum_query, where: a.asset_id == ^v)

          k == :user_id ->
            from(a in accum_query, where: a.user_id == ^v)

          k == :approved_by_id ->
            from(a in accum_query, where: a.approved_by_id == ^v)

          k == :performed_by_id ->
            from(a in accum_query, where: a.performed_by_id == ^v)

          true ->
            accum_query
        end
      end)

    from a in query,
      preload: [
        :asset,
        :user,
        :office,
        :approved_by,
        :performed_by
      ]
  end
end


# defmodule ImsWeb.AssetLogLive.FormComponent do
#   use ImsWeb, :live_component

#   alias Ims.Inventory

#   @impl true
#   def mount(socket) do
#     socket =
#       socket
#       |> allow_upload(:police_abstract_photo, accept: ~w(.jpg .jpeg .png .pdf), max_entries: 1)
#       |> allow_upload(:photo_evidence, accept: ~w(.jpg .jpeg .png), max_entries: 1)
#       |> allow_upload(:evidence, accept: ~w(.jpg .jpeg .png), max_entries: 1)

#     {:ok, socket}
#   end

#   @impl true
#   def update(%{asset: asset, action: action, return_to: return_to, current_user: current_user} = assigns, socket) do
#     current_time = DateTime.utc_now()
#     default_params = %{
#       "performed_at" => current_time,
#       "assigned_at" => current_time,
#       "status" => "active"
#     }

#     users = Ims.Accounts.list_users() |> Enum.map(&{&1.first_name, &1.id})
#     offices = Ims.Inventory.list_offices() |> Enum.map(&{&1.name, &1.id})

#     {:ok,
#      socket
#      |> assign(assigns)
#      |> assign(:users, users)
#      |> assign(:offices, offices)
#      |> assign_new(:assign_to, fn -> "user" end)
#      |> assign_new(:form, fn ->
#        to_form(Inventory.change_asset_log(%Ims.Inventory.AssetLog{}, default_params))
#      end)}
#   end

#   @impl true
#   def update(%{asset_log: asset_log} = assigns, socket) do
#     {:ok,
#      socket
#      |> assign(assigns)
#      |> assign_new(:form, fn ->
#        to_form(Inventory.change_asset_log(asset_log))
#      end)}
#   end

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <div>
#       <.simple_form
#         for={@form}
#         id="asset_log-form"
#         phx-target={@myself}
#         phx-change="validate"
#         phx-submit="save"
#       >
#         <.input field={@form[:action]} type="hidden" value={action_value(@action)} />

#         <%= if @form[:action].value == "assigned" do %>
#           <.input
#             name="assign_to"
#             type="select"
#             label="Assign to"
#             value={@assign_to}
#             options={[{"User", "user"}, {"Office", "office"}]}
#             phx-target={@myself}
#             phx-change="assign_to_changed"
#           />

#           <%= if @assign_to == "user" do %>
#             <.input field={@form[:user_id]} type="select" label="User" options={@users} />
#           <% else %>
#             <.input field={@form[:office_id]} type="select" label="Office" options={@offices} />
#           <% end %>

#           <.input field={@form[:assigned_at]} type="hidden" value={now_naive()} />
#           <.input field={@form[:performed_at]} type="hidden" value={now_naive()} />
#           <.input field={@form[:status]} type="hidden" value="active" />
#           <.input field={@form[:remarks]} type="textarea" label="Remarks" required />
#         <% end %>

#         <%= if @form[:action].value == "revoked" do %>
#           <.input field={@form[:revoked_until]} type="date" label="Revoked Until" required />
#           <.input field={@form[:revoke_type]} type="text" label="Revoke Type" required />
#           <.input field={@form[:performed_at]} type="hidden" value={now_naive()} />
#           <.input field={@form[:status]} type="hidden" value="revoked" />
#           <.input field={@form[:remarks]} type="textarea" label="Remarks" required />
#         <% end %>

#         <%= if @form[:action].value == "lost" do %>
#           <.input field={@form[:abstract_number]} type="text" label="Abstract Number" required />
#           <.input field={@form[:performed_at]} type="hidden" value={now_naive()} />
#           <.input field={@form[:status]} type="hidden" value="lost" />
#           <.input field={@form[:remarks]} type="textarea" label="Remarks" required />

#           <div class="mt-4">
#             <label class="block font-semibold">Police Abstract Photo</label>
#             <.live_file_input upload={@uploads.police_abstract_photo} />
#           </div>
#         <% end %>

#         <%= if @form[:action].value in ["returned", "revoked"] do %>
#           <.input field={@form[:date_returned]} type="date" label="Date Returned" />
#           <div class="mt-4">
#             <label class="block font-semibold">Evidence (e.g., return photo)</label>
#             <.live_file_input upload={@uploads.evidence} />
#           </div>
#         <% end %>

#         <div class="mt-4">
#           <label class="block font-semibold">Other Photo Evidence</label>
#           <.live_file_input upload={@uploads.photo_evidence} />
#         </div>

#         <:actions>
#           <.button phx-disable-with="Saving...">Save Asset Log</.button>
#         </:actions>
#       </.simple_form>
#     </div>
#     """
#   end

#   defp action_value(action) do
#     case action do
#       :assign_device -> "assigned"
#       :return_device -> "returned"
#       :revoke_device -> "revoked"
#       :decommission_device -> "decommissioned"
#       :lost_device -> "lost"
#       _ -> "assigned"
#     end
#   end

#   defp now_naive do
#     DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive() |> NaiveDateTime.to_string()
#   end

#   @impl true
#   def handle_event("validate", %{"asset_log" => asset_log_params}, socket) do
#     changeset =
#       %Ims.Inventory.AssetLog{}
#       |> Inventory.change_asset_log(asset_log_params)
#       |> Map.put(:action, :validate)

#     {:noreply, assign(socket, form: to_form(changeset))}
#   end

#   @impl true
#   def handle_event("assign_to_changed", %{"assign_to" => assign_to}, socket) do
#     {:noreply, assign(socket, :assign_to, assign_to)}
#   end

#   @impl true
#   def handle_event("save", %{"asset_log" => asset_log_params}, socket) do
#     uploads = socket.assigns.uploads

#     asset_log_params =
#       asset_log_params
#       |> process_upload(:police_abstract_photo, uploads, "abstract", socket)
#       |> process_upload(:photo_evidence, uploads, "evidence", socket)
#       |> process_upload(:evidence, uploads, "return", socket)
#       |> Map.put("asset_id", socket.assigns.asset.id)
#       |> Map.put("performed_by_id", socket.assigns.current_user.id)

#     case Inventory.create_asset_log(asset_log_params) do
#       {:ok, asset_log} ->
#         notify_parent({:saved, asset_log})

#         {:noreply,
#          socket
#          |> put_flash(:info, "Asset log created successfully")
#          |> push_patch(to: socket.assigns.return_to)}

#       {:error, %Ecto.Changeset{} = changeset} ->
#         {:noreply,
#          socket
#          |> assign(:form, to_form(changeset))
#          |> put_flash(:error, "Failed to create asset log")}
#     end
#   end

#   defp process_upload(params, key, uploads, prefix, socket) do
#     case uploads[key].entries do
#       [entry | _] ->
#         path =
#           Phoenix.LiveView.consume_uploaded_entry(socket, key, entry, fn %{path: path} ->
#             dest = Path.join("priv/static/uploads", "#{prefix}_#{entry.client_name}")
#             File.cp!(path, dest)
#             {:ok, "/uploads/#{prefix}_#{entry.client_name}"}
#           end)

#         Map.put(params, to_string(key), path)

#       _ -> params
#     end
#   end

#   defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
# end
