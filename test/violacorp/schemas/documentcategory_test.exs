defmodule Violacorp.Schemas.DocumentcategoryTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Documentcategory
  @moduledoc false

  @valid_attrs %{
    title: "sdvsdvsdvsdvsdv",
    code: "gfd",
    inserted_by: 1232
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Documentcategory.changeset(%Documentcategory{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Documentcategory.changeset(%Documentcategory{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "title required check" do
    changeset = Documentcategory.changeset(%Documentcategory{}, Map.delete(@valid_attrs, :title))
    assert !changeset.valid?
  end
  test "code required check" do
    changeset = Documentcategory.changeset(%Documentcategory{}, Map.delete(@valid_attrs, :code))
    assert !changeset.valid?
  end


  test "check if title format is correct " do
    attrs = %{@valid_attrs | title: "####23edrft"}
    changeset = Documentcategory.changeset(%Documentcategory{}, attrs)
    assert %{title: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if code format is correct " do
    attrs = %{@valid_attrs | code: "###"}
    changeset = Documentcategory.changeset(%Documentcategory{}, attrs)
    assert %{code: ["Make sure you only use A-z"]} = errors_on(changeset)
  end

  test "check if title minimum 3 characters" do
    attrs = %{@valid_attrs | title: "s"}
    changeset = Documentcategory.changeset(%Documentcategory{}, attrs)
    assert %{title: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if title maximum 80 characters" do
    attrs = %{@valid_attrs | title: "ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"}
    changeset = Documentcategory.changeset(%Documentcategory{}, attrs)
    assert %{title: ["should be at most 80 character(s)"]} = errors_on(changeset)
  end

  test "check if code maximum 3 characters" do
    attrs = %{@valid_attrs | code: "asdasdadad"}
    changeset = Documentcategory.changeset(%Documentcategory{}, attrs)
    assert %{code: ["should be at most 3 character(s)"]} = errors_on(changeset)
  end
















  end