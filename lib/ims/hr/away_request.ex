defmodule Ims.HR.AwayRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "away_requests" do
    field :reason, :string
    field :location, :string
    field :memo, :string
    field :memo_upload, :string
    field :days, :integer
    field :return_date, :date
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(away_request, attrs) do
    away_request
    |> cast(attrs, [:reason, :location, :memo, :memo_upload, :days, :return_date])
    |> validate_required([:reason, :location, :memo, :memo_upload, :days, :return_date])
  end
end
