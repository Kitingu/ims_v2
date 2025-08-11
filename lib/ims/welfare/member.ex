defmodule Ims.Welfare.Member do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  require Logger
  alias Ims.Welfare.Event


  use Ims.RepoHelpers, repo: Repo

  schema "welfare_members" do
    field :status, :string, default: "active"
    field :eligibility, :boolean, default: false
    belongs_to :user, Ims.Accounts.User
    field :entry_date, :date
    field :exit_date, :date
    field :amount_paid, :decimal, default: 0.0
    field :amount_due, :decimal, default: 0.0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [
      :user_id,
      :eligibility,
      :entry_date,
      :exit_date,
      :amount_paid,
      :amount_due,
      :status
    ])
    |> validate_required([:user_id, :entry_date, :status])
    |> IO.inspect()
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :status ->
            from(m in accum_query, where: ilike(m.status, ^"%#{v}%"))

          k == :user_id ->
            from(m in accum_query, where: m.user_id == ^v)

          true ->
            accum_query
        end
      end)

    # asset_name has a category_id
    from(q in query, preload: [:user])
  end

def check_eligibility(member) do
  # A member is eligible if they have paid for all events' amount payable
  # Loop through all events unless the event is marked as archived

  events =
    from(e in Event,
      where: e.user_id == ^member.user_id and e.status != "archived", # Ensure event is not archived
      select: e
    )
    |> Repo.all()

  # Check eligibility for each event
  eligibility =
    Enum.all?(events, fn event ->
      # Get the total amount paid for this event by the member
      total_paid =
        from(c in Contribution,
          where: c.user_id == ^member.user_id and c.event_id == ^event.id and c.verified == true, # Only count verified contributions
          select: coalesce(sum(c.amount), 0)
        )
        |> Repo.one()

      # Check if the total paid is greater than or equal to the amount_due
      total_paid >= event.amount_due
    end)

  Logger.info("Eligibility: #{eligibility}")

  # Update eligibility in the member record
  member
  |> Ecto.Changeset.change(eligibility: eligibility)
  |> Repo.update!()
end

end
