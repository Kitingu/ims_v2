defmodule Ims.Repo.Migrations.AlterTableAssetsAddCurrentLogId do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :current_log_id, references(:asset_logs, on_delete: :nothing), null: true
    end

    create index(:assets, [:current_log_id])
  end
end
