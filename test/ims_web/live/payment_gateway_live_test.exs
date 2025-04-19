defmodule ImsWeb.PaymentGatewayLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.PaymentsFixtures

  @create_attrs %{label: "some label", name: "some name", status: "some status", type: "some type", currency: "some currency", identifier: "some identifier", key: "some key", payload: %{}, slug: "some slug", identifier_type: "some identifier_type", secret: "some secret", payment_instructions: "some payment_instructions", common_name: "some common_name", validation_rules: %{}}
  @update_attrs %{label: "some updated label", name: "some updated name", status: "some updated status", type: "some updated type", currency: "some updated currency", identifier: "some updated identifier", key: "some updated key", payload: %{}, slug: "some updated slug", identifier_type: "some updated identifier_type", secret: "some updated secret", payment_instructions: "some updated payment_instructions", common_name: "some updated common_name", validation_rules: %{}}
  @invalid_attrs %{label: nil, name: nil, status: nil, type: nil, currency: nil, identifier: nil, key: nil, payload: nil, slug: nil, identifier_type: nil, secret: nil, payment_instructions: nil, common_name: nil, validation_rules: nil}

  defp create_payment_gateway(_) do
    payment_gateway = payment_gateway_fixture()
    %{payment_gateway: payment_gateway}
  end

  describe "Index" do
    setup [:create_payment_gateway]

    test "lists all payment_gateways", %{conn: conn, payment_gateway: payment_gateway} do
      {:ok, _index_live, html} = live(conn, ~p"/payment_gateways")

      assert html =~ "Listing Payment gateways"
      assert html =~ payment_gateway.label
    end

    test "saves new payment_gateway", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_gateways")

      assert index_live |> element("a", "New Payment gateway") |> render_click() =~
               "New Payment gateway"

      assert_patch(index_live, ~p"/payment_gateways/new")

      assert index_live
             |> form("#payment_gateway-form", payment_gateway: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#payment_gateway-form", payment_gateway: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/payment_gateways")

      html = render(index_live)
      assert html =~ "Payment gateway created successfully"
      assert html =~ "some label"
    end

    test "updates payment_gateway in listing", %{conn: conn, payment_gateway: payment_gateway} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_gateways")

      assert index_live |> element("#payment_gateways-#{payment_gateway.id} a", "Edit") |> render_click() =~
               "Edit Payment gateway"

      assert_patch(index_live, ~p"/payment_gateways/#{payment_gateway}/edit")

      assert index_live
             |> form("#payment_gateway-form", payment_gateway: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#payment_gateway-form", payment_gateway: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/payment_gateways")

      html = render(index_live)
      assert html =~ "Payment gateway updated successfully"
      assert html =~ "some updated label"
    end

    test "deletes payment_gateway in listing", %{conn: conn, payment_gateway: payment_gateway} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_gateways")

      assert index_live |> element("#payment_gateways-#{payment_gateway.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#payment_gateways-#{payment_gateway.id}")
    end
  end

  describe "Show" do
    setup [:create_payment_gateway]

    test "displays payment_gateway", %{conn: conn, payment_gateway: payment_gateway} do
      {:ok, _show_live, html} = live(conn, ~p"/payment_gateways/#{payment_gateway}")

      assert html =~ "Show Payment gateway"
      assert html =~ payment_gateway.label
    end

    test "updates payment_gateway within modal", %{conn: conn, payment_gateway: payment_gateway} do
      {:ok, show_live, _html} = live(conn, ~p"/payment_gateways/#{payment_gateway}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Payment gateway"

      assert_patch(show_live, ~p"/payment_gateways/#{payment_gateway}/show/edit")

      assert show_live
             |> form("#payment_gateway-form", payment_gateway: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#payment_gateway-form", payment_gateway: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/payment_gateways/#{payment_gateway}")

      html = render(show_live)
      assert html =~ "Payment gateway updated successfully"
      assert html =~ "some updated label"
    end
  end
end
