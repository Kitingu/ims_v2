defmodule Ims.Repo.Migrations.AlterUsersAddGender do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gender, :string
      add :department_id, references(:departments, on_delete: :nothing)
      add :job_group_id, references(:job_groups, on_delete: :nothing)
    end
  end
end
