defmodule ImsWeb.AssetTypeLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_asset_type(_) do
    asset_type = asset_type_fixture()
    %{asset_type: asset_type}
  end

  describe "Index" do
    setup [:create_asset_type]

    test "lists all asset_types", %{conn: conn, asset_type: asset_type} do
      {:ok, _index_live, html} = live(conn, ~p"/asset_types")

      assert html =~ "Listing Asset types"
      assert html =~ asset_type.name
    end

    test "saves new asset_type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_types")

      assert index_live |> element("a", "New Asset type") |> render_click() =~
               "New Asset type"

      assert_patch(index_live, ~p"/asset_types/new")

      assert index_live
             |> form("#asset_type-form", asset_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_type-form", asset_type: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_types")

      html = render(index_live)
      assert html =~ "Asset type created successfully"
      assert html =~ "some name"
    end

    test "updates asset_type in listing", %{conn: conn, asset_type: asset_type} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_types")

      assert index_live |> element("#asset_types-#{asset_type.id} a", "Edit") |> render_click() =~
               "Edit Asset type"

      assert_patch(index_live, ~p"/asset_types/#{asset_type}/edit")

      assert index_live
             |> form("#asset_type-form", asset_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_type-form", asset_type: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_types")

      html = render(index_live)
      assert html =~ "Asset type updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes asset_type in listing", %{conn: conn, asset_type: asset_type} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_types")

      assert index_live |> element("#asset_types-#{asset_type.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#asset_types-#{asset_type.id}")
    end
  end

  describe "Show" do
    setup [:create_asset_type]

    test "displays asset_type", %{conn: conn, asset_type: asset_type} do
      {:ok, _show_live, html} = live(conn, ~p"/asset_types/#{asset_type}")

      assert html =~ "Show Asset type"
      assert html =~ asset_type.name
    end

    test "updates asset_type within modal", %{conn: conn, asset_type: asset_type} do
      {:ok, show_live, _html} = live(conn, ~p"/asset_types/#{asset_type}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Asset type"

      assert_patch(show_live, ~p"/asset_types/#{asset_type}/show/edit")

      assert show_live
             |> form("#asset_type-form", asset_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#asset_type-form", asset_type: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/asset_types/#{asset_type}")

      html = render(show_live)
      assert html =~ "Asset type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
