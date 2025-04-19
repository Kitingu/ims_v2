defmodule Ims.Inventory.Request do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "requests" do
    field :status, :string, default: "pending"
    field :request_type, :string
    field :assigned_at, :utc_datetime
    belongs_to :user, Ims.Accounts.User
    belongs_to :actioned_by, Ims.Accounts.User
    field :actioned_at, :utc_datetime
    belongs_to :category, Ims.Inventory.Category

    field :asset_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :status,
      :request_type,
      :assigned_at,
      :user_id,
      :actioned_by_id,
      :category_id,
      :asset_id,
      :actioned_at
    ])
    |> validate_required([:status, :request_type, :user_id, :category_id])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "pending_requisition"])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in [nil, ""] -> accum_query
          k == "status" -> from r in accum_query, where: r.status == ^v
          k == "category_id" -> from r in accum_query, where: r.category_id == ^v
          k == "user_id" -> from r in accum_query, where: r.user_id == ^v
          k == "assigned_at" -> from r in accum_query, where: r.assigned_at == ^v
          true -> accum_query
        end
      end)

    from(r in query, preload: [:category, :user])
  end
end
