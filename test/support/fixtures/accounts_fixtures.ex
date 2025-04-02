defmodule Ims.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ims.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Ims.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a departments.
  """
  def departments_fixture(attrs \\ %{}) do
    {:ok, departments} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ims.Accounts.create_departments()

    departments
  end

  @doc """
  Generate a job_group.
  """
  def job_group_fixture(attrs \\ %{}) do
    {:ok, job_group} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Accounts.create_job_group()

    job_group
  end

  @doc """
  Generate a role.
  """
  def role_fixture(attrs \\ %{}) do
    {:ok, role} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Accounts.create_role()

    role
  end

  @doc """
  Generate a permission.
  """
  def permission_fixture(attrs \\ %{}) do
    {:ok, permission} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Ims.Accounts.create_permission()

    permission
  end
end
