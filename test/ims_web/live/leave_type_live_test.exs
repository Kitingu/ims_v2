defmodule ImsWeb.LeaveTypeLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.LeaveFixtures

  @create_attrs %{name: "some name", max_days: 42, carry_forward: true, requires_approval: true}
  @update_attrs %{name: "some updated name", max_days: 43, carry_forward: false, requires_approval: false}
  @invalid_attrs %{name: nil, max_days: nil, carry_forward: false, requires_approval: false}

  defp create_leave_type(_) do
    leave_type = leave_type_fixture()
    %{leave_type: leave_type}
  end

  describe "Index" do
    setup [:create_leave_type]

    test "lists all leave_types", %{conn: conn, leave_type: leave_type} do
      {:ok, _index_live, html} = live(conn, ~p"/leave_types")

      assert html =~ "Listing Leave types"
      assert html =~ leave_type.name
    end

    test "saves new leave_type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_types")

      assert index_live |> element("a", "New Leave type") |> render_click() =~
               "New Leave type"

      assert_patch(index_live, ~p"/leave_types/new")

      assert index_live
             |> form("#leave_type-form", leave_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#leave_type-form", leave_type: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/leave_types")

      html = render(index_live)
      assert html =~ "Leave type created successfully"
      assert html =~ "some name"
    end

    test "updates leave_type in listing", %{conn: conn, leave_type: leave_type} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_types")

      assert index_live |> element("#leave_types-#{leave_type.id} a", "Edit") |> render_click() =~
               "Edit Leave type"

      assert_patch(index_live, ~p"/leave_types/#{leave_type}/edit")

      assert index_live
             |> form("#leave_type-form", leave_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#leave_type-form", leave_type: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/leave_types")

      html = render(index_live)
      assert html =~ "Leave type updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes leave_type in listing", %{conn: conn, leave_type: leave_type} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_types")

      assert index_live |> element("#leave_types-#{leave_type.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#leave_types-#{leave_type.id}")
    end
  end

  describe "Show" do
    setup [:create_leave_type]

    test "displays leave_type", %{conn: conn, leave_type: leave_type} do
      {:ok, _show_live, html} = live(conn, ~p"/leave_types/#{leave_type}")

      assert html =~ "Show Leave type"
      assert html =~ leave_type.name
    end

    test "updates leave_type within modal", %{conn: conn, leave_type: leave_type} do
      {:ok, show_live, _html} = live(conn, ~p"/leave_types/#{leave_type}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Leave type"

      assert_patch(show_live, ~p"/leave_types/#{leave_type}/show/edit")

      assert show_live
             |> form("#leave_type-form", leave_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#leave_type-form", leave_type: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/leave_types/#{leave_type}")

      html = render(show_live)
      assert html =~ "Leave type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
