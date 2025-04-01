defmodule Ims.Repo.Seeds.Settings do
  alias Ims.Repo
  alias Ims.Settings.Setting

  def run do
    settings = [
      %{
        name: "app_name",
        value: "ODP IMS"
      },
      %{
        name: "logo_url",
        value: "1.0.0"
      },
      %{
        name: "app_description",
        value: "This is a sample application."
      }
    ]

    Enum.each(settings, fn setting ->
      Repo.insert!(%Setting{
        name: setting.name,
        value: setting.value
      })
    end)
  end
end
