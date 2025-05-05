defmodule Ims.Repo.Migrations.CreateContributions do
  use Ecto.Migration

  def change do
    create table(:contributions) do
      add :amount, :decimal
      add :payment_reference, :string
      add :source, :string
      add :verified, :boolean, default: false, null: false
      add :event_id, references(:events, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :payment_gateway_id, references(:payment_gateways, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contributions, [:payment_reference])
    create index(:contributions, [:event_id])
    create index(:contributions, [:user_id])
  end
end
