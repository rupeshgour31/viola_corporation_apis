defmodule Violacorp.Schemas.DocumenttypeTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Documenttype
  @moduledoc false

  @valid_attrs %{
    title: "sdvsdvsdv",
    code: "sds",
    description: "sddsfsdfvsdcsd",
    documentcategory_id: 34,
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Documenttype.changeset(%Documenttype{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Documenttype.changeset(%Documenttype{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documentcategory_id required check" do
    changeset = Documenttype.changeset(%Documenttype{}, Map.delete(@valid_attrs, :documentcategory_id))
    assert !changeset.valid?
  end

  test "title required check" do
    changeset = Documenttype.changeset(%Documenttype{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end

  test "code required check" do
    changeset = Documenttype.changeset(%Documenttype{}, Map.delete(@valid_attrs, :code))
    assert !changeset.valid?
  end

  test "description required check" do
    changeset = Documenttype.changeset(%Documenttype{}, Map.delete(@valid_attrs, :description))
    assert !changeset.valid?
  end


  test "check if title format is correct " do
    attrs = %{@valid_attrs | title: "####23edrft"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{title: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if title maximum 80 numbers" do
    attrs = %{@valid_attrs | title: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{title: ["should be at most 80 character(s)"]} = errors_on(changeset)
  end

  test "check if title minimum 3 numbers" do
    attrs = %{@valid_attrs | title: "ds"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{title: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if code format is correct " do
    attrs = %{@valid_attrs | code: "####23edrft"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{code: ["should be at most 3 character(s)",
               "Make sure you only use A-z"]
           } = errors_on(changeset)
  end

  test "check if code maximum 3 numbers" do
    attrs = %{@valid_attrs | code: "asas"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{code: ["should be at most 3 character(s)"]} = errors_on(changeset)
  end

  test "check if description format is correct " do
    attrs = %{@valid_attrs | description: "####23edrft"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{description: ["Make sure you only use A-z & 0-9"]
           } = errors_on(changeset)
  end

  test "check if description maximum 150 numbers" do
    attrs = %{@valid_attrs | description: "asasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasas"}
    changeset = Documenttype.changeset(%Documenttype{}, attrs)
    assert %{description: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end


  end