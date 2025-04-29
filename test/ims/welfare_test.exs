defmodule Ims.WelfareTest do
  use Ims.DataCase

  alias Ims.Welfare

  describe "event_types" do
    alias Ims.Welfare.EventType

    import Ims.WelfareFixtures

    @invalid_attrs %{name: nil, amount: nil}

    test "list_event_types/0 returns all event_types" do
      event_type = event_type_fixture()
      assert Welfare.list_event_types() == [event_type]
    end

    test "get_event_type!/1 returns the event_type with given id" do
      event_type = event_type_fixture()
      assert Welfare.get_event_type!(event_type.id) == event_type
    end

    test "create_event_type/1 with valid data creates a event_type" do
      valid_attrs = %{name: "some name", amount: 42}

      assert {:ok, %EventType{} = event_type} = Welfare.create_event_type(valid_attrs)
      assert event_type.name == "some name"
      assert event_type.amount == 42
    end

    test "create_event_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Welfare.create_event_type(@invalid_attrs)
    end

    test "update_event_type/2 with valid data updates the event_type" do
      event_type = event_type_fixture()
      update_attrs = %{name: "some updated name", amount: 43}

      assert {:ok, %EventType{} = event_type} = Welfare.update_event_type(event_type, update_attrs)
      assert event_type.name == "some updated name"
      assert event_type.amount == 43
    end

    test "update_event_type/2 with invalid data returns error changeset" do
      event_type = event_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Welfare.update_event_type(event_type, @invalid_attrs)
      assert event_type == Welfare.get_event_type!(event_type.id)
    end

    test "delete_event_type/1 deletes the event_type" do
      event_type = event_type_fixture()
      assert {:ok, %EventType{}} = Welfare.delete_event_type(event_type)
      assert_raise Ecto.NoResultsError, fn -> Welfare.get_event_type!(event_type.id) end
    end

    test "change_event_type/1 returns a event_type changeset" do
      event_type = event_type_fixture()
      assert %Ecto.Changeset{} = Welfare.change_event_type(event_type)
    end
  end

  describe "events" do
    alias Ims.Welfare.Event

    import Ims.WelfareFixtures

    @invalid_attrs %{status: nil, description: nil, title: nil, amount_paid: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Welfare.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Welfare.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{status: "some status", description: "some description", title: "some title", amount_paid: "120.5"}

      assert {:ok, %Event{} = event} = Welfare.create_event(valid_attrs)
      assert event.status == "some status"
      assert event.description == "some description"
      assert event.title == "some title"
      assert event.amount_paid == Decimal.new("120.5")
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Welfare.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      update_attrs = %{status: "some updated status", description: "some updated description", title: "some updated title", amount_paid: "456.7"}

      assert {:ok, %Event{} = event} = Welfare.update_event(event, update_attrs)
      assert event.status == "some updated status"
      assert event.description == "some updated description"
      assert event.title == "some updated title"
      assert event.amount_paid == Decimal.new("456.7")
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Welfare.update_event(event, @invalid_attrs)
      assert event == Welfare.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Welfare.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Welfare.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Welfare.change_event(event)
    end
  end
end
