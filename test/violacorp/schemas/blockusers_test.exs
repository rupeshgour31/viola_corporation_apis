defmodule Violacorp.Schemas.BlockusersTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Blockusers
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1212,
    reason: "reason",
    status_date: ~N[2019-04-14 06:50:33],
    block_date: ~N[2019-04-14 06:50:33],
    type: "B",
    status: "A",
    inserted_by: 1212
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Blockusers.changeset(%Blockusers{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Blockusers.changeset(%Blockusers{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "reason required check" do
    changeset = Blockusers.changeset(%Blockusers{}, Map.delete(@valid_attrs, :reason))
    assert !changeset.valid?
  end

  test "type required check" do
    changeset = Blockusers.changeset(%Blockusers{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Blockusers.changeset(%Blockusers{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "check if status accepts only A, D" do
    attrs = %{@valid_attrs | status: "R"}
    changeset = Blockusers.changeset(%Blockusers{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "check if type accepts only B, U" do
    attrs = %{@valid_attrs | type: "R"}
    changeset = Blockusers.changeset(%Blockusers{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if reason maximum 255 characters" do
    attrs = %{@valid_attrs | reason: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Blockusers.changeset(%Blockusers{}, attrs)
    assert %{reason: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if reason accepts only alpha characters" do
    attrs = %{@valid_attrs | reason: "%%%%%^&"}
    changeset = Blockusers.changeset(%Blockusers{}, attrs)
    assert %{reason: ["has invalid format"]} = errors_on(changeset)
  end

end