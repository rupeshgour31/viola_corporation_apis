defmodule Violacorp.Schemas.LoginhistoryTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Loginhistory
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    email_id: "vsdvsdvS@sdvsdvsdv.com",
    time_in: "12:12",
    time_out: "12:12",
    details: "dsfdsfdsfdsf",
    success: "Y",
    existing_user: "Y",
    device_type: "W"
  }
#  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Loginhistory.changeset(%Loginhistory{}, @valid_attrs)
    assert changeset.valid?
  end

  end