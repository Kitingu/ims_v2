defmodule Ims.InternsTest do
  use Ims.DataCase

  alias Ims.Interns

  describe "intern_attachees" do
    alias Ims.Interns.InternAttachee

    import Ims.InternsFixtures

    @invalid_attrs %{duration: nil, email: nil, end_date: nil, full_name: nil, next_of_kin_name: nil, next_of_kin_phone: nil, phone: nil, program: nil, school: nil, start_date: nil}

    test "list_intern_attachees/0 returns all intern_attachees" do
      intern_attachee = intern_attachee_fixture()
      assert Interns.list_intern_attachees() == [intern_attachee]
    end

    test "get_intern_attachee!/1 returns the intern_attachee with given id" do
      intern_attachee = intern_attachee_fixture()
      assert Interns.get_intern_attachee!(intern_attachee.id) == intern_attachee
    end

    test "create_intern_attachee/1 with valid data creates a intern_attachee" do
      valid_attrs = %{duration: "some duration", email: "some email", end_date: ~D[2025-04-27], full_name: "some full_name", next_of_kin_name: "some next_of_kin_name", next_of_kin_phone: "some next_of_kin_phone", phone: "some phone", program: "some program", school: "some school", start_date: ~D[2025-04-27]}

      assert {:ok, %InternAttachee{} = intern_attachee} = Interns.create_intern_attachee(valid_attrs)
      assert intern_attachee.duration == "some duration"
      assert intern_attachee.email == "some email"
      assert intern_attachee.end_date == ~D[2025-04-27]
      assert intern_attachee.full_name == "some full_name"
      assert intern_attachee.next_of_kin_name == "some next_of_kin_name"
      assert intern_attachee.next_of_kin_phone == "some next_of_kin_phone"
      assert intern_attachee.phone == "some phone"
      assert intern_attachee.program == "some program"
      assert intern_attachee.school == "some school"
      assert intern_attachee.start_date == ~D[2025-04-27]
    end

    test "create_intern_attachee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Interns.create_intern_attachee(@invalid_attrs)
    end

    test "update_intern_attachee/2 with valid data updates the intern_attachee" do
      intern_attachee = intern_attachee_fixture()
      update_attrs = %{duration: "some updated duration", email: "some updated email", end_date: ~D[2025-04-28], full_name: "some updated full_name", next_of_kin_name: "some updated next_of_kin_name", next_of_kin_phone: "some updated next_of_kin_phone", phone: "some updated phone", program: "some updated program", school: "some updated school", start_date: ~D[2025-04-28]}

      assert {:ok, %InternAttachee{} = intern_attachee} = Interns.update_intern_attachee(intern_attachee, update_attrs)
      assert intern_attachee.duration == "some updated duration"
      assert intern_attachee.email == "some updated email"
      assert intern_attachee.end_date == ~D[2025-04-28]
      assert intern_attachee.full_name == "some updated full_name"
      assert intern_attachee.next_of_kin_name == "some updated next_of_kin_name"
      assert intern_attachee.next_of_kin_phone == "some updated next_of_kin_phone"
      assert intern_attachee.phone == "some updated phone"
      assert intern_attachee.program == "some updated program"
      assert intern_attachee.school == "some updated school"
      assert intern_attachee.start_date == ~D[2025-04-28]
    end

    test "update_intern_attachee/2 with invalid data returns error changeset" do
      intern_attachee = intern_attachee_fixture()
      assert {:error, %Ecto.Changeset{}} = Interns.update_intern_attachee(intern_attachee, @invalid_attrs)
      assert intern_attachee == Interns.get_intern_attachee!(intern_attachee.id)
    end

    test "delete_intern_attachee/1 deletes the intern_attachee" do
      intern_attachee = intern_attachee_fixture()
      assert {:ok, %InternAttachee{}} = Interns.delete_intern_attachee(intern_attachee)
      assert_raise Ecto.NoResultsError, fn -> Interns.get_intern_attachee!(intern_attachee.id) end
    end

    test "change_intern_attachee/1 returns a intern_attachee changeset" do
      intern_attachee = intern_attachee_fixture()
      assert %Ecto.Changeset{} = Interns.change_intern_attachee(intern_attachee)
    end
  end
end
