defmodule Violacorp.Schemas.ListenerTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Listener
  @moduledoc false

  @valid_attrs %{
    accounts_id: "123fgfdg4352",
    nonce: "1589430851",
    type: "AccountCreated",
    header_request: "sfdfsdfsdfds",
    request: "dsfsdfsfsf",
    header_response: "dsfdsfdsf",
    response: "dsfsdfdsfds",
    status: "A",
    inserted_by: 4545,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Listener.changeset(%Listener{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Listener.changeset(%Listener{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "nonce required check" do
    changeset = Listener.changeset(%Listener{}, Map.delete(@valid_attrs, :nonce))
    assert !changeset.valid?
  end

  test "type required check" do
    changeset = Listener.changeset(%Listener{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  test "check if nonce max length 45 " do
    attrs = %{@valid_attrs | nonce: "eewfwefewfweewfwefewfweewfwefewfweewfwefewfweewfwefewfw"}
    changeset = Listener.changeset(%Listener{}, attrs)
    assert %{nonce: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if type max length 45 " do
    attrs = %{@valid_attrs | type: "eewfwefewfweewfwefewfweewfwefewfweewfwefewfweewfwefewfw"}
    changeset = Listener.changeset(%Listener{}, attrs)
    assert %{type: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if status valid value " do
    attrs = %{@valid_attrs | status: "G"}
    changeset = Listener.changeset(%Listener{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  test "check if inserted_by valid value " do
    attrs = %{@valid_attrs | inserted_by: 9999999999999999999999999}
    changeset = Listener.changeset(%Listener{}, attrs)
    assert %{inserted_by: ["must be less than 100000000000"]} = errors_on(changeset)
  end

  @doc " changesetUpdate"

  test "changeset with valid attributes changesetUpdate" do
    changeset = Listener.changesetUpdate(%Listener{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetUpdate" do
    changeset = Listener.changesetUpdate(%Listener{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "header_response required check changesetUpdate" do
    changeset = Listener.changesetUpdate(%Listener{}, Map.delete(@valid_attrs, :header_response))
    assert !changeset.valid?
  end

  test "response required check changesetUpdate" do
    changeset = Listener.changesetUpdate(%Listener{}, Map.delete(@valid_attrs, :response))
    assert !changeset.valid?
  end

  test "check if status valid value changesetUpdate " do
    attrs = %{@valid_attrs | status: "G"}
    changeset = Listener.changesetUpdate(%Listener{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end

  end