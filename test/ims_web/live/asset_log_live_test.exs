defmodule ImsWeb.AssetLogLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.InventoryFixtures

  @create_attrs %{status: "some status", action: "some action", remarks: "some remarks", performed_at: "2025-04-05T22:33:00Z", assigned_at: "2025-04-05T22:33:00Z", date_returned: "2025-04-05", evidence: "some evidence", abstract_number: "some abstract_number", police_abstract_photo: "some police_abstract_photo", photo_evidence: "some photo_evidence", revoke_type: "some revoke_type", revoked_until: "2025-04-05"}
  @update_attrs %{status: "some updated status", action: "some updated action", remarks: "some updated remarks", performed_at: "2025-04-06T22:33:00Z", assigned_at: "2025-04-06T22:33:00Z", date_returned: "2025-04-06", evidence: "some updated evidence", abstract_number: "some updated abstract_number", police_abstract_photo: "some updated police_abstract_photo", photo_evidence: "some updated photo_evidence", revoke_type: "some updated revoke_type", revoked_until: "2025-04-06"}
  @invalid_attrs %{status: nil, action: nil, remarks: nil, performed_at: nil, assigned_at: nil, date_returned: nil, evidence: nil, abstract_number: nil, police_abstract_photo: nil, photo_evidence: nil, revoke_type: nil, revoked_until: nil}

  defp create_asset_log(_) do
    asset_log = asset_log_fixture()
    %{asset_log: asset_log}
  end

  describe "Index" do
    setup [:create_asset_log]

    test "lists all asset_logs", %{conn: conn, asset_log: asset_log} do
      {:ok, _index_live, html} = live(conn, ~p"/asset_logs")

      assert html =~ "Listing Asset logs"
      assert html =~ asset_log.status
    end

    test "saves new asset_log", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_logs")

      assert index_live |> element("a", "New Asset log") |> render_click() =~
               "New Asset log"

      assert_patch(index_live, ~p"/asset_logs/new")

      assert index_live
             |> form("#asset_log-form", asset_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_log-form", asset_log: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_logs")

      html = render(index_live)
      assert html =~ "Asset log created successfully"
      assert html =~ "some status"
    end

    test "updates asset_log in listing", %{conn: conn, asset_log: asset_log} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_logs")

      assert index_live |> element("#asset_logs-#{asset_log.id} a", "Edit") |> render_click() =~
               "Edit Asset log"

      assert_patch(index_live, ~p"/asset_logs/#{asset_log}/edit")

      assert index_live
             |> form("#asset_log-form", asset_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset_log-form", asset_log: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/asset_logs")

      html = render(index_live)
      assert html =~ "Asset log updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes asset_log in listing", %{conn: conn, asset_log: asset_log} do
      {:ok, index_live, _html} = live(conn, ~p"/asset_logs")

      assert index_live |> element("#asset_logs-#{asset_log.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#asset_logs-#{asset_log.id}")
    end
  end

  describe "Show" do
    setup [:create_asset_log]

    test "displays asset_log", %{conn: conn, asset_log: asset_log} do
      {:ok, _show_live, html} = live(conn, ~p"/asset_logs/#{asset_log}")

      assert html =~ "Show Asset log"
      assert html =~ asset_log.status
    end

    test "updates asset_log within modal", %{conn: conn, asset_log: asset_log} do
      {:ok, show_live, _html} = live(conn, ~p"/asset_logs/#{asset_log}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Asset log"

      assert_patch(show_live, ~p"/asset_logs/#{asset_log}/show/edit")

      assert show_live
             |> form("#asset_log-form", asset_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#asset_log-form", asset_log: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/asset_logs/#{asset_log}")

      html = render(show_live)
      assert html =~ "Asset log updated successfully"
      assert html =~ "some updated status"
    end
  end
end
