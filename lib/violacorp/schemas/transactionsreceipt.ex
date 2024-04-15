defmodule Violacorp.Schemas.Transactionsreceipt do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Transactionsreceipt

  @moduledoc "Transactionsreceipt Table Model"

  schema "transactionsreceipt" do
    field :receipt_name, :string
    field :receipt_url, :string
    field :comments, :string
    field :content, :string
    field :inserted_by, :integer

    belongs_to :transactions, Violacorp.Schemas.Transactions
    timestamps()
  end

  @doc false
  def changeset(%Transactionsreceipt{} = transactionsreceipt, attrs) do
    transactionsreceipt
    |> cast(attrs, [:transactions_id, :receipt_name, :receipt_url, :comments, :content, :inserted_by])
    |> validate_required([:transactions_id])
    |> update_change(:receipt_name, &String.trim/1)
    |> update_change(:comments, &String.trim/1)
    |> validate_format(:receipt_name, ~r/[A-z-]*$/)
    |> validate_length(:receipt_name, max: 150)
    |> validate_length(:receipt_url, max: 150)
    |> validate_length(:comments, max: 255)
  end

  @doc false
  def changesetUpdate(%Transactionsreceipt{} = transactionsreceipt, attrs) do
    transactionsreceipt
    |> cast(attrs, [:receipt_url])
  end

end
