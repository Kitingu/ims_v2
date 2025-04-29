defmodule Ims.Repo.Migrations.CreateEventTypes do
  use Ecto.Migration

  def change do
    create table(:event_types) do
      add :name, :string
      add :amount, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:event_types, [:name])
  end
end
