defmodule Violacorp.Schemas.DirectorsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Directors
  @moduledoc false

  @valid_attrs %{
    position: "Director",
    title: "Mr",
    employeeids: "1234",
    email_id: "asd@asc.com",
    first_name: "asasdas",
    middle_name: "asdasda",
    last_name: "asdasdas",
    date_of_birth: ~D[1995-05-05],
    gender: "M",
    status: "A",
    signature: "dfdsfdsf",
    mendate_signature: "Yf",
    access_type: "Y",
    is_primary: "Y",
    verify_kyc: "gbg",
    allocating_cards: "Y",
    as_employee: "Y",
    sequence: 3,
    employee_id: 1212,
    inserted_by: 1212
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Directors.changeset(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Directors.changeset(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check" do
    changeset = Directors.changeset(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end

  test "first_name required check" do
    changeset = Directors.changeset(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end

  test "last_name required check" do
    changeset = Directors.changeset(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end

  test "check if first_name format is correct " do
    attrs = %{@valid_attrs | first_name: "####23edrft%4-="}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert  %{first_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if first_name maximum 40 characters" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name format is correct " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if position format is correct " do
    attrs = %{@valid_attrs | position: "####23edrft%4-="}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert  %{position: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if position maximum 40 characters" do
    attrs = %{@valid_attrs | position: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset(%Directors{}, attrs)
    assert %{position: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

@doc"changeset_update "


  test "changeset with valid attributes changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end

  test "first_name required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end
  test "signature required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :signature))
    assert !changeset.valid?
  end

  test "title required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "gender required check changeset_update" do
    changeset = Directors.changeset_update(%Directors{}, Map.delete(@valid_attrs, :gender))
    assert !changeset.valid?
  end

  test "check if first_name format is correct changeset_update" do
    attrs = %{@valid_attrs | first_name: "####23edrft%4-="}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert  %{first_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if first_name maximum 40 characters changeset_update" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters changeset_update" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end
  test "check if last_name format is correctchangeset_update " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters changeset_update" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters changeset_update" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct changeset_update " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters changeset_update" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if position format is correct changeset_update" do
    attrs = %{@valid_attrs | position: "####23edrft%4-="}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert  %{position: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if position maximum 40 characters changeset_update" do
    attrs = %{@valid_attrs | position: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{position: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end
  test "check if email_id format is correct" do
    attrs = %{@valid_attrs | email_id: "asas"}
    changeset = Directors.changeset_update(%Directors{}, attrs)
    assert %{email_id: ["Please use following format word@word.com"]} = errors_on(changeset)
  end

@doc " changeset_contact"

  test "changeset with valid attributes changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end
  test "title required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end
  test "first_name required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end
  test "date_of_birth required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :date_of_birth))
    assert !changeset.valid?
  end
  test "signature required check changeset_contact" do
    changeset = Directors.changeset_contact(%Directors{}, Map.delete(@valid_attrs, :signature))
    assert !changeset.valid?
  end
  test "signature length max 80 check" do
    attrs = %{@valid_attrs | signature: "ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{signature: ["should be at most 80 character(s)"]} = errors_on(changeset)

  end

  test "check if first_name maximum 40 characters changeset_contact" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters changeset_contact" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end
  test "check if last_name format is correct changeset_contact " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters changeset_contact" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters changeset_contact" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct changeset_contact " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters changeset_contact" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.changeset_contact(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

@doc "reg_step_five "




  test "changeset with valid attributes reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end
  test "title required check reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end
  test "first_name required check reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check reg_step_five" do
    changeset = Directors.reg_step_five(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end

    test "check if first_name maximum 40 characters reg_step_five" do
      attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
    end

    test "check if first_name minimum 3 characters reg_step_five" do
      attrs = %{@valid_attrs | first_name: "ff"}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
    end
    test "check if last_name format is correct reg_step_five " do
      attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
    end

    test "check if last_name maximum 40 characters reg_step_five" do
      attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
    end

    test "check if last_name minimum 3 characters reg_step_five" do
      attrs = %{@valid_attrs | last_name: "ff"}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
    end

    test "check if middle_name format is correct reg_step_five " do
      attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
    end

    test "check if middle_name maximum 40 characters reg_step_five" do
      attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
      changeset = Directors.reg_step_five(%Directors{}, attrs)
      assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
    end

@doc" reg_step_one"

  test "changeset with valid attributes reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end
  test "title required check reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end
  test "first_name required check reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end
  test "signature required check reg_step_one" do
    changeset = Directors.reg_step_one(%Directors{}, Map.delete(@valid_attrs, :signature))
    assert !changeset.valid?
  end

  test "check if first_name maximum 40 characters reg_step_one" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters reg_step_one" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end
  test "check if last_name format is correct reg_step_one " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters reg_step_one" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters reg_step_one" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct reg_step_one " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters reg_step_one" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_one(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

@doc"reg_step_oneV3 "

  test "changeset with valid attributes reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end
  test "title required check reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end
  test "first_name required check reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end
  test "gender required check reg_step_oneV3" do
    changeset = Directors.reg_step_oneV3(%Directors{}, Map.delete(@valid_attrs, :gender))
    assert !changeset.valid?
  end

  test "check if first_name format is correct reg_step_oneV3 " do
    attrs = %{@valid_attrs | first_name: "####23edrft%4-="}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert  %{first_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end
  test "check if first_name maximum 40 characters reg_step_oneV3" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters reg_step_oneV3" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end
  test "check if last_name format is correct reg_step_oneV3 " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters reg_step_oneV3" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters reg_step_oneV3" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct reg_step_oneV3 " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters reg_step_oneV3" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_oneV3(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

@doc" reg_step_fiveV3"

  test "changeset with valid attributes reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "position required check reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, Map.delete(@valid_attrs, :position))
    assert !changeset.valid?
  end
  test "email_id required check reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, Map.delete(@valid_attrs, :email_id))
    assert !changeset.valid?
  end
  test "first_name required check reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end
  test "last_name required check reg_step_fiveV3" do
    changeset = Directors.reg_step_fiveV3(%Directors{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end

  test "check if first_name format is correct reg_step_fiveV3" do
    attrs = %{@valid_attrs | first_name: "####23edrft%4-="}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert  %{first_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if first_name maximum 40 characters reg_step_fiveV3" do
    attrs = %{@valid_attrs | first_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if first_name minimum 3 characters reg_step_fiveV3" do
    attrs = %{@valid_attrs | first_name: "ff"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{first_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end
  test "check if last_name format is reg_step_fiveV3 " do
    attrs = %{@valid_attrs | last_name: "####23edrft%4-="}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert  %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters reg_step_fiveV3" do
    attrs = %{@valid_attrs | last_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name minimum 3 characters reg_step_fiveV3" do
    attrs = %{@valid_attrs | last_name: "ff"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{last_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct reg_step_fiveV3 " do
    attrs = %{@valid_attrs | middle_name: "####23edrft%4-="}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert  %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters reg_step_fiveV3" do
    attrs = %{@valid_attrs | middle_name: "fddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if email_id format is correct reg_step_fiveV3" do
    attrs = %{@valid_attrs | email_id: "asas"}
    changeset = Directors.reg_step_fiveV3(%Directors{}, attrs)
    assert %{email_id: ["has invalid format"]} = errors_on(changeset)
  end

  @doc"allocating_cards "


  test "changeset with valid attributes allocating_cards" do
    changeset = Directors.allocating_cards(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes allocating_cards" do
    changeset = Directors.allocating_cards(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "allocating_cards required check allocating_cards" do
    changeset = Directors.allocating_cards(%Directors{}, Map.delete(@valid_attrs, :allocating_cards))
    assert !changeset.valid?
  end

  @doc"update_status "


  test "changeset with valid attributes update_status" do
    changeset = Directors.update_status(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc"updateDob "


  test "changeset with valid attributes updateDob" do
    changeset = Directors.updateDob(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updateDob" do
    changeset = Directors.updateDob(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "DOB required check updateDob" do
    changeset = Directors.updateDob(%Directors{}, Map.delete(@valid_attrs, :date_of_birth))
    assert !changeset.valid?
  end

  @doc"update_gender "


  test "changeset with valid attributes update_gender" do
    changeset = Directors.update_gender(%Directors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update_gender" do
    changeset = Directors.update_gender(%Directors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "gender required check update_gender" do
    changeset = Directors.update_gender(%Directors{}, Map.delete(@valid_attrs, :gender))
    assert !changeset.valid?
  end

  test "check if gender format is correct update_gender" do
    attrs = %{@valid_attrs | gender: "R"}
    changeset = Directors.update_gender(%Directors{}, attrs)
    assert %{gender: ["is invalid"]} = errors_on(changeset)
  end

end