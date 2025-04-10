defmodule Ims.Repo.Migrations.AssetLogsAddOfficeId do
  use Ecto.Migration

  def change do
    alter table(:asset_logs) do
      add :office_id, references(:offices, on_delete: :nothing)
    end

    create index(:asset_logs, [:office_id])
  end
end
