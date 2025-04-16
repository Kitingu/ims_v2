defmodule Ims.HRTest do
  use Ims.DataCase

  alias Ims.HR

  describe "away_requests" do
    alias Ims.HR.AwayRequest

    import Ims.HRFixtures

    @invalid_attrs %{reason: nil, location: nil, memo: nil, memo_upload: nil, days: nil, return_date: nil}

    test "list_away_requests/0 returns all away_requests" do
      away_request = away_request_fixture()
      assert HR.list_away_requests() == [away_request]
    end

    test "get_away_request!/1 returns the away_request with given id" do
      away_request = away_request_fixture()
      assert HR.get_away_request!(away_request.id) == away_request
    end

    test "create_away_request/1 with valid data creates a away_request" do
      valid_attrs = %{reason: "some reason", location: "some location", memo: "some memo", memo_upload: "some memo_upload", days: 42, return_date: ~D[2025-04-15]}

      assert {:ok, %AwayRequest{} = away_request} = HR.create_away_request(valid_attrs)
      assert away_request.reason == "some reason"
      assert away_request.location == "some location"
      assert away_request.memo == "some memo"
      assert away_request.memo_upload == "some memo_upload"
      assert away_request.days == 42
      assert away_request.return_date == ~D[2025-04-15]
    end

    test "create_away_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = HR.create_away_request(@invalid_attrs)
    end

    test "update_away_request/2 with valid data updates the away_request" do
      away_request = away_request_fixture()
      update_attrs = %{reason: "some updated reason", location: "some updated location", memo: "some updated memo", memo_upload: "some updated memo_upload", days: 43, return_date: ~D[2025-04-16]}

      assert {:ok, %AwayRequest{} = away_request} = HR.update_away_request(away_request, update_attrs)
      assert away_request.reason == "some updated reason"
      assert away_request.location == "some updated location"
      assert away_request.memo == "some updated memo"
      assert away_request.memo_upload == "some updated memo_upload"
      assert away_request.days == 43
      assert away_request.return_date == ~D[2025-04-16]
    end

    test "update_away_request/2 with invalid data returns error changeset" do
      away_request = away_request_fixture()
      assert {:error, %Ecto.Changeset{}} = HR.update_away_request(away_request, @invalid_attrs)
      assert away_request == HR.get_away_request!(away_request.id)
    end

    test "delete_away_request/1 deletes the away_request" do
      away_request = away_request_fixture()
      assert {:ok, %AwayRequest{}} = HR.delete_away_request(away_request)
      assert_raise Ecto.NoResultsError, fn -> HR.get_away_request!(away_request.id) end
    end

    test "change_away_request/1 returns a away_request changeset" do
      away_request = away_request_fixture()
      assert %Ecto.Changeset{} = HR.change_away_request(away_request)
    end
  end
end
