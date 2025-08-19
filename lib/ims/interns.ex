defmodule Ims.Interns do
  @moduledoc """
  The Interns context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo.Audited, as: Repo

  alias Ims.Interns.InternAttachee

  @doc """
  Returns the list of intern_attachees.

  ## Examples

      iex> list_intern_attachees()
      [%InternAttachee{}, ...]

  """
  def list_intern_attachees do
    Repo.all(InternAttachee)
  end

  @doc """
  Gets a single intern_attachee.

  Raises `Ecto.NoResultsError` if the Intern attachee does not exist.

  ## Examples

      iex> get_intern_attachee!(123)
      %InternAttachee{}

      iex> get_intern_attachee!(456)
      ** (Ecto.NoResultsError)

  """
  def get_intern_attachee!(id), do: Repo.get!(InternAttachee, id)

  @doc """
  Creates a intern_attachee.

  ## Examples

      iex> create_intern_attachee(%{field: value})
      {:ok, %InternAttachee{}}

      iex> create_intern_attachee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_intern_attachee(attrs \\ %{}) do
    %InternAttachee{}
    |> InternAttachee.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a intern_attachee.

  ## Examples

      iex> update_intern_attachee(intern_attachee, %{field: new_value})
      {:ok, %InternAttachee{}}

      iex> update_intern_attachee(intern_attachee, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_intern_attachee(%InternAttachee{} = intern_attachee, attrs) do
    intern_attachee
    |> InternAttachee.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a intern_attachee.

  ## Examples

      iex> delete_intern_attachee(intern_attachee)
      {:ok, %InternAttachee{}}

      iex> delete_intern_attachee(intern_attachee)
      {:error, %Ecto.Changeset{}}

  """
  def delete_intern_attachee(%InternAttachee{} = intern_attachee) do
    Repo.delete(intern_attachee)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking intern_attachee changes.

  ## Examples

      iex> change_intern_attachee(intern_attachee)
      %Ecto.Changeset{data: %InternAttachee{}}

  """
  def change_intern_attachee(%InternAttachee{} = intern_attachee, attrs \\ %{}) do
    InternAttachee.changeset(intern_attachee, attrs)
  end
end
