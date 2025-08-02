defmodule Ims.FilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Files` context.
  """

  @doc """
  Generate a file.
  """
  def file_fixture(attrs \\ %{}) do
    {:ok, file} =
      attrs
      |> Enum.into(%{
        folio_number: "some folio_number",
        ref_no: "some ref_no",
        subject_matter: "some subject_matter"
      })
      |> Ims.Files.create_file()

    file
  end

  @doc """
  Generate a file_movement.
  """
  def file_movement_fixture(attrs \\ %{}) do
    {:ok, file_movement} =
      attrs
      |> Enum.into(%{
        remarks: "some remarks"
      })
      |> Ims.Files.create_file_movement()

    file_movement
  end
end
