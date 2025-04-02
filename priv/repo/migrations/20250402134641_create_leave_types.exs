defmodule Ims.Repo.Migrations.CreateLeaveTypes do
  use Ecto.Migration

  def change do
    create table(:leave_types) do
      add :name, :string
      add :max_days, :integer
      add :carry_forward, :boolean, default: false, null: false
      add :requires_approval, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leave_types, [:name])
  end
end
