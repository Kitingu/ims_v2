defmodule Ims.LeaveTest do
  use Ims.DataCase

  alias Ims.Leave

  describe "leave_types" do
    alias Ims.Leave.LeaveType

    import Ims.LeaveFixtures

    @invalid_attrs %{name: nil, max_days: nil, carry_forward: nil, requires_approval: nil}

    test "list_leave_types/0 returns all leave_types" do
      leave_type = leave_type_fixture()
      assert Leave.list_leave_types() == [leave_type]
    end

    test "get_leave_type!/1 returns the leave_type with given id" do
      leave_type = leave_type_fixture()
      assert Leave.get_leave_type!(leave_type.id) == leave_type
    end

    test "create_leave_type/1 with valid data creates a leave_type" do
      valid_attrs = %{name: "some name", max_days: 42, carry_forward: true, requires_approval: true}

      assert {:ok, %LeaveType{} = leave_type} = Leave.create_leave_type(valid_attrs)
      assert leave_type.name == "some name"
      assert leave_type.max_days == 42
      assert leave_type.carry_forward == true
      assert leave_type.requires_approval == true
    end

    test "create_leave_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Leave.create_leave_type(@invalid_attrs)
    end

    test "update_leave_type/2 with valid data updates the leave_type" do
      leave_type = leave_type_fixture()
      update_attrs = %{name: "some updated name", max_days: 43, carry_forward: false, requires_approval: false}

      assert {:ok, %LeaveType{} = leave_type} = Leave.update_leave_type(leave_type, update_attrs)
      assert leave_type.name == "some updated name"
      assert leave_type.max_days == 43
      assert leave_type.carry_forward == false
      assert leave_type.requires_approval == false
    end

    test "update_leave_type/2 with invalid data returns error changeset" do
      leave_type = leave_type_fixture()
      assert {:error, %Ecto.Changeset{}} = Leave.update_leave_type(leave_type, @invalid_attrs)
      assert leave_type == Leave.get_leave_type!(leave_type.id)
    end

    test "delete_leave_type/1 deletes the leave_type" do
      leave_type = leave_type_fixture()
      assert {:ok, %LeaveType{}} = Leave.delete_leave_type(leave_type)
      assert_raise Ecto.NoResultsError, fn -> Leave.get_leave_type!(leave_type.id) end
    end

    test "change_leave_type/1 returns a leave_type changeset" do
      leave_type = leave_type_fixture()
      assert %Ecto.Changeset{} = Leave.change_leave_type(leave_type)
    end
  end

  describe "leave_balances" do
    alias Ims.Leave.LeaveBalance

    import Ims.LeaveFixtures

    @invalid_attrs %{remaining_days: nil}

    test "list_leave_balances/0 returns all leave_balances" do
      leave_balance = leave_balance_fixture()
      assert Leave.list_leave_balances() == [leave_balance]
    end

    test "get_leave_balance!/1 returns the leave_balance with given id" do
      leave_balance = leave_balance_fixture()
      assert Leave.get_leave_balance!(leave_balance.id) == leave_balance
    end

    test "create_leave_balance/1 with valid data creates a leave_balance" do
      valid_attrs = %{remaining_days: 42}

      assert {:ok, %LeaveBalance{} = leave_balance} = Leave.create_leave_balance(valid_attrs)
      assert leave_balance.remaining_days == 42
    end

    test "create_leave_balance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Leave.create_leave_balance(@invalid_attrs)
    end

    test "update_leave_balance/2 with valid data updates the leave_balance" do
      leave_balance = leave_balance_fixture()
      update_attrs = %{remaining_days: 43}

      assert {:ok, %LeaveBalance{} = leave_balance} = Leave.update_leave_balance(leave_balance, update_attrs)
      assert leave_balance.remaining_days == 43
    end

    test "update_leave_balance/2 with invalid data returns error changeset" do
      leave_balance = leave_balance_fixture()
      assert {:error, %Ecto.Changeset{}} = Leave.update_leave_balance(leave_balance, @invalid_attrs)
      assert leave_balance == Leave.get_leave_balance!(leave_balance.id)
    end

    test "delete_leave_balance/1 deletes the leave_balance" do
      leave_balance = leave_balance_fixture()
      assert {:ok, %LeaveBalance{}} = Leave.delete_leave_balance(leave_balance)
      assert_raise Ecto.NoResultsError, fn -> Leave.get_leave_balance!(leave_balance.id) end
    end

    test "change_leave_balance/1 returns a leave_balance changeset" do
      leave_balance = leave_balance_fixture()
      assert %Ecto.Changeset{} = Leave.change_leave_balance(leave_balance)
    end
  end

  describe "leave_applications" do
    alias Ims.Leave.LeaveApplication

    import Ims.LeaveFixtures

    @invalid_attrs %{status: nil, comment: nil, days_requested: nil, start_date: nil, end_date: nil, resumption_date: nil, proof_document: nil}

    test "list_leave_applications/0 returns all leave_applications" do
      leave_application = leave_application_fixture()
      assert Leave.list_leave_applications() == [leave_application]
    end

    test "get_leave_application!/1 returns the leave_application with given id" do
      leave_application = leave_application_fixture()
      assert Leave.get_leave_application!(leave_application.id) == leave_application
    end

    test "create_leave_application/1 with valid data creates a leave_application" do
      valid_attrs = %{status: "some status", comment: "some comment", days_requested: 42, start_date: ~D[2025-04-01], end_date: ~D[2025-04-01], resumption_date: ~D[2025-04-01], proof_document: "some proof_document"}

      assert {:ok, %LeaveApplication{} = leave_application} = Leave.create_leave_application(valid_attrs)
      assert leave_application.status == "some status"
      assert leave_application.comment == "some comment"
      assert leave_application.days_requested == 42
      assert leave_application.start_date == ~D[2025-04-01]
      assert leave_application.end_date == ~D[2025-04-01]
      assert leave_application.resumption_date == ~D[2025-04-01]
      assert leave_application.proof_document == "some proof_document"
    end

    test "create_leave_application/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Leave.create_leave_application(@invalid_attrs)
    end

    test "update_leave_application/2 with valid data updates the leave_application" do
      leave_application = leave_application_fixture()
      update_attrs = %{status: "some updated status", comment: "some updated comment", days_requested: 43, start_date: ~D[2025-04-02], end_date: ~D[2025-04-02], resumption_date: ~D[2025-04-02], proof_document: "some updated proof_document"}

      assert {:ok, %LeaveApplication{} = leave_application} = Leave.update_leave_application(leave_application, update_attrs)
      assert leave_application.status == "some updated status"
      assert leave_application.comment == "some updated comment"
      assert leave_application.days_requested == 43
      assert leave_application.start_date == ~D[2025-04-02]
      assert leave_application.end_date == ~D[2025-04-02]
      assert leave_application.resumption_date == ~D[2025-04-02]
      assert leave_application.proof_document == "some updated proof_document"
    end

    test "update_leave_application/2 with invalid data returns error changeset" do
      leave_application = leave_application_fixture()
      assert {:error, %Ecto.Changeset{}} = Leave.update_leave_application(leave_application, @invalid_attrs)
      assert leave_application == Leave.get_leave_application!(leave_application.id)
    end

    test "delete_leave_application/1 deletes the leave_application" do
      leave_application = leave_application_fixture()
      assert {:ok, %LeaveApplication{}} = Leave.delete_leave_application(leave_application)
      assert_raise Ecto.NoResultsError, fn -> Leave.get_leave_application!(leave_application.id) end
    end

    test "change_leave_application/1 returns a leave_application changeset" do
      leave_application = leave_application_fixture()
      assert %Ecto.Changeset{} = Leave.change_leave_application(leave_application)
    end
  end
end
