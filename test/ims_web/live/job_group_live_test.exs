defmodule ImsWeb.JobGroupLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.AccountsFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_job_group(_) do
    job_group = job_group_fixture()
    %{job_group: job_group}
  end

  describe "Index" do
    setup [:create_job_group]

    test "lists all job_groups", %{conn: conn, job_group: job_group} do
      {:ok, _index_live, html} = live(conn, ~p"/job_groups")

      assert html =~ "Listing Job groups"
      assert html =~ job_group.name
    end

    test "saves new job_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/job_groups")

      assert index_live |> element("a", "New Job group") |> render_click() =~
               "New Job group"

      assert_patch(index_live, ~p"/job_groups/new")

      assert index_live
             |> form("#job_group-form", job_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_group-form", job_group: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_groups")

      html = render(index_live)
      assert html =~ "Job group created successfully"
      assert html =~ "some name"
    end

    test "updates job_group in listing", %{conn: conn, job_group: job_group} do
      {:ok, index_live, _html} = live(conn, ~p"/job_groups")

      assert index_live |> element("#job_groups-#{job_group.id} a", "Edit") |> render_click() =~
               "Edit Job group"

      assert_patch(index_live, ~p"/job_groups/#{job_group}/edit")

      assert index_live
             |> form("#job_group-form", job_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#job_group-form", job_group: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/job_groups")

      html = render(index_live)
      assert html =~ "Job group updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes job_group in listing", %{conn: conn, job_group: job_group} do
      {:ok, index_live, _html} = live(conn, ~p"/job_groups")

      assert index_live |> element("#job_groups-#{job_group.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#job_groups-#{job_group.id}")
    end
  end

  describe "Show" do
    setup [:create_job_group]

    test "displays job_group", %{conn: conn, job_group: job_group} do
      {:ok, _show_live, html} = live(conn, ~p"/job_groups/#{job_group}")

      assert html =~ "Show Job group"
      assert html =~ job_group.name
    end

    test "updates job_group within modal", %{conn: conn, job_group: job_group} do
      {:ok, show_live, _html} = live(conn, ~p"/job_groups/#{job_group}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Job group"

      assert_patch(show_live, ~p"/job_groups/#{job_group}/show/edit")

      assert show_live
             |> form("#job_group-form", job_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#job_group-form", job_group: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/job_groups/#{job_group}")

      html = render(show_live)
      assert html =~ "Job group updated successfully"
      assert html =~ "some updated name"
    end
  end
end
