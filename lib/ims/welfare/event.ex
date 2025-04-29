defmodule Ims.Welfare.Event do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "events" do
    field :status, :string, default: "active"
    field :description, :string
    field :title, :string
    field :amount_paid, :decimal, default: 0.0
    belongs_to :user, Ims.Accounts.User
    belongs_to :event_type, Ims.Welfare.EventType

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :description, :user_id, :event_type_id, :amount_paid, :status])
    |> validate_required([:title, :description, :event_type_id, :user_id, :amount_paid, :status])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :title ->
            from(a in accum_query, where: ilike(a.title, ^"%#{v}%"))

          k == :description ->
            from(a in accum_query, where: ilike(a.description, ^"%#{v}%"))

          k == :status ->
            from(a in accum_query, where: ilike(a.status, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)

    from(a in query, preload: [:event_type, user: :department])
  end
end
