defmodule Ims.Repo.Migrations.AlterTrainingApplicationsAddDisabilityDetails do
  use Ecto.Migration

  def up do
    alter table(:training_applications) do
      add :disability_details, :string
      remove :period_of_study
    end

    alter table(:training_applications) do
      add :period_of_study, :integer
    end
  end

  def down do
    alter table(:training_applications) do
      remove :disability_details
      remove :period_of_study
    end

    alter table(:training_applications) do
      add :period_of_study, :string
    end
  end
end
