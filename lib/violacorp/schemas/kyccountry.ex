defmodule Violacorp.Schemas.Kyccountry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "kyccountry" do
    field :title, :string
    field :status, :string
    field :inserted_by, :integer

    timestamps()
  end
  

  @doc false
  def changeset(kyccountry, attrs) do
    kyccountry
    |> cast(attrs, [:title, :status, :inserted_by])
    |> validate_required([:title, :status])
    |> validate_inclusion(:status, ["A", "D", "B"])
  end
end
