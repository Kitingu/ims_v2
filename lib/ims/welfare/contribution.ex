defmodule Ims.Welfare.Contribution do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "contributions" do
    field :amount, :decimal
    field :payment_reference, :string
    # mpesa number
    field :source, :string
    field :verified, :boolean, default: false
    belongs_to :user, Ims.Accounts.User
    belongs_to :event, Ims.Welfare.Event
    belongs_to :payment_gateway, Ims.Payments.PaymentGateway

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(contribution, attrs) do
    contribution
    |> cast(attrs, [:amount, :payment_reference, :event_id, :user_id, :source, :verified])
    |> validate_required([:amount, :payment_reference, :source, :verified])
    |> unique_constraint(:payment_reference)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Ims.Repo.insert()
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :event_id ->
            from(c in accum_query, where: c.event_id == ^v)

          k == :user_id ->
            from(c in accum_query, where: c.user_id == ^v)

          k == :payment_reference ->
            from(c in accum_query, where: ilike(c.payment_reference, ^"%#{v}%"))

          k == :source ->
            from(c in accum_query, where: ilike(c.source, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)

    from(i in query, preload: [:user, :event, :payment_gateway])
  end

  def total_contributions_for_event(event_id) do
    query =
      from c in __MODULE__,
        where: c.event_id == ^event_id and c.verified == true,
        select: sum(c.amount)

    Repo.one(query) || Decimal.new(0)
  end

  # check if member is clean
  # 1 check the date of their first contribution
  # 2 check if they have contributed to all events after the first one



end
