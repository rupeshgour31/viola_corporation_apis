defmodule Violacorp.Schemas.EmployeeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Employee
  @moduledoc false

  @valid_attrs %{
    group_id: 1,
    group_member_id: 12,
    title: "Mr",
    employeeids: "3422",
    position: "Manager",
    first_name: "Peter",
    middle_name: "A",
    last_name: "Capaldi",
    date_of_birth: ~D[1995-02-02],
    gender: "M",
    verify_kyc: "gbg",
    profile_picture: "",
    is_manager: "N",
    no_of_cards: 3,
    director_id: 221,
    status: "A",
    terms_accepted: "Y",
    terms_accepted_at: ~N[2019-06-06 11:52:41],
    inserted_by: 1221
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Employee.changeset(%Employee{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Employee.changeset(%Employee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Employee.changeset(%Employee{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "first_name required check" do
    changeset = Employee.changeset(%Employee{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end

  test "last_name required check" do
    changeset = Employee.changeset(%Employee{}, Map.delete(@valid_attrs, :last_name))
    assert !changeset.valid?
  end

  test "gender required check" do
    changeset = Employee.changeset(%Employee{}, Map.delete(@valid_attrs, :gender))
    assert !changeset.valid?
  end


  test "check if first_name format is correct " do
    attrs = %{@valid_attrs | first_name: "----------------%"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{first_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if first_name maximum 40 characters" do
    attrs = %{@valid_attrs | first_name: "asbveterdfssasbveterdfssasbveterdfssasbveterdfss"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{first_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if middle_name format is correct " do
    attrs = %{@valid_attrs | middle_name: "----------------%"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{middle_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if middle_name maximum 40 characters" do
    attrs = %{@valid_attrs | middle_name: "asbveterdfssasbveterdfssasbveterdfssasbveterdfss"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{middle_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name format is correct " do
    attrs = %{@valid_attrs | last_name: "----------------%"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{last_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if last_name maximum 40 characters" do
    attrs = %{@valid_attrs | last_name: "asbveterdfssasbveterdfssasbveterdfssasbveterdfss"}
    changeset = Employee.changeset(%Employee{}, attrs)
    assert %{last_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

@doc " changesetStatus"

  @valid_attrs_status %{
    status: "A"
  }

  test "changeset with valid attributes for status changeset" do
    changeset = Employee.changesetStatus(%Employee{}, @valid_attrs_status)
    assert changeset.valid?
  end

  test "check if status contains correct values" do
    attrs = %{@valid_attrs | status: "V"}
    changeset = Employee.changesetStatus(%Employee{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

@doc " updateEmployeeCardschangeset"

@valid_attrs_updateEmployeeCards %{
  no_of_cards: 4
}

  test "changeset with valid attributes for updateEmployeeCardschangeset" do
    changeset = Employee.updateEmployeeCardschangeset(%Employee{}, @valid_attrs_updateEmployeeCards)
    assert changeset.valid?
  end


@doc " departmentToNull"

@valid_attrs_departmentToNull %{
  departments_id: 423
}

  test "changeset with valid attributes for departmentToNull" do
    changeset = Employee.departmentToNull(%Employee{}, @valid_attrs_departmentToNull)
    assert changeset.valid?
  end

@doc " updateTerms"

  @valid_attrs_updateTerms %{
    terms_accepted: "Yes",
    status: "A",
    terms_accepted_at: ~N[2019-06-06 11:52:41]
  }

  test "changeset with valid attributes for updateTerms" do
    changeset = Employee.updateTerms(%Employee{}, @valid_attrs_updateTerms)
    assert changeset.valid?
  end

@doc " changesetDirector"

  @valid_attrs_changesetDirector %{
    director_id: 1231
  }

  test "changeset with valid attributes for changesetDirector" do
    changeset = Employee.changesetDirector(%Employee{}, @valid_attrs_changesetDirector)
    assert changeset.valid?
  end


@doc " update_gender"

  @valid_attrs_update_gender %{
    gender: "M"
  }

  test "changeset with valid attributes for update_gender" do
    changeset = Employee.update_gender(%Employee{}, @valid_attrs_update_gender)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update_gender" do
    changeset = Employee.update_gender(%Employee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "gender required check update_gender" do
    changeset = Employee.update_gender(%Employee{}, Map.delete(@valid_attrs_update_gender, :gender))
    assert !changeset.valid?
  end


  test "check if gender contains correct values update_gender" do
    attrs = %{@valid_attrs_update_gender | gender: "V"}
    changeset = Employee.update_gender(%Employee{}, attrs)
    assert %{gender: ["is invalid"]} = errors_on(changeset)
  end


  @doc " changesetVerifyKyc"

  @valid_attrs_changesetVerifyKyc %{
    verify_kyc: "gbg"
  }

  test "changeset with valid attributes for changesetVerifyKyc" do
    changeset = Employee.changesetVerifyKyc(%Employee{}, @valid_attrs_changesetVerifyKyc)
    assert changeset.valid?
  end


  @doc " changesetDob"

  @valid_attrs_changesetDob %{
    date_of_birth: ~D[1989-02-02]
  }

  test "changeset with valid attributes for changesetDob" do
    changeset = Employee.changesetDob(%Employee{}, @valid_attrs_changesetDob)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetDob" do
    changeset = Employee.changesetDob(%Employee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "date_of_birth required check changesetDob" do
    changeset = Employee.changesetDob(%Employee{}, Map.delete(@valid_attrs_changesetDob, :date_of_birth))
    assert !changeset.valid?
  end










  end