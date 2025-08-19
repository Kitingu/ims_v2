defmodule Ims.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :actor_type, :string, default: "user"
    field :action, :string
    field :resource_type, :string
    field :resource_id, :string
    field :changes, :map, default: %{}
    field :metadata, :map, default: %{}
    belongs_to :actor, Ims.Accounts.User
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :actor_id,
      :actor_type,
      :action,
      :resource_type,
      :resource_id,
      :changes,
      :metadata
    ])
    |> validate_required([:action, :resource_type])
  end
end
