defmodule Ims.Accounts.JobGroup do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  schema "job_groups" do
    field :name, :string
    field :description, :string
    belongs_to :created_by, Ims.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job_group, attrs) do
    job_group
    |> cast(attrs, [:name, :description, :created_by_id])
    |> validate_required([:name, :description])
  end

  def search(queryable \\ __MODULE__, filters) do
    Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
      cond do
        v in ["", nil] ->
          accum_query

        k == :name ->
          from(o in accum_query, where: ilike(o.name, ^"%#{v}%"))

        true ->
          accum_query
      end
    end)
  end
end
