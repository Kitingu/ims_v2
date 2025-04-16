defmodule ImsWeb.RequestLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{status: "some status", request_type: "some request_type", assigned_at: "2025-04-15T08:38:00Z"}
  @update_attrs %{status: "some updated status", request_type: "some updated request_type", assigned_at: "2025-04-16T08:38:00Z"}
  @invalid_attrs %{status: nil, request_type: nil, assigned_at: nil}

  defp create_request(_) do
    request = request_fixture()
    %{request: request}
  end

  describe "Index" do
    setup [:create_request]

    test "lists all requests", %{conn: conn, request: request} do
      {:ok, _index_live, html} = live(conn, ~p"/requests")

      assert html =~ "Listing Requests"
      assert html =~ request.status
    end

    test "saves new request", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/requests")

      assert index_live |> element("a", "New Request") |> render_click() =~
               "New Request"

      assert_patch(index_live, ~p"/requests/new")

      assert index_live
             |> form("#request-form", request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#request-form", request: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/requests")

      html = render(index_live)
      assert html =~ "Request created successfully"
      assert html =~ "some status"
    end

    test "updates request in listing", %{conn: conn, request: request} do
      {:ok, index_live, _html} = live(conn, ~p"/requests")

      assert index_live |> element("#requests-#{request.id} a", "Edit") |> render_click() =~
               "Edit Request"

      assert_patch(index_live, ~p"/requests/#{request}/edit")

      assert index_live
             |> form("#request-form", request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#request-form", request: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/requests")

      html = render(index_live)
      assert html =~ "Request updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes request in listing", %{conn: conn, request: request} do
      {:ok, index_live, _html} = live(conn, ~p"/requests")

      assert index_live |> element("#requests-#{request.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#requests-#{request.id}")
    end
  end

  describe "Show" do
    setup [:create_request]

    test "displays request", %{conn: conn, request: request} do
      {:ok, _show_live, html} = live(conn, ~p"/requests/#{request}")

      assert html =~ "Show Request"
      assert html =~ request.status
    end

    test "updates request within modal", %{conn: conn, request: request} do
      {:ok, show_live, _html} = live(conn, ~p"/requests/#{request}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Request"

      assert_patch(show_live, ~p"/requests/#{request}/show/edit")

      assert show_live
             |> form("#request-form", request: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#request-form", request: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/requests/#{request}")

      html = render(show_live)
      assert html =~ "Request updated successfully"
      assert html =~ "some updated status"
    end
  end
end
