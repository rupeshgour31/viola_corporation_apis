defmodule Violacorp.Schemas.CurrenciesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Currencies
  @moduledoc false

  @valid_attrs %{
    countries_id: 1232,
    currency_name: "GBP",
    currency_code: "321",
    currency_symbol: "&#x00a3;",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Currencies.changeset(%Currencies{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Currencies.changeset(%Currencies{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check" do
    changeset = Currencies.changeset(%Currencies{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "currency_symbol required check" do
    changeset = Currencies.changeset(%Currencies{}, Map.delete(@valid_attrs, :currency_symbol))
    assert !changeset.valid?
  end

  test "currency_code required check" do
    changeset = Currencies.changeset(%Currencies{}, Map.delete(@valid_attrs, :currency_code))
    assert !changeset.valid?
  end

  test "currency_name required check" do
    changeset = Currencies.changeset(%Currencies{}, Map.delete(@valid_attrs, :currency_name))
    assert !changeset.valid?
  end

  test "countries_id required check" do
    changeset = Currencies.changeset(%Currencies{}, Map.delete(@valid_attrs, :countries_id))
    assert !changeset.valid?
  end

  test "check if currency_name format is correct " do
    attrs = %{@valid_attrs | currency_name: "####23edrft"}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{currency_name: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if currency_name maximum 45 numbers" do
    attrs = %{@valid_attrs | currency_name: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{currency_name: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if currency_name minimum 3 numbers" do
    attrs = %{@valid_attrs | currency_name: "a"}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{currency_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end


  test "check if currency_symbol format is correct " do
    attrs = %{@valid_attrs | currency_symbol: "####23edrft!!!!!-="}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{currency_symbol: ["has invalid format"]
           } = errors_on(changeset)
  end

  test "check if currency_symbol maximum 45 numbers" do
    attrs = %{@valid_attrs | currency_symbol: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{currency_symbol: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if status only includes A, D, B" do
    attrs = %{@valid_attrs | status: "V"}
    changeset = Currencies.changeset(%Currencies{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  @doc" updateChangeset"

  @valid_attrs_update %{
  status: "A"
  }
  test "changeset with valid attributes updateChangeset" do
    changeset = Currencies.updateChangeset(%Currencies{}, @valid_attrs_update)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updateChangeset" do
    changeset = Currencies.updateChangeset(%Currencies{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check updateChangeset" do
    changeset = Currencies.updateChangeset(%Currencies{}, Map.delete(@valid_attrs_update, :status))
    assert !changeset.valid?
  end
  test "check if status only includes A, D, B for changeset update" do
    attrs = %{@valid_attrs_update | status: "V"}
    changeset = Currencies.updateChangeset(%Currencies{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

end