defmodule Violacorp.Schemas.ContactsdirectorsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Contactsdirectors
  @moduledoc false

  @valid_attrs %{
    directors_id: 1232,
    code: "0144",
    contact_number: "01252326587",
    is_primary: "Y",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contact_number required check" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, Map.delete(@valid_attrs, :contact_number))
    assert !changeset.valid?
  end

  test "check if contact_number format is correct " do
    attrs = %{@valid_attrs | contact_number: "####23edrft"}
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, attrs)
    assert %{contact_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if contact_number maximum 11 numbers" do
    attrs = %{@valid_attrs | contact_number: "01221554154825"}
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, attrs)
    assert %{contact_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end

  test "check if contact_number minimum 10 numbers" do
    attrs = %{@valid_attrs | contact_number: "0122155"}
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, attrs)
    assert %{contact_number: ["should be at least 10 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  @doc" changeset_number"

  @valid_attrs_number %{
    contact_number: "07415452548"
  }

  test "changeset with valid attributes changeset_number" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, @valid_attrs_number)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_number" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contact_number required check changeset_number" do
    changeset = Contactsdirectors.changeset(%Contactsdirectors{}, Map.delete(@valid_attrs_number, :contact_number))
    assert !changeset.valid?
  end

  end