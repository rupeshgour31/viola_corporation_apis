defmodule Violacorp.Schemas.Notificationtemplates do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Notificationtemplates

  @moduledoc "Notificationtemplates Table Model"

  schema "notificationtemplates" do
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Notificationtemplates{} = notificationtemplates, attrs) do
    notificationtemplates
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
