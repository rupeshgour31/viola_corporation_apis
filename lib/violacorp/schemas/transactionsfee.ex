defmodule Violacorp.Schemas.Transactionsfee do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Transactionsfee

  @moduledoc "Transactionsfee Table Model"

  schema "transactionsfee" do
    field :groupfee_id, :integer
    field :fee_amount, :string
    field :fee_type, :string
    field :inserted_by, :integer
    timestamps()
    belongs_to :transactions, Violacorp.Schemas.Transactions
  end

  @doc false
  def changeset(%Transactionsfee{} = transactionsfee, attrs) do
    transactionsfee
    |> cast(attrs, [:transactions_id, :groupfee_id, :fee_amount, :fee_type, :inserted_by])
    |> validate_required([:groupfee_id])
  end

  def changeset_fee(transactionsfee, attrs \\ :empty) do
    transactionsfee
    |> cast(attrs, [:transactions_id, :groupfee_id, :fee_amount, :fee_type, :inserted_by])
    |> validate_required([:groupfee_id])
  end
end
