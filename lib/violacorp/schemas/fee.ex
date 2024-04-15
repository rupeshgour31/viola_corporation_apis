defmodule Violacorp.Schemas.Fee do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Fee

  @moduledoc "Fee Table Model"

  schema "fee" do
    field :title, :string
    field :amount, :decimal
    field :type, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false
  def changeset(%Fee{} = fee, attrs) do
    fee
    |> cast(attrs, [:title, :amount, :type, :inserted_by])
    |> validate_required([:title])
  end
end
