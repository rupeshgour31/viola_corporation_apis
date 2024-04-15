defmodule Violacorp.Schemas.Fourstopcallback do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Fourstopcallback

  @moduledoc "Fourstopcallback Table Model"

  schema "fourstopcallback" do
    field :stopid, :string
    field :reference_id, :string
    field :request, :string
    field :response, :string
    timestamps()
  end

  @doc false
  def changeset(%Fourstopcallback{} = fourstopcallback, attrs) do
    fourstopcallback
    |> cast(attrs, [:stopid, :reference_id, :request, :response])
  end
end
