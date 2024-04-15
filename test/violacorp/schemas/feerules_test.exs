#defmodule Violacorp.Schemas.FeerulesTest do
#
#  use Violacorp.DataCase
#  alias Violacorp.Schemas.Feerules
#  @moduledoc false
#
#  @valid_attrs %{
#    monthly_fee: 21.00,
#    per_card_fee: 7.00,
#    minimum_card: 3,
#    vat: 0.00,
#    status: "A",
#    inserted_by: 4545,
#    type: "M"
#  }
#  @invalid_attrs %{}
#
##  test "changeset with valid attributes" do
##    changeset = Feerules.changeset(%Feerules{}, @valid_attrs)
##    assert changeset.valid?
##  end
##
##  test "changeset with invalid attributes" do
##    changeset = Feerules.changeset(%Feerules{}, @invalid_attrs)
##    refute changeset.valid?
##  end
##
##  test "title required check" do
##    changeset = Feerules.changeset(%Feerules{}, Map.delete(@valid_attrs, :title))
##    assert !changeset.valid?
##  end
#
#
#  end