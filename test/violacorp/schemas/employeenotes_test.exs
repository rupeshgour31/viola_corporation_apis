defmodule Violacorp.Schemas.EmployeenotesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Employeenotes
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    notes: "dsfsdfdsfdsf",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Employeenotes.changeset(%Employeenotes{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Employeenotes.changeset(%Employeenotes{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "notes required check" do
    changeset = Employeenotes.changeset(%Employeenotes{}, Map.delete(@valid_attrs, :notes))
    assert !changeset.valid?
  end

  test "check if notes maximum 150 characters" do
    attrs = %{@valid_attrs | notes: "dsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfdsfsfsfdsfv"}
    changeset = Employeenotes.changeset(%Employeenotes{}, attrs)
    assert %{notes: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if notes format is correct" do
    attrs = %{@valid_attrs | notes: "_-+()#';"}
    changeset = Employeenotes.changeset(%Employeenotes{}, attrs)
    assert %{notes: ["has invalid format"]} = errors_on(changeset)
  end



  end