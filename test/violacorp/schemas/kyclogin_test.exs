defmodule Violacorp.Schemas.KycloginTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kyclogin
  @moduledoc false

  @valid_attrs %{
    directors_id: 1234,
    username: "sdfsdfsdfsdf",
    directors_company_id: 1232,
    password: "01252326587",
    steps: "OTP",
    status: "A",
    otp_code: "543234",
    last_login: ~N[2018-05-08 13:42:15],
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kyclogin.changeset(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kyclogin.changeset(%Kyclogin{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "username required check" do
    changeset = Kyclogin.changeset(%Kyclogin{}, Map.delete(@valid_attrs, :username))
    assert !changeset.valid?
  end

  test "check if password maximum 15 numbers" do
    attrs = %{@valid_attrs | password: "01221554154sdsd825"}
    changeset = Kyclogin.changeset(%Kyclogin{}, attrs)
    assert %{password: ["should be at most 15 character(s)"]} = errors_on(changeset)
  end

  test "check if password minimum 8 numbers" do
    attrs = %{@valid_attrs | password: "0122155"}
    changeset = Kyclogin.changeset(%Kyclogin{}, attrs)
    assert %{password: ["should be at least 8 character(s)"]} = errors_on(changeset)
  end

  @doc "stepsChangeset "


  test "changeset with valid attributes stepsChangeset" do
    changeset = Kyclogin.stepsChangeset(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end


@doc "passwordChangeset"

  test "changeset with valid attributes passwordChangeset" do
    changeset = Kyclogin.passwordChangeset(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "stepsOTPChangeset"


  test "changeset with valid attributes stepsOTPChangeset" do
    changeset = Kyclogin.stepsOTPChangeset(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc" updateOTP"

  test "changeset with valid attributes updateOTP" do
    changeset = Kyclogin.updateOTP(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updateOTP" do
    changeset = Kyclogin.updateOTP(%Kyclogin{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "otp_code required check updateOTP" do
    changeset = Kyclogin.updateOTP(%Kyclogin{}, Map.delete(@valid_attrs, :otp_code))
    assert !changeset.valid?
  end

  @doc " updateEmailID"


  test "changeset with valid attributes updateEmailID" do
    changeset = Kyclogin.updateEmailID(%Kyclogin{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes updateEmailID" do
    changeset = Kyclogin.updateEmailID(%Kyclogin{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "username required check updateEmailID" do
    changeset = Kyclogin.updateEmailID(%Kyclogin{}, Map.delete(@valid_attrs, :username))
    assert !changeset.valid?
  end






end