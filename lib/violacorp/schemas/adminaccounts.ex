defmodule Violacorp.Schemas.Adminaccounts do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Adminaccounts Table Model"

  schema "adminaccounts" do
    field :account_id, :string
    field :account_number, :string
    field :account_name, :string
    field :iban_number, :string
    field :bban_number, :string
    field :currency, :string
    field :balance, :decimal
    field :viola_balance, :decimal
    field :sort_code, :string
    field :bank_code, :string
    field :bank_type, :string
    field :bank_status, :string
    field :request, :string
    field :response, :string
    field :status, :string
    field :type, :string
    field :inserted_by, :integer

    belongs_to :administratorusers, Violacorp.Schemas.Administratorusers
    has_many :admintransactions, Violacorp.Schemas.Admintransactions
    has_many :adminbeneficiaries, Violacorp.Schemas.Adminbeneficiaries

    timestamps()
  end

  @doc false
  def changeset(adminaccounts, attrs) do
    adminaccounts
    |> cast(attrs, [:administratorusers_id, :account_id, :account_number, :account_name, :iban_number, :bban_number, :currency, :balance, :viola_balance, :sort_code, :bank_code, :bank_type, :bank_status, :request, :response, :type, :status, :inserted_by])
    |> validate_required([:account_number])
  end

  @doc false
  def changesetFailed(adminaccounts, attrs) do
    adminaccounts
    |> cast(attrs, [:administratorusers_id, :request, :response, :type, :status, :inserted_by])
    |> validate_required([:request, :response])
  end

  @doc false
  def changesetUpdateBalance(adminaccounts, attrs) do
    adminaccounts
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end

  @doc false
  def changesetUpdateViolaBalance(adminaccounts, attrs) do
    adminaccounts
    |> cast(attrs, [:balance, :viola_balance])
    |> validate_required([:viola_balance])
  end

end
