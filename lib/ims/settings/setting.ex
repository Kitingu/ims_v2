defmodule Ims.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Ims.Repo
  import Ecto.Query

  schema "settings" do
    field :name, :string
    field :value, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:name, :value])
    |> validate_required([:name, :value])
  end

  def get_setting(name) do
    case Repo.get_by(__MODULE__, name: name) do
      nil -> nil
      setting -> setting.value
    end
  end
end
