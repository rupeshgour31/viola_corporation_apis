defmodule Violacorp.Schemas.Dwmtransactions do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Dwmtransactions Table Model"

  schema "dwmtransactions" do
    field :account_success_amount, :decimal
    field :account_failed_amount, :decimal
    field :account_success_count, :integer
    field :account_failed_count, :integer
    field :card_success_amount, :decimal
    field :card_failed_amount, :decimal
    field :card_success_count, :integer
    field :card_failed_count, :integer
    field :trans_date, :date
    field :status, :string
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(dwmtransactions, attrs) do
    dwmtransactions
    |> cast(attrs, [:commanall_id, :account_success_amount, :account_failed_amount, :account_success_count, :account_failed_count, :card_success_amount, :card_failed_amount, :card_success_count, :card_failed_count, :trans_date, :status, :inserted_by])
    |> validate_required([:commanall_id])
  end

end
