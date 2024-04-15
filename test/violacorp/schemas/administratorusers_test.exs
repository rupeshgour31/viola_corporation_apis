defmodule Violacorp.Schemas.AdministratorusersTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Administratorusers
  @moduledoc false

  @valid_attrs %{
    fullname: "Rhian Hopkins",
    role: "ADMIN",
    unique_id: "VIOLA001",
    email_id: "rhian@boohoo.com",
    password: "jkshdc*&**&*(&*#@",
    contact_number: "07411452563",
    inserted_by: 1212,
  }
#  @invalid_attrs %{}
  @doc"changeset"

  test "changeset with valid attributes" do
    changeset = Administratorusers.changeset(%Administratorusers{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc " changeset_updatepassword"

  @valid_attrs_updatepassword %{
    secret_password: "Kkjkdk8(*#"
  }
  test "changeset with valid attributes secret_password" do
    changeset = Administratorusers.changeset_updatepassword(%Administratorusers{}, @valid_attrs_updatepassword)
    assert changeset.valid?
  end

  @doc " changeset_password"

  @valid_attrs_password %{
    password: "Kkjkdk8(*#"
  }
  test "changeset with valid attributes password" do
    changeset = Administratorusers.changeset_password(%Administratorusers{}, @valid_attrs_password)
    assert changeset.valid?
  end

  @doc " login_changeset"

  @valid_attrs_login %{
  email_id: "Kkjkdk8(*#",
    password: "Kkjkdk8(*#",
    status: "A",
  }
  test "changeset with valid attributes login" do
    changeset = Administratorusers.login_changeset(%Administratorusers{}, @valid_attrs_login)
    assert changeset.valid?
  end

end