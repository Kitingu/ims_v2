defmodule Ims.Repo.Migrations.AddWards do
  use Ecto.Migration

  def change do
    create table(:wards) do
      add :name, :string, null: false
      add :constituency_id, references(:constituencies, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:wards, [:constituency_id, :name], name: :wards_constituency_name_ux)
  end
end
