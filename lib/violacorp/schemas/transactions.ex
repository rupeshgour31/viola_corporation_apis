defmodule Violacorp.Schemas.Transactions do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Transactions

  @moduledoc "Transactions Table Model"

  schema "transactions" do
    field :commanall_id, :integer
    field :company_id, :integer
    field :employee_id, :integer
    field :employeecards_id, :integer
    field :beneficiaries_id, :integer
    field :related_with_id, :integer
    field :account_id, :integer
    field :bank_id, :integer
    field :entertain_id, :integer
    field :category_id, :integer
    field :amount, :decimal
    field :previous_amount, :decimal
    field :fee_amount, :decimal
    field :final_amount, :decimal
    field :cur_code, :string
    field :balance, :decimal
    field :previous_balance, :decimal
    field :exchange, :string
    field :exchange_rate, :decimal
    field :transaction_id, :string
    field :transactions_id_api, :string
    field :status, :string
    field :description, :string
    field :pos_id, :integer
    field :transaction_date, :naive_datetime
    field :server_date, :string
    field :api_transaction_date, :string
    field :transaction_mode, :string
    field :transaction_type, :string
    field :category, :string
    field :category_info, :string
    field :lost_receipt, :string
    field :remark, :string
    field :notes, :string
    field :api_type, :integer
    field :notes_inserted, :integer
    field :inserted_by, :integer

    has_many :transactionsreceipt, Violacorp.Schemas.Transactionsreceipt
    has_many :transactionsfee, Violacorp.Schemas.Transactionsfee
    has_one :duefees, Violacorp.Schemas.Duefees
    belongs_to :projects, Violacorp.Schemas.Projects

    timestamps()
  end

  @doc false
  def changeset(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :employee_id, :employeecards_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transactions_id_api, :transaction_date, :server_date, :transaction_mode, :description, :transaction_type, :category, :status, :api_type, :remark, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetClearbankWorker(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :beneficiaries_id, :bank_id, :account_id, :related_with_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transactions_id_api, :transaction_date, :server_date, :transaction_mode, :description, :transaction_type, :category, :status, :api_type, :remark, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetBeneficiaryPayment(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :account_id, :bank_id, :beneficiaries_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transactions_id_api, :transaction_date, :server_date, :transaction_mode, :description, :transaction_type, :category, :status, :api_type, :remark, :inserted_by])
    |> validate_required([:company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetTopupStepFirst(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :bank_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :description, :transaction_type, :category, :remark, :api_type, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
  end

  @doc false
  def changesetTopupStepSecond(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :employee_id, :employeecards_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category, :description, :remark, :api_type, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :employee_id, :employeecards_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
  end

  @doc false
  def changesetAFTransaction(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :account_id, :employee_id, :employeecards_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category, :description, :remark, :api_type, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
  end


  @doc false
  def changesetTopupStepThird(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :employee_id, :employeecards_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category, :status, :description, :transactions_id_api, :api_type, :remark, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :employee_id, :employeecards_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetFee(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category, :description, :api_type, :remark, :notes, :status, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
  end

  @doc false
  def changesetUpdateStatus(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:status, :transactions_id_api, :description, :remark])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetUpdateStatusQR(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:status, :transactions_id_api, :server_date, :api_transaction_date])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetAssignProject(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:projects_id])
  end

  @doc false
  def changesetDescription(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:status, :description])
  end

  @doc false
  def changesetUpdateStatusOnly(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:status])
  end

  @doc false
  def changesetDescriptionRemark(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:remark, :description])
  end

  @doc false
  def changeset_pos(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :employee_id, :employeecards_id, :pos_id, :amount, :fee_amount, :final_amount, :balance, :previous_balance, :cur_code, :transaction_id, :transactions_id_api, :transaction_date, :server_date, :api_transaction_date, :transaction_mode, :description, :transaction_type, :category, :status, :api_type, :remark, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :employee_id, :employeecards_id, :pos_id, :amount, :fee_amount, :final_amount, :cur_code, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  @doc false
  def changesetUpdateStatusApi(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:status, :pos_id, :transactions_id_api, :amount, :previous_amount])
    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

  def changesetNotes(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:notes, :notes_inserted])
    |> validate_required([:notes])
  end

  @doc false
  def changesetAssignCategory(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:category_id])
    |> validate_required(:category_id)
  end

  @doc false
  def changesetAssignEntertain(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:entertain_id])
    |> validate_required(:entertain_id)
  end

  @doc false
  def changesetWebhook(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :company_id, :bank_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transaction_date, :transaction_mode, :description, :transaction_type, :category, :remark, :api_type, :status, :inserted_by])
    |> validate_required([:commanall_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code])
  end

  def changesetLostReceipt(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:lost_receipt])
    |> validate_required(:lost_receipt)
    |> validate_inclusion(:lost_receipt, ["Yes", "No"])
  end

  def changesetCategoryInfo(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:category_info])
    |> validate_required(:category_info)
  end

  @doc """
    this function used for transfer all bank fund to admin account
  """
  def changesetPayment(%Transactions{} = transactions, attrs) do
    transactions
    |> cast(attrs, [:commanall_id, :account_id, :bank_id, :company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :previous_balance, :transaction_id, :transactions_id_api, :transaction_date, :server_date, :transaction_mode, :description, :transaction_type, :category, :status, :api_type, :remark, :inserted_by])
    |> validate_required([:company_id, :amount, :fee_amount, :final_amount, :cur_code, :balance, :transaction_id, :transaction_date, :transaction_mode, :transaction_type, :category])
#    |> unique_constraint(:transactions_id_api, name: :transactions_id_api_UNIQUE, message: "Duplicate transaction api id is not allowed.")
  end

end
