defmodule Violacorp.Schemas.FourstopCallback do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "fourstop_callback Table Model"

  schema "fourstopcallback" do
    field :response, :string

    timestamps()
  end

  @doc false
  def changeset(fourstopcallback, attrs) do
    fourstopcallback
    |> cast(attrs, [:response])
    |> validate_required([:response])
  end
end
