defmodule Violacorp.Schemas.DepartmentsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Departments
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    department_name: "asdasdasd",
    number_of_employee: 50,
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Departments.changeset(%Departments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Departments.changeset(%Departments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "department_name required check" do
    changeset = Departments.changeset(%Departments{}, Map.delete(@valid_attrs, :department_name))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Departments.changeset(%Departments{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "check if department_name format is correct " do
    attrs = %{@valid_attrs | department_name: "####23edrft"}
    changeset = Departments.changeset(%Departments{}, attrs)
    assert %{department_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if department_name maximum 40 numbers" do
    attrs = %{@valid_attrs | department_name: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Departments.changeset(%Departments{}, attrs)
    assert %{department_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if department_name minimum 3 numbers" do
    attrs = %{@valid_attrs | department_name: "sa"}
    changeset = Departments.changeset(%Departments{}, attrs)
    assert  %{department_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if status format has A or D " do
    attrs = %{@valid_attrs | status: "F"}
    changeset = Departments.changeset(%Departments{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

@doc" updateEmployeeNumberchangeset"
  @valid_attrs_employee %{
    number_of_employee: 23
  }

  test "changeset with valid attributes updateEmployeeNumberchangeset" do
    changeset = Departments.updateEmployeeNumberchangeset(%Departments{}, @valid_attrs_employee)
    assert changeset.valid?
  end



end