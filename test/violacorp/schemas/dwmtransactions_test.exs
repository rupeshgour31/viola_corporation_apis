defmodule Violacorp.Schemas.DwmtransactionsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Dwmtransactions
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    account_success_amount: Decimal.from_float(120.20),
    account_failed_amount: Decimal.from_float(120.20),
    account_success_count: 1,
    account_failed_count: 3,
    card_success_amount: Decimal.from_float(120.20),
    card_failed_amount: Decimal.from_float(120.20),
    card_success_count: 22,
    card_failed_count: 25,
    trans_date: ~D[2023-12-12],
    status: "A",
    inserted_by: 1232
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Dwmtransactions.changeset(%Dwmtransactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Dwmtransactions.changeset(%Dwmtransactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Dwmtransactions.changeset(%Dwmtransactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


end