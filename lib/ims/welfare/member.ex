defmodule Ims.Welfare.Member do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo
  use Ims.RepoHelpers, repo: Repo


  schema "welfare_members" do
    field :status, :string, default: "active"
    field :eligibility, :boolean, default: true
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
    |> cast(attrs, [:user_id,:eligibility, :entry_date, :exit_date, :amount_paid, :amount_due, :status])
    |> validate_required([:user_id, :entry_date, :status])
    |> IO.inspect()
  end

end
