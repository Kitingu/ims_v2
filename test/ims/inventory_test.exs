defmodule Ims.InventoryTest do
  use Ims.DataCase

  alias Ims.Inventory

  describe "locations" do
    alias Ims.Inventory.Location

    import Ims.InventoryFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_locations/0 returns all locations" do
      location = location_fixture()
      assert Inventory.list_locations() == [location]
    end

    test "get_location!/1 returns the location with given id" do
      location = location_fixture()
      assert Inventory.get_location!(location.id) == location
    end

    test "create_location/1 with valid data creates a location" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Location{} = location} = Inventory.create_location(valid_attrs)
      assert location.name == "some name"
      assert location.description == "some description"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_location(@invalid_attrs)
    end

    test "update_location/2 with valid data updates the location" do
      location = location_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Location{} = location} = Inventory.update_location(location, update_attrs)
      assert location.name == "some updated name"
      assert location.description == "some updated description"
    end

    test "update_location/2 with invalid data returns error changeset" do
      location = location_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_location(location, @invalid_attrs)
      assert location == Inventory.get_location!(location.id)
    end

    test "delete_location/1 deletes the location" do
      location = location_fixture()
      assert {:ok, %Location{}} = Inventory.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset" do
      location = location_fixture()
      assert %Ecto.Changeset{} = Inventory.change_location(location)
    end
  end

  describe "offices" do
    alias Ims.Inventory.Office

    import Ims.InventoryFixtures

    @invalid_attrs %{name: nil, floor: nil, building: nil, door_name: nil}

    test "list_offices/0 returns all offices" do
      office = office_fixture()
      assert Inventory.list_offices() == [office]
    end

    test "get_office!/1 returns the office with given id" do
      office = office_fixture()
      assert Inventory.get_office!(office.id) == office
    end

    test "create_office/1 with valid data creates a office" do
      valid_attrs = %{name: "some name", floor: "some floor", building: "some building", door_name: "some door_name"}

      assert {:ok, %Office{} = office} = Inventory.create_office(valid_attrs)
      assert office.name == "some name"
      assert office.floor == "some floor"
      assert office.building == "some building"
      assert office.door_name == "some door_name"
    end

    test "create_office/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_office(@invalid_attrs)
    end

    test "update_office/2 with valid data updates the office" do
      office = office_fixture()
      update_attrs = %{name: "some updated name", floor: "some updated floor", building: "some updated building", door_name: "some updated door_name"}

      assert {:ok, %Office{} = office} = Inventory.update_office(office, update_attrs)
      assert office.name == "some updated name"
      assert office.floor == "some updated floor"
      assert office.building == "some updated building"
      assert office.door_name == "some updated door_name"
    end

    test "update_office/2 with invalid data returns error changeset" do
      office = office_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_office(office, @invalid_attrs)
      assert office == Inventory.get_office!(office.id)
    end

    test "delete_office/1 deletes the office" do
      office = office_fixture()
      assert {:ok, %Office{}} = Inventory.delete_office(office)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_office!(office.id) end
    end

    test "change_office/1 returns a office changeset" do
      office = office_fixture()
      assert %Ecto.Changeset{} = Inventory.change_office(office)
    end
  end

  describe "asset_types" do
    alias Ims.Inventory.AssetType

    import Ims.InventoryFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_asset_types/0 returns all asset_types" do
      asset_type = asset_type_fixture()
      assert Inventory.list_asset_types() == [asset_type]
    end

    test "get_asset_type!/1 returns the asset_type with given id" do
      asset_type = asset_type_fixture()
      assert Inventory.get_asset_type!(asset_type.id) == asset_type
    end

    test "create_asset_type/1 with valid data creates a asset_type" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %AssetType{} = asset_type} = Inventory.create_asset_type(valid_attrs)
      assert asset_type.name == "some name"
      assert asset_type.description == "some description"
    end

    test "create_asset_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_asset_type(@invalid_attrs)
    end

    test "update_asset_type/2 with valid data updates the asset_type" do
      asset_type = asset_type_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %AssetType{} = asset_type} = Inventory.update_asset_type(asset_type, update_attrs)
      assert asset_type.name == "some updated name"
      assert asset_type.description == "some updated description"
    end

    test "update_asset_type/2 with invalid data returns error changeset" do
      asset_type = asset_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_asset_type(asset_type, @invalid_attrs)
      assert asset_type == Inventory.get_asset_type!(asset_type.id)
    end

    test "delete_asset_type/1 deletes the asset_type" do
      asset_type = asset_type_fixture()
      assert {:ok, %AssetType{}} = Inventory.delete_asset_type(asset_type)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_asset_type!(asset_type.id) end
    end

    test "change_asset_type/1 returns a asset_type changeset" do
      asset_type = asset_type_fixture()
      assert %Ecto.Changeset{} = Inventory.change_asset_type(asset_type)
    end
  end

  describe "asset_names" do
    alias Ims.Inventory.AssetName

    import Ims.InventoryFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_asset_names/0 returns all asset_names" do
      asset_name = asset_name_fixture()
      assert Inventory.list_asset_names() == [asset_name]
    end

    test "get_asset_name!/1 returns the asset_name with given id" do
      asset_name = asset_name_fixture()
      assert Inventory.get_asset_name!(asset_name.id) == asset_name
    end

    test "create_asset_name/1 with valid data creates a asset_name" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %AssetName{} = asset_name} = Inventory.create_asset_name(valid_attrs)
      assert asset_name.name == "some name"
      assert asset_name.description == "some description"
    end

    test "create_asset_name/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_asset_name(@invalid_attrs)
    end

    test "update_asset_name/2 with valid data updates the asset_name" do
      asset_name = asset_name_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %AssetName{} = asset_name} = Inventory.update_asset_name(asset_name, update_attrs)
      assert asset_name.name == "some updated name"
      assert asset_name.description == "some updated description"
    end

    test "update_asset_name/2 with invalid data returns error changeset" do
      asset_name = asset_name_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_asset_name(asset_name, @invalid_attrs)
      assert asset_name == Inventory.get_asset_name!(asset_name.id)
    end

    test "delete_asset_name/1 deletes the asset_name" do
      asset_name = asset_name_fixture()
      assert {:ok, %AssetName{}} = Inventory.delete_asset_name(asset_name)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_asset_name!(asset_name.id) end
    end

    test "change_asset_name/1 returns a asset_name changeset" do
      asset_name = asset_name_fixture()
      assert %Ecto.Changeset{} = Inventory.change_asset_name(asset_name)
    end
  end

  describe "categories" do
    alias Ims.Inventory.Category

    import Ims.InventoryFixtures

    @invalid_attrs %{name: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Inventory.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Inventory.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Category{} = category} = Inventory.create_category(valid_attrs)
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Category{} = category} = Inventory.update_category(category, update_attrs)
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_category(category, @invalid_attrs)
      assert category == Inventory.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Inventory.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Inventory.change_category(category)
    end
  end

  describe "assets" do
    alias Ims.Inventory.Asset

    import Ims.InventoryFixtures

    @invalid_attrs %{status: nil, tag_number: nil, serial_number: nil, original_cost: nil, purchase_date: nil, warranty_expiry: nil, condition: nil}

    test "list_assets/0 returns all assets" do
      asset = asset_fixture()
      assert Inventory.list_assets() == [asset]
    end

    test "get_asset!/1 returns the asset with given id" do
      asset = asset_fixture()
      assert Inventory.get_asset!(asset.id) == asset
    end

    test "create_asset/1 with valid data creates a asset" do
      valid_attrs = %{status: "some status", tag_number: "some tag_number", serial_number: "some serial_number", original_cost: "120.5", purchase_date: ~D[2025-04-05], warranty_expiry: ~D[2025-04-05], condition: "some condition"}

      assert {:ok, %Asset{} = asset} = Inventory.create_asset(valid_attrs)
      assert asset.status == "some status"
      assert asset.tag_number == "some tag_number"
      assert asset.serial_number == "some serial_number"
      assert asset.original_cost == Decimal.new("120.5")
      assert asset.purchase_date == ~D[2025-04-05]
      assert asset.warranty_expiry == ~D[2025-04-05]
      assert asset.condition == "some condition"
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_asset(@invalid_attrs)
    end

    test "update_asset/2 with valid data updates the asset" do
      asset = asset_fixture()
      update_attrs = %{status: "some updated status", tag_number: "some updated tag_number", serial_number: "some updated serial_number", original_cost: "456.7", purchase_date: ~D[2025-04-06], warranty_expiry: ~D[2025-04-06], condition: "some updated condition"}

      assert {:ok, %Asset{} = asset} = Inventory.update_asset(asset, update_attrs)
      assert asset.status == "some updated status"
      assert asset.tag_number == "some updated tag_number"
      assert asset.serial_number == "some updated serial_number"
      assert asset.original_cost == Decimal.new("456.7")
      assert asset.purchase_date == ~D[2025-04-06]
      assert asset.warranty_expiry == ~D[2025-04-06]
      assert asset.condition == "some updated condition"
    end

    test "update_asset/2 with invalid data returns error changeset" do
      asset = asset_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_asset(asset, @invalid_attrs)
      assert asset == Inventory.get_asset!(asset.id)
    end

    test "delete_asset/1 deletes the asset" do
      asset = asset_fixture()
      assert {:ok, %Asset{}} = Inventory.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset" do
      asset = asset_fixture()
      assert %Ecto.Changeset{} = Inventory.change_asset(asset)
    end
  end
end
