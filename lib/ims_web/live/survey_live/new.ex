# lib/ims_web/live/survey_live/new.ex
defmodule ImsWeb.SurveyLive.New do
  use ImsWeb, :live_view
  alias Ims.Surveys
  alias Ims.Surveys.SurveyResponse

  def mount(_params, _session, socket) do
    counties = Surveys.counties_opts()
    changeset = Surveys.new_survey_response(%{"date_of_data_collection" => Date.utc_today()})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:counties, counties)
      |> assign(:constituencies, [])
      |> assign(:wards, [])

    {:ok, socket}
  end

  def handle_event("validate", %{"survey_response" => params}, socket) do
    cs = SurveyResponse.changeset(%SurveyResponse{}, params) |> Map.put(:action, :validate)
    {:noreply, socket |> maybe_reload_deps(params) |> assign(:changeset, cs)}
  end

  def handle_event("save", %{"survey_response" => params}, socket) do
    case Surveys.create_survey_response(params) do
      {:ok, _sr} ->
        {:noreply,
         socket
         |> put_flash(:info, "Submitted successfully.")
         |> push_navigate(to: ~p"/surveys/new")}

      {:error, cs} ->
        {:noreply, socket |> maybe_reload_deps(params) |> assign(:changeset, cs)}
    end
  end

  # Reload dependent selects when county/constituency change
  defp maybe_reload_deps(socket, params) do
    county_id = to_int(Map.get(params, "county_id"))
    constituency_id = to_int(Map.get(params, "constituency_id"))

    constituencies =
      case county_id do
        nil -> []
        id -> Surveys.constituencies_opts(id)
      end

    wards =
      case constituency_id do
        nil -> []
        id -> Surveys.wards_opts(id)
      end

    socket
    |> assign(:constituencies, constituencies)
    |> assign(:wards, wards)
  end

  defp to_int(nil), do: nil
  defp to_int(""), do: nil
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
  defp to_int(v) when is_integer(v), do: v
end
