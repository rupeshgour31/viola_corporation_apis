defmodule Violacorp.Schemas.FourstopCallbackTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.FourstopCallback
  @moduledoc false

  @valid_attrs %{
    response: "fgdsfsdfsdfsdfdsfsd",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = FourstopCallback.changeset(%FourstopCallback{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = FourstopCallback.changeset(%FourstopCallback{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "response required check" do
    changeset = FourstopCallback.changeset(%FourstopCallback{}, Map.delete(@valid_attrs, :response))
    assert !changeset.valid?
  end

  end