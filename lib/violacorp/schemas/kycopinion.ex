defmodule Violacorp.Schemas.Kycopinion do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Kycopinion

  schema "kycopinion" do
    field :status, :string
    field :description, :string
    field :signature, :string
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  def changeset(%Kycopinion{} = kycopinion, attrs) do
    kycopinion
    |> cast(attrs, [:commanall_id, :status, :description, :signature, :inserted_by])
    |> validate_required([:description, :status, :signature])
    |> foreign_key_constraint(:id, name: :fk_kycopinion_commanall1, message: "Invalid Commanall_ID")
    |> validate_inclusion(:status, ["A", "H", "R"])
    |> validate_length(:signature, max: 45)
    |> validate_length(:description, min: 3)
  end
end
