defmodule Ims.Leave.AnnualLeaveEntry do
  use Ecto.Schema

  alias Ims.Leave.LeaveApplication

  schema "annual_leave_entries" do
    field :kind, :string
    field :effective_on, :date
    field :days, :decimal
    field :reason, :string
    field :actor_id, :integer
    field :actor_label, :string
    belongs_to :user, Ims.Accounts.User
    belongs_to :application, LeaveApplication

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
