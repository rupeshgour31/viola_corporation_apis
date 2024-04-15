defmodule Violacorp.Schemas.TransactionsreceiptTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Transactionsreceipt
  @moduledoc false

  @valid_attrs %{
    transactions_id: 1232,
    receipt_name: "dfgsdfsf",
    receipt_url: "sfsdfsdf",
    comments: "sdfdsfdsf",
    content: "Asdfsdfdsfdsf",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "transactions_id required check" do
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, Map.delete(@valid_attrs, :transactions_id))
    assert !changeset.valid?
  end

#  test "check if receipt_name format is correct " do
#    attrs = %{@valid_attrs | receipt_name: "::::::@|"}
#    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, attrs)
#    assert %{receipt_name: ["has invalid format"]} = errors_on(changeset)
#  end

  test "check if receipt_name length max 150" do
    attrs = %{@valid_attrs | receipt_name: "sedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsf"}
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, attrs)
    assert %{receipt_name: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if receipt_url length max 150" do
    attrs = %{@valid_attrs | receipt_url: "sedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsf"}
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, attrs)
    assert %{receipt_url: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if comments length max 255" do
    attrs = %{@valid_attrs | comments: "sedfsfdfsfsdfdsfsedfsfsdfdsfsedfsfdfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsfsedfsfsdfdsf"}
    changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, attrs)
    assert %{comments: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end


  @doc"changesetUpdate "

  test "changeset with valid attributes changesetUpdate" do
    changeset = Transactionsreceipt.changesetUpdate(%Transactionsreceipt{}, @valid_attrs)
    assert changeset.valid?
  end


end