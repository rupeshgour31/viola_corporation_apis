defmodule Violacorp.Schemas.AlertswitchTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Alertswitch
  @moduledoc false

  @valid_attrs %{
    section: "Reg OTP",
    email: "N",
    notification: "Y",
    sms: "Y",
    subject: "Ydsdfsdfsdfsdfsdfsdf",
    templatefile: "new_global_template.html",
    sms_body: "kjhkjashklfhaskjfljksafsafs",
    notification_body: "Welcome to Viola Corp",
    layoutfile: "new_global_template.html",
    inserted_by: 1221,
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Alertswitch.changeset(%Alertswitch{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Alertswitch.changeset(%Alertswitch{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "section required check" do
    changeset = Alertswitch.changeset(%Alertswitch{}, Map.delete(@valid_attrs, :section))
    assert !changeset.valid?
  end

  test "check if section maximum 45 characters" do
    attrs = %{@valid_attrs | section: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{section: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if section minimum 2 characters" do
    attrs = %{@valid_attrs | section: "a"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{section: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  test "check if subject maximum 255 characters" do
    attrs = %{@valid_attrs | subject: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{subject: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if subject minimum 2 characters" do
    attrs = %{@valid_attrs | subject: "v"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{subject: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  test "check if templatefile maximum 45 characters" do
    attrs = %{@valid_attrs | templatefile: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{templatefile: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if templatefile minimum 6 characters" do
    attrs = %{@valid_attrs | templatefile: "acv"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{templatefile: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if sms_body maximum 255 characters" do
    attrs = %{@valid_attrs | sms_body: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{sms_body: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if sms_body minimum 2 characters" do
    attrs = %{@valid_attrs | sms_body: "a"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{sms_body: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  test "check if notification_body maximum 255 characters" do
    attrs = %{@valid_attrs | notification_body: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{notification_body: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  test "check if notification_body minimum 2 characters" do
    attrs = %{@valid_attrs | notification_body: "a"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{notification_body: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  test "check if layoutfile maximum 45 characters" do
    attrs = %{@valid_attrs | layoutfile: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{layoutfile: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if layoutfile minimum 6 characters" do
    attrs = %{@valid_attrs | layoutfile: "acv"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{layoutfile: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if sms accepts only Y, N" do
    attrs = %{@valid_attrs | sms: "R"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{sms: ["is invalid"]} = errors_on(changeset)
  end

  test "check if notification accepts only Y, N" do
    attrs = %{@valid_attrs | notification: "R"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{notification: ["is invalid"]} = errors_on(changeset)
  end

  test "check if email accepts only Y, N" do
    attrs = %{@valid_attrs | email: "R"}
    changeset = Alertswitch.changeset(%Alertswitch{}, attrs)
    assert %{email: ["is invalid"]} = errors_on(changeset)
  end


end