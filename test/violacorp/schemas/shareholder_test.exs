defmodule Violacorp.Schemas.ShareholderTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Shareholder
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    fullname: "dsfsdfsd dfssddf",
    dob: ~D[1989-02-02],
    type: "P",
    status: "A",
    percentage: 12,
    address: "dgvsdfdsf dddsf",
    inserted_by: 4545,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Shareholder.changeset(%Shareholder{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Shareholder.changeset(%Shareholder{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "fullname required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :fullname))
    assert !changeset.valid?
  end

  test "dob required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :dob))
    assert !changeset.valid?
  end

  test "type required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  test "address required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :address))
    assert !changeset.valid?
  end

  test "percentage required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :percentage))
    assert !changeset.valid?
  end

  test "company_id required check" do
    changeset = Shareholder.changeset(%Shareholder{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "check if fullname format is correct " do
    attrs = %{@valid_attrs | fullname: "####23edrft$%^&*"}
    changeset = Shareholder.changeset(%Shareholder{}, attrs)
    assert %{fullname: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if fullname length is correct " do
    attrs = %{@valid_attrs | fullname: "sdasdasdasdasdsdasdasdasdasdsdasdasdasdasdsdasdasdasdasdsdasdasdasdasdsdasdasdasdasd"}
    changeset = Shareholder.changeset(%Shareholder{}, attrs)
    assert %{fullname: ["should be at most 50 character(s)"]} = errors_on(changeset)
  end

  test "check if type has correct value" do
    attrs = %{@valid_attrs | type: "D"}
    changeset = Shareholder.changeset(%Shareholder{}, attrs)
    assert %{type: ["Make sure you use P or C"]} = errors_on(changeset)
  end

#  test "check if status has correct value" do
#    attrs = %{@valid_attrs | status: "Z"}
#    changeset = Shareholder.changeset(%Shareholder{}, attrs)
#    assert %{status: ["is invalid"]} = errors_on(changeset)
#  end

  test "check if address format is correct " do
    attrs = %{@valid_attrs | address: "####23edrft%^&*()"}
    changeset = Shareholder.changeset(%Shareholder{}, attrs)
    assert %{address: ["has invalid format"]} = errors_on(changeset)
  end


  end