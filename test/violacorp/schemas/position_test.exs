defmodule Violacorp.Schemas.PositionTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Position
  @moduledoc false

  @valid_attrs %{
    title: "fgfdgfdgfdgfdg",
    show: "014sdfdsf4",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Position.changeset(%Position{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Position.changeset(%Position{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Position.changeset(%Position{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "show required check" do
    changeset = Position.changeset(%Position{}, Map.delete(@valid_attrs, :show))
    assert !changeset.valid?
  end

  end