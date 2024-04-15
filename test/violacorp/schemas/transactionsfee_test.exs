defmodule Violacorp.Schemas.TransactionsfeeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Transactionsfee
  @moduledoc false

  @valid_attrs %{
    transactions_id: 1232,
    groupfee_id: 2323,
    fee_amount: "120.20",
    fee_type: "F",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Transactionsfee.changeset(%Transactionsfee{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Transactionsfee.changeset(%Transactionsfee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "groupfee_id required check" do
    changeset = Transactionsfee.changeset(%Transactionsfee{}, Map.delete(@valid_attrs, :groupfee_id))
    assert !changeset.valid?
  end


  @doc " groupfee_id"

  test "changeset with valid attributes groupfee_id" do
    changeset = Transactionsfee.groupfee_id(%Transactionsfee{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes groupfee_id" do
    changeset = Transactionsfee.groupfee_id(%Transactionsfee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "groupfee_id required check groupfee_id" do
    changeset = Transactionsfee.groupfee_id(%Transactionsfee{}, Map.delete(@valid_attrs, :groupfee_id))
    assert !changeset.valid?
  end


  end