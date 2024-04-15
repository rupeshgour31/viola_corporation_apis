defmodule Violacorp.Schemas.AddressdirectorsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Addressdirectors
  @moduledoc false

  @valid_attrs %{
    directors_id: 331,
    countries_id: 53,
    address_line_one: "Address_line_one",
    address_line_two: "address_line_two",
    address_line_three: "address_line_three",
    city: "address_line_three",
    town: "town",
    county: "county",
    post_code: "cf313ph",
    is_primary: "Y",
    inserted_by: 1212,
  }
  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "address_line_one required check" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, Map.delete(@valid_attrs, :address_line_one))
    assert !changeset.valid?
  end

  test "post_code required check" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, Map.delete(@valid_attrs, :post_code))
    assert !changeset.valid?
  end

  test "town required check" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, Map.delete(@valid_attrs, :town))
    assert !changeset.valid?
  end

  test "countries_id required check" do
    changeset = Addressdirectors.changeset(%Addressdirectors{}, Map.delete(@valid_attrs, :countries_id))
    assert !changeset.valid?
  end


  test "check if address_line_one maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_one: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_one: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_one accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_one: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_one: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if address_line_two maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_two: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_two: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_two accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_two: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_two: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if address_line_three maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_three: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_three: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_three accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_three: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{address_line_three: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if town maximum 58 characters" do
    attrs = %{@valid_attrs | town: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{town: ["should be at most 58 character(s)"]} = errors_on(changeset)
  end

  test "check if town accepts only alpha characters" do
    attrs = %{@valid_attrs | town: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{town: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if county maximum 50 characters" do
    attrs = %{@valid_attrs | county: "aaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbcc"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{county: ["should be at most 50 character(s)"]} = errors_on(changeset)
  end

  test "check if county accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | county: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{county: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if post_code maximum 9 characters" do
    attrs = %{@valid_attrs | post_code: "cf14    4tg"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{post_code: ["should be at most 9 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if post_code accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | post_code: "%%%%%^&"}
    changeset = Addressdirectors.changeset(%Addressdirectors{}, attrs)
    assert %{post_code: ["has invalid format"]} = errors_on(changeset)
  end


end