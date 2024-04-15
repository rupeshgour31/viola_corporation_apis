defmodule Violacorp.Schemas.CountriesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Countries
  @moduledoc false

  @valid_attrs %{
    country_name: "Belarus",
    country_iso_2: "BE",
    country_iso_3: "BEL",
    country_isdcode: "074",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}


  test "changeset with valid attributes" do
    changeset = Countries.changeset(%Countries{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Countries.changeset(%Countries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "country_name required check" do
    changeset = Countries.changeset(%Countries{}, Map.delete(@valid_attrs, :country_name))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Countries.changeset(%Countries{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "country_iso_2 required check" do
    changeset = Countries.changeset(%Countries{}, Map.delete(@valid_attrs, :country_iso_2))
    assert !changeset.valid?
  end

  test "country_iso_3 required check" do
    changeset = Countries.changeset(%Countries{}, Map.delete(@valid_attrs, :country_iso_3))
    assert !changeset.valid?
  end

  test "country_isdcode required check" do
    changeset = Countries.changeset(%Countries{}, Map.delete(@valid_attrs, :country_isdcode))
    assert !changeset.valid?
  end

  test "check if country_name format is correct " do
    attrs = %{@valid_attrs | country_name: "####23edrft"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if country_iso_2 format is correct " do
    attrs = %{@valid_attrs | country_iso_2: "##"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_2: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if country_iso_3 format is correct " do
    attrs = %{@valid_attrs | country_iso_3: "###"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_3: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if country_isdcode format is correct " do
    attrs = %{@valid_attrs | country_isdcode: "####"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_isdcode: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if country_name maximum 45 numbers" do
    attrs = %{@valid_attrs | country_name: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_name: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if country_name minimum 3 numbers" do
    attrs = %{@valid_attrs | country_name: "k"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if country_iso_2 maximum 2 numbers" do
    attrs = %{@valid_attrs | country_iso_2: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_2: ["should be at most 2 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if country_iso_2 minimum 2 numbers" do
    attrs = %{@valid_attrs | country_iso_2: "k"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_2: ["should be at least 2 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if country_iso_3 maximum 3 numbers" do
    attrs = %{@valid_attrs | country_iso_3: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_3: ["should be at most 3 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if country_iso_3 minimum 3 numbers" do
    attrs = %{@valid_attrs | country_iso_3: "k"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{country_iso_3: ["should be at least 3 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if status, [A, D, B]" do
    attrs = %{@valid_attrs | status: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "check if inserted_by is less than 100000000000" do
    attrs = %{@valid_attrs | inserted_by: 999999999999999999999}
    changeset = Countries.changeset(%Countries{}, attrs)
    assert %{inserted_by: ["must be less than 100000000000"]} = errors_on(changeset)
  end


  @doc" updateChangeset"

  @valid_attrs_update %{
  status: "A"
  }

  test "changeset with valid attributes updateChangeset" do
    changeset = Countries.updateChangeset(%Countries{}, @valid_attrs_update)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updateChangeset" do
    changeset = Countries.updateChangeset(%Countries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check updateChangeset" do
    changeset = Countries.updateChangeset(%Countries{}, Map.delete(@valid_attrs_update, :status))
    assert !changeset.valid?
  end

  test "check if status, [A, D, B] updateChangeset" do
    attrs = %{@valid_attrs | status: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Countries.updateChangeset(%Countries{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end


















end