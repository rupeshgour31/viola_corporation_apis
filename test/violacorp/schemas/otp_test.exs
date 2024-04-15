defmodule Violacorp.Schemas.OtpTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Otp
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    otp_code: "123456",
    otp_source: "dsvdsvdsvsdv",
    status: "A",
    inserted_by: 4545
  }
#  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Otp.changeset(%Otp{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc" attempt_changeset"

  test "changeset with valid attributes attempt_changeset" do
    changeset = Otp.attempt_changeset(%Otp{}, @valid_attrs)
    assert changeset.valid?
  end



  end