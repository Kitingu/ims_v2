defmodule Ims.Files.File do
  use Ecto.Schema
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo
  import Ecto.Changeset

  schema "files" do
    field :folio_number, :string
    field :subject_matter, :string
    field :ref_no, :string
    # field :current_office_id, :id
    belongs_to :current_office, Ims.Inventory.Office
    belongs_to :user, Ims.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:folio_number, :subject_matter, :ref_no, :current_office_id, :user_id])
    |> validate_required([:folio_number, :subject_matter, :ref_no])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v == nil or v == "" ->
            accum_query

          k == :folio_number ->
            from(f in accum_query, where: ilike(f.folio_number, ^"%#{v}%"))

          k == :subject_matter ->
            from(f in accum_query, where: ilike(f.subject_matter, ^"%#{v}%"))

          k == :ref_no ->
            from(f in accum_query, where: ilike(f.ref_no, ^"%#{v}%"))

          true ->
            accum_query
        end
      end)

    from(f in query, preload: [:user, :current_office])
  end
end
