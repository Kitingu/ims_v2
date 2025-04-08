defmodule Ims.Repo.Migrations.CreateAssetLogs do
  use Ecto.Migration

  def change do
    create table(:asset_logs) do
      add :action, :string
      add :remarks, :text
      add :status, :string
      add :performed_at, :utc_datetime
      add :assigned_at, :utc_datetime
      add :date_returned, :date
      add :evidence, :string
      add :abstract_number, :string
      add :police_abstract_photo, :string
      add :photo_evidence, :string
      add :revoke_type, :string
      add :revoked_until, :date
      add :asset_id, references(:assets, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :approved_by_id, references(:users, on_delete: :nothing)
      add :performed_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:asset_logs, [:asset_id])
    create index(:asset_logs, [:user_id])
    create index(:asset_logs, [:approved_by_id])
    create index(:asset_logs, [:performed_by_id])
  end
end
