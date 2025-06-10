defmodule Ims.Trainings.TrainingProjections do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

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
      :quarter,
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

end
