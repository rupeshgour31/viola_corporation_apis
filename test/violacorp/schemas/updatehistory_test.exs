defmodule Violacorp.Schemas.UpdateHistoryTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.UpdateHistory
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    employee_id: 2314,
    directors_id: 3432,
    field_name: "Ysdfs",
    new_value: "Asdfdsf",
    old_value: "dfdsfsdf",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = UpdateHistory.changeset(%UpdateHistory{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = UpdateHistory.changeset(%UpdateHistory{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "new_value required check" do
    changeset = UpdateHistory.changeset(%UpdateHistory{}, Map.delete(@valid_attrs, :new_value))
    assert !changeset.valid?
  end


  end