defmodule Ims.Repo.Migrations.AddConstraintToWelfareContributionsPerUserId do
  use Ecto.Migration

  def change do
    alter table(:contributions) do
      add :date_paid, :utc_datetime, null: true
    end

    create unique_index(:contributions, [:user_id, :event_id],
             name: :contributions_user_id_event_id_index
           )
  end
end
