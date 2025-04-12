defmodule Ims.DemographicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Demographics` context.
  """

  @doc """
  Generate a ethnicity.
  """
  def ethnicity_fixture(attrs \\ %{}) do
    {:ok, ethnicity} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ims.Demographics.create_ethnicity()

    ethnicity
  end
end
