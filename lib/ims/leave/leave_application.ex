defmodule Ims.Leave.LeaveApplication do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leave_applications" do
    field :status, :string
    field :comment, :string
    field :days_requested, :integer
    field :start_date, :date
    field :end_date, :date
    field :resumption_date, :date
    field :proof_document, :string
    field :user_id, :id
    field :leave_type_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leave_application, attrs) do
    leave_application
    |> cast(attrs, [:days_requested, :status, :comment, :start_date, :end_date, :resumption_date, :proof_document])
    |> validate_required([:days_requested, :status, :comment, :start_date, :end_date, :resumption_date, :proof_document])
  end
end
