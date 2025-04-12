defmodule Ims.DemographicsTest do
  use Ims.DataCase

  alias Ims.Demographics

  describe "ethnicities" do
    alias Ims.Demographics.Ethnicity

    import Ims.DemographicsFixtures

    @invalid_attrs %{name: nil}

    test "list_ethnicities/0 returns all ethnicities" do
      ethnicity = ethnicity_fixture()
      assert Demographics.list_ethnicities() == [ethnicity]
    end

    test "get_ethnicity!/1 returns the ethnicity with given id" do
      ethnicity = ethnicity_fixture()
      assert Demographics.get_ethnicity!(ethnicity.id) == ethnicity
    end

    test "create_ethnicity/1 with valid data creates a ethnicity" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Ethnicity{} = ethnicity} = Demographics.create_ethnicity(valid_attrs)
      assert ethnicity.name == "some name"
    end

    test "create_ethnicity/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Demographics.create_ethnicity(@invalid_attrs)
    end

    test "update_ethnicity/2 with valid data updates the ethnicity" do
      ethnicity = ethnicity_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Ethnicity{} = ethnicity} = Demographics.update_ethnicity(ethnicity, update_attrs)
      assert ethnicity.name == "some updated name"
    end

    test "update_ethnicity/2 with invalid data returns error changeset" do
      ethnicity = ethnicity_fixture()
      assert {:error, %Ecto.Changeset{}} = Demographics.update_ethnicity(ethnicity, @invalid_attrs)
      assert ethnicity == Demographics.get_ethnicity!(ethnicity.id)
    end

    test "delete_ethnicity/1 deletes the ethnicity" do
      ethnicity = ethnicity_fixture()
      assert {:ok, %Ethnicity{}} = Demographics.delete_ethnicity(ethnicity)
      assert_raise Ecto.NoResultsError, fn -> Demographics.get_ethnicity!(ethnicity.id) end
    end

    test "change_ethnicity/1 returns a ethnicity changeset" do
      ethnicity = ethnicity_fixture()
      assert %Ecto.Changeset{} = Demographics.change_ethnicity(ethnicity)
    end
  end
end
