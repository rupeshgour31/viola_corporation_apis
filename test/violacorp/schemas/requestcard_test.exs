defmodule Violacorp.Schemas.RequestcardTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Requestcard
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    currencies_id: 12,
    currency: "GBP",
    card_type: "P",
    status: "A",
    inserted_by: 3421,
    employee_id: 3424,
    reason: "fdsfsdfsdfsdfdfssdf"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Requestcard.changeset(%Requestcard{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Requestcard.changeset(%Requestcard{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "currencies_id required check" do
    changeset = Requestcard.changeset(%Requestcard{}, Map.delete(@valid_attrs, :currencies_id))
    assert !changeset.valid?
  end

  test "card_type required check" do
    changeset = Requestcard.changeset(%Requestcard{}, Map.delete(@valid_attrs, :card_type))
    assert !changeset.valid?
  end

  test "reason required check" do
    changeset = Requestcard.changeset(%Requestcard{}, Map.delete(@valid_attrs, :reason))
    assert !changeset.valid?
  end


  @doc "updatestatus_changeset "

  test "changeset with valid attributes updatestatus_changeset" do
    changeset = Requestcard.updatestatus_changeset(%Requestcard{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updatestatus_changeset" do
    changeset = Requestcard.updatestatus_changeset(%Requestcard{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check updatestatus_changeset" do
    changeset = Requestcard.updatestatus_changeset(%Requestcard{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end



  end