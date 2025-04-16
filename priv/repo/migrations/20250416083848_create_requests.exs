defmodule Ims.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add :status, :string
      add :request_type, :string
      add :assigned_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :actioned_by_id, references(:users, on_delete: :nothing)
      add :asset_id, references(:assets, on_delete: :nothing)
      add :actioned_at, :utc_datetime
      add :category_id, references(:categories, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:requests, [:user_id])
    create index(:requests, [:asset_id])
    create index(:requests, [:category_id])
  end
end
