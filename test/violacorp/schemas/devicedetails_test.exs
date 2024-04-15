defmodule Violacorp.Schemas.DevicedetailsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Devicedetails
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    session_id: "0144",
    type: "M",
    unique_id: "Ysda",
    token: "Aasdasdasdasdas",
    details: "fdsfdsfsdfsdfsdf",
    status: "A",
    is_delete: "N",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Devicedetails.changeset(%Devicedetails{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Devicedetails.changeset(%Devicedetails{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Devicedetails.changeset(%Devicedetails{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "type required check" do
    changeset = Devicedetails.changeset(%Devicedetails{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  @doc"deleteStatusChangeset "


  @valid_attrs_status %{
    is_delete: "Y"
  }


  test "changeset with valid attributes deleteStatusChangeset" do
    changeset = Devicedetails.deleteStatusChangeset(%Devicedetails{}, @valid_attrs_status)
    assert changeset.valid?
  end

  test "changeset with invalid attributes deleteStatusChangeset" do
    changeset = Devicedetails.deleteStatusChangeset(%Devicedetails{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "is_delete required check deleteStatusChangeset" do
    changeset = Devicedetails.deleteStatusChangeset(%Devicedetails{}, Map.delete(@valid_attrs_status, :is_delete))
    assert !changeset.valid?
  end


  end