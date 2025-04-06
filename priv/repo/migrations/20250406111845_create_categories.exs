defmodule Ims.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :asset_type_id, references(:asset_types, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:asset_type_id])
  end
end
