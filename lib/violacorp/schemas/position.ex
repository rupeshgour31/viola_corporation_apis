defmodule Violacorp.Schemas.Position do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Position

  @moduledoc "Position Table Model"

  schema "position" do
    field :title, :string
    field :show, :string
    field :inserted_by, :integer
    timestamps()

    belongs_to :directors, Violacorp.Schemas.Directors
  end

  @doc false
  def changeset(%Position{} = position, attrs) do
    position
    |> cast(attrs, [:title, :show, :inserted_by])
    |> validate_required([:title, :show])
  end
end
