defmodule ImsWeb.AssetLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{status: "some status", tag_number: "some tag_number", serial_number: "some serial_number", original_cost: "120.5", purchase_date: "2025-04-05", warranty_expiry: "2025-04-05", condition: "some condition"}
  @update_attrs %{status: "some updated status", tag_number: "some updated tag_number", serial_number: "some updated serial_number", original_cost: "456.7", purchase_date: "2025-04-06", warranty_expiry: "2025-04-06", condition: "some updated condition"}
  @invalid_attrs %{status: nil, tag_number: nil, serial_number: nil, original_cost: nil, purchase_date: nil, warranty_expiry: nil, condition: nil}

  defp create_asset(_) do
    asset = asset_fixture()
    %{asset: asset}
  end

  describe "Index" do
    setup [:create_asset]

    test "lists all assets", %{conn: conn, asset: asset} do
      {:ok, _index_live, html} = live(conn, ~p"/assets")

      assert html =~ "Listing Assets"
      assert html =~ asset.status
    end

    test "saves new asset", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("a", "New Asset") |> render_click() =~
               "New Asset"

      assert_patch(index_live, ~p"/assets/new")

      assert index_live
             |> form("#asset-form", asset: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset-form", asset: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assets")

      html = render(index_live)
      assert html =~ "Asset created successfully"
      assert html =~ "some status"
    end

    test "updates asset in listing", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("#assets-#{asset.id} a", "Edit") |> render_click() =~
               "Edit Asset"

      assert_patch(index_live, ~p"/assets/#{asset}/edit")

      assert index_live
             |> form("#asset-form", asset: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset-form", asset: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assets")

      html = render(index_live)
      assert html =~ "Asset updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes asset in listing", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("#assets-#{asset.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#assets-#{asset.id}")
    end
  end

  describe "Show" do
    setup [:create_asset]

    test "displays asset", %{conn: conn, asset: asset} do
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      assert html =~ "Show Asset"
      assert html =~ asset.status
    end

    test "updates asset within modal", %{conn: conn, asset: asset} do
      {:ok, show_live, _html} = live(conn, ~p"/assets/#{asset}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Asset"

      assert_patch(show_live, ~p"/assets/#{asset}/show/edit")

      assert show_live
             |> form("#asset-form", asset: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#asset-form", asset: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/assets/#{asset}")

      html = render(show_live)
      assert html =~ "Asset updated successfully"
      assert html =~ "some updated status"
    end
  end
end
