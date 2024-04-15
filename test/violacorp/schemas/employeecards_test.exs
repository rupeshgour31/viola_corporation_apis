defmodule Violacorp.Schemas.EmployeecardsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Employeecards
  @moduledoc false

      @valid_attrs %{
        employee_id: 211,
        currencies_id: 1,
        currency_code: "GBP",
        card_number: nil,
        last_digit: "3423",
        expiry_date: "2021-02-02",
        name_on_card: "Paterson",
        available_balance: Decimal.from_float(120.20),
        current_balance: Decimal.from_float(120.20),
        bin_id: "4848",
        source_id: "violaTeamllPQuOOY",
        accomplish_card_id: 23423,
        activation_code: "33157024",
        reason: "dsfsdsdfsd",
        change_status: "E",
        ip_address: nil,
        status: "1",
        card_type: "P",
        browser_info: "info",
        inserted_by: 2311
      }
      @invalid_attrs %{}


      test "changeset with valid attributes" do
        changeset = Employeecards.changeset(%Employeecards{}, @valid_attrs)
        assert changeset.valid?
      end

      test "changeset with invalid attributes" do
        changeset = Employeecards.changeset(%Employeecards{}, @invalid_attrs)
        refute changeset.valid?
      end

      test "employee_id required check" do
        changeset = Employeecards.changeset(%Employeecards{}, Map.delete(@valid_attrs, :employee_id))
        assert !changeset.valid?
      end

      test "currency_code required check" do
        changeset = Employeecards.changeset(%Employeecards{}, Map.delete(@valid_attrs, :currency_code))
        assert !changeset.valid?
      end

      test "check if reason maximum 255 numbers" do
        attrs = %{@valid_attrs | reason: "sdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfssdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsd"}
        changeset = Employeecards.changeset(%Employeecards{}, attrs)
        assert %{reason: ["should be at most 255 character(s)"]} = errors_on(changeset)
      end

      test "check if card_type contains valid values" do
        attrs = %{@valid_attrs | card_type: "F"}
        changeset = Employeecards.changeset(%Employeecards{}, attrs)
        assert %{card_type: ["is invalid"]} = errors_on(changeset)
      end

@doc" changesetStatus"

@valid_attrs_changesetStatus %{
  status: "1",
  reason: "kjhkdfsdaf",
  change_status: "E"
}

  test "changeset with valid attributes changesetStatus" do
    changeset = Employeecards.changesetStatus(%Employeecards{}, @valid_attrs_changesetStatus)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetStatus" do
    changeset = Employeecards.changesetStatus(%Employeecards{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check changesetStatus" do
    changeset = Employeecards.changesetStatus(%Employeecards{}, Map.delete(@valid_attrs_changesetStatus, :status))
    assert !changeset.valid?
  end

@doc" changesetCardStatus"

@valid_attrs_changesetCardStatus %{
  status: "1",
  reason: "kjhkdfsdaf",
  change_status: "E"
}

  test "changeset with valid attributes changesetCardStatus" do
    changeset = Employeecards.changesetCardStatus(%Employeecards{}, @valid_attrs_changesetCardStatus)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetCardStatus" do
    changeset = Employeecards.changesetCardStatus(%Employeecards{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check changesetCardStatus" do
    changeset = Employeecards.changesetCardStatus(%Employeecards{}, Map.delete(@valid_attrs_changesetCardStatus, :status))
    assert !changeset.valid?
  end


  @doc" changesetBalance"

  @valid_attrs_changesetBalance %{
    status: "1",
    reason: "kjhkdfsdaf",
    change_status: "E"
  }

  test "changeset with valid attributes changesetBalance" do
    changeset = Employeecards.changesetBalance(%Employeecards{}, @valid_attrs_changesetBalance)
    assert changeset.valid?
  end


  end