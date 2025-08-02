defmodule Ims.Leave.LeaveType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leave_types" do
    field :name, :string
    field :max_days, :integer
    field :carry_forward, :boolean, default: false
    field :requires_approval, :boolean, default: false
    field :default_days, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leave_type, attrs) do
    leave_type
    |> cast(attrs, [:name, :max_days, :carry_forward, :requires_approval])
    |> validate_required([:name, :max_days, :carry_forward, :requires_approval])
    |> unique_constraint(:name)
  end
end
