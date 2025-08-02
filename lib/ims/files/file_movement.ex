defmodule Ims.Files.FileMovement do
  use Ecto.Schema
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo
  import Ecto.Changeset

  schema "file_movements" do
    field :remarks, :string
    # field :file_id, :id
    # field :from_office_id, :id
    # field :to_office_id, :id
    # field :user_id, :id
    belongs_to :file, Ims.Files.File
    belongs_to :from_office_id, Ims.Invetory.Office
    belongs_to :to_office_id, Ims.Invetory.Office
    belongs_to :user, Ims.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file_movement, attrs) do
    file_movement
    |> cast(attrs, [:remarks, :from_office_id, :to_office_id, :user_id])
    |> validate_required([:from_office_id])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v == nil or v == "" ->
            accum_query

          k == :remarks ->
            from(f in accum_query, where: ilike(f.remarks, ^"%#{v}%"))

          k == :from_office_id ->
            from(f in accum_query, where: f.from_office_id == ^v)

          k == :to_office_id ->
            from(f in accum_query, where: f.to_office_id == ^v)

          k == :file_id ->
            from(f in accum_query, where: f.file_id == ^v)

          true ->
            accum_query
        end
      end)

    from(f in query, preload: [:file, :from_office_id, :to_office_id, :user])
  end
end
