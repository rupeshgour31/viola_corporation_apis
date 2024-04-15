defmodule Violacorp.Schemas.AmountlimitsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Amountlimits
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1212,
    account_max_balance: Decimal.from_float(120.20),
    single_transaction_limit: Decimal.from_float(120.20),
    weekly_transaction_limit: Decimal.from_float(120.20),
    monthly_transaction_limit: Decimal.from_float(120.20),
    max_load_per_year_amount: Decimal.from_float(120.20),
    max_load_per_year_count: Decimal.from_float(120.20),
    max_load_per_month_amount: Decimal.from_float(120.20),
    max_load_per_month_count: Decimal.from_float(120.20),
    max_load_per_day_amount: Decimal.from_float(120.20),
    max_load_per_day_count: Decimal.from_float(120.20),
    min_amount: Decimal.from_float(120.20),
    max_amount_card: Decimal.from_float(120.20),
    status: "A",
    inserted_by: 1212,
  }

  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Amountlimits.changeset(%Amountlimits{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Amountlimits.changeset(%Amountlimits{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Amountlimits.changeset(%Amountlimits{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end
end