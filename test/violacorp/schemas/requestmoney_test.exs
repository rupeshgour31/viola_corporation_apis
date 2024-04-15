defmodule Violacorp.Schemas.RequestmoneyTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Requestmoney
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    cur_code: "GBP",
    amount: Decimal.from_float(120.20),
    reason: "Yfsdfsdf",
    status: "A",
    company_reason: "fdfdsfsdfsdf",
    employeecards_id: 454534,
    employee_id: 4545,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Requestmoney.changeset(%Requestmoney{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Requestmoney.changeset(%Requestmoney{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "employee_id required check" do
    changeset = Requestmoney.changeset(%Requestmoney{}, Map.delete(@valid_attrs, :employee_id))
    assert !changeset.valid?
  end

  test "employeecards_id required check" do
    changeset = Requestmoney.changeset(%Requestmoney{}, Map.delete(@valid_attrs, :employeecards_id))
    assert !changeset.valid?
  end

  test "amount required check" do
    changeset = Requestmoney.changeset(%Requestmoney{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end


  test "reason required check" do
    changeset = Requestmoney.changeset(%Requestmoney{}, Map.delete(@valid_attrs, :reason))
    assert !changeset.valid?
  end

  test "check if reason max length 60 " do
    attrs = %{@valid_attrs | reason: "sdfsafdasdasdassdfsafdasdasdassdfsafdasdasdassdfsafdasdasdassdfsafdasdasdas"}
    changeset = Requestmoney.changeset(%Requestmoney{}, attrs)
    assert %{reason: ["should be at most 60 character(s)"]} = errors_on(changeset)
  end

  test "check if amount is not 0" do
    attrs = %{@valid_attrs | amount: "sdfsafdasdasdassdfsafdasdasdassdfsafdasdasdassdfsafdasdasdassdfsafdasdasdas"}
    changeset = Requestmoney.changeset(%Requestmoney{}, attrs)
    assert %{amount: ["is invalid"]} = errors_on(changeset)
  end


  @doc "updatestatus_changeset "

  test "changeset with valid attributes updatestatus_changeset" do
    changeset = Requestmoney.updatestatus_changeset(%Requestmoney{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updatestatus_changeset" do
    changeset = Requestmoney.updatestatus_changeset(%Requestmoney{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check updatestatus_changeset" do
    changeset = Requestmoney.updatestatus_changeset(%Requestmoney{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  end