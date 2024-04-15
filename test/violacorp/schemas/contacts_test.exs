defmodule Violacorp.Schemas.ContactsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Contacts
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    code: "0144",
    contact_number: "01252326587",
    is_primary: "Y",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contacts.changeset(%Contacts{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contacts.changeset(%Contacts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contact_number required check" do
    changeset = Contacts.changeset(%Contacts{}, Map.delete(@valid_attrs, :contact_number))
    assert !changeset.valid?
  end

  test "check if contact_number format is correct " do
    attrs = %{@valid_attrs | contact_number: "####23edrft"}
    changeset = Contacts.changeset(%Contacts{}, attrs)
    assert %{contact_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if contact_number maximum 11 numbers" do
    attrs = %{@valid_attrs | contact_number: "01221554154825"}
    changeset = Contacts.changeset(%Contacts{}, attrs)
    assert %{contact_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end

  test "check if contact_number minimum 10 numbers" do
    attrs = %{@valid_attrs | contact_number: "0122155"}
    changeset = Contacts.changeset(%Contacts{}, attrs)
    assert %{contact_number: ["should be at least 10 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  @doc" changesetonlynumber"

  test "changeset with valid attributes changesetonlynumber" do
    changeset = Contacts.changesetonlynumber(%Contacts{}, @valid_attrs)
    assert changeset.valid?
  end

  test "check if contact_number maximum 11 numbers changesetonlynumber" do
    attrs = %{@valid_attrs | contact_number: "01221554154825"}
    changeset = Contacts.changesetonlynumber(%Contacts{}, attrs)
    assert %{contact_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end

  test "check if contact_number minimum 10 numbers changesetonlynumber" do
    attrs = %{@valid_attrs | contact_number: "0122155"}
    changeset = Contacts.changesetonlynumber(%Contacts{}, attrs)
    assert %{contact_number: ["should be at least 10 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end


  @doc" changeset_number"

  @valid_attrs_number %{
    contact_number: "07415253658"
  }

  test "changeset with valid attributes changeset_number" do
    changeset = Contacts.changeset_number(%Contacts{}, @valid_attrs_number)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_number" do
    changeset = Contacts.changeset_number(%Contacts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contact_number required check changeset_number" do
    changeset = Contacts.changeset_number(%Contacts{}, Map.delete(@valid_attrs_number, :contact_number))
    assert !changeset.valid?
  end

  @doc" changeset_employee"

  test "changeset with valid attributes changeset_employee" do
    changeset = Contacts.changeset_employee(%Contacts{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_employee" do
    changeset = Contacts.changeset_employee(%Contacts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contact_number required check changeset_employee" do
    changeset = Contacts.changeset_employee(%Contacts{}, Map.delete(@valid_attrs, :contact_number))
    assert !changeset.valid?
  end

  test "check if contact_number format is correct changeset_employee" do
    attrs = %{@valid_attrs | contact_number: "####23edrft"}
    changeset = Contacts.changeset_employee(%Contacts{}, attrs)
    assert %{contact_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if contact_number maximum 11 numbers changeset_employee" do
    attrs = %{@valid_attrs | contact_number: "01221554154825"}
    changeset = Contacts.changeset_employee(%Contacts{}, attrs)
    assert %{contact_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end

  test "check if contact_number minimum 10 numbers changeset_employee" do
    attrs = %{@valid_attrs | contact_number: "0122155"}
    changeset = Contacts.changeset_employee(%Contacts{}, attrs)
    assert %{contact_number: ["should be at least 10 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end
























end