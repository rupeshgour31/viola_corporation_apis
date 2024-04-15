defmodule Violacorp.Schemas.GroupfeeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Groupfee
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    feehead_id: 1232,
    amount: Decimal.from_float(120.20),
    fee_type: "F",
    trans_type: "ONE",
    rules: "Asdcsc",
    mode: "D",
    status: "A",
    as_default: "Yes",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Groupfee.changeset(%Groupfee{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Groupfee.changeset(%Groupfee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "feehead_id required check" do
    changeset = Groupfee.changeset(%Groupfee{}, Map.delete(@valid_attrs, :feehead_id))
    assert !changeset.valid?
  end

  test "amount required check" do
    changeset = Groupfee.changeset(%Groupfee{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_type required check" do
    changeset = Groupfee.changeset(%Groupfee{}, Map.delete(@valid_attrs, :fee_type))
    assert !changeset.valid?
  end

  test "trans_type required check" do
    changeset = Groupfee.changeset(%Groupfee{}, Map.delete(@valid_attrs, :trans_type))
    assert !changeset.valid?
  end

  test "check if fee_type is valid value" do
    attrs = %{@valid_attrs | fee_type: "S"}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{fee_type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if trans_type is valid value" do
    attrs = %{@valid_attrs | trans_type: "S"}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{trans_type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if mode is valid value" do
    attrs = %{@valid_attrs | mode: "S"}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{mode: ["is invalid"]} = errors_on(changeset)
  end

  test "check if status is valid value" do
    attrs = %{@valid_attrs | status: "S"}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "check if as_default is valid value" do
    attrs = %{@valid_attrs | as_default: "S"}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{as_default: ["is invalid"]} = errors_on(changeset)
  end

  test "check if amount is valid value" do
    attrs = %{@valid_attrs | amount: 0.00}
    changeset = Groupfee.changeset(%Groupfee{}, attrs)
    assert %{amount: ["must be greater than 0.00"]} = errors_on(changeset)
  end



  end