defmodule Violacorp.Schemas.CardTransactionsandReceiptsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.CardTransactionsandReceipts
  @moduledoc false

  @valid_attrs %{
    total_amount: 150.20,
    total_receipt_pending: 4,
    total_transactions: 1
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = CardTransactionsandReceipts.changeset(%CardTransactionsandReceipts{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CardTransactionsandReceipts.changeset(%CardTransactionsandReceipts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "total_amount required check" do
    changeset = CardTransactionsandReceipts.changeset(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs, :total_amount))
    assert !changeset.valid?
  end

  test "total_receipt_pending required check" do
    changeset = CardTransactionsandReceipts.changeset(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs, :total_receipt_pending))
    assert !changeset.valid?
  end

  test "total_transactions required check" do
    changeset = CardTransactionsandReceipts.changeset(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs, :total_transactions))
    assert !changeset.valid?
  end

  @doc "changesetUpdatePending "

  @valid_attrs_UpdatePending %{
    total_receipt_pending: 2
  }
  test "changeset with valid attributes UpdatePending" do
    changeset = CardTransactionsandReceipts.changesetUpdatePending(%CardTransactionsandReceipts{}, @valid_attrs_UpdatePending)
    assert changeset.valid?
  end

  test "changeset with invalid attributes UpdatePending" do
    changeset = CardTransactionsandReceipts.changesetUpdatePending(%CardTransactionsandReceipts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "total_receipt_pending required check UpdatePending" do
    changeset = CardTransactionsandReceipts.changesetUpdatePending(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs_UpdatePending, :total_receipt_pending))
    assert !changeset.valid?
  end

  @doc " changesetTransactionCount"

  @valid_attrs_count %{
    total_amount: 150.20,
    employeecards_id: 4,
    total_transactions: 1
  }

  test "changeset with valid attributes count" do
    changeset = CardTransactionsandReceipts.changesetTransactionCount(%CardTransactionsandReceipts{}, @valid_attrs_count)
    assert changeset.valid?
  end

  test "changeset with invalid attributes count" do
    changeset = CardTransactionsandReceipts.changesetTransactionCount(%CardTransactionsandReceipts{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "total_amount required check for count" do
    changeset = CardTransactionsandReceipts.changesetTransactionCount(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs_count, :total_amount))
    assert !changeset.valid?
  end

  test "employeecards_id required check for count" do
    changeset = CardTransactionsandReceipts.changesetTransactionCount(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs_count, :employeecards_id))
    assert !changeset.valid?
  end

  test "total_transactions required check for count" do
    changeset = CardTransactionsandReceipts.changesetTransactionCount(%CardTransactionsandReceipts{}, Map.delete(@valid_attrs_count, :total_transactions))
    assert !changeset.valid?
  end

  @doc"changesetInsertorUpdate"

  @valid_attrs_InsertorUpdate %{
    total_amount: 150.20,
    employeecards_id: 4,
    total_transactions: 1
  }

  test "changeset with valid attributes for changesetInsertorUpdate" do
    changeset = CardTransactionsandReceipts.changesetInsertorUpdate(%CardTransactionsandReceipts{}, @valid_attrs_InsertorUpdate)
    assert changeset.valid?
  end
end