defmodule Violacorp.Schemas.KycopinionTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kycopinion
  @moduledoc false

  @valid_attrs %{
    status: "A",
    commanall_id: 1234,
    description: "sdasdasdas",
    signature: "Ysadsdsa",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kycopinion.changeset(%Kycopinion{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kycopinion.changeset(%Kycopinion{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "description required check" do
    changeset = Kycopinion.changeset(%Kycopinion{}, Map.delete(@valid_attrs, :description))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Kycopinion.changeset(%Kycopinion{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "signature required check" do
    changeset = Kycopinion.changeset(%Kycopinion{}, Map.delete(@valid_attrs, :signature))
    assert !changeset.valid?
  end

  test "check if status is correct value" do
    attrs = %{@valid_attrs | status: "K"}
    changeset = Kycopinion.changeset(%Kycopinion{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "check if signature is correct length" do
    attrs = %{@valid_attrs | signature: "sdvsdvsdsdvsdsdvsdvsdsdvsdsdvsdvsdsdvsdsdvsdvsdsdvsd"}
    changeset = Kycopinion.changeset(%Kycopinion{}, attrs)
    assert %{signature: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if description is correct length" do
    attrs = %{@valid_attrs | description: "23"}
    changeset = Kycopinion.changeset(%Kycopinion{}, attrs)
    assert %{description: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  end