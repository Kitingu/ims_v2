defmodule ImsWeb.OfficeLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{name: "some name", floor: "some floor", building: "some building", door_name: "some door_name"}
  @update_attrs %{name: "some updated name", floor: "some updated floor", building: "some updated building", door_name: "some updated door_name"}
  @invalid_attrs %{name: nil, floor: nil, building: nil, door_name: nil}

  defp create_office(_) do
    office = office_fixture()
    %{office: office}
  end

  describe "Index" do
    setup [:create_office]

    test "lists all offices", %{conn: conn, office: office} do
      {:ok, _index_live, html} = live(conn, ~p"/offices")

      assert html =~ "Listing Offices"
      assert html =~ office.name
    end

    test "saves new office", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/offices")

      assert index_live |> element("a", "New Office") |> render_click() =~
               "New Office"

      assert_patch(index_live, ~p"/offices/new")

      assert index_live
             |> form("#office-form", office: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#office-form", office: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/offices")

      html = render(index_live)
      assert html =~ "Office created successfully"
      assert html =~ "some name"
    end

    test "updates office in listing", %{conn: conn, office: office} do
      {:ok, index_live, _html} = live(conn, ~p"/offices")

      assert index_live |> element("#offices-#{office.id} a", "Edit") |> render_click() =~
               "Edit Office"

      assert_patch(index_live, ~p"/offices/#{office}/edit")

      assert index_live
             |> form("#office-form", office: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#office-form", office: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/offices")

      html = render(index_live)
      assert html =~ "Office updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes office in listing", %{conn: conn, office: office} do
      {:ok, index_live, _html} = live(conn, ~p"/offices")

      assert index_live |> element("#offices-#{office.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#offices-#{office.id}")
    end
  end

  describe "Show" do
    setup [:create_office]

    test "displays office", %{conn: conn, office: office} do
      {:ok, _show_live, html} = live(conn, ~p"/offices/#{office}")

      assert html =~ "Show Office"
      assert html =~ office.name
    end

    test "updates office within modal", %{conn: conn, office: office} do
      {:ok, show_live, _html} = live(conn, ~p"/offices/#{office}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Office"

      assert_patch(show_live, ~p"/offices/#{office}/show/edit")

      assert show_live
             |> form("#office-form", office: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#office-form", office: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/offices/#{office}")

      html = render(show_live)
      assert html =~ "Office updated successfully"
      assert html =~ "some updated name"
    end
  end
end
