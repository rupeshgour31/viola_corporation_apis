defmodule Violacorp.Schemas.CronsetupTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Cronsetup
  @moduledoc false

  @valid_attrs %{
    total_rows: 1232,
    limit: 45,
    offset: 51,
    type: "Y",
    last_update: ~N[2018-05-08 08:47:44],
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Cronsetup.changeset(%Cronsetup{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Cronsetup.changeset(%Cronsetup{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "total_rows required check" do
    changeset = Cronsetup.changeset(%Cronsetup{}, Map.delete(@valid_attrs, :total_rows))
    assert !changeset.valid?
  end

  test "limit required check" do
    changeset = Cronsetup.changeset(%Cronsetup{}, Map.delete(@valid_attrs, :limit))
    assert !changeset.valid?
  end

  test "offset required check" do
    changeset = Cronsetup.changeset(%Cronsetup{}, Map.delete(@valid_attrs, :offset))
    assert !changeset.valid?
  end


  end