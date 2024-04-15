defmodule Violacorp.Schemas.AdminbeneficiariesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Adminbeneficiaries
  @moduledoc false

  @valid_attrs %{
    adminaccounts_id: 331,
    fullname: "Full Name",
    nick_name: "nick_name",
    sort_code: "121212",
    account_number: "20000007",
    description: "description",
    contacts: "contacts",
    notification: "B",
    type: "C",
    status: "A",
    inserted_by: 1212,
  }
  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Adminbeneficiaries.changeset(%Adminbeneficiaries{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Adminbeneficiaries.changeset(%Adminbeneficiaries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "account_number required check" do
    changeset = Adminbeneficiaries.changeset(%Adminbeneficiaries{}, Map.delete(@valid_attrs, :account_number))
    assert !changeset.valid?
  end


end





