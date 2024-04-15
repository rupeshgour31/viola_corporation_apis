defmodule Violacorp.Schemas.ThirdpartylogsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Thirdpartylogs
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    section: "0144",
    method: "POST",
    request: "Ydfbdfbdfb",
    response: "Adfbfdbdfbdfb",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "request required check" do
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, Map.delete(@valid_attrs, :request))
    assert !changeset.valid?
  end

  test "response required check" do
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, Map.delete(@valid_attrs, :response))
    assert !changeset.valid?
  end



  end
