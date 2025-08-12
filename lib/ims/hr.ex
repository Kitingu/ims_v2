defmodule Ims.HR do
  @moduledoc """
  The HR context.
  """

  import Ecto.Query, warn: false
  alias Ims.Repo

  alias Ims.HR.AwayRequest
  alias Ims.Interns.InternAttachee

  @doc """
  Returns the list of away_requests.

  ## Examples

      iex> list_away_requests()
      [%AwayRequest{}, ...]

  """
  def list_away_requests do
    Repo.all(AwayRequest)
  end

  @doc """
  Gets a single away_request.

  Raises `Ecto.NoResultsError` if the Away request does not exist.

  ## Examples

      iex> get_away_request!(123)
      %AwayRequest{}

      iex> get_away_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_away_request!(id), do: Repo.get!(AwayRequest, id)

  @doc """
  Creates a away_request.

  ## Examples

      iex> create_away_request(%{field: value})
      {:ok, %AwayRequest{}}

      iex> create_away_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_away_request(attrs \\ %{}) do
    %AwayRequest{}
    |> AwayRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a away_request.

  ## Examples

      iex> update_away_request(away_request, %{field: new_value})
      {:ok, %AwayRequest{}}

      iex> update_away_request(away_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_away_request(%AwayRequest{} = away_request, attrs) do
    away_request
    |> AwayRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a away_request.

  ## Examples

      iex> delete_away_request(away_request)
      {:ok, %AwayRequest{}}

      iex> delete_away_request(away_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_away_request(%AwayRequest{} = away_request) do
    Repo.delete(away_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking away_request changes.

  ## Examples

      iex> change_away_request(away_request)
      %Ecto.Changeset{data: %AwayRequest{}}

  """
  def change_away_request(%AwayRequest{} = away_request, attrs \\ %{}) do
    AwayRequest.changeset(away_request, attrs)
  end

  # def list_away_requests do
  #   AwayRequest
  #   |> where([ar], ar.status == "active")
  #   |> Repo.all()
  # end

  def list_interns do
    InternAttachee
    |> where([i], i.program == "intern")
    |> Repo.all()
  end

  def list_attachees do
    InternAttachee
    |> where([i], i.program == "attachee")
    |> Repo.all()
  end
end
