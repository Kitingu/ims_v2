defmodule Ims.Repo.Migrations.AlterTableAssetsAddCategoryId do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :category_id, references(:categories, on_delete: :nothing)
    end

    create index(:assets, [:category_id])
  end
end
