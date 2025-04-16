defmodule Ims.Repo.Migrations.CreateAwayRequests do
  use Ecto.Migration

  def change do
    create table(:away_requests) do
      add :reason, :string
      add :location, :string
      add :memo, :string
      add :memo_upload, :string
      add :days, :integer
      add :return_date, :date
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:away_requests, [:user_id])
  end
end
