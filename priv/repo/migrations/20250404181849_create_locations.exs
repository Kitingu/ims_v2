defmodule Ims.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
