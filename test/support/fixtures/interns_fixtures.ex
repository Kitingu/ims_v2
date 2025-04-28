defmodule Ims.InternsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Interns` context.
  """

  @doc """
  Generate a intern_attachee.
  """
  def intern_attachee_fixture(attrs \\ %{}) do
    {:ok, intern_attachee} =
      attrs
      |> Enum.into(%{
        duration: "some duration",
        email: "some email",
        end_date: ~D[2025-04-27],
        full_name: "some full_name",
        next_of_kin_name: "some next_of_kin_name",
        next_of_kin_phone: "some next_of_kin_phone",
        phone: "some phone",
        program: "some program",
        school: "some school",
        start_date: ~D[2025-04-27]
      })
      |> Ims.Interns.create_intern_attachee()

    intern_attachee
  end
end
