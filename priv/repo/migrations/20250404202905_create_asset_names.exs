defmodule Ims.Repo.Migrations.CreateAssetNames do
  use Ecto.Migration

  def change do
    create table(:asset_names) do
      add :name, :string
      add :description, :string
      add :asset_type_id, references(:asset_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:asset_names, [:asset_type_id])
  end
end
