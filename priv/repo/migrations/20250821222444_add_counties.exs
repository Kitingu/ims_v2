defmodule Ims.Repo.Migrations.AddCounties do
  use Ecto.Migration

  def change do
    create table(:counties) do
      add :name, :string, null: false
      # optional, e.g., numeric code if you have it
      add :code, :string
      timestamps()
    end

    create unique_index(:counties, [:name])
    create unique_index(:counties, [:code])
  end
end
