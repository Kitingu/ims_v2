defmodule Ims.HR.AwayRequest do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

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

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :reason ->
            from(a in accum_query, where: ilike(a.reason, ^"%#{v}%"))

          k == :location ->
            from(a in accum_query, where: ilike(a.location, ^"%#{v}%"))

          k == :memo ->
            from(a in accum_query, where: ilike(a.memo, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)
  end
end
