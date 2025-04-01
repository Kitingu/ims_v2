defmodule ImsWeb.SettingLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.SettingsFixtures

  @create_attrs %{name: "some name", value: "some value"}
  @update_attrs %{name: "some updated name", value: "some updated value"}
  @invalid_attrs %{name: nil, value: nil}

  defp create_setting(_) do
    setting = setting_fixture()
    %{setting: setting}
  end

  describe "Index" do
    setup [:create_setting]

    test "lists all settings", %{conn: conn, setting: setting} do
      {:ok, _index_live, html} = live(conn, ~p"/settings")

      assert html =~ "Listing Settings"
      assert html =~ setting.name
    end

    test "saves new setting", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/settings")

      assert index_live |> element("a", "New Setting") |> render_click() =~
               "New Setting"

      assert_patch(index_live, ~p"/settings/new")

      assert index_live
             |> form("#setting-form", setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#setting-form", setting: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/settings")

      html = render(index_live)
      assert html =~ "Setting created successfully"
      assert html =~ "some name"
    end

    test "updates setting in listing", %{conn: conn, setting: setting} do
      {:ok, index_live, _html} = live(conn, ~p"/settings")

      assert index_live |> element("#settings-#{setting.id} a", "Edit") |> render_click() =~
               "Edit Setting"

      assert_patch(index_live, ~p"/settings/#{setting}/edit")

      assert index_live
             |> form("#setting-form", setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#setting-form", setting: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/settings")

      html = render(index_live)
      assert html =~ "Setting updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes setting in listing", %{conn: conn, setting: setting} do
      {:ok, index_live, _html} = live(conn, ~p"/settings")

      assert index_live |> element("#settings-#{setting.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#settings-#{setting.id}")
    end
  end

  describe "Show" do
    setup [:create_setting]

    test "displays setting", %{conn: conn, setting: setting} do
      {:ok, _show_live, html} = live(conn, ~p"/settings/#{setting}")

      assert html =~ "Show Setting"
      assert html =~ setting.name
    end

    test "updates setting within modal", %{conn: conn, setting: setting} do
      {:ok, show_live, _html} = live(conn, ~p"/settings/#{setting}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Setting"

      assert_patch(show_live, ~p"/settings/#{setting}/show/edit")

      assert show_live
             |> form("#setting-form", setting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#setting-form", setting: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/settings/#{setting}")

      html = render(show_live)
      assert html =~ "Setting updated successfully"
      assert html =~ "some updated name"
    end
  end
end
