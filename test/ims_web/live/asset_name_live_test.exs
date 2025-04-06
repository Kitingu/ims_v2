defmodule ImsWeb.AssetNameLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_asset_name(_) do
    asset_name = asset_name_fixture()
    %{asset_name: asset_name}
  end

  describe "Index" do
    setup [:create_asset_name]

    test "lists all asset_names", %{conn: conn, asset_name: asset_name} do
      {:ok, _index_live, html} = live(conn, ~p"/asset_names")

      assert html =~ "Listing Asset names"
      assert html =~ asset_name.name
    end

    test "saves new asset_name", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_names")

      assert index_live |> element("a", "New Asset name") |> render_click() =~
               "New Asset name"

      assert_patch(index_live, ~p"/asset_names/new")

      assert index_live
             |> form("#asset_name-form", asset_name: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_name-form", asset_name: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_names")

      html = render(index_live)
      assert html =~ "Asset name created successfully"
      assert html =~ "some name"
    end

    test "updates asset_name in listing", %{conn: conn, asset_name: asset_name} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_names")

      assert index_live |> element("#asset_names-#{asset_name.id} a", "Edit") |> render_click() =~
               "Edit Asset name"

      assert_patch(index_live, ~p"/asset_names/#{asset_name}/edit")

      assert index_live
             |> form("#asset_name-form", asset_name: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_name-form", asset_name: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_names")

      html = render(index_live)
      assert html =~ "Asset name updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes asset_name in listing", %{conn: conn, asset_name: asset_name} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_names")

      assert index_live |> element("#asset_names-#{asset_name.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#asset_names-#{asset_name.id}")
    end
  end

  describe "Show" do
    setup [:create_asset_name]

    test "displays asset_name", %{conn: conn, asset_name: asset_name} do
      {:ok, _show_live, html} = live(conn, ~p"/asset_names/#{asset_name}")

      assert html =~ "Show Asset name"
      assert html =~ asset_name.name
    end

    test "updates asset_name within modal", %{conn: conn, asset_name: asset_name} do
      {:ok, show_live, _html} = live(conn, ~p"/asset_names/#{asset_name}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Asset name"

      assert_patch(show_live, ~p"/asset_names/#{asset_name}/show/edit")

      assert show_live
             |> form("#asset_name-form", asset_name: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#asset_name-form", asset_name: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/asset_names/#{asset_name}")

      html = render(show_live)
      assert html =~ "Asset name updated successfully"
      assert html =~ "some updated name"
    end
  end
end
