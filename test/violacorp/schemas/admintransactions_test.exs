defmodule Violacorp.Schemas.AdmintransactionsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Admintransactions
  @moduledoc false

  @valid_attrs %{
    adminaccounts_id: 1,
    amount: Decimal.from_float(120.20),
    currency: "GBP",
    from_user: "GB56CLRB04043100000816",
    to_user: "GB56CLRB04043100000816",
    reference_id: "67362269",
    transaction_id: "b5958619-dd59-4ca4-a5ef-6686de6d87c6",
    api_status: "ACSC",
    end_to_en_identifier: "1128271322",
    mode: "C",
    identification: "GB04CLRB04043100000685",
    transaction_date: ~N[2019-04-25 10:32:23],
    description: "desc",
    status: "S",
    inserted_by: 1212,
  }
#  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Admintransactions.changeset(%Admintransactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "adminaccounts_id required check" do
    changeset = Admintransactions.changeset(%Admintransactions{}, Map.delete(@valid_attrs, :adminaccounts_id))
    assert !changeset.valid?
  end

  test "amount required check" do
    changeset = Admintransactions.changeset(%Admintransactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  @doc" changesetUpdateStatus"

  @valid_attrs_status %{
    status: "S",
    api_status: "ACSC",
    end_to_en_identifier: "1128271322",
    response: "MAP",
  }
  test "changeset with valid attributes status" do
    changeset = Admintransactions.changesetUpdateStatus(%Admintransactions{}, @valid_attrs_status)
    assert changeset.valid?
  end

end