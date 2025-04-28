defmodule ImsWeb.InternAttacheeLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InternsFixtures

  @create_attrs %{duration: "some duration", email: "some email", end_date: "2025-04-27", full_name: "some full_name", next_of_kin_name: "some next_of_kin_name", next_of_kin_phone: "some next_of_kin_phone", phone: "some phone", program: "some program", school: "some school", start_date: "2025-04-27"}
  @update_attrs %{duration: "some updated duration", email: "some updated email", end_date: "2025-04-28", full_name: "some updated full_name", next_of_kin_name: "some updated next_of_kin_name", next_of_kin_phone: "some updated next_of_kin_phone", phone: "some updated phone", program: "some updated program", school: "some updated school", start_date: "2025-04-28"}
  @invalid_attrs %{duration: nil, email: nil, end_date: nil, full_name: nil, next_of_kin_name: nil, next_of_kin_phone: nil, phone: nil, program: nil, school: nil, start_date: nil}

  defp create_intern_attachee(_) do
    intern_attachee = intern_attachee_fixture()
    %{intern_attachee: intern_attachee}
  end

  describe "Index" do
    setup [:create_intern_attachee]

    test "lists all intern_attachees", %{conn: conn, intern_attachee: intern_attachee} do
      {:ok, _index_live, html} = live(conn, ~p"/intern_attachees")

      assert html =~ "Listing Intern attachees"
      assert html =~ intern_attachee.duration
    end

    test "saves new intern_attachee", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/intern_attachees")

      assert index_live |> element("a", "New Intern attachee") |> render_click() =~
               "New Intern attachee"

      assert_patch(index_live, ~p"/intern_attachees/new")

      assert index_live
             |> form("#intern_attachee-form", intern_attachee: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#intern_attachee-form", intern_attachee: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/intern_attachees")

      html = render(index_live)
      assert html =~ "Intern attachee created successfully"
      assert html =~ "some duration"
    end

    test "updates intern_attachee in listing", %{conn: conn, intern_attachee: intern_attachee} do
      {:ok, index_live, _html} = live(conn, ~p"/intern_attachees")

      assert index_live |> element("#intern_attachees-#{intern_attachee.id} a", "Edit") |> render_click() =~
               "Edit Intern attachee"

      assert_patch(index_live, ~p"/intern_attachees/#{intern_attachee}/edit")

      assert index_live
             |> form("#intern_attachee-form", intern_attachee: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#intern_attachee-form", intern_attachee: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/intern_attachees")

      html = render(index_live)
      assert html =~ "Intern attachee updated successfully"
      assert html =~ "some updated duration"
    end

    test "deletes intern_attachee in listing", %{conn: conn, intern_attachee: intern_attachee} do
      {:ok, index_live, _html} = live(conn, ~p"/intern_attachees")

      assert index_live |> element("#intern_attachees-#{intern_attachee.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#intern_attachees-#{intern_attachee.id}")
    end
  end

  describe "Show" do
    setup [:create_intern_attachee]

    test "displays intern_attachee", %{conn: conn, intern_attachee: intern_attachee} do
      {:ok, _show_live, html} = live(conn, ~p"/intern_attachees/#{intern_attachee}")

      assert html =~ "Show Intern attachee"
      assert html =~ intern_attachee.duration
    end

    test "updates intern_attachee within modal", %{conn: conn, intern_attachee: intern_attachee} do
      {:ok, show_live, _html} = live(conn, ~p"/intern_attachees/#{intern_attachee}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Intern attachee"

      assert_patch(show_live, ~p"/intern_attachees/#{intern_attachee}/show/edit")

      assert show_live
             |> form("#intern_attachee-form", intern_attachee: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#intern_attachee-form", intern_attachee: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/intern_attachees/#{intern_attachee}")

      html = render(show_live)
      assert html =~ "Intern attachee updated successfully"
      assert html =~ "some updated duration"
    end
  end
end
