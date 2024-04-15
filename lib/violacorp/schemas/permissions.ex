defmodule Violacorp.Schemas.Permissions do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Permissions

  @moduledoc "Permissions Table Model"

  schema "permissions" do
    field :commanall_id, :integer
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(commanall_id inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Permissions{} = permissions, attrs) do
    permissions
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
