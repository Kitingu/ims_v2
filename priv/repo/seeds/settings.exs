  alias Ims.Repo
alias Ims.Settings.Setting

settings = [
  %{
    name: "app_name",
    value: "ODP IMS"
  },
  %{
    name: "logo_url",
    value:
      "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Coat_of_arms_of_Kenya_%28Official%29.svg/1920px-Coat_of_arms_of_Kenya_%28Official%29.svg.png"
  },
  %{
    name: "primary_color",
    # Blue
    value: "#007bff"
  },
  %{
    name: "secondary_color",
    # Gray
    value: "#6c757d"
  }
]

Enum.each(settings, fn setting ->
  Repo.insert!(%Setting{
    name: setting.name,
    value: setting.value
  })
end)
