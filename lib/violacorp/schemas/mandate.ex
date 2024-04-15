defmodule Violacorp.Schemas.Mandate do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Mandate

  @moduledoc "Mandate Table Model"

  schema "mandate" do
    field :commanall_id, :integer
#    field :directors_id, :integer
    field :signature, :string
    field :response_data, :string
    field :inserted_by, :integer

    belongs_to :directors, Violacorp.Schemas.Directors
    timestamps()
  end

  @doc false
  def changeset(%Mandate{} = mandate, attrs) do
    mandate
    |> cast(attrs, [:commanall_id, :directors_id, :signature, :response_data, :inserted_by])
    |> validate_required([:commanall_id, :directors_id])
  end
end
