defmodule Ims.Repo.Migrations.AlterPermissionsAddApprovalLevels do
  use Ecto.Migration

  def change do
    alter table(:permissions) do
      add :approval_levels, :integer, default: 0
    end
  end
end
