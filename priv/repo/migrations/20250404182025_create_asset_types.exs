defmodule Ims.Repo.Migrations.CreateAssetTypes do
  use Ecto.Migration

  def change do
    create table(:asset_types) do
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
