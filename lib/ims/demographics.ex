defmodule Ims.Demographics do
  @moduledoc """
  The Demographics context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo.Audited, as: Repo

  alias Ims.Demographics.Ethnicity

  @doc """
  Returns the list of ethnicities.

  ## Examples

      iex> list_ethnicities()
      [%Ethnicity{}, ...]

  """
  def list_ethnicities do
    Repo.all(Ethnicity)
  end

  @doc """
  Gets a single ethnicity.

  Raises `Ecto.NoResultsError` if the Ethnicity does not exist.

  ## Examples

      iex> get_ethnicity!(123)
      %Ethnicity{}

      iex> get_ethnicity!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ethnicity!(id), do: Repo.get!(Ethnicity, id)

  @doc """
  Creates a ethnicity.

  ## Examples

      iex> create_ethnicity(%{field: value})
      {:ok, %Ethnicity{}}

      iex> create_ethnicity(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ethnicity(attrs \\ %{}) do
    %Ethnicity{}
    |> Ethnicity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ethnicity.

  ## Examples

      iex> update_ethnicity(ethnicity, %{field: new_value})
      {:ok, %Ethnicity{}}

      iex> update_ethnicity(ethnicity, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ethnicity(%Ethnicity{} = ethnicity, attrs) do
    ethnicity
    |> Ethnicity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ethnicity.

  ## Examples

      iex> delete_ethnicity(ethnicity)
      {:ok, %Ethnicity{}}

      iex> delete_ethnicity(ethnicity)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ethnicity(%Ethnicity{} = ethnicity) do
    Repo.delete(ethnicity)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ethnicity changes.

  ## Examples

      iex> change_ethnicity(ethnicity)
      %Ecto.Changeset{data: %Ethnicity{}}

  """
  def change_ethnicity(%Ethnicity{} = ethnicity, attrs \\ %{}) do
    Ethnicity.changeset(ethnicity, attrs)
  end
end
