defmodule Ims.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string
      add :description, :text
      add :amount_paid, :decimal
      add :status, :string
      add :event_type_id, references(:event_types, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:event_type_id])
    create index(:events, [:user_id])
  end
end
