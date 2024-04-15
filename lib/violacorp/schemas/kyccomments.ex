defmodule Violacorp.Schemas.Kyccomments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "kyccomments" do
    field :comment, :string
    field :inserted_by, :integer

    belongs_to :kycdirectors, Violacorp.Schemas.Kycdirectors
    timestamps()
  end

  @doc false
  def changeset(kyccomment, attr)do
   kyccomment
    |>cast(attr,[:kycdirectors_id, :comment, :inserted_by])
   |> validate_required([:comment])
  end

end
