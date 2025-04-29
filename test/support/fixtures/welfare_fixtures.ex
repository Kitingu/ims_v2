defmodule Ims.WelfareFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Welfare` context.
  """

  @doc """
  Generate a event_type.
  """
  def event_type_fixture(attrs \\ %{}) do
    {:ok, event_type} =
      attrs
      |> Enum.into(%{
        amount: 42,
        name: "some name"
      })
      |> Ims.Welfare.create_event_type()

    event_type
  end

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        amount_paid: "120.5",
        description: "some description",
        status: "some status",
        title: "some title"
      })
      |> Ims.Welfare.create_event()

    event
  end
end
