#defmodule Violacorp.Schemas.SpendsTest do
#
#  use Violacorp.DataCase
#  alias Violacorp.Schemas.Spends
#  @moduledoc false
#
#  @valid_attrs %{
#    commanall_id: 1232,
#    daily_amount: Decimal.from_float(120.20),
#    weekly_amount: Decimal.from_float(120.20),
#    monthly_amount: Decimal.from_float(120.20),
#    inserted_by: 4545
#  }
#  @invalid_attrs %{}
#
#  test "changeset with valid attributes" do
#    changeset = Spends.changeset(%Spends{}, @valid_attrs)
#    assert changeset.valid?
#  end
#
#  test "changeset with invalid attributes" do
#    changeset = Spends.changeset(%Spends{}, @invalid_attrs)
#    refute changeset.valid?
#  end
#
#  test "contact_number required check" do
#    changeset = Spends.changeset(%Spends{}, Map.delete(@valid_attrs, :contact_number))
#    assert !changeset.valid?
#  end
#
#
#  end