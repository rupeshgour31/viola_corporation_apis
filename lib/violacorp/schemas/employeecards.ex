defmodule Violacorp.Schemas.Employeecards do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Employeecards

  @moduledoc "Employeecards Table Model"

  schema "employeecards" do
    field :currencies_id, :integer
    field :currency_code, :string
    field :card_number, :string
    field :last_digit, :string
    field :expiry_date, :string
    field :name_on_card, :string
    field :available_balance, :decimal
    field :current_balance, :decimal
    field :bin_id, :string
    field :source_id, :string
    field :accomplish_card_id, :integer
    field :activation_code, :string
    field :reason, :string
    field :change_status, :string
    field :ip_address, :string
    field :status, :string
    field :card_type, :string
    field :browser_info, :string
    field :inserted_by, :integer

    belongs_to :employee, Violacorp.Schemas.Employee
    has_many :requestmoney, Violacorp.Schemas.Requestmoney
    has_many :expense, Violacorp.Schemas.Expense
    has_many :cardtransactionsandreceipts, Violacorp.Schemas.CardTransactionsandReceipts

    timestamps()
  end

  @doc false
  def changeset(%Employeecards{} = employeecards, attrs) do
    employeecards
    |> cast(attrs, [:employee_id, :currencies_id, :currency_code, :last_digit, :expiry_date, :available_balance, :current_balance, :bin_id, :source_id, :accomplish_card_id, :activation_code, :change_status, :reason, :status, :card_type, :inserted_by])
    |> validate_required([:employee_id, :currency_code])
    |> validate_length(:reason, max: 255)
    |> validate_inclusion(:card_type, ["P", "V"])
  end
  def changesetAssignCrad(%Employeecards{} = employeecards, attrs) do
    employeecards
    |> cast(attrs, [:employee_id, :currencies_id, :currency_code, :last_digit, :expiry_date, :available_balance, :current_balance, :bin_id, :source_id, :accomplish_card_id, :activation_code, :change_status, :reason, :status, :card_type, :inserted_by])
    |> validate_required([:employee_id, :card_type, :reason])
    |> validate_length(:reason, max: 150)
    |> validate_inclusion(:card_type, ["P", "V"],message: "Require only V and P")
  end

  @doc false
  def changesetStatus(%Employeecards{} = employeecards, attrs) do
    employeecards
    |> cast(attrs, [:status, :reason, :change_status])
    |> validate_required([:status])
  end

  @doc false
  def changesetCardStatus(%Employeecards{} = employeecards, attrs) do
    employeecards
    |> cast(attrs, [:status, :reason, :change_status])
    |> validate_required([:status])
  end

  @doc false
  def changesetBalance(%Employeecards{} = employeecards, attrs) do
    employeecards
    |> cast(attrs, [:available_balance, :current_balance])
  end
end
