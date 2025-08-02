defmodule ImsWeb.FileMovementLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.FilesFixtures

  @create_attrs %{remarks: "some remarks"}
  @update_attrs %{remarks: "some updated remarks"}
  @invalid_attrs %{remarks: nil}

  defp create_file_movement(_) do
    file_movement = file_movement_fixture()
    %{file_movement: file_movement}
  end

  describe "Index" do
    setup [:create_file_movement]

    test "lists all file_movements", %{conn: conn, file_movement: file_movement} do
      {:ok, _index_live, html} = live(conn, ~p"/file_movements")

      assert html =~ "Listing File movements"
      assert html =~ file_movement.remarks
    end

    test "saves new file_movement", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/file_movements")

      assert index_live |> element("a", "New File movement") |> render_click() =~
               "New File movement"

      assert_patch(index_live, ~p"/file_movements/new")

      assert index_live
             |> form("#file_movement-form", file_movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#file_movement-form", file_movement: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/file_movements")

      html = render(index_live)
      assert html =~ "File movement created successfully"
      assert html =~ "some remarks"
    end

    test "updates file_movement in listing", %{conn: conn, file_movement: file_movement} do
      {:ok, index_live, _html} = live(conn, ~p"/file_movements")

      assert index_live |> element("#file_movements-#{file_movement.id} a", "Edit") |> render_click() =~
               "Edit File movement"

      assert_patch(index_live, ~p"/file_movements/#{file_movement}/edit")

      assert index_live
             |> form("#file_movement-form", file_movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#file_movement-form", file_movement: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/file_movements")

      html = render(index_live)
      assert html =~ "File movement updated successfully"
      assert html =~ "some updated remarks"
    end

    test "deletes file_movement in listing", %{conn: conn, file_movement: file_movement} do
      {:ok, index_live, _html} = live(conn, ~p"/file_movements")

      assert index_live |> element("#file_movements-#{file_movement.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#file_movements-#{file_movement.id}")
    end
  end

  describe "Show" do
    setup [:create_file_movement]

    test "displays file_movement", %{conn: conn, file_movement: file_movement} do
      {:ok, _show_live, html} = live(conn, ~p"/file_movements/#{file_movement}")

      assert html =~ "Show File movement"
      assert html =~ file_movement.remarks
    end

    test "updates file_movement within modal", %{conn: conn, file_movement: file_movement} do
      {:ok, show_live, _html} = live(conn, ~p"/file_movements/#{file_movement}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit File movement"

      assert_patch(show_live, ~p"/file_movements/#{file_movement}/show/edit")

      assert show_live
             |> form("#file_movement-form", file_movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#file_movement-form", file_movement: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/file_movements/#{file_movement}")

      html = render(show_live)
      assert html =~ "File movement updated successfully"
      assert html =~ "some updated remarks"
    end
  end
end
