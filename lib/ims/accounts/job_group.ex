defmodule Ims.Accounts.JobGroup do
  use Ecto.Schema
  import Ecto.Changeset

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
end
