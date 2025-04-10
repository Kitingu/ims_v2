defmodule Ims.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Inventory.Location

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations()
      [%Location{}, ...]

  """
  def list_locations do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(location)
      {:ok, %Location{}}

      iex> delete_location(location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  alias Ims.Inventory.Office

  @doc """
  Returns the list of offices.

  ## Examples

      iex> list_offices()
      [%Office{}, ...]

  """
  def list_offices do
    Repo.all(Office)
  end

  @doc """
  Gets a single office.

  Raises `Ecto.NoResultsError` if the Office does not exist.

  ## Examples

      iex> get_office!(123)
      %Office{}

      iex> get_office!(456)
      ** (Ecto.NoResultsError)

  """
  def get_office!(id), do: Repo.get!(Office, id)

  @doc """
  Creates a office.

  ## Examples

      iex> create_office(%{field: value})
      {:ok, %Office{}}

      iex> create_office(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_office(attrs \\ %{}) do
    %Office{}
    |> Office.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a office.

  ## Examples

      iex> update_office(office, %{field: new_value})
      {:ok, %Office{}}

      iex> update_office(office, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_office(%Office{} = office, attrs) do
    office
    |> Office.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a office.

  ## Examples

      iex> delete_office(office)
      {:ok, %Office{}}

      iex> delete_office(office)
      {:error, %Ecto.Changeset{}}

  """
  def delete_office(%Office{} = office) do
    Repo.delete(office)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking office changes.

  ## Examples

      iex> change_office(office)
      %Ecto.Changeset{data: %Office{}}

  """
  def change_office(%Office{} = office, attrs \\ %{}) do
    Office.changeset(office, attrs)
  end

  alias Ims.Inventory.AssetType

  @doc """
  Returns the list of asset_types.

  ## Examples

      iex> list_asset_types()
      [%AssetType{}, ...]

  """
  def list_asset_types do
    Repo.all(AssetType)
  end

  @doc """
  Gets a single asset_type.

  Raises `Ecto.NoResultsError` if the Asset type does not exist.

  ## Examples

      iex> get_asset_type!(123)
      %AssetType{}

      iex> get_asset_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset_type!(id), do: Repo.get!(AssetType, id)

  @doc """
  Creates a asset_type.

  ## Examples

      iex> create_asset_type(%{field: value})
      {:ok, %AssetType{}}

      iex> create_asset_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset_type(attrs \\ %{}) do
    %AssetType{}
    |> AssetType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a asset_type.

  ## Examples

      iex> update_asset_type(asset_type, %{field: new_value})
      {:ok, %AssetType{}}

      iex> update_asset_type(asset_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset_type(%AssetType{} = asset_type, attrs) do
    asset_type
    |> AssetType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a asset_type.

  ## Examples

      iex> delete_asset_type(asset_type)
      {:ok, %AssetType{}}

      iex> delete_asset_type(asset_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset_type(%AssetType{} = asset_type) do
    Repo.delete(asset_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset_type changes.

  ## Examples

      iex> change_asset_type(asset_type)
      %Ecto.Changeset{data: %AssetType{}}

  """
  def change_asset_type(%AssetType{} = asset_type, attrs \\ %{}) do
    AssetType.changeset(asset_type, attrs)
  end

  alias Ims.Inventory.AssetName

  @doc """
  Returns the list of asset_names.

  ## Examples

      iex> list_asset_names()
      [%AssetName{}, ...]

  """
  def list_asset_names do
    Repo.all(AssetName)
  end

  def list_asset_names_by_category(category_id) do
    AssetName
    |> where([a], a.category_id == ^category_id)
    |> Repo.all()
  end

  @doc """
  Gets a single asset_name.

  Raises `Ecto.NoResultsError` if the Asset name does not exist.

  ## Examples

      iex> get_asset_name!(123)
      %AssetName{}

      iex> get_asset_name!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset_name!(id), do: Repo.get!(AssetName, id)

  @doc """
  Creates a asset_name.

  ## Examples

      iex> create_asset_name(%{field: value})
      {:ok, %AssetName{}}

      iex> create_asset_name(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset_name(attrs \\ %{}) do
    %AssetName{}
    |> AssetName.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a asset_name.

  ## Examples

      iex> update_asset_name(asset_name, %{field: new_value})
      {:ok, %AssetName{}}

      iex> update_asset_name(asset_name, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset_name(%AssetName{} = asset_name, attrs) do
    asset_name
    |> AssetName.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a asset_name.

  ## Examples

      iex> delete_asset_name(asset_name)
      {:ok, %AssetName{}}

      iex> delete_asset_name(asset_name)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset_name(%AssetName{} = asset_name) do
    Repo.delete(asset_name)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset_name changes.

  ## Examples

      iex> change_asset_name(asset_name)
      %Ecto.Changeset{data: %AssetName{}}

  """
  def change_asset_name(%AssetName{} = asset_name, attrs \\ %{}) do
    AssetName.changeset(asset_name, attrs)
  end

  alias Ims.Inventory.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Ims.Inventory.Asset

  @doc """
  Returns the list of assets.

  ## Examples

      iex> list_assets()
      [%Asset{}, ...]

  """
  def list_assets do
    Repo.all(Asset)
  end

  @doc """
  Gets a single asset.

  Raises `Ecto.NoResultsError` if the Asset does not exist.

  ## Examples

      iex> get_asset!(123)
      %Asset{}

      iex> get_asset!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset!(id) do
    Repo.get!(Asset, id)
    |> Repo.preload([:user, :office, asset_name: :category])
  end

  def get_available_assets() do
    Asset
    |> where([a], a.status == :available)
    |> Repo.all()
  end

  # def get_available_assets_by_category(category_id) do
  #   Asset
  #   |> where([a], a.status == :available)
  #   |> where([a], a.asset_name.category_id == ^category_id)
  #   |> Repo.all()
  # end

  def get_assigned_assets() do
    Asset
    |> where([a], a.status == :assigned)
    |> Repo.all()
  end

  def get_lost_assets() do
    Asset
    |> where([a], a.status == :lost)
    |> Repo.all()
  end

  @doc """
  Creates a asset.

  ## Examples

      iex> create_asset(%{field: value})
      {:ok, %Asset{}}

      iex> create_asset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a asset.

  ## Examples

      iex> update_asset(asset, %{field: new_value})
      {:ok, %Asset{}}

      iex> update_asset(asset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a asset.

  ## Examples

      iex> delete_asset(asset)
      {:ok, %Asset{}}

      iex> delete_asset(asset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.

  ## Examples

      iex> change_asset(asset)
      %Ecto.Changeset{data: %Asset{}}

  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  def list_device_names() do
    AssetName
    |> Repo.all()
  end

  alias Ims.Inventory.AssetLog

  @doc """
  Returns the list of asset_logs.

  ## Examples

      iex> list_asset_logs()
      [%AssetLog{}, ...]

  """
  def list_asset_logs do
    Repo.all(AssetLog)
  end

  @doc """
  Gets a single asset_log.

  Raises `Ecto.NoResultsError` if the Asset log does not exist.

  ## Examples

      iex> get_asset_log!(123)
      %AssetLog{}

      iex> get_asset_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset_log!(id), do: Repo.get!(AssetLog, id)

  @doc """
  Creates a asset_log.

  ## Examples

      iex> create_asset_log(%{field: value})
      {:ok, %AssetLog{}}

      iex> create_asset_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_asset_log(%{"action" => "assigned", "asset_id" => asset_id} = log_attrs) do
    asset = get_asset!(asset_id)

    # if category.name != "catridge" do
    #   check_device_limit!(request.user_id, device.category_id)
    # end

    Repo.transaction(fn ->
      category =
        asset
        |> Repo.preload([:asset_name])
        |> Map.get(:asset_name)
        |> Repo.preload([:category])
        |> Map.get(:category)
        |> IO.inspect(label: "category")

      # unless category is tonner or catridge, check device limit

      # Update the asset status to :assigned and link user/office
      asset_changes =
        %{}
        |> maybe_put(:user_id, Map.get(log_attrs, "user_id"))
        |> maybe_put(:office_id, Map.get(log_attrs, "office_id"))
        |> Map.put(:status, :assigned)

      asset
      |> Asset.changeset(asset_changes)
      |> Repo.update!()

      %AssetLog{}
      |> AssetLog.changeset(log_attrs)
      |> Repo.insert!()
    end)
  end

  def create_asset_log(%{"action" => "returned", "asset_id" => asset_id} = log_attrs) do
    IO.inspect(log_attrs, label: "log_attrs")
    IO.inspect("REturn device")

    Repo.transaction(fn ->
      asset = get_asset!(asset_id)

      # Update asset to available and unlink user/office
      asset
      |> Asset.changeset(%{status: :available, user_id: nil, office_id: nil})
      |> Repo.update!()

      %AssetLog{}
      |> AssetLog.changeset(log_attrs)
      |> Repo.insert!()
    end)
  end

  def create_asset_log(%{"action" => "mark_as_lost", "asset_id" => asset_id} = log_attrs) do
    Repo.transaction(fn ->
      asset = get_asset!(asset_id)

      # Update asset status to lost
      asset
      |> Asset.changeset(%{status: :lost})
      |> Repo.update!()

      %AssetLog{}
      |> AssetLog.changeset(log_attrs)
      |> Repo.insert!()
    end)
  end

  # fallback for other actions
  def create_asset_log(attrs) do
    IO.inspect(attrs, label: "attrs for fallback")
    IO.inspect("Fallback")

    %AssetLog{}
    |> AssetLog.changeset(attrs)
    |> Repo.insert()
  end

  # Helper
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
  defp maybe_put(map, key, value) when is_map(value), do: Map.put(map, key, value)

  @doc """
  Updates a asset_log.

  ## Examples

      iex> update_asset_log(asset_log, %{field: new_value})
      {:ok, %AssetLog{}}

      iex> update_asset_log(asset_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset_log(%AssetLog{} = asset_log, attrs) do
    asset_log
    |> AssetLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a asset_log.

  ## Examples

      iex> delete_asset_log(asset_log)
      {:ok, %AssetLog{}}

      iex> delete_asset_log(asset_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset_log(%AssetLog{} = asset_log) do
    Repo.delete(asset_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset_log changes.

  ## Examples

      iex> change_asset_log(asset_log)
      %Ecto.Changeset{data: %AssetLog{}}

  """
  def change_asset_log(%AssetLog{} = asset_log, attrs \\ %{}) do
    AssetLog.changeset(asset_log, attrs)
  end

  # def check_device_limit!(user_id, category_id) do
  #   assigned_devices =
  #     Repo.one(
  #       from a in Asset,
  #         where:
  #           a.user_id == ^user_id and a.category_id == ^category_id and
  #             a.status == "assigned",
  #         select: count(d.id)
  #     )

  #   if assigned_devices > 0 do
  #     Repo.rollback("User already has a device assigned in this category.")
  #   end
  # end
end
