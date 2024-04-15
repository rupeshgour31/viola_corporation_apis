defmodule Violacorp.Schemas.ContactusTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Contactus
  @moduledoc false

  @valid_attrs %{
    firstname: "Mark",
    lastname: "Sullivan",
    email: "mark.sulli@smail.com",
    contact_number: "07441554525",
    message: "Message"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contactus.changeset(%Contactus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contactus.changeset(%Contactus{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email required check" do
    changeset = Contactus.changeset(%Contactus{}, Map.delete(@valid_attrs, :email))
    assert !changeset.valid?
  end

  end