defmodule Violacorp.Schemas.MandateTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Mandate
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    signature: "0144",
    response_data: "01252326587",
    inserted_by: 4545,
    directors_id: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Mandate.changeset(%Mandate{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Mandate.changeset(%Mandate{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Mandate.changeset(%Mandate{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "directors_id required check" do
    changeset = Mandate.changeset(%Mandate{}, Map.delete(@valid_attrs, :directors_id))
    assert !changeset.valid?
  end


end