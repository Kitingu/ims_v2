defmodule Ims.Repo.Migrations.AlterTableAssetNameAddCategoryId do
  use Ecto.Migration

  def up do
    # Remove index and column first
    drop index(:asset_names, [:asset_type_id])

    alter table(:asset_names) do
      remove :asset_type_id
      add :category_id, references(:categories, on_delete: :nothing)
    end

    create index(:asset_names, [:category_id])
  end

  def down do
    # Rollback: remove category and bring back asset_type
    drop index(:asset_names, [:category_id])

    alter table(:asset_names) do
      remove :category_id
      add :asset_type_id, references(:asset_types, on_delete: :nothing)
    end

    create index(:asset_names, [:asset_type_id])
  end
end
