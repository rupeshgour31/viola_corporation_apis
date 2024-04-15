defmodule Violacorp.Schemas.Feetemplate do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Feetemplate

  @moduledoc "Feetemplate Table Model"

  schema "feetemplatee" do
    field :countries_id, :integer
    field :fee_title, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(countries_id fee_title status inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Feetemplate{} = feetemplatee, attrs) do
    feetemplatee
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
