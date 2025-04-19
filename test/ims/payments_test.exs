defmodule Ims.PaymentsTest do
  use Ims.DataCase

  alias Ims.Payments

  describe "payment_gateways" do
    alias Ims.Payments.PaymentGateway

    import Ims.PaymentsFixtures

    @invalid_attrs %{label: nil, name: nil, status: nil, type: nil, currency: nil, identifier: nil, key: nil, payload: nil, slug: nil, identifier_type: nil, secret: nil, payment_instructions: nil, common_name: nil, validation_rules: nil}

    test "list_payment_gateways/0 returns all payment_gateways" do
      payment_gateway = payment_gateway_fixture()
      assert Payments.list_payment_gateways() == [payment_gateway]
    end

    test "get_payment_gateway!/1 returns the payment_gateway with given id" do
      payment_gateway = payment_gateway_fixture()
      assert Payments.get_payment_gateway!(payment_gateway.id) == payment_gateway
    end

    test "create_payment_gateway/1 with valid data creates a payment_gateway" do
      valid_attrs = %{label: "some label", name: "some name", status: "some status", type: "some type", currency: "some currency", identifier: "some identifier", key: "some key", payload: %{}, slug: "some slug", identifier_type: "some identifier_type", secret: "some secret", payment_instructions: "some payment_instructions", common_name: "some common_name", validation_rules: %{}}

      assert {:ok, %PaymentGateway{} = payment_gateway} = Payments.create_payment_gateway(valid_attrs)
      assert payment_gateway.label == "some label"
      assert payment_gateway.name == "some name"
      assert payment_gateway.status == "some status"
      assert payment_gateway.type == "some type"
      assert payment_gateway.currency == "some currency"
      assert payment_gateway.identifier == "some identifier"
      assert payment_gateway.key == "some key"
      assert payment_gateway.payload == %{}
      assert payment_gateway.slug == "some slug"
      assert payment_gateway.identifier_type == "some identifier_type"
      assert payment_gateway.secret == "some secret"
      assert payment_gateway.payment_instructions == "some payment_instructions"
      assert payment_gateway.common_name == "some common_name"
      assert payment_gateway.validation_rules == %{}
    end

    test "create_payment_gateway/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_payment_gateway(@invalid_attrs)
    end

    test "update_payment_gateway/2 with valid data updates the payment_gateway" do
      payment_gateway = payment_gateway_fixture()
      update_attrs = %{label: "some updated label", name: "some updated name", status: "some updated status", type: "some updated type", currency: "some updated currency", identifier: "some updated identifier", key: "some updated key", payload: %{}, slug: "some updated slug", identifier_type: "some updated identifier_type", secret: "some updated secret", payment_instructions: "some updated payment_instructions", common_name: "some updated common_name", validation_rules: %{}}

      assert {:ok, %PaymentGateway{} = payment_gateway} = Payments.update_payment_gateway(payment_gateway, update_attrs)
      assert payment_gateway.label == "some updated label"
      assert payment_gateway.name == "some updated name"
      assert payment_gateway.status == "some updated status"
      assert payment_gateway.type == "some updated type"
      assert payment_gateway.currency == "some updated currency"
      assert payment_gateway.identifier == "some updated identifier"
      assert payment_gateway.key == "some updated key"
      assert payment_gateway.payload == %{}
      assert payment_gateway.slug == "some updated slug"
      assert payment_gateway.identifier_type == "some updated identifier_type"
      assert payment_gateway.secret == "some updated secret"
      assert payment_gateway.payment_instructions == "some updated payment_instructions"
      assert payment_gateway.common_name == "some updated common_name"
      assert payment_gateway.validation_rules == %{}
    end

    test "update_payment_gateway/2 with invalid data returns error changeset" do
      payment_gateway = payment_gateway_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_payment_gateway(payment_gateway, @invalid_attrs)
      assert payment_gateway == Payments.get_payment_gateway!(payment_gateway.id)
    end

    test "delete_payment_gateway/1 deletes the payment_gateway" do
      payment_gateway = payment_gateway_fixture()
      assert {:ok, %PaymentGateway{}} = Payments.delete_payment_gateway(payment_gateway)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_payment_gateway!(payment_gateway.id) end
    end

    test "change_payment_gateway/1 returns a payment_gateway changeset" do
      payment_gateway = payment_gateway_fixture()
      assert %Ecto.Changeset{} = Payments.change_payment_gateway(payment_gateway)
    end
  end
end
