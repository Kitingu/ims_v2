defmodule Ims.TrainingsTest do
  use Ims.DataCase

  alias Ims.Trainings

  describe "training_applications" do
    alias Ims.Trainings.TrainingApplication

    import Ims.TrainingsFixtures

    @invalid_attrs %{status: nil, course_approved: nil, institution: nil, program_title: nil, financial_year: nil, quarter: nil, disability: nil, period_of_study: nil, costs: nil, authority_reference: nil, memo_reference: nil}

    test "list_training_applications/0 returns all training_applications" do
      training_application = training_application_fixture()
      assert Trainings.list_training_applications() == [training_application]
    end

    test "get_training_application!/1 returns the training_application with given id" do
      training_application = training_application_fixture()
      assert Trainings.get_training_application!(training_application.id) == training_application
    end

    test "create_training_application/1 with valid data creates a training_application" do
      valid_attrs = %{status: "some status", course_approved: "some course_approved", institution: "some institution", program_title: "some program_title", financial_year: "some financial_year", quarter: "some quarter", disability: true, period_of_study: "some period_of_study", costs: "120.5", authority_reference: "some authority_reference", memo_reference: "some memo_reference"}

      assert {:ok, %TrainingApplication{} = training_application} = Trainings.create_training_application(valid_attrs)
      assert training_application.status == "some status"
      assert training_application.course_approved == "some course_approved"
      assert training_application.institution == "some institution"
      assert training_application.program_title == "some program_title"
      assert training_application.financial_year == "some financial_year"
      assert training_application.quarter == "some quarter"
      assert training_application.disability == true
      assert training_application.period_of_study == "some period_of_study"
      assert training_application.costs == Decimal.new("120.5")
      assert training_application.authority_reference == "some authority_reference"
      assert training_application.memo_reference == "some memo_reference"
    end

    test "create_training_application/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trainings.create_training_application(@invalid_attrs)
    end

    test "update_training_application/2 with valid data updates the training_application" do
      training_application = training_application_fixture()
      update_attrs = %{status: "some updated status", course_approved: "some updated course_approved", institution: "some updated institution", program_title: "some updated program_title", financial_year: "some updated financial_year", quarter: "some updated quarter", disability: false, period_of_study: "some updated period_of_study", costs: "456.7", authority_reference: "some updated authority_reference", memo_reference: "some updated memo_reference"}

      assert {:ok, %TrainingApplication{} = training_application} = Trainings.update_training_application(training_application, update_attrs)
      assert training_application.status == "some updated status"
      assert training_application.course_approved == "some updated course_approved"
      assert training_application.institution == "some updated institution"
      assert training_application.program_title == "some updated program_title"
      assert training_application.financial_year == "some updated financial_year"
      assert training_application.quarter == "some updated quarter"
      assert training_application.disability == false
      assert training_application.period_of_study == "some updated period_of_study"
      assert training_application.costs == Decimal.new("456.7")
      assert training_application.authority_reference == "some updated authority_reference"
      assert training_application.memo_reference == "some updated memo_reference"
    end

    test "update_training_application/2 with invalid data returns error changeset" do
      training_application = training_application_fixture()
      assert {:error, %Ecto.Changeset{}} = Trainings.update_training_application(training_application, @invalid_attrs)
      assert training_application == Trainings.get_training_application!(training_application.id)
    end

    test "delete_training_application/1 deletes the training_application" do
      training_application = training_application_fixture()
      assert {:ok, %TrainingApplication{}} = Trainings.delete_training_application(training_application)
      assert_raise Ecto.NoResultsError, fn -> Trainings.get_training_application!(training_application.id) end
    end

    test "change_training_application/1 returns a training_application changeset" do
      training_application = training_application_fixture()
      assert %Ecto.Changeset{} = Trainings.change_training_application(training_application)
    end
  end

  describe "training_projections" do
    alias Ims.Trainings.TrainingProjections

    import Ims.TrainingsFixtures

    @invalid_attrs %{costs: nil, department: nil, designation: nil, disability: nil, financial_year: nil, full_name: nil, gender: nil, institution: nil, job_group: nil, period_of_study: nil, personal_number: nil, program_title: nil, qualification: nil, quarter: nil, status: nil}

    test "list_training_projections/0 returns all training_projections" do
      training_projections = training_projections_fixture()
      assert Trainings.list_training_projections() == [training_projections]
    end

    test "get_training_projections!/1 returns the training_projections with given id" do
      training_projections = training_projections_fixture()
      assert Trainings.get_training_projections!(training_projections.id) == training_projections
    end

    test "create_training_projections/1 with valid data creates a training_projections" do
      valid_attrs = %{costs: "120.5", department: "some department", designation: "some designation", disability: true, financial_year: "some financial_year", full_name: "some full_name", gender: "some gender", institution: "some institution", job_group: "some job_group", period_of_study: "some period_of_study", personal_number: "some personal_number", program_title: "some program_title", qualification: "some qualification", quarter: "some quarter", status: "some status"}

      assert {:ok, %TrainingProjections{} = training_projections} = Trainings.create_training_projections(valid_attrs)
      assert training_projections.costs == Decimal.new("120.5")
      assert training_projections.department == "some department"
      assert training_projections.designation == "some designation"
      assert training_projections.disability == true
      assert training_projections.financial_year == "some financial_year"
      assert training_projections.full_name == "some full_name"
      assert training_projections.gender == "some gender"
      assert training_projections.institution == "some institution"
      assert training_projections.job_group == "some job_group"
      assert training_projections.period_of_study == "some period_of_study"
      assert training_projections.personal_number == "some personal_number"
      assert training_projections.program_title == "some program_title"
      assert training_projections.qualification == "some qualification"
      assert training_projections.quarter == "some quarter"
      assert training_projections.status == "some status"
    end

    test "create_training_projections/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trainings.create_training_projections(@invalid_attrs)
    end

    test "update_training_projections/2 with valid data updates the training_projections" do
      training_projections = training_projections_fixture()
      update_attrs = %{costs: "456.7", department: "some updated department", designation: "some updated designation", disability: false, financial_year: "some updated financial_year", full_name: "some updated full_name", gender: "some updated gender", institution: "some updated institution", job_group: "some updated job_group", period_of_study: "some updated period_of_study", personal_number: "some updated personal_number", program_title: "some updated program_title", qualification: "some updated qualification", quarter: "some updated quarter", status: "some updated status"}

      assert {:ok, %TrainingProjections{} = training_projections} = Trainings.update_training_projections(training_projections, update_attrs)
      assert training_projections.costs == Decimal.new("456.7")
      assert training_projections.department == "some updated department"
      assert training_projections.designation == "some updated designation"
      assert training_projections.disability == false
      assert training_projections.financial_year == "some updated financial_year"
      assert training_projections.full_name == "some updated full_name"
      assert training_projections.gender == "some updated gender"
      assert training_projections.institution == "some updated institution"
      assert training_projections.job_group == "some updated job_group"
      assert training_projections.period_of_study == "some updated period_of_study"
      assert training_projections.personal_number == "some updated personal_number"
      assert training_projections.program_title == "some updated program_title"
      assert training_projections.qualification == "some updated qualification"
      assert training_projections.quarter == "some updated quarter"
      assert training_projections.status == "some updated status"
    end

    test "update_training_projections/2 with invalid data returns error changeset" do
      training_projections = training_projections_fixture()
      assert {:error, %Ecto.Changeset{}} = Trainings.update_training_projections(training_projections, @invalid_attrs)
      assert training_projections == Trainings.get_training_projections!(training_projections.id)
    end

    test "delete_training_projections/1 deletes the training_projections" do
      training_projections = training_projections_fixture()
      assert {:ok, %TrainingProjections{}} = Trainings.delete_training_projections(training_projections)
      assert_raise Ecto.NoResultsError, fn -> Trainings.get_training_projections!(training_projections.id) end
    end

    test "change_training_projections/1 returns a training_projections changeset" do
      training_projections = training_projections_fixture()
      assert %Ecto.Changeset{} = Trainings.change_training_projections(training_projections)
    end
  end
end
