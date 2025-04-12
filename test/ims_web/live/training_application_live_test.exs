defmodule ImsWeb.TrainingApplicationLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.TrainingsFixtures

  @create_attrs %{status: "some status", course_approved: "some course_approved", institution: "some institution", program_title: "some program_title", financial_year: "some financial_year", quarter: "some quarter", disability: true, period_of_study: "some period_of_study", costs: "120.5", authority_reference: "some authority_reference", memo_reference: "some memo_reference"}
  @update_attrs %{status: "some updated status", course_approved: "some updated course_approved", institution: "some updated institution", program_title: "some updated program_title", financial_year: "some updated financial_year", quarter: "some updated quarter", disability: false, period_of_study: "some updated period_of_study", costs: "456.7", authority_reference: "some updated authority_reference", memo_reference: "some updated memo_reference"}
  @invalid_attrs %{status: nil, course_approved: nil, institution: nil, program_title: nil, financial_year: nil, quarter: nil, disability: false, period_of_study: nil, costs: nil, authority_reference: nil, memo_reference: nil}

  defp create_training_application(_) do
    training_application = training_application_fixture()
    %{training_application: training_application}
  end

  describe "Index" do
    setup [:create_training_application]

    test "lists all training_applications", %{conn: conn, training_application: training_application} do
      {:ok, _index_live, html} = live(conn, ~p"/training_applications")

      assert html =~ "Listing Training applications"
      assert html =~ training_application.status
    end

    test "saves new training_application", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/training_applications")

      assert index_live |> element("a", "New Training application") |> render_click() =~
               "New Training application"

      assert_patch(index_live, ~p"/training_applications/new")

      assert index_live
             |> form("#training_application-form", training_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#training_application-form", training_application: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/training_applications")

      html = render(index_live)
      assert html =~ "Training application created successfully"
      assert html =~ "some status"
    end

    test "updates training_application in listing", %{conn: conn, training_application: training_application} do
      {:ok, index_live, _html} = live(conn, ~p"/training_applications")

      assert index_live |> element("#training_applications-#{training_application.id} a", "Edit") |> render_click() =~
               "Edit Training application"

      assert_patch(index_live, ~p"/training_applications/#{training_application}/edit")

      assert index_live
             |> form("#training_application-form", training_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#training_application-form", training_application: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/training_applications")

      html = render(index_live)
      assert html =~ "Training application updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes training_application in listing", %{conn: conn, training_application: training_application} do
      {:ok, index_live, _html} = live(conn, ~p"/training_applications")

      assert index_live |> element("#training_applications-#{training_application.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#training_applications-#{training_application.id}")
    end
  end

  describe "Show" do
    setup [:create_training_application]

    test "displays training_application", %{conn: conn, training_application: training_application} do
      {:ok, _show_live, html} = live(conn, ~p"/training_applications/#{training_application}")

      assert html =~ "Show Training application"
      assert html =~ training_application.status
    end

    test "updates training_application within modal", %{conn: conn, training_application: training_application} do
      {:ok, show_live, _html} = live(conn, ~p"/training_applications/#{training_application}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Training application"

      assert_patch(show_live, ~p"/training_applications/#{training_application}/show/edit")

      assert show_live
             |> form("#training_application-form", training_application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#training_application-form", training_application: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/training_applications/#{training_application}")

      html = render(show_live)
      assert html =~ "Training application updated successfully"
      assert html =~ "some updated status"
    end
  end
end
