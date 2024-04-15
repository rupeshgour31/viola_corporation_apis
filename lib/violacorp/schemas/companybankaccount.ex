defmodule Violacorp.Schemas.Companybankaccount do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Companybankaccount

  @moduledoc "Companybankaccount Table Model"

  schema "companybankaccount" do
    field :account_id, :string
    field :account_number, :string
    field :account_name, :string
    field :iban_number, :string
    field :bban_number, :string
    field :currency, :string
    field :balance, :decimal
    field :sort_code, :string
    field :bank_code, :string
    field :bank_type, :string
    field :bank_status, :string
    field :request, :string
    field :response, :string
    field :status, :string
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company

    timestamps()
  end

  @doc false
  def changeset(%Companybankaccount{} = companybankaccount, attrs) do
    companybankaccount
    |> cast(attrs, [:company_id, :account_id, :account_number, :account_name, :iban_number, :bban_number, :currency, :balance, :sort_code, :bank_code, :bank_type, :bank_status, :request, :response, :status, :inserted_by])
    |> validate_required([:account_number, :account_id, :account_name, :iban_number, :bban_number, :currency, :balance, :sort_code, :bank_code, :bank_type, :bank_status, :inserted_by])
    |> update_change(:account_id, &String.trim/1)
    |> update_change(:account_name, &String.trim/1)
    |> update_change(:account_number, &String.trim/1)
    |> update_change(:bank_code, &String.trim/1)
    |> update_change(:bank_status, &String.trim/1)
    |> update_change(:bank_type, &String.trim/1)
    |> update_change(:bban_number, &String.trim/1)
    |> update_change(:currency, &String.trim/1)
    |> update_change(:iban_number, &String.trim/1)
    |> update_change(:sort_code, &String.trim/1)
    |> update_change(:status, &String.trim/1)
    |> validate_format(:account_id, ~r/[A-z0-9]+$/)
    |> validate_format(:account_name, ~r/[A-z0-9]+$/)
    |> validate_format(:account_number, ~r/[A-z0-9]+$/)
    |> validate_format(:bank_code, ~r/[A-z0-9]+$/)
    |> validate_format(:bank_status, ~r/[A-z0-9]+$/)
    |> validate_format(:bank_type, ~r/[A-z0-9]+$/)
    |> validate_format(:bban_number, ~r/[A-z0-9]+$/)
    |> validate_format(:currency, ~r/[A-z0-9]+$/)
    |> validate_format(:iban_number, ~r/[A-z0-9]+$/)
    |> validate_format(:sort_code, ~r/[A-z0-9]+$/)
    |> validate_length(:account_id, max: 255)
    |> validate_length(:account_number, max: 15)
    |> validate_length(:account_name, max: 45)
    |> validate_length(:iban_number, max: 45)
    |> validate_length(:bban_number, max: 45)
    |> validate_length(:currency, max: 4)
    |> validate_length(:sort_code, max: 10)
    |> validate_length(:bank_code, max: 10)
    |> validate_length(:bank_type, max: 10)
    |> validate_length(:bank_status, max: 10)
    |> validate_inclusion(:status, ["A", "D", "B"], message: "Make Sure you use A or D or B")
  end

  @doc false
  def changesetUpdate(%Companybankaccount{} = companybankaccount, attrs) do
    companybankaccount
    |> cast(attrs, [:company_id, :account_id, :account_number, :account_name, :iban_number, :bban_number, :currency, :balance, :sort_code, :bank_code, :bank_type, :bank_status, :request, :response, :status, :inserted_by])
    |> validate_required([:account_number])
  end

  @doc false
  def changesetFirstCall(accounts, attrs) do
    accounts
    |> cast(attrs, [:company_id, :account_name, :status, :inserted_by])
    |> validate_required([:account_name])
  end

  @doc false
  def changesetFailed(%Companybankaccount{} = companybankaccount, attrs) do
    companybankaccount
    |> cast(attrs, [:company_id, :request, :response, :status, :inserted_by])
    |> validate_required([:request, :response])
  end

  @doc false
  def changesetStatus(%Companybankaccount{} = companybankaccount, attrs) do
    companybankaccount
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  @doc false
  def changesetUpdateBalance(%Companybankaccount{} = companybankaccount, attrs) do
    companybankaccount
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end

end
