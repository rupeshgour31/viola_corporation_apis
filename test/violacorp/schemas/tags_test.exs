defmodule Violacorp.Schemas.TagsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Tags
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    description: "fdbdfbdfss",
    status: "A"
  }

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Tags.changeset(%Tags{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Tags.changeset(%Tags{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "description required check" do
    changeset = Tags.changeset(%Tags{}, Map.delete(@valid_attrs, :description))
    assert !changeset.valid?
  end

  test "status required check" do
    changeset = Tags.changeset(%Tags{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end






  end