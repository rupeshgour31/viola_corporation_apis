defmodule Violacorp.Schemas.AdminaccountsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Adminaccounts
  @moduledoc false

  @valid_attrs %{
    administratorusers_id: 2,
    account_id: "965372d2-8c65-49f2-b14a-f66cfca45f7e",
    account_number: "00000802",
    account_name: "Fee Account",
    iban_number: "GB46CLRB04043100000802",
    bban_number: "GB46CLRB04043100000802",
    currency: "GBP",
    balance: Decimal.from_float(100.50),
    viola_balance: Decimal.from_float(100.50),
    sort_code: "34-34-34",
    bank_code: "CLBR",
    bank_type: "CACC",
    bank_status: "VALU",
    request: "MAP",
    response: "MAP",
    type: "FEE",
    status: "A",
    inserted_by: 2
  }
  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Adminaccounts.changeset(%Adminaccounts{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Adminaccounts.changeset(%Adminaccounts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "account_number required check" do
    changeset = Adminaccounts.changeset(%Adminaccounts{}, Map.delete(@valid_attrs, :account_number))
    assert !changeset.valid?
  end

  @doc" changesetFailed"
  @valid_attrs_failed %{
    administratorusers_id: 2,
    request: "MAP",
    response: "MAP",
    type: "FEE",
    status: "A",
    inserted_by: 2
  }

  test "changeset with valid attributes for Failed" do
    changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, @valid_attrs_failed)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for Failed" do
    changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "request required check for Failed" do
    changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, Map.delete(@valid_attrs_failed, :request))
    assert !changeset.valid?
  end

    test "response required check for Failed" do
    changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, Map.delete(@valid_attrs_failed, :response))
    assert !changeset.valid?
  end

  @doc" changesetUpdateBalance"

  @valid_attrs_balance %{
    balance: Decimal.from_float(120.20)
  }

  test "changeset with valid attributes for Balance" do
    changeset = Adminaccounts.changesetUpdateBalance(%Adminaccounts{}, @valid_attrs_balance)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for Balance" do
    changeset = Adminaccounts.changesetUpdateBalance(%Adminaccounts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "balance required check for Balance" do
    changeset = Adminaccounts.changesetUpdateBalance(%Adminaccounts{}, Map.delete(@valid_attrs_balance, :balance))
    assert !changeset.valid?
  end

  @doc " changesetUpdateViolaBalance"

  @valid_attrs_viola %{
    balance: Decimal.from_float(120.20),
    viola_balance: Decimal.from_float(120.20)
  }

  test "changeset with valid attributes for ViolaBalance" do
    changeset = Adminaccounts.changesetUpdateViolaBalance(%Adminaccounts{}, @valid_attrs_viola)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for ViolaBalance" do
    changeset = Adminaccounts.changesetUpdateViolaBalance(%Adminaccounts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "viola_balance required check for ViolaBalance" do
    changeset = Adminaccounts.changesetUpdateViolaBalance(%Adminaccounts{}, Map.delete(@valid_attrs_viola, :viola_balance))
    assert !changeset.valid?
  end

end