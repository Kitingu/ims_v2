defmodule Ims.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Settings` context.
  """

  @doc """
  Generate a setting.
  """
  def setting_fixture(attrs \\ %{}) do
    {:ok, setting} =
      attrs
      |> Enum.into(%{
        name: "some name",
        value: "some value"
      })
      |> Ims.Settings.create_setting()

    setting
  end
end
