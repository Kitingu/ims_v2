  alias Ims.Repo
alias Ims.Inventory.Office
alias Ims.Inventory.Location
IO.puts("🌱 Seeding offices...")

locations = [
  %{
    name: "Harambee House",
    description: "Main office located in Nairobi",
  },
  %{
    name: "Karen Residence",
    description: "Official residence of the Deputy President"
  }
]
Enum.each(locations, fn location ->
  Repo.insert!(%Location{
    name: location.name,
    description: location.description
  })
end)


offices = [
  %{
    name: "Head of ICT",
    floor: "4th Floor",
    door_name: "ICT Office",
    location_name: "Harambee House",
    location_id: Repo.get_by!(Location, name: "Harambee House").id
  },
  %{
    name: "Deputy President's Office",
    floor: "2nd Floor",
    door_name: "DP Office",
    location_name: "Harambee House",
    location_id: Repo.get_by!(Location, name: "Harambee House").id
  }
]
Enum.each(offices, fn office ->
  Repo.insert!(%Office{
    name: office.name,
    floor: office.floor,
    door_name: office.door_name,
    location_id: office.location_id
  })
end)
IO.puts("✅ Offices seeded successfully.")
IO.puts("🌱 Seeding complete.")
