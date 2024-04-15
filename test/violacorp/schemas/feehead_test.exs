defmodule Violacorp.Schemas.FeeheadTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Feehead
  @moduledoc false

  @valid_attrs %{
    title: "sdefsfsdfsdf",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Feehead.changeset(%Feehead{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Feehead.changeset(%Feehead{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Feehead.changeset(%Feehead{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "check if title format is correct " do
    attrs = %{@valid_attrs | title: "####23edrft"}
    changeset = Feehead.changeset(%Feehead{}, attrs)
    assert %{title: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if title maximum 150 characters" do
    attrs = %{@valid_attrs | title: "ssdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdassdadasdasdasdas"}
    changeset = Feehead.changeset(%Feehead{}, attrs)
    assert %{title: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if title minimum 4 characters" do
    attrs = %{@valid_attrs | title: "qwe"}
    changeset = Feehead.changeset(%Feehead{}, attrs)
    assert %{title: ["should be at least 4 character(s)"]} = errors_on(changeset)
  end

  test "check if status is valid value" do
    attrs = %{@valid_attrs | status: "B"}
    changeset = Feehead.changeset(%Feehead{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  end