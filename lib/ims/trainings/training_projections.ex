defmodule Ims.Trainings.TrainingProjections do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo
  alias Elixlsx.{Workbook, Sheet}
  # alias Ims.Trainings.TrainingProjections

  schema "training_projections" do
    field :costs, :decimal
    field :department, :string
    field :designation, :string
    field :disability, :boolean, default: false
    field :disability_details, :string
    field :financial_year, :string
    field :full_name, :string
    field :gender, :string
    field :institution, :string
    field :job_group, :string
    field :period_of_study, :integer
    field :period_input, :string, virtual: true
    field :personal_number, :string
    field :program_title, :string
    field :qualification, :string
    field :quarter, :string
    field :status, :string, default: "Pending"
    belongs_to :ethnicity, Ims.Demographics.Ethnicity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_projections, attrs) do
    training_projections
    |> cast(attrs, [
      :full_name,
      :gender,
      :personal_number,
      :designation,
      :department,
      :job_group,
      :qualification,
      :institution,
      :program_title,
      :financial_year,
      :quarter,
      :disability,
      :period_input,
      :period_of_study,
      :ethnicity_id,
      :costs,
      :status
    ])
    |> maybe_convert_period_to_days()
    |> validate_required([
      :full_name,
      :gender,
      :personal_number,
      :designation,
      :department,
      :job_group,
      :qualification,
      :institution,
      :program_title,
      :financial_year,
      :disability,
      :period_input,
      :costs,
      :status
    ])
    |> validate_number(:period_of_study,
      greater_than: 0,
      less_than_or_equal_to: 1825,
      message: "Must be between 1 day and 5 years"
    )
    |> unique_constraint(:personal_number,
      name: :training_projections_personal_number_index,
      message: "You have already submitted a projection for this financial year."
    )
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :full_name ->
            from(t in accum_query, where: ilike(t.full_name, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)

    from(t in query, preload: [:ethnicity])
  end

  defp maybe_convert_period_to_days(changeset) do
    IO.inspect(changeset, label: "Changeset before conversion")

    case get_change(changeset, :period_input) do
      nil -> changeset
      value -> put_change(changeset, :period_of_study, convert_period_to_days(value))
    end
  end

  defp convert_period_to_days(value) when is_binary(value) do
    case String.split(value, "_") do
      [duration, "days"] -> String.to_integer(duration)
      [duration, "weeks"] -> String.to_integer(duration) * 7
      [duration, "months"] -> String.to_integer(duration) * 30
      [duration, "years"] -> String.to_integer(duration) * 365
      # Default fallback
      _ -> 0
    end
  end

  def generate_report(format \\ :csv, filters \\ %{}) do
    projections = search(filters) |> Repo.all()

    case format do
      :csv -> generate_csv(projections)
      :excel -> generate_excel_binary(projections)
      _ -> {:error, "Unsupported format"}
    end
  end

  # defp generate_excel_with_logo(projections) do
  #   logo_url =
  #     Ims.Settings.Setting.get_setting("logo_url")
  #     |> IO.inspect(label: "Logo URL")

  #   logo_temp_path = "/tmp/excel_logo.png" |> IO.inspect(label: "Logo Temp Path")
  #   json_path = "/tmp/training_projection_data.json" |> IO.inspect(label: "JSON Path")
  #   output_path = "/tmp/training_projections.xlsx" |> IO.inspect(label: "Output Path")
  #   script_path = "assets/js/excel_generator.js"

  #   # Download the logo

  #   headers = [{~c"User-Agent", ~c"ProtoEnergy IMS/1.0 (benedict@protoenergy.com)"}]

  #   case :httpc.request(:get, {to_charlist(logo_url), headers}, [], [{:body_format, :binary}]) do
  #     {:ok, {{_, 200, _}, _headers, body}} ->
  #       File.write!(logo_temp_path, body)

  #     {:error, reason} ->
  #       IO.inspect(reason, label: "Failed to fetch logo")
  #       {:error, "Failed to download logo"}

  #     other ->
  #       IO.inspect(other, label: "Unexpected HTTP response")
  #       {:error, "Unexpected response while downloading logo"}
  #   end

  #   # Define custom order of columns
  #   ordered_keys = [
  #     "ID",
  #     "Full Name",
  #     "Personal Number",
  #     "Designation",
  #     "Department",
  #     "Job Group",
  #     "Ethnicity",
  #     "Program Title",
  #     "Institution",
  #     "Period of Study (Days)",
  #     "Costs (KSH)"
  #   ]

  #   # Transform and sort data
  #   data =
  #     projections
  #     # 🔃 sort by last name
  #     |> Enum.sort_by(& &1.id)
  #     |> Enum.map(fn app ->
  #       %{
  #         "ID" => app.id,
  #         "Full Name" => app.full_name |> String.capitalize(),
  #         "Personal Number" => app.personal_number,
  #         "Designation" => app.designation,
  #         "Department" => app.department || "N/A",
  #         "Job Group" => app.job_group || "N/A",
  #         "Ethnicity" => app.ethnicity.name,
  #         "Program Title" => app.program_title,
  #         "Institution" => app.institution,
  #         "Period of Study (Days)" => app.period_of_study |> Ims.Helpers.format_duration(),
  #         "Costs (KSH)" => "KES #{Decimal.to_string(app.costs)}"
  #       }
  #     end)
  #     |> Enum.map(fn row ->
  #       # 🔄 Ensure final structure follows your custom column order
  #       Enum.into(ordered_keys, %{}, fn key -> {key, Map.get(row, key)} end)
  #     end)

  #   # Write JSON
  #   File.write!(json_path, Jason.encode!(data))

  #   # Run Node
  #   case System.cmd("node", [script_path, json_path, output_path, logo_temp_path]) do
  #     {_, 0} -> File.read(output_path)
  #     {error_msg, _} -> {:error, error_msg}
  #   end
  # end

  alias Elixlsx.{Workbook, Sheet}

  def generate_excel_binary(projections) do
    headers = [
      "ID",
      "Full Name",
      "Personal Number",
      "Designation",
      "Department",
      "Job Group",
      "Ethnicity",
      "Program Title",
      "Institution",
      "Period of Study (Days)",
      "Costs (KSH)"
    ]

    data_rows =
      projections
      |> Enum.sort_by(& &1.id)
      |> Enum.map(fn app ->
        [
          app.id,
          String.capitalize(app.full_name),
          app.personal_number,
          app.designation,
          app.department || "N/A",
          app.job_group || "N/A",
          app.ethnicity.name,
          app.program_title,
          app.institution,
          Ims.Helpers.format_duration(app.period_of_study),
          "KES #{Decimal.to_string(app.costs)}"
        ]
      end)

    rows = [headers | data_rows]
    sheet = %Elixlsx.Sheet{name: "Training Projections", rows: rows}
    workbook = %Elixlsx.Workbook{sheets: [sheet]}

    # ✅ Fix: capture file name and binary
    case Elixlsx.write_to_memory(workbook, "training_projections.xlsx") do
      {:ok, {_filename, binary}} ->
        {:ok, binary}

      error ->
        error
    end
  end

  defp generate_csv(projections) do
    headers = [
      "ID",
      "First Name",
      "Last Name",
      "Personal Number",
      "Designation",
      "Job Group",
      "Department",
      "Course Approved",
      "Institution",
      "Program Title",
      "Financial Year",
      "Quarter",
      "Period of Study (Days)",
      "Costs (KSH)",
      "Memo Reference",
      "Authority Reference",
      "Status"
    ]

    rows =
      projections
      |> Enum.map(fn app ->
        [
          app.id,
          app.user.first_name,
          app.user.last_name,
          app.user.personal_number,
          app.user.designation,
          app.user.job_group_id || "N/A",
          app.user.department.name || "N/A",
          app.course_approved,
          app.institution,
          app.program_title,
          app.financial_year,
          app.quarter,
          app.period_of_study,
          Decimal.to_string(app.costs),
          app.memo_reference,
          app.authority_reference,
          app.status
        ]
      end)

    [headers | rows]
    |> CSV.encode()
    |> Enum.to_list()
    |> IO.iodata_to_binary()
  end

  defp generate_excel_report(projections) do
    headers = [
      "ID",
      "Full Name",
      "Personal Number",
      "Designation",
      "Job Group",
      "Department",
      "Program",
      "Institution",
      "Period of Study (Days)",
      "Costs (KSH)"
    ]

    rows =
      projections
      |> Enum.map(fn app ->
        [
          app.id,
          app.full_name,
          app.user.personal_number,
          app.designation,
          app.job_group || "N/A",
          app.department || "N/A",
          app.program_title,
          app.institution,
          app.period_of_study,
          Decimal.to_string(app.costs)
        ]
      end)

    sheet = %Sheet{name: "Training projections", rows: [headers | rows]}
    workbook = %Workbook{sheets: [sheet]}

    file_path =
      "/tmp/training_projections_report_#{Timex.format!(Timex.now(), "{YYYY}-{0M}-{0D}_{h24}-{m}-{s}")}.xlsx"

    case Elixlsx.write_to(workbook, file_path) do
      {:ok, _} ->
        case File.read(file_path) do
          # ✅ Return binary content
          {:ok, binary_content} -> {:ok, binary_content}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
