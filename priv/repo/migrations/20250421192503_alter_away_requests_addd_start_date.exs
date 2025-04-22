defmodule Ims.Repo.Migrations.AlterAwayRequestsAdddStartDate do
  use Ecto.Migration

  def change do
    alter table(:away_requests) do
      add :start_date, :date
      add :status, :string
    end

    create index(:away_requests, [:start_date])
    create index(:away_requests, [:status])
  end
end
