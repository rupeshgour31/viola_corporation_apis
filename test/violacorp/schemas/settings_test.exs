defmodule Violacorp.Schemas.SettingsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Settings
  @moduledoc false

  @valid_attrs %{
    category: "fsdfsdfsdf",
    access_token: "dsfsdfs34rw34r5324523r4324",
    token_type: "M",
    generate_date: ~D[2020-02-02]
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Settings.changeset(%Settings{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Settings.changeset(%Settings{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "access_token required check" do
    changeset = Settings.changeset(%Settings{}, Map.delete(@valid_attrs, :access_token))
    assert !changeset.valid?
  end


  test "token_type required check" do
    changeset = Settings.changeset(%Settings{}, Map.delete(@valid_attrs, :token_type))
    assert !changeset.valid?
  end


  test "generate_date required check" do
    changeset = Settings.changeset(%Settings{}, Map.delete(@valid_attrs, :generate_date))
    assert !changeset.valid?
  end


  end