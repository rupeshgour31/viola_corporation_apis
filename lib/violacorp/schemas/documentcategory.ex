defmodule Violacorp.Schemas.Documentcategory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Documentcategory

  @moduledoc "Documentcategory Table Model"

  schema "documentcategory" do
    field :title, :string
    field :code, :string
    field :inserted_by, :integer
    has_many :documenttype, Violacorp.Schemas.Documenttype
    timestamps()
  end

  @doc false
  def changeset(%Documentcategory{} = documentcategories, attrs) do
    documentcategories
    |> cast(attrs, [:title, :code, :inserted_by])
    |> validate_required([:title, :code])
    |> update_change(:title, &String.trim/1)
    |> update_change(:code, &String.trim/1)
    |> update_change(:code, &String.upcase/1)
    |> validate_format(:title, ~r/^[a-zA-Z ]+$/, message: "Make sure you only use A-z")
    |> validate_length(:title, min: 3, max: 80)
    |> validate_format(:code, ~r/^[a-zA-Z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:code, max: 3)
  end
end
