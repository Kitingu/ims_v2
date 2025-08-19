  alias Ims.Repo
alias Ims.Inventory.AssetType
alias Ims.Inventory.AssetName
alias Ims.Inventory.Category

IO.puts("🌱 Seeding asset types...")

asset_types = [
  %{
    name: "Electronics",
    description: "Devices that operate on electrical power"
  },
  %{
    name: "Furniture",
    description: "Items used to furnish a space"
  },
  %{
    name: "Vehicles",
    description: "Transport vehicles used for official duties"
  }
]


Enum.each(asset_types, fn asset_type ->
  Repo.insert!(%AssetType{
    name: asset_type.name,
    description: asset_type.description
  })
end)







# insert all popular asset names for laptops desktops and printers
IO.puts("🌱 Seeding asset names...")

categories = [
  %{
    name: "Printer",
    asset_type_id: Repo.get_by!(AssetType, name: "Electronics").id
  },
  %{
    name: "Laptop",
    asset_type_id: Repo.get_by!(AssetType, name: "Electronics").id
  },
  %{
    name: "Desktop",
    asset_type_id: Repo.get_by!(AssetType, name: "Electronics").id
  },
  %{
    name: "Vehicle",
    asset_type_id: Repo.get_by!(AssetType, name: "Vehicles").id
  },
  %{
    name: "Office Furniture",
    asset_type_id: Repo.get_by!(AssetType, name: "Furniture").id
  },
  %{
    name: "Office Supplies",
    asset_type_id: Repo.get_by!(AssetType, name: "Electronics").id
  }

]

Enum.each(categories, fn category ->
  Repo.insert!(%Category{
    name: category.name,
    asset_type_id: category.asset_type_id
  })
end)











asset_names = [
  %{
    name: "Dell Latitude 7420",
    description: "High-performance laptop for business use",
    category_id: Repo.get_by!(Category, name: "Laptop").id
  },
  %{
    name: "HP EliteBook 840 G8",
    description: "Premium business laptop with advanced features",
    category_id: Repo.get_by!(Category, name: "Laptop").id
  },
  %{
    name: "MacBook Pro 16-inch",
    description: "Apple's flagship laptop for professionals",
    category_id: Repo.get_by!(Category, name: "Laptop").id
  },
  %{
    name: "Lenovo ThinkPad X1 Carbon",
    description: "Lightweight and durable business laptop",
    category_id: Repo.get_by!(Category, name: "Laptop").id
  },
  %{
    name: "Macbook Air M2",
    description: "Apple's ultra-portable laptop with M2 chip",
    category_id: Repo.get_by!(Category, name: "Laptop").id
  },
  %{
    name: "Hp laserjet Pro M404dn",
    description: "High-speed monochrome laser printer",
    category_id: Repo.get_by!(Category, name: "Printer").id
  },
  %{
    name: "Brother MFC-L3770CDW",
    description: "All-in-one color laser printer with scanning and faxing",
    category_id: Repo.get_by!(Category, name: "Printer").id
  },

  %{
    name: "HP Color LaserJet Pro MFP M479fdw",
    description: "Versatile color laser printer with advanced features",
    category_id: Repo.get_by!(Category, name: "Printer").id
  },

  %{
    name: "HP LaserJet Pro M15w",
    description: "Compact and affordable monochrome laser printer",
    category_id: Repo.get_by!(Category, name: "Printer").id
  },

  %{
    name: "Lenovo All-in-One Desktop",
    description: "Space-saving desktop computer with integrated display",
    category_id: Repo.get_by!(Category, name: "Desktop").id
  },

  %{
    name: "Canon ImageCLASS MF445dw",
    description: "All-in-one monochrome laser printer",
    category_id: Repo.get_by!(Category, name: "Printer").id
  },

  %{
    name: "Toyota Land Cruiser Prado",
    description: "Official vehicle for senior management",
    category_id: Repo.get_by!(Category, name: "Vehicle").id
  }

]


Enum.each(asset_names, fn asset_name ->
  Repo.insert!(%AssetName{
    name: asset_name.name,
    description: asset_name.description,
    category_id: asset_name.category_id
  })
end)





IO.puts("✅ Asset types and names seeded successfully.")
IO.puts("🌱 Seeding complete.")
