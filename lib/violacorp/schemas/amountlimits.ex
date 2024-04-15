defmodule Violacorp.Schemas.Amountlimits do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Amountlimits

  @moduledoc "Amountlimits Table Model"

  schema "amountlimits" do
    field :account_max_balance, :decimal
    field :single_transaction_limit, :decimal
    field :weekly_transaction_limit, :decimal
    field :monthly_transaction_limit, :decimal
    field :max_load_per_year_amount, :decimal
    field :max_load_per_year_count, :decimal
    field :max_load_per_month_amount, :decimal
    field :max_load_per_month_count, :decimal
    field :max_load_per_day_amount, :decimal
    field :max_load_per_day_count, :decimal
    field :min_amount, :decimal
    field :max_amount_card, :decimal
    field :status, :string
    field :inserted_by, :integer



    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(%Amountlimits{} = amountlimits, attrs) do
    amountlimits
    |> cast(attrs, [:commanall_id, :account_max_balance, :single_transaction_limit, :weekly_transaction_limit, :monthly_transaction_limit, :max_load_per_year_amount, :max_load_per_year_count, :max_load_per_month_amount, :max_load_per_month_count, :max_load_per_day_amount, :max_load_per_day_count, :min_amount, :max_amount_card, :status, :inserted_by])
    |> validate_required([:commanall_id])
  end
end
