defmodule Violacorp.Schemas.Documenttype do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Documenttype

  @moduledoc "Documenttype Table Model"

  schema "documenttype" do
    field :title, :string
    field :code, :string
    field :description, :string
    field :inserted_by, :integer
    belongs_to :documentcategory, Violacorp.Schemas.Documentcategory
    has_many :kycshareholder, Violacorp.Schemas.Kycshareholder
    timestamps()
  end

  @doc false
  def changeset(%Documenttype{} = documenttype, attrs) do
    documenttype
    |> cast(attrs, [:documentcategory_id, :title, :code, :description, :inserted_by])
    |> validate_required([:documentcategory_id, :title, :code, :description])
    |> update_change(:title, &String.trim/1)
    |> update_change(:code, &String.trim/1)
    |> update_change(:code, &String.upcase/1)
    |> update_change(:description, &String.trim/1)
    |> validate_format(:title, ~r/^[a-zA-Z ]+$/, message: "Make sure you only use A-z")
    |> validate_length(:title, min: 3, max: 80)
    |> validate_format(:code, ~r/^[a-zA-Z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:code, max: 3)
    |> validate_format(:description, ~r/^[A-z0-9- ]+$/, message: "Make sure you only use A-z & 0-9")
    |> validate_length(:description, max: 150)
  end
end
