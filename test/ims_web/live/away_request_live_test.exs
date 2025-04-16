defmodule ImsWeb.AwayRequestLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.HRFixtures

  @create_attrs %{reason: "some reason", location: "some location", memo: "some memo", memo_upload: "some memo_upload", days: 42, return_date: "2025-04-15"}
  @update_attrs %{reason: "some updated reason", location: "some updated location", memo: "some updated memo", memo_upload: "some updated memo_upload", days: 43, return_date: "2025-04-16"}
  @invalid_attrs %{reason: nil, location: nil, memo: nil, memo_upload: nil, days: nil, return_date: nil}

  defp create_away_request(_) do
    away_request = away_request_fixture()
    %{away_request: away_request}
  end

  describe "Index" do
    setup [:create_away_request]

    test "lists all away_requests", %{conn: conn, away_request: away_request} do
      {:ok, _index_live, html} = live(conn, ~p"/away_requests")

      assert html =~ "Listing Away requests"
      assert html =~ away_request.reason
    end

    test "saves new away_request", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/away_requests")

      assert index_live |> element("a", "New Away request") |> render_click() =~
               "New Away request"

      assert_patch(index_live, ~p"/away_requests/new")

      assert index_live
             |> form("#away_request-form", away_request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#away_request-form", away_request: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/away_requests")

      html = render(index_live)
      assert html =~ "Away request created successfully"
      assert html =~ "some reason"
    end

    test "updates away_request in listing", %{conn: conn, away_request: away_request} do
      {:ok, index_live, _html} = live(conn, ~p"/away_requests")

      assert index_live |> element("#away_requests-#{away_request.id} a", "Edit") |> render_click() =~
               "Edit Away request"

      assert_patch(index_live, ~p"/away_requests/#{away_request}/edit")

      assert index_live
             |> form("#away_request-form", away_request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#away_request-form", away_request: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/away_requests")

      html = render(index_live)
      assert html =~ "Away request updated successfully"
      assert html =~ "some updated reason"
    end

    test "deletes away_request in listing", %{conn: conn, away_request: away_request} do
      {:ok, index_live, _html} = live(conn, ~p"/away_requests")

      assert index_live |> element("#away_requests-#{away_request.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#away_requests-#{away_request.id}")
    end
  end

  describe "Show" do
    setup [:create_away_request]

    test "displays away_request", %{conn: conn, away_request: away_request} do
      {:ok, _show_live, html} = live(conn, ~p"/away_requests/#{away_request}")

      assert html =~ "Show Away request"
      assert html =~ away_request.reason
    end

    test "updates away_request within modal", %{conn: conn, away_request: away_request} do
      {:ok, show_live, _html} = live(conn, ~p"/away_requests/#{away_request}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Away request"

      assert_patch(show_live, ~p"/away_requests/#{away_request}/show/edit")

      assert show_live
             |> form("#away_request-form", away_request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#away_request-form", away_request: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/away_requests/#{away_request}")

      html = render(show_live)
      assert html =~ "Away request updated successfully"
      assert html =~ "some updated reason"
    end
  end
end
