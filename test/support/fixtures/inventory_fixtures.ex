defmodule Ims.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Inventory` context.
  """

  @doc """
  Generate a location.
  """
  def location_fixture(attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Inventory.create_location()

    location
  end

  @doc """
  Generate a office.
  """
  def office_fixture(attrs \\ %{}) do
    {:ok, office} =
      attrs
      |> Enum.into(%{
        building: "some building",
        door_name: "some door_name",
        floor: "some floor",
        name: "some name"
      })
      |> Ims.Inventory.create_office()

    office
  end

  @doc """
  Generate a asset_type.
  """
  def asset_type_fixture(attrs \\ %{}) do
    {:ok, asset_type} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Inventory.create_asset_type()

    asset_type
  end

  @doc """
  Generate a asset_name.
  """
  def asset_name_fixture(attrs \\ %{}) do
    {:ok, asset_name} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Inventory.create_asset_name()

    asset_name
  end

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ims.Inventory.create_category()

    category
  end

  @doc """
  Generate a asset.
  """
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        condition: "some condition",
        original_cost: "120.5",
        purchase_date: ~D[2025-04-05],
        serial_number: "some serial_number",
        status: "some status",
        tag_number: "some tag_number",
        warranty_expiry: ~D[2025-04-05]
      })
      |> Ims.Inventory.create_asset()

    asset
  end
end
