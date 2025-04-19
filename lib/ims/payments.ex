defmodule Ims.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Payments.PaymentGateway

  @doc """
  Returns the list of payment_gateways.

  ## Examples

      iex> list_payment_gateways()
      [%PaymentGateway{}, ...]

  """
  def list_payment_gateways do
    Repo.all(PaymentGateway)
  end

  @doc """
  Gets a single payment_gateway.

  Raises `Ecto.NoResultsError` if the Payment gateway does not exist.

  ## Examples

      iex> get_payment_gateway!(123)
      %PaymentGateway{}

      iex> get_payment_gateway!(456)
      ** (Ecto.NoResultsError)

  """
  def get_payment_gateway!(id), do: Repo.get!(PaymentGateway, id)

  @doc """
  Creates a payment_gateway.

  ## Examples

      iex> create_payment_gateway(%{field: value})
      {:ok, %PaymentGateway{}}

      iex> create_payment_gateway(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment_gateway(attrs \\ %{}) do
    %PaymentGateway{}
    |> PaymentGateway.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a payment_gateway.

  ## Examples

      iex> update_payment_gateway(payment_gateway, %{field: new_value})
      {:ok, %PaymentGateway{}}

      iex> update_payment_gateway(payment_gateway, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment_gateway(%PaymentGateway{} = payment_gateway, attrs) do
    payment_gateway
    |> PaymentGateway.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a payment_gateway.

  ## Examples

      iex> delete_payment_gateway(payment_gateway)
      {:ok, %PaymentGateway{}}

      iex> delete_payment_gateway(payment_gateway)
      {:error, %Ecto.Changeset{}}

  """
  def delete_payment_gateway(%PaymentGateway{} = payment_gateway) do
    Repo.delete(payment_gateway)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment_gateway changes.

  ## Examples

      iex> change_payment_gateway(payment_gateway)
      %Ecto.Changeset{data: %PaymentGateway{}}

  """
  def change_payment_gateway(%PaymentGateway{} = payment_gateway, attrs \\ %{}) do
    PaymentGateway.changeset(payment_gateway, attrs)
  end
end
