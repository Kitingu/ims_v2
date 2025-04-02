defmodule Ims.Leave.LeaveBalance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leave_balances" do
    field :remaining_days, :integer
    field :user_id, :id
    field :leave_type_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leave_balance, attrs) do
    leave_balance
    |> cast(attrs, [:remaining_days])
    |> validate_required([:remaining_days])
  end
end
