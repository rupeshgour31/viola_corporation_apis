defmodule Violacorp.Schemas.CompanybankaccountTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Companybankaccount
  @moduledoc false

  @valid_attrs %{
    account_id: "12123",
    account_number: "25252658",
    account_name: "Account Name",
    iban_number: "gbuk121541285695",
    bban_number: "gbuk4512555552525552",
    currency: "GBP",
    balance: Decimal.from_float(120.20),
    sort_code: "20-04-02",
    bank_code: "GBUKB",
    bank_type: "S",
    bank_status: "A",
    request: "request",
    response: "response",
    status: "A",
    inserted_by: 1231
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "account_number required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :account_number))
    assert !changeset.valid?
  end

  test "account_id required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :account_id))
    assert !changeset.valid?
  end

  test "account_name required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :account_name))
    assert !changeset.valid?
  end

  test "iban_number required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :iban_number))
    assert !changeset.valid?
  end

  test "bban_number required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :bban_number))
    assert !changeset.valid?
  end

  test "currency required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :currency))
    assert !changeset.valid?
  end

  test "balance required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "sort_code required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :sort_code))
    assert !changeset.valid?
  end

  test "bank_code required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :bank_code))
    assert !changeset.valid?
  end

  test "bank_type required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :bank_type))
    assert !changeset.valid?
  end

  test "bank_status required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :bank_status))
    assert !changeset.valid?
  end

  test "inserted_by required check" do
    changeset = Companybankaccount.changeset(%Companybankaccount{}, Map.delete(@valid_attrs, :inserted_by))
    assert !changeset.valid?
  end

  test "check if incorrect format account_id" do
    attrs = %{@valid_attrs | account_id: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_id: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format account_name" do
    attrs = %{@valid_attrs | account_name: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format account_number" do
    attrs = %{@valid_attrs | account_number: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format bank_code" do
    attrs = %{@valid_attrs | bank_code: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_code: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format bank_status" do
    attrs = %{@valid_attrs | bank_status: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_status: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format bank_type" do
    attrs = %{@valid_attrs | bank_type: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_type: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format bban_number" do
    attrs = %{@valid_attrs | bban_number: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bban_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format currency" do
    attrs = %{@valid_attrs | currency: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{currency: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format iban_number" do
    attrs = %{@valid_attrs | iban_number: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{iban_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if incorrect format sort_code" do
    attrs = %{@valid_attrs | sort_code: "####"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{sort_code: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if account_id maximum 255 characters" do
    attrs = %{@valid_attrs | account_id: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_id: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if account_number maximum 15 characters" do
    attrs = %{@valid_attrs | account_number: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_number: ["should be at most 15 character(s)"]} = errors_on(changeset)
  end

  test "check if account_name maximum 45 characters" do
    attrs = %{@valid_attrs | account_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{account_name: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if iban_number maximum 45 characters" do
    attrs = %{@valid_attrs | iban_number: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{iban_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if bban_number maximum 45 characters" do
    attrs = %{@valid_attrs | bban_number: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bban_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if currency maximum 4 characters" do
    attrs = %{@valid_attrs | currency: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{currency: ["should be at most 4 character(s)"]} = errors_on(changeset)
  end

  test "check if sort_code maximum 10 characters" do
    attrs = %{@valid_attrs | sort_code: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{sort_code: ["should be at most 10 character(s)"]} = errors_on(changeset)
  end

  test "check if bank_code maximum 10 characters" do
    attrs = %{@valid_attrs | bank_code: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_code: ["should be at most 10 character(s)"]} = errors_on(changeset)
  end

  test "check if bank_type maximum 10 characters" do
    attrs = %{@valid_attrs | bank_type: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_type: ["should be at most 10 character(s)"]} = errors_on(changeset)
  end

  test "check if bank_status maximum 10 characters" do
    attrs = %{@valid_attrs | bank_status: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Companybankaccount.changeset(%Companybankaccount{}, attrs)
    assert %{bank_status: ["should be at most 10 character(s)"]} = errors_on(changeset)
  end

  @doc "changeset_update"

  @valid_attrs_update %{
    company_id: 12321,
    account_id: "12321",
    account_number: "21215454",
    account_name: "aberjan",
    iban_number: "sdf521454545454",
    bban_number: "ds5454545454555",
    currency: "GBP",
    balance: Decimal.from_float(120.20),
    sort_code: "123265",
    bank_type: "AS",
    bank_status: "A",
    request: "Request",
    response: "Response",
    inserted_by: 12122,
    status: "A"
  }

  test "changeset with valid attributes changesetUpdate" do
    changeset = Companybankaccount.changesetUpdate(%Companybankaccount{}, @valid_attrs_update)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetUpdate" do
    changeset = Companybankaccount.changesetUpdate(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "account_number required check changesetUpdate" do
    changeset = Companybankaccount.changesetUpdate(%Companybankaccount{}, Map.delete(@valid_attrs_update, :account_number))
    assert !changeset.valid?
  end

  @doc "changesetFirstCall"

  @valid_attrs_changesetFirstCall %{
    company_id: 12321,
    account_name: "aberjan",
    inserted_by: 12122,
    status: "A"
  }

  test "changeset with valid attributes changesetFirstCall" do
    changeset = Companybankaccount.changesetFirstCall(%Companybankaccount{}, @valid_attrs_changesetFirstCall)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetFirstCall" do
    changeset = Companybankaccount.changesetFirstCall(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "account_name required check changesetFirstCall" do
    changeset = Companybankaccount.changesetFirstCall(%Companybankaccount{}, Map.delete(@valid_attrs_changesetFirstCall, :account_name))
    assert !changeset.valid?
  end

  @doc"changesetFailed "

  @valid_attrs_changesetFailed %{
    company_id: 12321,
    request: "Request",
    response: "Response",
    inserted_by: 12122,
    status: "A"
  }

  test "changeset with valid attributes changesetFailed" do
    changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, @valid_attrs_changesetFailed)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetFailed" do
    changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "request required check changesetFailed" do
    changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, Map.delete(@valid_attrs_changesetFailed, :request))
    assert !changeset.valid?
  end

  test "response required check changesetFailed" do
    changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, Map.delete(@valid_attrs_changesetFailed, :response))
    assert !changeset.valid?
  end

  @doc"changesetStatus "

  @valid_attrs_changesetStatus %{
    status: "A"
  }

  test "changeset with valid attributes changesetStatus" do
    changeset = Companybankaccount.changesetStatus(%Companybankaccount{}, @valid_attrs_changesetStatus)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetStatus" do
    changeset = Companybankaccount.changesetStatus(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "request required check changesetStatus" do
    changeset = Companybankaccount.changesetStatus(%Companybankaccount{}, Map.delete(@valid_attrs_changesetStatus, :status))
    assert !changeset.valid?
  end
  @doc"changesetUpdateBalance "

  @valid_attrs_changesetUpdateBalance %{
    balance: Decimal.from_float(120.20)
  }

  test "changeset with valid attributes changesetUpdateBalance" do
    changeset = Companybankaccount.changesetUpdateBalance(%Companybankaccount{}, @valid_attrs_changesetUpdateBalance)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetUpdateBalance" do
    changeset = Companybankaccount.changesetUpdateBalance(%Companybankaccount{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "request required check changesetUpdateBalance" do
    changeset = Companybankaccount.changesetUpdateBalance(%Companybankaccount{}, Map.delete(@valid_attrs_changesetUpdateBalance, :balance))
    assert !changeset.valid?
  end



end