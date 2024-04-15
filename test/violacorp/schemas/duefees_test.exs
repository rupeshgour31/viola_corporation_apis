defmodule Violacorp.Schemas.DuefeesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Duefees
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    amount: Decimal.from_float(120.20),
    description: "sdcsdcsdcsdc",
    status: "A",
    pay_date: ~N[2019-05-02 06:56:35],
    next_date: ~N[2019-05-02 06:56:35],
    type: "M",
    remark: "zdfbzdfzdf",
    reason: "zdfbzdfbdzfb",
    total_cards: 3,
    inserted_by: 3432
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Duefees.changeset(%Duefees{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Duefees.changeset(%Duefees{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "amount required check" do
    changeset = Duefees.changeset(%Duefees{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  @doc" changesetStatus"

  test "changeset with valid attributes changesetStatus" do
    changeset = Duefees.changesetStatus(%Duefees{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetStatus" do
    changeset = Duefees.changesetStatus(%Duefees{}, @invalid_attrs)
    refute changeset.valid?
  end
  test "status required check changesetStatus" do
    changeset = Duefees.changesetStatus(%Duefees{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  @doc" changesetReason"

  test "changeset with valid attributes changesetReason" do
    changeset = Duefees.changesetReason(%Duefees{}, @valid_attrs)
    assert changeset.valid?
  end

  end