defmodule Violacorp.Schemas.Feerules do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Feerules

  @moduledoc "Fee Table Model"

  schema "feerules" do
    field :monthly_fee, :decimal
    field :per_card_fee, :decimal
    field :minimum_card, :integer
    field :vat, :decimal
    field :status, :string
    field :type, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false
  def changeset(%Feerules{} = feerules, attrs) do
    feerules
    |> cast(attrs, [:monthly_fee, :per_card_fee, :minimum_card, :vat, :status, :type, :inserted_by])
    |> validate_required([:title])
  end
end
