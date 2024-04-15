defmodule Violacorp.Schemas.CompanyaccountsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Companyaccounts
  @moduledoc false

  @valid_attrs %{
    company_id: 1217,
    currencies_id: 1,
    currency_code: "GBP",
    available_balance: Decimal.from_float(120.20),
    current_balance: 5000.25,
    account_number: 12345678,
    accomplish_account_number: "123456789",
    accomplish_account_id: 1234,
    bin_id: "125415",
    expiry_date: ~D[2028-05-08],
    source_id: "dsdfsdfsdfsdfdsfdsfdsfds",
    status: "A",
    reason: "1221sdasdasd",
    inserted_by: 1221
  }
#  @invalid_attrs %{}

  test "changeset with valid attributes for valid_attrs_changesetContact" do
    changeset = Companyaccounts.changeset(%Companyaccounts{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc " changesetBalance"

  @valid_attrs_changesetBalance %{
    landline_number: "07411542587"
  }

  test "changeset with valid attributes for valid_attrs_changesetBalance" do
    changeset = Companyaccounts.changesetBalance(%Companyaccounts{}, @valid_attrs_changesetBalance)
    assert changeset.valid?
  end

  @doc " changesetStatus"

  @valid_attrs_changesetStatus %{
    landline_number: "07411542587",
    reason: "reason"
  }

  test "changeset with valid attributes for changesetStatus" do
    changeset = Companyaccounts.changesetStatus(%Companyaccounts{}, @valid_attrs_changesetStatus)
    assert changeset.valid?
  end

end