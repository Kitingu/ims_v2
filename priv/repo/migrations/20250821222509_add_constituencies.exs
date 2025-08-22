defmodule Ims.Repo.Migrations.AddConstituencies do
  use Ecto.Migration

  def change do
    create table(:constituencies) do
      add :name, :string, null: false
      add :county_id, references(:counties, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:constituencies, [:county_id, :name],
             name: :constituencies_county_name_ux
           )
  end
end
