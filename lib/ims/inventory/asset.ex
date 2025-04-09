defmodule Ims.Inventory.Asset do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo
  alias Elixlsx.{Workbook, Sheet}

  schema "assets" do
    field :status, Ecto.Enum, values: [:available, :assigned, :revoked, :lost, :decommissioned]
    field :tag_number, :string
    field :serial_number, :string
    field :original_cost, :decimal
    field :purchase_date, :date
    field :warranty_expiry, :date
    field :condition, :string
    # associations
    belongs_to :asset_name, Ims.Inventory.AssetName
    belongs_to :user, Ims.Accounts.User
    belongs_to :office, Ims.Inventory.Office

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :tag_number,
      :asset_name_id,
      :status,
      :serial_number,
      :original_cost,
      :purchase_date,
      :warranty_expiry,
      :user_id,
      :office_id,
      :condition
    ])
    |> validate_required([
      :status,
      :serial_number,
      :original_cost,
      :condition,
      :asset_name_id
    ])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(a in accum_query,
              join: an in Ims.Inventory.AssetName,
              on: a.asset_name_id == an.id,
              where: ilike(an.name, ^"%#{v}%")
            )

          k == :tag_number ->
            from(a in accum_query, where: ilike(a.tag_number, ^"%#{v}%"))

          k == :serial_number ->
            from(a in accum_query, where: ilike(a.serial_number, ^"%#{v}%"))

          k == :original_cost ->
            from(a in accum_query, where: a.original_cost == ^v)

          k == :purchase_date ->
            from(a in accum_query, where: a.purchase_date == ^v)

          k == :warranty_expiry ->
            from(a in accum_query, where: a.warranty_expiry == ^v)

          k == :condition ->
            from(a in accum_query, where: ilike(a.condition, ^"%#{v}%"))

          k == :status ->
            from(a in accum_query, where: ilike(a.status, ^"%#{v}%"))

          k == :category_id ->
            from(a in accum_query,
              join: an in Ims.Inventory.AssetName,
              on: a.asset_name_id == an.id,
              where: an.category_id == ^v
            )

          k == :category_name ->
            from(a in accum_query,
              join: an in Ims.Inventory.AssetName,
              on: a.asset_name_id == an.id,
              join: c in Ims.Inventory.Category,
              on: an.category_id == c.id,
              where: ilike(c.name, ^"%#{v}%")
            )

          k == :user_id ->
            from(a in accum_query, where: a.user_id == ^v)

          k == :user_name ->
            from(a in accum_query,
              join: u in Ims.Accounts.User,
              on: a.user_id == u.id,
              where: ilike(u.first_name, ^"%#{v}%")
            )

          k == :office_id ->
            from(a in accum_query, where: a.office_id == ^v)

          k == :office_name ->
            from(a in accum_query,
              join: o in Ims.Inventory.Office,
              on: a.office_id == o.id,
              where: ilike(o.name, ^"%#{v}%")
            )

          k == :office_floor ->
            from(a in accum_query,
              join: o in Ims.Inventory.Office,
              on: a.office_id == o.id,
              where: ilike(o.floor, ^"%#{v}%")
            )

          k == :office_door_name ->
            from(a in accum_query,
              join: o in Ims.Inventory.Office,
              on: a.office_id == o.id,
              where: ilike(o.door_name, ^"%#{v}%")
            )

          k == :location_id ->
            from(a in accum_query,
              join: o in Ims.Inventory.Office,
              on: a.office_id == o.id,
              where: o.location_id == ^v
            )

          k == :location_name ->
            from(a in accum_query,
              join: o in Ims.Inventory.Office,
              on: a.office_id == o.id,
              join: l in Ims.Inventory.Location,
              on: o.location_id == l.id,
              where: ilike(l.name, ^"%#{v}%")
            )

          true ->
            accum_query
        end
      end)
# asset_name has a category_id
    from(q in query, preload: [ :user, :office, asset_name: :category])
  end

  def generate_report(filters \\ %{}) do
    # Query devices with necessary preloads
    devices =
      __MODULE__
      |> search(filters)
      |> Repo.all()
      # Adjust association names as needed
      |> Repo.preload([:category, assigned_user: [:department]])

    headers = [
      "Assigned User Name",
      "Designation",
      "Department",
      "Personal Number",
      "Device Name",
      "Serial Number",
      "Status",
      "Original Cost",
      "Category Name"
    ]

    rows =
      devices
      |> Enum.map(fn device ->
        [
          (device.assigned_user && device.assigned_user.first_name) || "N/A",
          (device.assigned_user && device.assigned_user.designation) || "N/A",
          (device.assigned_user && device.assigned_user.department &&
             device.assigned_user.department.name) || "N/A",
          (device.assigned_user && device.assigned_user.personal_number) || "N/A",
          (device.device_name && device.device_name.name) || "N/A",
          device.serial_number,
          device.status,
          Decimal.to_string(device.original_cost),
          # Fetch category name
          (device.category && device.category.name) || "N/A"
          # Fetch assigned user name
        ]
      end)

    sheet = %Sheet{name: "Assets Report", rows: [headers | rows]}
    workbook = %Workbook{sheets: [sheet]}

    file_path = "/tmp/assets_report.xlsx"
    Elixlsx.write_to(workbook, file_path)

    {:ok, file_path}
  end

  def device_in_lost_state?(asset) do
    # check if the device current user_id is the one that lost the device and alos the device is approved
    from(a in __MODULE__,
      where: a.id == ^asset.id and a.status == ^:lost
    )
    |> Repo.one()
    |> case do
      nil -> false
      _ -> true
    end
  end
end
