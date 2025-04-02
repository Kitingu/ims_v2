defmodule ImsWeb.LeaveApplicationLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.LeaveFixtures

  @create_attrs %{status: "some status", comment: "some comment", days_requested: 42, start_date: "2025-04-01", end_date: "2025-04-01", resumption_date: "2025-04-01", proof_document: "some proof_document"}
  @update_attrs %{status: "some updated status", comment: "some updated comment", days_requested: 43, start_date: "2025-04-02", end_date: "2025-04-02", resumption_date: "2025-04-02", proof_document: "some updated proof_document"}
  @invalid_attrs %{status: nil, comment: nil, days_requested: nil, start_date: nil, end_date: nil, resumption_date: nil, proof_document: nil}

  defp create_leave_application(_) do
    leave_application = leave_application_fixture()
    %{leave_application: leave_application}
  end

  describe "Index" do
    setup [:create_leave_application]

    test "lists all leave_applications", %{conn: conn, leave_application: leave_application} do
      {:ok, _index_live, html} = live(conn, ~p"/leave_applications")

      assert html =~ "Listing Leave applications"
      assert html =~ leave_application.status
    end

    test "saves new leave_application", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_applications")

      assert index_live |> element("a", "New Leave application") |> render_click() =~
               "New Leave application"

      assert_patch(index_live, ~p"/leave_applications/new")

      assert index_live
             |> form("#leave_application-form", leave_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#leave_application-form", leave_application: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/leave_applications")

      html = render(index_live)
      assert html =~ "Leave application created successfully"
      assert html =~ "some status"
    end

    test "updates leave_application in listing", %{conn: conn, leave_application: leave_application} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_applications")

      assert index_live |> element("#leave_applications-#{leave_application.id} a", "Edit") |> render_click() =~
               "Edit Leave application"

      assert_patch(index_live, ~p"/leave_applications/#{leave_application}/edit")

      assert index_live
             |> form("#leave_application-form", leave_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#leave_application-form", leave_application: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/leave_applications")

      html = render(index_live)
      assert html =~ "Leave application updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes leave_application in listing", %{conn: conn, leave_application: leave_application} do
      {:ok, index_live, _html} = live(conn, ~p"/leave_applications")

      assert index_live |> element("#leave_applications-#{leave_application.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#leave_applications-#{leave_application.id}")
    end
  end

  describe "Show" do
    setup [:create_leave_application]

    test "displays leave_application", %{conn: conn, leave_application: leave_application} do
      {:ok, _show_live, html} = live(conn, ~p"/leave_applications/#{leave_application}")

      assert html =~ "Show Leave application"
      assert html =~ leave_application.status
    end

    test "updates leave_application within modal", %{conn: conn, leave_application: leave_application} do
      {:ok, show_live, _html} = live(conn, ~p"/leave_applications/#{leave_application}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Leave application"

      assert_patch(show_live, ~p"/leave_applications/#{leave_application}/show/edit")

      assert show_live
             |> form("#leave_application-form", leave_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#leave_application-form", leave_application: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/leave_applications/#{leave_application}")

      html = render(show_live)
      assert html =~ "Leave application updated successfully"
      assert html =~ "some updated status"
    end
  end
end
