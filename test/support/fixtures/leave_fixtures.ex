defmodule Ims.LeaveFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Leave` context.
  """

  @doc """
  Generate a unique leave_type name.
  """
  def unique_leave_type_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a leave_type.
  """
  def leave_type_fixture(attrs \\ %{}) do
    {:ok, leave_type} =
      attrs
      |> Enum.into(%{
        carry_forward: true,
        max_days: 42,
        name: unique_leave_type_name(),
        requires_approval: true
      })
      |> Ims.Leave.create_leave_type()

    leave_type
  end

  @doc """
  Generate a leave_balance.
  """
  def leave_balance_fixture(attrs \\ %{}) do
    {:ok, leave_balance} =
      attrs
      |> Enum.into(%{
        remaining_days: 42
      })
      |> Ims.Leave.create_leave_balance()

    leave_balance
  end

  @doc """
  Generate a leave_application.
  """
  def leave_application_fixture(attrs \\ %{}) do
    {:ok, leave_application} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        days_requested: 42,
        end_date: ~D[2025-04-01],
        proof_document: "some proof_document",
        resumption_date: ~D[2025-04-01],
        start_date: ~D[2025-04-01],
        status: "some status"
      })
      |> Ims.Leave.create_leave_application()

    leave_application
  end
end
