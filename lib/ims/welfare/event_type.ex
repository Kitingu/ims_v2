defmodule Ims.Welfare.EventType do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  schema "event_types" do
    field :name, :string
    field :amount, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_type, attrs) do
    event_type
    |> cast(attrs, [:name, :amount])
    |> validate_required([:name, :amount])
    # |> validate_number(:amount, greater_than_or_equal_to: 1)
    |> unique_constraint(:name)
  end

  def search(queryable \\ __MODULE__, filters) do
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :name ->
            from(a in accum_query, where: ilike(a.name, ^"%#{v}%"))

          k == :amount ->
            from(a in accum_query, where: ilike(a.amount, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)
  end
end
