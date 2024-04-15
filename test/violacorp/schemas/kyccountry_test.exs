defmodule Violacorp.Schemas.KyccountryTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kyccountry
  @moduledoc false

  @valid_attrs %{
    title: "dfgdfg",
    status: "A",
    inserted_by: "01252326587",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kyccountry.changeset(%Kyccountry{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kyccountry.changeset(%Kyccountry{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Kyccountry.changeset(%Kyccountry{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Kyccountry.changeset(%Kyccountry{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "check if status has correct value" do
    attrs = %{@valid_attrs | status: "F"}
    changeset = Kyccountry.changeset(%Kyccountry{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end


  end