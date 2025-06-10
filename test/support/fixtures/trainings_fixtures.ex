defmodule Ims.TrainingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Trainings` context.
  """

  @doc """
  Generate a training_application.
  """
  def training_application_fixture(attrs \\ %{}) do
    {:ok, training_application} =
      attrs
      |> Enum.into(%{
        authority_reference: "some authority_reference",
        costs: "120.5",
        course_approved: "some course_approved",
        disability: true,
        financial_year: "some financial_year",
        institution: "some institution",
        memo_reference: "some memo_reference",
        period_of_study: "some period_of_study",
        program_title: "some program_title",
        quarter: "some quarter",
        status: "some status"
      })
      |> Ims.Trainings.create_training_application()

    training_application
  end

  @doc """
  Generate a training_projections.
  """
  def training_projections_fixture(attrs \\ %{}) do
    {:ok, training_projections} =
      attrs
      |> Enum.into(%{
        costs: "120.5",
        department: "some department",
        designation: "some designation",
        disability: true,
        financial_year: "some financial_year",
        full_name: "some full_name",
        gender: "some gender",
        institution: "some institution",
        job_group: "some job_group",
        period_of_study: "some period_of_study",
        personal_number: "some personal_number",
        program_title: "some program_title",
        qualification: "some qualification",
        quarter: "some quarter",
        status: "some status"
      })
      |> Ims.Trainings.create_training_projections()

    training_projections
  end
end
