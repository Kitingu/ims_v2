defmodule Ims.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Files.File

  @doc """
  Returns the list of files.

  ## Examples

      iex> list_files()
      [%File{}, ...]

  """
  def list_files do
    Repo.all(File)
  end

  @doc """
  Gets a single file.

  Raises `Ecto.NoResultsError` if the File does not exist.

  ## Examples

      iex> get_file!(123)
      %File{}

      iex> get_file!(456)
      ** (Ecto.NoResultsError)

  """
  def get_file!(id), do: Repo.get!(File, id)

  @doc """
  Creates a file.

  ## Examples

      iex> create_file(%{field: value})
      {:ok, %File{}}

      iex> create_file(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file(attrs \\ %{}) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a file.

  ## Examples

      iex> update_file(file, %{field: new_value})
      {:ok, %File{}}

      iex> update_file(file, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file(%File{} = file, attrs) do
    file
    |> File.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a file.

  ## Examples

      iex> delete_file(file)
      {:ok, %File{}}

      iex> delete_file(file)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file(%File{} = file) do
    Repo.delete(file)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file changes.

  ## Examples

      iex> change_file(file)
      %Ecto.Changeset{data: %File{}}

  """
  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end

  alias Ims.Files.FileMovement

  @doc """
  Returns the list of file_movements.

  ## Examples

      iex> list_file_movements()
      [%FileMovement{}, ...]

  """
  def list_file_movements do
    Repo.all(FileMovement)
  end

  @doc """
  Gets a single file_movement.

  Raises `Ecto.NoResultsError` if the File movement does not exist.

  ## Examples

      iex> get_file_movement!(123)
      %FileMovement{}

      iex> get_file_movement!(456)
      ** (Ecto.NoResultsError)

  """
  def get_file_movement!(id), do: Repo.get!(FileMovement, id)

  @doc """
  Creates a file_movement.

  ## Examples

      iex> create_file_movement(%{field: value})
      {:ok, %FileMovement{}}

      iex> create_file_movement(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file_movement(attrs \\ %{}) do
    %FileMovement{}
    |> FileMovement.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a file_movement.

  ## Examples

      iex> update_file_movement(file_movement, %{field: new_value})
      {:ok, %FileMovement{}}

      iex> update_file_movement(file_movement, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file_movement(%FileMovement{} = file_movement, attrs) do
    file_movement
    |> FileMovement.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a file_movement.

  ## Examples

      iex> delete_file_movement(file_movement)
      {:ok, %FileMovement{}}

      iex> delete_file_movement(file_movement)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file_movement(%FileMovement{} = file_movement) do
    Repo.delete(file_movement)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file_movement changes.

  ## Examples

      iex> change_file_movement(file_movement)
      %Ecto.Changeset{data: %FileMovement{}}

  """
  def change_file_movement(%FileMovement{} = file_movement, attrs \\ %{}) do
    FileMovement.changeset(file_movement, attrs)
  end
end
