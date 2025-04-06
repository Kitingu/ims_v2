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
end
