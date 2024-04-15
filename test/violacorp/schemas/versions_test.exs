defmodule Violacorp.Schemas.VersionsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Versions
  @moduledoc false

  @valid_attrs %{
    android: "1.011",
    inserted_by: 1234,
    iphone: "1.023",
    ekyc: "Y",
    dev_email: "Asadsadasd@sdasd.com",
    live_email: "dsfsdfsdfsdf@gkjdf.com",
    api_enable: "Y",
    fee_sole_trade: Decimal.from_float(120.20),
    fee_limited: Decimal.from_float(120.20)
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Versions.changeset(%Versions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Versions.changeset(%Versions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "android required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :android))
    assert !changeset.valid?
  end

  test "iphone required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :iphone))
    assert !changeset.valid?
  end

  test "ekyc required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :ekyc))
    assert !changeset.valid?
  end

  test "dev_email required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :dev_email))
    assert !changeset.valid?
  end

  test "live_email required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :live_email))
    assert !changeset.valid?
  end

  test "api_enable required check" do
    changeset = Versions.changeset(%Versions{}, Map.delete(@valid_attrs, :api_enable))
    assert !changeset.valid?
  end

  test "check if android format is correct " do
    attrs = %{@valid_attrs | android: "####23edrft"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{android: ["should be at most 8 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if iphone format is correct " do
    attrs = %{@valid_attrs | iphone: "####23edrft"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{iphone: ["should be at most 8 character(s)", "has invalid format"]} = errors_on(changeset)
  end

  test "check if android length max 8 " do
    attrs = %{@valid_attrs | android: "sdasdasdasdasdsadsa"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{android: ["should be at most 8 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if iphone length max 8 " do
    attrs = %{@valid_attrs | iphone: "sdasdasdasdasdsadsa"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{iphone: ["should be at most 8 character(s)", "has invalid format"]} = errors_on(changeset)
  end

  test "check if dev_email length max 150 " do
    attrs = %{@valid_attrs | dev_email: "sacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascas@scasc.com"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{dev_email: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end


    test "check if live_email length max 150 " do
    attrs = %{@valid_attrs | live_email: "sacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascassacascsascas@dsdc.com"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{live_email: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end


    test "check if api_enable has correct value " do
    attrs = %{@valid_attrs | api_enable: "G"}
    changeset = Versions.changeset(%Versions{}, attrs)
    assert %{api_enable: ["is invalid"]} = errors_on(changeset)
  end


  end