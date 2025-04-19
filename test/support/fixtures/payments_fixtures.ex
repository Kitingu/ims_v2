defmodule Ims.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Payments` context.
  """

  @doc """
  Generate a payment_gateway.
  """
  def payment_gateway_fixture(attrs \\ %{}) do
    {:ok, payment_gateway} =
      attrs
      |> Enum.into(%{
        common_name: "some common_name",
        currency: "some currency",
        identifier: "some identifier",
        identifier_type: "some identifier_type",
        key: "some key",
        label: "some label",
        name: "some name",
        payload: %{},
        payment_instructions: "some payment_instructions",
        secret: "some secret",
        slug: "some slug",
        status: "some status",
        type: "some type",
        validation_rules: %{}
      })
      |> Ims.Payments.create_payment_gateway()

    payment_gateway
  end
end
