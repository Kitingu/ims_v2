defmodule ImsWeb.DepartmentsLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.AccountsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_departments(_) do
    departments = departments_fixture()
    %{departments: departments}
  end

  describe "Index" do
    setup [:create_departments]

    test "lists all departments", %{conn: conn, departments: departments} do
      {:ok, _index_live, html} = live(conn, ~p"/departments")

      assert html =~ "Listing Departments"
      assert html =~ departments.name
    end

    test "saves new departments", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/departments")

      assert index_live |> element("a", "New Departments") |> render_click() =~
               "New Departments"

      assert_patch(index_live, ~p"/departments/new")

      assert index_live
             |> form("#departments-form", departments: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#departments-form", departments: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/departments")

      html = render(index_live)
      assert html =~ "Departments created successfully"
      assert html =~ "some name"
    end

    test "updates departments in listing", %{conn: conn, departments: departments} do
      {:ok, index_live, _html} = live(conn, ~p"/departments")

      assert index_live |> element("#departments-#{departments.id} a", "Edit") |> render_click() =~
               "Edit Departments"

      assert_patch(index_live, ~p"/departments/#{departments}/edit")

      assert index_live
             |> form("#departments-form", departments: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#departments-form", departments: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/departments")

      html = render(index_live)
      assert html =~ "Departments updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes departments in listing", %{conn: conn, departments: departments} do
      {:ok, index_live, _html} = live(conn, ~p"/departments")

      assert index_live |> element("#departments-#{departments.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#departments-#{departments.id}")
    end
  end

  describe "Show" do
    setup [:create_departments]

    test "displays departments", %{conn: conn, departments: departments} do
      {:ok, _show_live, html} = live(conn, ~p"/departments/#{departments}")

      assert html =~ "Show Departments"
      assert html =~ departments.name
    end

    test "updates departments within modal", %{conn: conn, departments: departments} do
      {:ok, show_live, _html} = live(conn, ~p"/departments/#{departments}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Departments"

      assert_patch(show_live, ~p"/departments/#{departments}/show/edit")

      assert show_live
             |> form("#departments-form", departments: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#departments-form", departments: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/departments/#{departments}")

      html = render(show_live)
      assert html =~ "Departments updated successfully"
      assert html =~ "some updated name"
    end
  end
end
