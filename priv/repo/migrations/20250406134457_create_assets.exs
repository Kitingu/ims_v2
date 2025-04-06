defmodule Ims.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :tag_number, :string
      add :status, :string
      add :serial_number, :string
      add :original_cost, :decimal
      add :purchase_date, :date
      add :warranty_expiry, :date
      add :condition, :string
      add :asset_name_id, references(:asset_names, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :office_id, references(:offices, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end


    create index(:assets, [:asset_name_id])
    create index(:assets, [:user_id])
    create index(:assets, [:office_id])

    create unique_index(:assets, [:tag_number])
    create unique_index(:assets, [:serial_number])
  end
end
