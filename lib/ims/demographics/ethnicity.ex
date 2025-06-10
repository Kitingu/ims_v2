defmodule Ims.Demographics.Ethnicity do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "ethnicities" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ethnicity, attrs) do
    ethnicity
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def insert_ethnicities()do
    ethnic_groups = [
      "Kikuyu", "Luhya", "Luo", "Kalenjin", "Kamba", "Kisii", "Meru", "Maasai", "Mijikenda",
      "Somali", "Turkana", "Taita", "Embu", "Swahili", "Teso", "Kurya", "Samburu",
      "Nubian", "Borana", "Rendille", "Orma", "Gabbra", "Dasenach", "Burji", "Suba",
      "Mbeere", "Basuba", "Maragoli", "Tharaka", "Pokot", "Sakuye", "Bajuni", "Ilchamus",
      "Ariaal", "Boni", "Gosha", "Digo", "Duruma", "El Molo", "Saanye", "Waata",
      "Ogiek", "Awer", "Makonde", "Yaku", "Leysan"
    ]

    Enum.each(ethnic_groups, fn name ->
     Repo.insert!(%__MODULE__{name: name})
    end)

  end
end
