defmodule Ims.Repo.Migrations.CreatePaymentGateways do
  use Ecto.Migration

  def change do
    create table(:payment_gateways) do
      add :name, :string
      add :slug, :string
      add :payload, :map
      add :label, :string
      add :type, :string
      add :status, :string
      add :identifier, :string
      add :identifier_type, :string
      add :key, :string
      add :secret, :string
      add :currency, :string
      add :payment_instructions, :string
      add :common_name, :string
      add :validation_rules, :map

      timestamps(type: :utc_datetime)
    end
  end
end
