defmodule Violacorp.Schemas.FeeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Fee
  @moduledoc false

  @valid_attrs %{
    title: "dsadasd",
    amount: Decimal.from_float(120.20),
    type: "F",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Fee.changeset(%Fee{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Fee.changeset(%Fee{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Fee.changeset(%Fee{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end



  end