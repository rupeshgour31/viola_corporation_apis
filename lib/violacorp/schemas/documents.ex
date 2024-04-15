defmodule Violacorp.Schemas.Documents do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Documents

  @moduledoc "Documents Table Model"

  schema "documents" do
    field :commanall_id, :integer
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(commanall_id inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Documents{} = documents, attrs) do
    documents
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
