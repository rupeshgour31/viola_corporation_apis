#defmodule Violacorp.Schemas.FeetemplateTest do
#
#  use Violacorp.DataCase
#  alias Violacorp.Schemas.Feetemplate
#  @moduledoc false
#
#  @valid_attrs %{
#    countries_id: 1,
#    fee_title: "sadfdsfdsfdsf",
#    status: "A",
#    inserted_by: 4545
#  }
#  @invalid_attrs %{}
#
##  test "changeset with valid attributes" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, @valid_attrs)
##    assert changeset.valid?
##  end
##
##  test "changeset with invalid attributes" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, @invalid_attrs)
##    refute changeset.valid?
##  end
##
##  test "countries_id required check" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, Map.delete(@valid_attrs, :countries_id))
##    assert !changeset.valid?
##  end
##  test "fee_title required check" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, Map.delete(@valid_attrs, :fee_title))
##    assert !changeset.valid?
##  end
##  test "status required check" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, Map.delete(@valid_attrs, :status))
##    assert !changeset.valid?
##  end
##  test "inserted_by required check" do
##    changeset = Feetemplate.changeset(%Feetemplate{}, Map.delete(@valid_attrs, :inserted_by))
##    assert !changeset.valid?
##  end
##
#
#  end