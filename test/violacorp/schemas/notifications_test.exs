defmodule Violacorp.Schemas.NotificationsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Notifications
  @moduledoc false

  @valid_attrs %{
    subject: "fbfdbdfb",
    message: "0144",
    status: "01252326587",
    inserted_by: 4234,
    commanall_id: 3242
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Notifications.changeset(%Notifications{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Notifications.changeset(%Notifications{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Notifications.changeset(%Notifications{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "message required check" do
    changeset = Notifications.changeset(%Notifications{}, Map.delete(@valid_attrs, :message))
    assert !changeset.valid?
  end

  @doc "updatestatus_changeset "

  test "changeset with valid attributes updatestatus_changeset" do
    changeset = Notifications.updatestatus_changeset(%Notifications{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updatestatus_changeset" do
    changeset = Notifications.updatestatus_changeset(%Notifications{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check updatestatus_changeset" do
    changeset = Notifications.updatestatus_changeset(%Notifications{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end






  end