defmodule Violacorp.Schemas.Companyaccounts do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Companyaccounts

  @moduledoc "Companyaccounts Table Model"

  schema "companyaccounts" do
    field :currencies_id, :integer
    field :currency_code, :string
    field :available_balance, :decimal
    field :current_balance, :decimal
    field :account_number, :integer
    field :accomplish_account_number, :string
    field :accomplish_account_id, :integer
    field :bin_id, :string
    field :expiry_date, :date
    field :source_id, :string
    field :status, :string
    field :reason, :string
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company

    timestamps()
  end

  @doc false
  def changeset(%Companyaccounts{} = companyaccounts, attrs) do
    companyaccounts
    |> cast(attrs, [:company_id, :currencies_id, :currency_code, :available_balance, :current_balance, :account_number, :accomplish_account_number, :expiry_date, :accomplish_account_id, :bin_id, :source_id, :status, :inserted_by])
  end

  @doc false
  def changesetBalance(%Companyaccounts{} = companyaccounts, attrs) do
    companyaccounts
    |> cast(attrs, [:available_balance, :current_balance])
  end

  @doc "company Status change"
  def changesetStatus(%Companyaccounts{} = companyaccounts, attrs) do
    companyaccounts
    |> cast(attrs, [:status, :reason])
  end
end
