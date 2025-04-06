defmodule Ims.Repo.Migrations.CreateOffices do
  use Ecto.Migration

  def change do
    create table(:offices) do
      add :name, :string
      add :building, :string
      add :floor, :string
      add :door_name, :string
      add :location_id, references(:locations, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:offices, [:location_id])
  end
end
