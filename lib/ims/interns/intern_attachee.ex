defmodule Ims.Interns.InternAttachee do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo

  schema "intern_attachees" do
    field :duration, :string
    field :email, :string
    field :end_date, :date
    field :id_number, :string
    field :full_name, :string
    field :next_of_kin_name, :string
    field :next_of_kin_phone, :string
    field :phone, :string
    field :program, :string
    field :school, :string
    field :start_date, :date
    belongs_to :department, Ims.Accounts.Departments

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(intern_attachee, attrs) do
    intern_attachee
    |> cast(attrs, [
      :full_name,
      :id_number,
      :department_id,
      :email,
      :phone,
      :school,
      :program,
      :start_date,
      :end_date,
      :duration,
      :next_of_kin_name,
      :next_of_kin_phone
    ])
    |> validate_required([
      :full_name,
      :id_number,
      :email,
      :department_id,
      :phone,
      :school,
      :program,
      :start_date,
      :end_date,
      :duration,
      :next_of_kin_name,
      :next_of_kin_phone
    ])
  end

  def search(queryable \\ __MODULE__, filters) do
    query =
      Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
        cond do
          v in ["", nil] ->
            accum_query

          k == :full_name ->
            from(i in accum_query, where: ilike(i.full_name, ^"%#{v}%"))

          k == :id_number ->
            from(i in accum_query, where: ilike(i.id_number, ^"%#{v}%"))

          k == :email ->
            from(i in accum_query, where: ilike(i.email, ^"%#{v}%"))

          k == :phone ->
            from(i in accum_query, where: ilike(i.phone, ^"%#{v}%"))

          k == :school ->
            from(i in accum_query, where: ilike(i.school, ^"%#{v}%"))

          k == :program ->
            from(i in accum_query, where: ilike(i.program, ^"%#{v}%"))

          k == :department_id ->
            from(i in accum_query, where: i.department_id == ^v)

          true ->
            accum_query
        end
      end)

    #  preload: [:department]
    from(i in query, preload: [:department])
  end
end
