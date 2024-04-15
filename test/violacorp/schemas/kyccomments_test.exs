defmodule Violacorp.Schemas.KyccommentsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kyccomments
  @moduledoc false

  @valid_attrs %{
    comment: "fgfdgfdgdfg",
    inserted_by: 1234,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kyccomments.changeset(%Kyccomments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kyccomments.changeset(%Kyccomments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "comment required check" do
    changeset = Kyccomments.changeset(%Kyccomments{}, Map.delete(@valid_attrs, :comment))
    assert !changeset.valid?
  end









  end