defmodule ImsWeb.EventTypeLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.WelfareFixtures

  @create_attrs %{name: "some name", amount: 42}
  @update_attrs %{name: "some updated name", amount: 43}
  @invalid_attrs %{name: nil, amount: nil}

  defp create_event_type(_) do
    event_type = event_type_fixture()
    %{event_type: event_type}
  end

  describe "Index" do
    setup [:create_event_type]

    test "lists all event_types", %{conn: conn, event_type: event_type} do
      {:ok, _index_live, html} = live(conn, ~p"/event_types")

      assert html =~ "Listing Event types"
      assert html =~ event_type.name
    end

    test "saves new event_type", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/event_types")

      assert index_live |> element("a", "New Event type") |> render_click() =~
               "New Event type"

      assert_patch(index_live, ~p"/event_types/new")

      assert index_live
             |> form("#event_type-form", event_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event_type-form", event_type: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/event_types")

      html = render(index_live)
      assert html =~ "Event type created successfully"
      assert html =~ "some name"
    end

    test "updates event_type in listing", %{conn: conn, event_type: event_type} do
      {:ok, index_live, _html} = live(conn, ~p"/event_types")

      assert index_live |> element("#event_types-#{event_type.id} a", "Edit") |> render_click() =~
               "Edit Event type"

      assert_patch(index_live, ~p"/event_types/#{event_type}/edit")

      assert index_live
             |> form("#event_type-form", event_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event_type-form", event_type: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/event_types")

      html = render(index_live)
      assert html =~ "Event type updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes event_type in listing", %{conn: conn, event_type: event_type} do
      {:ok, index_live, _html} = live(conn, ~p"/event_types")

      assert index_live |> element("#event_types-#{event_type.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#event_types-#{event_type.id}")
    end
  end

  describe "Show" do
    setup [:create_event_type]

    test "displays event_type", %{conn: conn, event_type: event_type} do
      {:ok, _show_live, html} = live(conn, ~p"/event_types/#{event_type}")

      assert html =~ "Show Event type"
      assert html =~ event_type.name
    end

    test "updates event_type within modal", %{conn: conn, event_type: event_type} do
      {:ok, show_live, _html} = live(conn, ~p"/event_types/#{event_type}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Event type"

      assert_patch(show_live, ~p"/event_types/#{event_type}/show/edit")

      assert show_live
             |> form("#event_type-form", event_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#event_type-form", event_type: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/event_types/#{event_type}")

      html = render(show_live)
      assert html =~ "Event type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
