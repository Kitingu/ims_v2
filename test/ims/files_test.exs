defmodule Ims.FilesTest do
  use Ims.DataCase

  alias Ims.Files

  describe "files" do
    alias Ims.Files.File

    import Ims.FilesFixtures

    @invalid_attrs %{folio_number: nil, subject_matter: nil, ref_no: nil}

    test "list_files/0 returns all files" do
      file = file_fixture()
      assert Files.list_files() == [file]
    end

    test "get_file!/1 returns the file with given id" do
      file = file_fixture()
      assert Files.get_file!(file.id) == file
    end

    test "create_file/1 with valid data creates a file" do
      valid_attrs = %{folio_number: "some folio_number", subject_matter: "some subject_matter", ref_no: "some ref_no"}

      assert {:ok, %File{} = file} = Files.create_file(valid_attrs)
      assert file.folio_number == "some folio_number"
      assert file.subject_matter == "some subject_matter"
      assert file.ref_no == "some ref_no"
    end

    test "create_file/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Files.create_file(@invalid_attrs)
    end

    test "update_file/2 with valid data updates the file" do
      file = file_fixture()
      update_attrs = %{folio_number: "some updated folio_number", subject_matter: "some updated subject_matter", ref_no: "some updated ref_no"}

      assert {:ok, %File{} = file} = Files.update_file(file, update_attrs)
      assert file.folio_number == "some updated folio_number"
      assert file.subject_matter == "some updated subject_matter"
      assert file.ref_no == "some updated ref_no"
    end

    test "update_file/2 with invalid data returns error changeset" do
      file = file_fixture()
      assert {:error, %Ecto.Changeset{}} = Files.update_file(file, @invalid_attrs)
      assert file == Files.get_file!(file.id)
    end

    test "delete_file/1 deletes the file" do
      file = file_fixture()
      assert {:ok, %File{}} = Files.delete_file(file)
      assert_raise Ecto.NoResultsError, fn -> Files.get_file!(file.id) end
    end

    test "change_file/1 returns a file changeset" do
      file = file_fixture()
      assert %Ecto.Changeset{} = Files.change_file(file)
    end
  end

  describe "file_movements" do
    alias Ims.Files.FileMovement

    import Ims.FilesFixtures

    @invalid_attrs %{remarks: nil}

    test "list_file_movements/0 returns all file_movements" do
      file_movement = file_movement_fixture()
      assert Files.list_file_movements() == [file_movement]
    end

    test "get_file_movement!/1 returns the file_movement with given id" do
      file_movement = file_movement_fixture()
      assert Files.get_file_movement!(file_movement.id) == file_movement
    end

    test "create_file_movement/1 with valid data creates a file_movement" do
      valid_attrs = %{remarks: "some remarks"}

      assert {:ok, %FileMovement{} = file_movement} = Files.create_file_movement(valid_attrs)
      assert file_movement.remarks == "some remarks"
    end

    test "create_file_movement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Files.create_file_movement(@invalid_attrs)
    end

    test "update_file_movement/2 with valid data updates the file_movement" do
      file_movement = file_movement_fixture()
      update_attrs = %{remarks: "some updated remarks"}

      assert {:ok, %FileMovement{} = file_movement} = Files.update_file_movement(file_movement, update_attrs)
      assert file_movement.remarks == "some updated remarks"
    end

    test "update_file_movement/2 with invalid data returns error changeset" do
      file_movement = file_movement_fixture()
      assert {:error, %Ecto.Changeset{}} = Files.update_file_movement(file_movement, @invalid_attrs)
      assert file_movement == Files.get_file_movement!(file_movement.id)
    end

    test "delete_file_movement/1 deletes the file_movement" do
      file_movement = file_movement_fixture()
      assert {:ok, %FileMovement{}} = Files.delete_file_movement(file_movement)
      assert_raise Ecto.NoResultsError, fn -> Files.get_file_movement!(file_movement.id) end
    end

    test "change_file_movement/1 returns a file_movement changeset" do
      file_movement = file_movement_fixture()
      assert %Ecto.Changeset{} = Files.change_file_movement(file_movement)
    end
  end
end
