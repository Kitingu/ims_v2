defmodule Ims.Repo.Migrations.CreateAnnualLeaveHistory do
  use Ecto.Migration

  def up do
    alter table(:leave_applications) do
      add :submitted_by_id, references(:users, on_delete: :nilify_all)
      add :decided_by_id, references(:users, on_delete: :nilify_all)
      add :decided_at, :utc_datetime
    end

    create table(:annual_leave_entries) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :actor_id, :bigint
      add :actor_label, :string, null: false
      add :application_id, references(:leave_applications, on_delete: :restrict)
      add :kind, :string, null: false
      add :effective_on, :date, null: false
      add :days, :decimal, null: false
      add :reason, :text
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:annual_leave_entries, [:user_id, :effective_on, :id])
    create unique_index(:annual_leave_entries, [:application_id])
    create unique_index(:annual_leave_entries, [:user_id, :effective_on],
             where: "kind IN ('opening', 'entitlement')",
             name: :annual_leave_entries_one_opening
           )

    execute """
    INSERT INTO annual_leave_entries
      (user_id, actor_label, kind, effective_on, days, reason, inserted_at)
    SELECT balances.user_id, 'System', 'opening',
           (date_trunc('year', timezone('Africa/Nairobi', now()) - interval '6 months')
             + interval '6 months')::date,
           COALESCE(balances.remaining_days, 0),
           'Balance at the start of history tracking', timezone('UTC', now())
    FROM leave_balances balances
    JOIN leave_types types ON types.id = balances.leave_type_id
    WHERE types.name = 'Annual Leave'
    """

    execute """
    INSERT INTO annual_leave_entries
      (user_id, actor_label, application_id, kind, effective_on, days, reason, inserted_at)
    SELECT applications.user_id, 'Unknown', applications.id, 'legacy_leave',
           applications.start_date, 0, 'Approved before history tracking',
           COALESCE(applications.inserted_at, timezone('UTC', now()))
    FROM leave_applications applications
    JOIN leave_types types ON types.id = applications.leave_type_id
    WHERE types.name = 'Annual Leave' AND applications.status = 'approved'
      AND applications.user_id IS NOT NULL AND applications.start_date IS NOT NULL
    """
  end

  def down do
    drop table(:annual_leave_entries)

    alter table(:leave_applications) do
      remove :submitted_by_id
      remove :decided_by_id
      remove :decided_at
    end
  end
end
