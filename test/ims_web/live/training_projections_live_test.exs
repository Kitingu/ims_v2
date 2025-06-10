defmodule ImsWeb.TrainingProjectionsLiveTest do
  use ImsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ims.TrainingsFixtures

  @create_attrs %{costs: "120.5", department: "some department", designation: "some designation", disability: true, financial_year: "some financial_year", full_name: "some full_name", gender: "some gender", institution: "some institution", job_group: "some job_group", period_of_study: "some period_of_study", personal_number: "some personal_number", program_title: "some program_title", qualification: "some qualification", quarter: "some quarter", status: "some status"}
  @update_attrs %{costs: "456.7", department: "some updated department", designation: "some updated designation", disability: false, financial_year: "some updated financial_year", full_name: "some updated full_name", gender: "some updated gender", institution: "some updated institution", job_group: "some updated job_group", period_of_study: "some updated period_of_study", personal_number: "some updated personal_number", program_title: "some updated program_title", qualification: "some updated qualification", quarter: "some updated quarter", status: "some updated status"}
  @invalid_attrs %{costs: nil, department: nil, designation: nil, disability: false, financial_year: nil, full_name: nil, gender: nil, institution: nil, job_group: nil, period_of_study: nil, personal_number: nil, program_title: nil, qualification: nil, quarter: nil, status: nil}

  defp create_training_projections(_) do
    training_projections = training_projections_fixture()
    %{training_projections: training_projections}
  end

  describe "Index" do
    setup [:create_training_projections]

    test "lists all training_projections", %{conn: conn, training_projections: training_projections} do
      {:ok, _index_live, html} = live(conn, ~p"/training_projections")

      assert html =~ "Listing Training projections"
      assert html =~ training_projections.department
    end

    test "saves new training_projections", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/training_projections")

      assert index_live |> element("a", "New Training projections") |> render_click() =~
               "New Training projections"

      assert_patch(index_live, ~p"/training_projections/new")

      assert index_live
             |> form("#training_projections-form", training_projections: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#training_projections-form", training_projections: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/training_projections")

      html = render(index_live)
      assert html =~ "Training projections created successfully"
      assert html =~ "some department"
    end

    test "updates training_projections in listing", %{conn: conn, training_projections: training_projections} do
      {:ok, index_live, _html} = live(conn, ~p"/training_projections")

      assert index_live |> element("#training_projections-#{training_projections.id} a", "Edit") |> render_click() =~
               "Edit Training projections"

      assert_patch(index_live, ~p"/training_projections/#{training_projections}/edit")

      assert index_live
             |> form("#training_projections-form", training_projections: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#training_projections-form", training_projections: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/training_projections")

      html = render(index_live)
      assert html =~ "Training projections updated successfully"
      assert html =~ "some updated department"
    end

    test "deletes training_projections in listing", %{conn: conn, training_projections: training_projections} do
      {:ok, index_live, _html} = live(conn, ~p"/training_projections")

      assert index_live |> element("#training_projections-#{training_projections.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#training_projections-#{training_projections.id}")
    end
  end

  describe "Show" do
    setup [:create_training_projections]

    test "displays training_projections", %{conn: conn, training_projections: training_projections} do
      {:ok, _show_live, html} = live(conn, ~p"/training_projections/#{training_projections}")

      assert html =~ "Show Training projections"
      assert html =~ training_projections.department
    end

    test "updates training_projections within modal", %{conn: conn, training_projections: training_projections} do
      {:ok, show_live, _html} = live(conn, ~p"/training_projections/#{training_projections}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Training projections"

      assert_patch(show_live, ~p"/training_projections/#{training_projections}/show/edit")

      assert show_live
             |> form("#training_projections-form", training_projections: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#training_projections-form", training_projections: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/training_projections/#{training_projections}")

      html = render(show_live)
      assert html =~ "Training projections updated successfully"
      assert html =~ "some updated department"
    end
  end
end
