defmodule Violacorp.Schemas.AppversionsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Appversions
  @moduledoc false

  @valid_attrs %{
    type: "I",
    version: "1.20",
    is_active: "Y",
    inserted_by: 1212,
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Appversions.changeset(%Appversions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Appversions.changeset(%Appversions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "type required check" do
    changeset = Appversions.changeset(%Appversions{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  test "version required check" do
    changeset = Appversions.changeset(%Appversions{}, Map.delete(@valid_attrs, :version))
    assert !changeset.valid?
  end

  test "check if type accepts only A, I" do
    attrs = %{@valid_attrs | type: "R"}
    changeset = Appversions.changeset(%Appversions{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if is_active accepts only Y, N" do
    attrs = %{@valid_attrs | is_active: "R"}
    changeset = Appversions.changeset(%Appversions{}, attrs)
    assert %{is_active: ["is invalid"]} = errors_on(changeset)
  end



end