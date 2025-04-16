defmodule Ims.HRFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.HR` context.
  """

  @doc """
  Generate a away_request.
  """
  def away_request_fixture(attrs \\ %{}) do
    {:ok, away_request} =
      attrs
      |> Enum.into(%{
        days: 42,
        location: "some location",
        memo: "some memo",
        memo_upload: "some memo_upload",
        reason: "some reason",
        return_date: ~D[2025-04-15]
      })
      |> Ims.HR.create_away_request()

    away_request
  end
end
