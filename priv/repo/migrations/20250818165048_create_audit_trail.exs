defmodule Ims.Repo.Migrations.CreateAuditTrail do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :actor_id, references(:users, on_delete: :nilify_all)
      # "user" | "system"
      add :actor_type, :string, null: false, default: "user"
      # "insert" | "update" | "delete" | custom
      add :action, :string, null: false
      # e.g. "User", "LeaveBalance"
      add :resource_type, :string, null: false
      # string to support UUID or int pks
      add :resource_id, :string
      # diff: %{changed: %{field => %{before, after}}} or payload
      add :changes, :map, default: %{}
      # ip, user_agent, request_id, path, etc.
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:resource_type, :resource_id])
    create index(:audit_logs, [:action])
    create index(:audit_logs, [:inserted_at])
  end
end
