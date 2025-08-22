defmodule ImsWeb.SurveyLive.New do
  use ImsWeb, :live_view

  alias Ims.Repo
  alias Ims.Regions
  alias Ims.Surveys.SurveyResponse

  # ───────────────── mount ─────────────────

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      SurveyResponse.changeset(%SurveyResponse{}, %{
        "date_of_data_collection" => Date.utc_today()
      })

    counties = Regions.list_counties() |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:page_title, "Economic Empowerment Programmes Questionnaire")
     |> assign(:counties, counties)
     |> assign(:constituencies, [])
     |> assign(:wards, [])
     |> assign_form(changeset)}
  end

  # ─────────────── validate (robust) ───────────────

  # Normal case – nested params
  @impl true
  def handle_event("validate", %{"survey_response" => params}, socket) do
    validate_and_assign(params, socket)
  end

  # Fallback – flat params from input-level phx-change
  def handle_event("validate", flat_params, socket) when is_map(flat_params) do
    params = extract_form_params(flat_params)
    validate_and_assign(params, socket)
  end

  defp validate_and_assign(params, socket) do
    changeset =
      %SurveyResponse{}
      |> SurveyResponse.changeset(params)
      |> Map.put(:action, :validate)

    {constits, wards} = dependent_options(params)

    {:noreply,
     socket
     |> assign(:constituencies, constits)
     |> assign(:wards, wards)
     |> assign_form(changeset)}
  end

  # ─────────────── save (normal + fallback) ───────────────

  @impl true
  def handle_event("save", %{"survey_response" => params}, socket) do
    do_save(params, socket)
  end

  def handle_event("save", flat_params, socket) when is_map(flat_params) do
    params = extract_form_params(flat_params)
    do_save(params, socket)
  end

  defp do_save(params, socket) do
    case %SurveyResponse{} |> SurveyResponse.changeset(params) |> Repo.insert() do
      {:ok, _rec} ->
        {:noreply,
         socket
         |> put_flash(:info, "Response submitted successfully.")
         |> push_navigate(to: ~p"/surveys/new")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {constits, wards} = dependent_options(params)

        {:noreply,
         socket
         |> assign(:constituencies, constits)
         |> assign(:wards, wards)
         |> assign_form(changeset)}
    end
  end

  # ─────────────── county_changed (normal + fallback) ───────────────

  @impl true
  def handle_event(
        "county_changed",
        %{"survey_response" => %{"county_id" => county_id} = params},
        socket
      ) do
    on_county_changed(params, county_id, socket)
  end

  def handle_event("county_changed", flat_params, socket) when is_map(flat_params) do
    params = extract_form_params(flat_params)
    on_county_changed(params, Map.get(params, "county_id"), socket)
  end

  defp on_county_changed(params, county_id, socket) do
    constits = list_constituency_options(county_id)

    params =
      params
      |> Map.put("constituency_id", nil)
      |> Map.put("ward_id", nil)

    changeset =
      %SurveyResponse{}
      |> SurveyResponse.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:constituencies, constits)
     |> assign(:wards, [])
     |> assign_form(changeset)}
  end

  # ─────────────── constituency_changed (normal + fallback) ───────────────

  @impl true
  def handle_event(
        "constituency_changed",
        %{"survey_response" => %{"constituency_id" => cid} = params},
        socket
      ) do
    on_constituency_changed(params, cid, socket)
  end

  def handle_event("constituency_changed", flat_params, socket) when is_map(flat_params) do
    params = extract_form_params(flat_params)
    on_constituency_changed(params, Map.get(params, "constituency_id"), socket)
  end

  defp on_constituency_changed(params, constituency_id, socket) do
    wards = list_ward_options(constituency_id)

    changeset =
      %SurveyResponse{}
      |> SurveyResponse.changeset(params)
      |> Map.put(:action, :validate)

    constits = list_constituency_options(params["county_id"])

    {:noreply,
     socket
     |> assign(:constituencies, constits)
     |> assign(:wards, wards)
     |> assign_form(changeset)}
  end

  # ─────────────── helpers ───────────────

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(:changeset, changeset)
    |> assign(:form, to_form(changeset))
  end

  defp dependent_options(params) do
    {
      list_constituency_options(params["county_id"]),
      list_ward_options(params["constituency_id"])
    }
  end

  # Pull out only form fields, ignore LV metadata & any "_unused_*"
  defp extract_form_params(map) when is_map(map) do
    map
    |> Enum.reject(fn {k, _v} -> reject_key?(k) end)
    |> Map.new()
  end

  # Helpers to drop non-form keys without guards
  defp reject_key?("_csrf_token"), do: true
  defp reject_key?("_target"), do: true
  defp reject_key?(<<"_unused_", _rest::binary>>), do: true
  defp reject_key?(_), do: false

  defp list_constituency_options(nil), do: []
  defp list_constituency_options(""), do: []

  defp list_constituency_options(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> list_constituency_options(int)
      :error -> []
    end
  end

  defp list_constituency_options(id) when is_integer(id) do
    Regions.list_constituencies(id) |> Enum.map(&{&1.name, &1.id})
  end

  defp list_ward_options(nil), do: []
  defp list_ward_options(""), do: []

  defp list_ward_options(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> list_ward_options(int)
      :error -> []
    end
  end

  defp list_ward_options(id) when is_integer(id) do
    Regions.list_wards(id) |> Enum.map(&{&1.name, &1.id})
  end
end
