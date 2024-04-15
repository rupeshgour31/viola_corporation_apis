#defmodule Violacorp.Schemas.NotificationtemplatesTest do
#
#  use Violacorp.DataCase
#  alias Violacorp.Schemas.Notificationtemplates
#  @moduledoc false

#  @valid_attrs %{
#
#    inserted_by: 4545
#  }
#  @invalid_attrs %{}
#
#  test "changeset with valid attributes" do
#    changeset = Notificationtemplates.changeset(%Notificationtemplates{}, @valid_attrs)
#    assert changeset.valid?
#  end
#
#  test "changeset with invalid attributes" do
#    changeset = Notificationtemplates.changeset(%Notificationtemplates{}, @invalid_attrs)
#    refute changeset.valid?
#  end

#  test "contact_number required check" do
#    changeset = Notificationtemplates.changeset(%Notificationtemplates{}, Map.delete(@valid_attrs, :contact_number))
#    assert !changeset.valid?
#  end






#  end