defmodule Ims.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :name, :string
      add :value, :string

      timestamps(type: :utc_datetime)
    end
  end
end
