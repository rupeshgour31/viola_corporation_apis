defmodule  Violacorp.Schemas.Intilaze do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Intilaze


  schema "intilaze" do
    field :feedetail, :string
    field :comment, :string
    field :signature, :string
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    belongs_to :administratorusers, Violacorp.Schemas.Administratorusers
    timestamps()
  end
  @doc false
  def changeset(%Intilaze{} = intilaze, attrs) do
    intilaze
    |> cast(attrs, [:commanall_id, :administratorusers_id, :feedetail, :comment,:signature, :inserted_by])
    |> validate_required([:signature,:comment])
    |> validate_inclusion(:feedetail, ["R", "W", "P", "F", "N"])
    |> validate_length(:comment, max: 255)
    |> validate_length(:signature, max: 255)
  end
end
