defmodule Violacorp.Schemas.Duefees do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Duefees Table Model"

  schema "duefees" do
    field :amount, :decimal
    field :description, :string
    field :status, :string
    field :pay_date, :naive_datetime
    field :next_date, :naive_datetime
    field :type, :string
    field :remark, :string
    field :reason, :string
    field :total_cards, :integer
#    field :transactions_id, :integer
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    belongs_to :transactions, Violacorp.Schemas.Transactions
    timestamps()
  end

  @doc false
  def changeset(duefees, attrs) do
    duefees
    |> cast(attrs, [:commanall_id, :amount, :remark, :total_cards, :transactions_id, :description, :reason, :status, :pay_date, :next_date, :type, :inserted_by])
    |> validate_required([:amount])
  end

  @doc false
  def changesetStatus(duefees, attrs) do
    duefees
    |> cast(attrs, [:transactions_id, :status])
    |> validate_required([:status])
  end

  @doc false
  def changesetReason(duefees, attrs) do
    duefees
    |> cast(attrs, [:transactions_id, :reason])
  end

end
