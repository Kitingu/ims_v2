defmodule Ims.Payments.PaymentGateway do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ims.Repo.Audited, as: Repo
  use Ims.RepoHelpers, repo: Repo

  @timestamps_opts [type: :naive_datetime_usec]

  schema "payment_gateways" do
    field :label, :string
    field :name, :string
    field :status, :string, default: "active"
    field :type, :string
    field :currency, :string
    field :identifier, :string
    field :key, :string
    field :payload, :map
    field :slug, :string
    field :identifier_type, :string
    field :secret, :string
    field :payment_instructions, :string
    field :common_name, :string
    field :validation_rules, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment_gateway, attrs) do
    payment_gateway
    |> cast(attrs, [
      :name,
      :slug,
      :payload,
      :label,
      :type,
      :status,
      :identifier,
      :identifier_type,
      :key,
      :secret,
      :currency,
      :payment_instructions,
      :common_name,
      :validation_rules
    ])
    |> set_slug()
    |> validate_required([:name, :slug])
    |> validate_required([
      :name,
      :slug,
      :type,
      :status,
      :key,
      :secret,
      :currency,
      :payment_instructions,
    ])
    |> set_if_null(:key, &random_bytes(&1, 16))
    |> set_if_null(:secret, &random_bytes(&1, 32))
  end

  defp set_slug(changeset) do
    if name = get_change(changeset, :name) do
      changeset
      |> put_change(:slug, slug_from_name(name))
    else
      changeset
    end
  end

  defp slug_from_name(name) do
    Slugger.slugify_downcase(name)
  end

  defp set_if_null(changeset, field, fun) do
    if get_field(changeset, field) do
      changeset
    else
      put_change(changeset, field, fun.(field))
    end
  end

  defp random_bytes(:r, length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  defp random_bytes(_, length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
  end

  def search(queryable \\ __MODULE__, filters) do
    Enum.reduce(filters, queryable, fn {k, v}, accum_query ->
      cond do
        v in ["", nil] ->
          accum_query

        k == :name ->
          from(pg in accum_query, where: ilike(pg.name, ^"%#{v}%"))

        true ->
          accum_query
      end
    end)
  end
end
