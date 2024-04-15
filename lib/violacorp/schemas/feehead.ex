defmodule Violacorp.Schemas.Feehead do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Feehead

  @moduledoc "Feehead Table Model"

  schema "feehead" do
    field :title, :string
    field :status, :string
    field :inserted_by, :integer

    has_many :groupfee, Violacorp.Schemas.Groupfee
    timestamps()
  end

  @doc false
  def changeset(%Feehead{} = feehead, attrs) do
    feehead
    |> cast(attrs, [:title, :status, :inserted_by])
    |> validate_required([:title])
    |> unique_constraint(:title, name: :title_UNIQUE, message: "title already exist")
    |> validate_format(:title, ~r/^[A-z- ]+$/)
    |> validate_length(:title, min: 4, max: 150)
    |> validate_inclusion(:status, ["A", "D"])
  end
end
