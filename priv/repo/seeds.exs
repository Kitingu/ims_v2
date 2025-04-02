# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ims.Repo.insert!(%Ims.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
IO.puts("🌱 Starting seed...")

# Ordered list to respect dependencies
seed_files = [
  "priv/repo/seeds/settings.exs",
  "priv/repo/seeds/roles_and_departments.exs",
  "priv/repo/seeds/leave_types.exs",
  "priv/repo/seeds/users.exs",
]

Enum.each(seed_files, fn file ->
  IO.puts("➡️  Running #{file}")
  Code.eval_file(file)
end)

IO.puts("✅ Seeding complete.")
