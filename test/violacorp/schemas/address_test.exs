defmodule Violacorp.Schemas.AddressTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Address
  @moduledoc false

  @valid_attrs %{
    commanall_id: 331,
    countries_id: 53,
    address_line_one: "Address_line_one",
    address_line_two: "address_line_two",
    address_line_three: "address_line_three",
    town: "town",
    sequence: 1,
    county: "county",
    post_code: "cf313ph",
    is_primary: "Y",
    inserted_by: 1212,
  }

  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Address.changeset(%Address{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Address.changeset(%Address{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "address_line_one required check" do
    changeset = Address.changeset(%Address{}, Map.delete(@valid_attrs, :address_line_one))
    assert !changeset.valid?
  end

  test "town required check" do
    changeset = Address.changeset(%Address{}, Map.delete(@valid_attrs, :town))
    assert !changeset.valid?
  end

  test "post_code required check" do
    changeset = Address.changeset(%Address{}, Map.delete(@valid_attrs, :post_code))
    assert !changeset.valid?
  end

  test "check if address_line_one maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_one: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_one: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_one accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_one: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_one: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if address_line_two maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_two: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_two: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_two accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_two: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_two: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if address_line_three maximum 40 characters" do
    attrs = %{@valid_attrs | address_line_three: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_three: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if address_line_three accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | address_line_three: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{address_line_three: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if town maximum 58 characters" do
    attrs = %{@valid_attrs | town: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{town: ["should be at most 58 character(s)"]} = errors_on(changeset)
  end

  test "check if town accepts only alpha characters" do
    attrs = %{@valid_attrs | town: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{town: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if county maximum 50 characters" do
    attrs = %{@valid_attrs | county: "aaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbcc"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{county: ["should be at most 50 character(s)"]} = errors_on(changeset)
  end

  test "check if county accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | county: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{county: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if post_code maximum 9 characters" do
    attrs = %{@valid_attrs | post_code: "cf14    4tg"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{post_code: ["should be at most 9 character(s)",
                             "has invalid format"]} = errors_on(changeset)
  end

  test "check if post_code accepts only alpha numeric characters" do
    attrs = %{@valid_attrs | post_code: "%%%%%^&"}
    changeset = Address.changeset(%Address{}, attrs)
    assert %{post_code: ["has invalid format"]} = errors_on(changeset)
  end

  @doc" changeset_trading"

  @valid_attrs_trading %{
    commanall_id: 255,
    t_countries_id: 53,
    t_address_line_one: "t_address_line_one",
    t_address_line_two: "t_address_line_two",
    t_address_line_three: "t_address_line_three",
    t_town: "t_town",
    sequence: 1,
    t_county: "t_county",
    t_post_code: "cf313ph",
    is_primary: "Y",
    inserted_by: 1212,
  }

  test "changeset with valid attributes for trading" do
    changeset = Address.changeset_trading(%Address{}, @valid_attrs_trading)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for trading" do
    changeset = Address.changeset_trading(%Address{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "address_line_one required check for trading" do
    changeset = Address.changeset_trading(%Address{}, Map.delete(@valid_attrs_trading, :t_address_line_one))
    assert !changeset.valid?
  end

  test "t_town required check for trading" do
    changeset = Address.changeset_trading(%Address{}, Map.delete(@valid_attrs_trading, :t_town))
    assert !changeset.valid?
  end

  test "t_post_code required check for trading" do
    changeset = Address.changeset_trading(%Address{}, Map.delete(@valid_attrs_trading, :t_post_code))
    assert !changeset.valid?
  end

  test "check if t_address_line_one maximum 40 characters" do
    attrs = %{@valid_attrs_trading | t_address_line_one: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_one: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if t_address_line_one accepts only alpha numeric characters" do
    attrs = %{@valid_attrs_trading | t_address_line_one: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_one: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if t_address_line_two maximum 40 characters" do
    attrs = %{@valid_attrs_trading | t_address_line_two: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_two: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if t_address_line_two accepts only alpha numeric characters" do
    attrs = %{@valid_attrs_trading | t_address_line_two: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_two: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if t_address_line_three maximum 40 characters" do
    attrs = %{@valid_attrs_trading | t_address_line_three: "321231231232123fsdfsdf21sdFdsFDSfsdFsDFSDfsdFSDfsdFSDFDSfsdFsdFsDfSDfsdFsdFsFsFsDfSD"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_three: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if t_address_line_three accepts only alpha numeric characters" do
    attrs = %{@valid_attrs_trading | t_address_line_three: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_address_line_three: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if t_town maximum 58 characters" do
    attrs = %{@valid_attrs_trading | t_town: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_town: ["should be at most 58 character(s)"]} = errors_on(changeset)
  end

  test "check if t_town accepts only alpha characters" do
    attrs = %{@valid_attrs_trading | t_town: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_town: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if t_county maximum 50 characters" do
    attrs = %{@valid_attrs_trading | t_county: "aaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbccaaaabbbbcc"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_county: ["should be at most 50 character(s)"]} = errors_on(changeset)
  end

  test "check if t_county accepts only alpha numeric characters" do
    attrs = %{@valid_attrs_trading | t_county: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_county: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if t_post_code maximum 9 characters" do
    attrs = %{@valid_attrs_trading | t_post_code: "cf14    4tg"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_post_code: ["should be at most 9 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if t_post_code accepts only alpha numeric characters" do
    attrs = %{@valid_attrs_trading | t_post_code: "%%%%%^&"}
    changeset = Address.changeset_trading(%Address{}, attrs)
    assert %{t_post_code: ["has invalid format"]} = errors_on(changeset)
  end


end
