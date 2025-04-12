defmodule Ims.Repo.Migrations.CreateEthnicities do
  use Ecto.Migration

  def change do
    create table(:ethnicities) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
