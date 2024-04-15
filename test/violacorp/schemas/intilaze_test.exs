defmodule Violacorp.Schemas.IntilazeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Intilaze
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    administratorusers_id: 1232,
    feedetail: "R",
    comment: "dsfsdfdsf",
    signature: "dsfsdfdsf dsfsdf",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Intilaze.changeset(%Intilaze{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Intilaze.changeset(%Intilaze{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "comment required check" do
    changeset = Intilaze.changeset(%Intilaze{}, Map.delete(@valid_attrs, :comment))
    assert !changeset.valid?
  end

  test "signature required check" do
    changeset = Intilaze.changeset(%Intilaze{}, Map.delete(@valid_attrs, :signature))
    assert !changeset.valid?
  end

  test "check if feedetail has correct value" do
    attrs = %{@valid_attrs | feedetail: "E"}
    changeset = Intilaze.changeset(%Intilaze{}, attrs)
    assert %{feedetail: ["is invalid"]} = errors_on(changeset)
  end

  test "check if comment has correct length max 255" do
    attrs = %{@valid_attrs | comment: "dvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdv"}
    changeset = Intilaze.changeset(%Intilaze{}, attrs)
    assert %{comment: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if signature has correct length max 255" do
    attrs = %{@valid_attrs | signature: "dvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdvdv"}
    changeset = Intilaze.changeset(%Intilaze{}, attrs)
    assert %{signature: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end


  end