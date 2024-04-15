defmodule Violacorp.Schemas.CompanydocumentinfoTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Companydocumentinfo
  @moduledoc false

  @valid_attrs %{
    company_id: 12312,
    contant: "Content Test",
    status: "A",
    inserted_by: 4545,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Companydocumentinfo.changeset(%Companydocumentinfo{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Companydocumentinfo.changeset(%Companydocumentinfo{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "contant required check" do
    changeset = Companydocumentinfo.changeset(%Companydocumentinfo{}, Map.delete(@valid_attrs, :contant))
    assert !changeset.valid?
  end


  end