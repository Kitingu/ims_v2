defmodule Ims.Trainings do
  @moduledoc """
  The Trainings context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.Trainings.TrainingApplication
  alias Ims.Trainings.TrainingProjections

  @doc """
  Returns the list of training_applications.

  ## Examples

      iex> list_training_applications()
      [%TrainingApplication{}, ...]

  """
  def list_training_applications do
    Repo.all(TrainingApplication) |> Repo.preload(:user)
    |> IO.inspect(label: "Training applications")
  end

  @doc """
  Gets a single training_application.

  Raises `Ecto.NoResultsError` if the Training application does not exist.

  ## Examples

      iex> get_training_application!(123)
      %TrainingApplication{}

      iex> get_training_application!(456)
      ** (Ecto.NoResultsError)

  """
  def get_training_application!(id), do: Repo.get!(TrainingApplication, id)

  @doc """
  Creates a training_application.

  ## Examples

      iex> create_training_application(%{field: value})
      {:ok, %TrainingApplication{}}

      iex> create_training_application(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_training_application(attrs \\ %{}) do
    %TrainingApplication{}
    |> TrainingApplication.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a training_application.

  ## Examples

      iex> update_training_application(training_application, %{field: new_value})
      {:ok, %TrainingApplication{}}

      iex> update_training_application(training_application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_training_application(%TrainingApplication{} = training_application, attrs) do
    training_application
    |> TrainingApplication.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a training_application.

  ## Examples

      iex> delete_training_application(training_application)
      {:ok, %TrainingApplication{}}

      iex> delete_training_application(training_application)
      {:error, %Ecto.Changeset{}}

  """
  def delete_training_application(%TrainingApplication{} = training_application) do
    Repo.delete(training_application)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking training_application changes.

  ## Examples

      iex> change_training_application(training_application)
      %Ecto.Changeset{data: %TrainingApplication{}}

  """
  def change_training_application(%TrainingApplication{} = training_application, attrs \\ %{}) do
    TrainingApplication.changeset(training_application, attrs)
  end

  @doc """
  Returns the list of training_projections.

  ## Examples

      iex> list_training_projections()
      [%TrainingProjections{}, ...]

  """
  def list_training_projections do
    Repo.all(TrainingProjections)
  end

  @doc """
  Gets a single training_projections.

  Raises `Ecto.NoResultsError` if the Training projections does not exist.

  ## Examples

      iex> get_training_projections!(123)
      %TrainingProjections{}

      iex> get_training_projections!(456)
      ** (Ecto.NoResultsError)

  """
  def get_training_projections!(id), do: Repo.get!(TrainingProjections, id)

  @doc """
  Creates a training_projections.

  ## Examples

      iex> create_training_projections(%{field: value})
      {:ok, %TrainingProjections{}}

      iex> create_training_projections(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_training_projections(attrs \\ %{}) do
    %TrainingProjections{}
    |> TrainingProjections.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a training_projections.

  ## Examples

      iex> update_training_projections(training_projections, %{field: new_value})
      {:ok, %TrainingProjections{}}

      iex> update_training_projections(training_projections, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_training_projections(%TrainingProjections{} = training_projections, attrs) do
    training_projections
    |> TrainingProjections.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a training_projections.

  ## Examples

      iex> delete_training_projections(training_projections)
      {:ok, %TrainingProjections{}}

      iex> delete_training_projections(training_projections)
      {:error, %Ecto.Changeset{}}

  """
  def delete_training_projections(%TrainingProjections{} = training_projections) do
    Repo.delete(training_projections)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking training_projections changes.

  ## Examples

      iex> change_training_projections(training_projections)
      %Ecto.Changeset{data: %TrainingProjections{}}

  """
  def change_training_projections(%TrainingProjections{} = training_projections, attrs \\ %{}) do
    TrainingProjections.changeset(training_projections, attrs)
  end
end
