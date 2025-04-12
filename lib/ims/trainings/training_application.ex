defmodule Ims.Trainings.TrainingApplication do
  use Ecto.Schema
  import Ecto.Changeset

  schema "training_applications" do
    field :status, :string
    field :course_approved, :string
    field :institution, :string
    field :program_title, :string
    field :financial_year, :string
    field :quarter, :string
    field :disability, :boolean, default: false
    field :period_of_study, :string
    field :costs, :decimal
    field :authority_reference, :string
    field :memo_reference, :string
    field :user_id, :id
    field :ethnicity_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_application, attrs) do
    training_application
    |> cast(attrs, [:course_approved, :institution, :program_title, :financial_year, :quarter, :disability, :period_of_study, :costs, :authority_reference, :memo_reference, :status])
    |> validate_required([:course_approved, :institution, :program_title, :financial_year, :quarter, :disability, :period_of_study, :costs, :authority_reference, :memo_reference, :status])
  end
end
