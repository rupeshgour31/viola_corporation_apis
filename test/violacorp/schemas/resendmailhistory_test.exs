defmodule Violacorp.Schemas.ResendmailhistoryTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Resendmailhistory
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    section: "sdfsdfsdf",
    employee_id: 123,
    type: "Y",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Resendmailhistory.changeset(%Resendmailhistory{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Resendmailhistory.changeset(%Resendmailhistory{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "section required check" do
    changeset = Resendmailhistory.changeset(%Resendmailhistory{}, Map.delete(@valid_attrs, :section))
    assert !changeset.valid?
  end



  end