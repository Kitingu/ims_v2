# lib/ims/surveys.ex
defmodule Ims.Surveys do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Ims.Repo
  alias Ims.Surveys.SurveyResponse
  alias Ims.Regions

  def new_survey_response(attrs \\ %{}) do
    %SurveyResponse{} |> SurveyResponse.changeset(attrs)
  end

  def create_survey_response(attrs) do
    %SurveyResponse{}
    |> SurveyResponse.changeset(attrs)
    |> Repo.insert()
  end

  # helpers for dependent selects
  def counties_opts do
    Regions.list_counties() |> Enum.map(&{&1.name, &1.id})
  end

  def constituencies_opts(county_id) when is_integer(county_id) do
    Regions.list_constituencies(county_id) |> Enum.map(&{&1.name, &1.id})
  end

  def wards_opts(constituency_id) when is_integer(constituency_id) do
    Regions.list_wards(constituency_id) |> Enum.map(&{&1.name, &1.id})
  end
end
