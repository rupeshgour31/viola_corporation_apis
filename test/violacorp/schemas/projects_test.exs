defmodule Violacorp.Schemas.ProjectsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Projects
  @moduledoc false

  @valid_attrs %{
    company_id: 1232,
    project_name: "sdffdsfds",
    start_date: ~D[2022-02-02],
    is_delete: "N",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Projects.changeset(%Projects{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Projects.changeset(%Projects{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "project_name required check" do
    changeset = Projects.changeset(%Projects{}, Map.delete(@valid_attrs, :project_name))
    assert !changeset.valid?
  end

  test "start_date required check" do
    changeset = Projects.changeset(%Projects{}, Map.delete(@valid_attrs, :start_date))
    assert !changeset.valid?
  end

  test "company_id required check" do
    changeset = Projects.changeset(%Projects{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end


  @doc"deleteChangeset "

  test "changeset with valid attributes deleteChangeset" do
    changeset = Projects.deleteChangeset(%Projects{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes deleteChangeset" do
    changeset = Projects.deleteChangeset(%Projects{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "is_delete required check deleteChangeset" do
    changeset = Projects.deleteChangeset(%Projects{}, Map.delete(@valid_attrs, :is_delete))
    assert !changeset.valid?
  end

  end
