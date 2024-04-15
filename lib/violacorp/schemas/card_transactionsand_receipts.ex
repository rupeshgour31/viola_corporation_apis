defmodule Violacorp.Schemas.CardTransactionsandReceipts do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.CardTransactionsandReceipts


  schema "cardtransactionsandreceipts" do
    field :total_amount, :decimal
    field :total_receipt_pending, :integer
    field :total_transactions, :integer

    belongs_to :employeecards, Violacorp.Schemas.Employeecards
    timestamps()
  end

  @doc false
  def changeset(%CardTransactionsandReceipts{} = card_transactionsand_receipts, attrs) do
    card_transactionsand_receipts
    |> cast(attrs, [:total_amount, :total_transactions, :total_receipt_pending])
    |> validate_required([:total_amount, :total_transactions, :total_receipt_pending])
  end

  def changesetUpdatePending(%CardTransactionsandReceipts{} = card_transactionsand_receipts, attrs) do
    card_transactionsand_receipts
    |> cast(attrs, [:total_receipt_pending])
    |> validate_required([:total_receipt_pending])
  end
  def changesetTransactionCount(%CardTransactionsandReceipts{} = card_transactionsand_receipts, attrs) do
    card_transactionsand_receipts
    |> cast(attrs, [:employeecards_id, :total_amount, :total_transactions])
    |> validate_required([:employeecards_id, :total_amount, :total_transactions])
  end

  def changesetInsertorUpdate(%CardTransactionsandReceipts{} = card_transactionsand_receipts, attrs) do
    card_transactionsand_receipts
    |> cast(attrs, [:employeecards_id, :total_amount, :total_transactions])
  end
end
