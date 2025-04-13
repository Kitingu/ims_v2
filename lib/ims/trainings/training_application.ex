defmodule Ims.Trainings.TrainingApplication do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  alias Elixlsx.{Workbook, Sheet}

  schema "training_applications" do
    field :authority_reference, :string
    field :costs, :decimal
    field :course_approved, :string
    field :disability, :boolean, default: false
    field :financial_year, :string
    field :institution, :string
    field :memo_reference, :string
    # Stored in days
    field :period_of_study, :integer
    field :program_title, :string
    field :quarter, :string
    field :status, :string, default: "Pending"
    field :disability_details, :string

    belongs_to :user, Ims.Accounts.User
    belongs_to :ethnicity, Ims.Demographics.Ethnicity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_application, attrs) do
    training_application
    |> cast(attrs, [
      :course_approved,
      :user_id,
      :ethnicity_id,
      :institution,
      :program_title,
      :financial_year,
      :quarter,
      :disability,
      :period_of_study,
      :costs,
      :authority_reference,
      :memo_reference,
      :status,
      :disability_details
    ])
    |> transform_period_of_study()
    |> validate_number(:period_of_study,
      greater_than: 0,
      less_than_or_equal_to: 1825,
      message: "Must be between 1 day and 5 years"
    )
    |> validate_required([
      :course_approved,
      :user_id,
      :ethnicity_id,
      :institution,
      :program_title,
      :financial_year,
      :quarter,
      :period_of_study,
      :costs,
      :authority_reference,
      :memo_reference,
      :status
    ])
    |> assoc_constraint(:user)
    |> assoc_constraint(:ethnicity)
  end

  # ✅ Convert "5_days" into integer 5
  defp transform_period_of_study(changeset) do
    case get_field(changeset, :period_of_study) do
      nil ->
        changeset

      value when is_binary(value) ->
        put_change(changeset, :period_of_study, convert_period_to_days(value))

      _ ->
        changeset
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

  # ✅ Search Functionality
  def search(filters) do
    query =
      from q in __MODULE__,
        preload: [:user, user: [:department]]

    filters
    |> Enum.reduce(query, fn {k, v}, query ->
      case {k, v} do
        # Skip empty filters
        {_, ""} -> query
        {"status", v} -> from q in query, where: q.status == ^v
        {"institution", v} -> from q in query, where: ilike(q.institution, ^"%#{v}%")
        {"program_title", v} -> from q in query, where: ilike(q.program_title, ^"%#{v}%")
        {"user_id", v} -> from q in query, where: q.user_id == ^String.to_integer(v)
        _ -> query
      end
    end)
    |> Repo.all()
  end

  # ✅ Export to CSV & Excel
  def generate_report(format \\ :csv, filters \\ %{}) do
    applications = search(filters)

    case format do
      :csv -> generate_csv(applications)
      :excel -> generate_excel_report(applications)
      _ -> {:error, "Unsupported format"}
    end
  end

  # ✅ Generate CSV Report
  defp generate_csv(applications) do
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
      applications
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

  # ✅ Generate Excel Report
  defp generate_excel_report(applications) do
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
      applications
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

    sheet = %Sheet{name: "Training Applications", rows: [headers | rows]}
    workbook = %Workbook{sheets: [sheet]}

    file_path =
      "/tmp/training_applications_report_#{Timex.format!(Timex.now(), "{YYYY}-{0M}-{0D}_{h24}-{m}-{s}")}.xlsx"

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
