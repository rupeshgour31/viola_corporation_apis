defmodule Violacorp.Schemas.Tags do
  use Ecto.Schema
  import Ecto.Changeset


  schema "tags" do
    field :description, :string
    field :status, :string

    belongs_to :commanall, Violacorp.Schemas.Commanall
    belongs_to :administratorusers, Violacorp.Schemas.Administratorusers
    timestamps()
  end

  @doc false
  def changeset(tags, attrs) do
    tags
    |> cast(attrs, [:commanall_id, :administratorusers_id, :description, :status])
    |> validate_required([:description, :status])
  end
end
