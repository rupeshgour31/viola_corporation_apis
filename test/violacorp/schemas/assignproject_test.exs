defmodule Violacorp.Schemas.AssignprojectTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Assignproject
  @moduledoc false

  @valid_attrs %{
    employee_id: 121,
    projects_id: 120,
    inserted_by: 1212
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Assignproject.changeset(%Assignproject{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Assignproject.changeset(%Assignproject{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "type employee_id check" do
    changeset = Assignproject.changeset(%Assignproject{}, Map.delete(@valid_attrs, :employee_id))
    assert !changeset.valid?
  end

end