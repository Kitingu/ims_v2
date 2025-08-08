defmodule Ims.Repo.Migrations.AddIdNumberToUsers do
use Ecto.Migration

  def change do
    alter table(:users) do
      add :id_number, :string
    end

    create unique_index(:users, [:id_number])
  end
end
