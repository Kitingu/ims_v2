  alias Ims.Repo
alias Ims.Demographics.Ethnicity

ethnic_groups = [
  "Kikuyu", "Luhya", "Luo", "Kalenjin", "Kamba", "Kisii", "Meru", "Maasai", "Mijikenda",
  "Somali", "Turkana", "Taita", "Embu", "Swahili", "Teso", "Kurya", "Samburu",
  "Nubian", "Borana", "Rendille", "Orma", "Gabbra", "Dasenach", "Burji", "Suba",
  "Mbeere", "Basuba", "Maragoli", "Tharaka", "Pokot", "Sakuye", "Bajuni", "Ilchamus",
  "Ariaal", "Boni", "Gosha", "Digo", "Duruma", "El Molo", "Saanye", "Waata",
  "Ogiek", "Awer", "Makonde", "Yaku", "Leysan"
]

Enum.each(ethnic_groups, fn name ->
  Repo.insert!(%Ethnicity{name: name})
end)
