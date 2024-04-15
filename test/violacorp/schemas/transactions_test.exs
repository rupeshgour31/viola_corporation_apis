defmodule Violacorp.Schemas.TransactionsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Transactions
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1234,
    company_id: 1234,
    employee_id: 1234,
    employeecards_id: 1234,
    beneficiaries_id: 1234,
    related_with_id: 1234,
    account_id: 123456,
    bank_id: 2345,
    entertain_id: 23456,
    category_id: 3234,
    amount: Decimal.from_float(120.20),
    previous_amount: Decimal.from_float(120.20),
    fee_amount: Decimal.from_float(120.20),
    final_amount: Decimal.from_float(120.20),
    cur_code: "123",
    balance: Decimal.from_float(120.20),
    previous_balance: Decimal.from_float(120.20),
    exchange: "ewrs",
    exchange_rate: Decimal.from_float(120.20),
    transaction_id: "938409242342",
    transactions_id_api: "2342343141",
    status: "A",
    description: "ewfwefwef",
    pos_id: 123123,
    transaction_date: ~N[2018-07-02 08:24:00],
    server_date: "2018-07-02 08:24:00",
    api_transaction_date: "2018-07-02 08:24:00",
    transaction_mode: "C",
    transaction_type: "A2A",
    category: "One",
    category_info: "dsvsdvsdv",
    lost_receipt: "Yes",
    remark: "rwegfwegwef",
    notes: "efwefewf",
    api_type: 222,
    notes_inserted: 2,
    inserted_by: 1234
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Transactions.changeset(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Transactions.changeset(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check" do
    changeset = Transactions.changeset(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc " changesetClearbankWorker"

  test "changeset with valid attributes changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetClearbankWorker" do
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc "changesetBeneficiaryPayment "

  test "changeset with valid attributes changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "company_id required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetBeneficiaryPayment" do
    changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc "changesetTopupStepFirst"

  test "changeset with valid attributes changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetTopupStepFirst" do
    changeset = Transactions.changesetTopupStepFirst(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

@doc "changesetTopupStepSecond"


  test "changeset with valid attributes changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  test "employee_id required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :employee_id))
    assert !changeset.valid?
  end

  test "employeecards_id required check changesetTopupStepSecond" do
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, Map.delete(@valid_attrs, :employeecards_id))
    assert !changeset.valid?
  end

@doc "changesetAFTransaction"

  test "changeset with valid attributes changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetAFTransaction" do
    changeset = Transactions.changesetAFTransaction(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc "changesetTopupStepThird"

  test "changeset with valid attributes changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  test "employee_id required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :employee_id))
    assert !changeset.valid?
  end

  test "employeecards_id required check changesetTopupStepThird" do
    changeset = Transactions.changesetTopupStepThird(%Transactions{}, Map.delete(@valid_attrs, :employeecards_id))
    assert !changeset.valid?
  end

  @doc "changesetFee"


  test "changeset with valid attributes changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetFee" do
    changeset = Transactions.changesetFee(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc "changesetUpdateStatus"

  test "changeset with valid attributes changesetUpdateStatus" do
    changeset = Transactions.changesetUpdateStatus(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "changesetUpdateStatusQR"

  test "changeset with valid attributes changesetUpdateStatusQR" do
    changeset = Transactions.changesetUpdateStatusQR(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "changesetAssignProject"

  test "changeset with valid attributes changesetAssignProject" do
    changeset = Transactions.changesetAssignProject(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

    @doc "changesetDescription"

  test "changeset with valid attributes changesetDescription" do
    changeset = Transactions.changesetDescription(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end


    @doc "changesetUpdateStatusOnly"

  test "changeset with valid attributes changesetUpdateStatusOnly" do
    changeset = Transactions.changesetUpdateStatusOnly(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end


    @doc "changesetDescriptionRemark"

  test "changeset with valid attributes changesetDescriptionRemark" do
    changeset = Transactions.changesetDescriptionRemark(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "changeset_pos"

  test "changeset with valid attributes changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "transaction_id required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changeset_pos" do
    changeset = Transactions.changeset_pos(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

  @doc "changesetUpdateStatusApi"


  test "changeset with valid attributes changesetUpdateStatusApi" do
    changeset = Transactions.changesetUpdateStatusApi(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "changesetNotes"

  test "changeset with valid attributes changesetNotes" do
    changeset = Transactions.changesetNotes(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetNotes" do
    changeset = Transactions.changesetNotes(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "notes required check changesetNotes" do
    changeset = Transactions.changesetNotes(%Transactions{}, Map.delete(@valid_attrs, :notes))
    assert !changeset.valid?
  end

  @doc "changesetAssignCategory "

  test "changeset with valid attributes changesetAssignCategory" do
    changeset = Transactions.changesetAssignCategory(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetAssignCategory" do
    changeset = Transactions.changesetAssignCategory(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "category_id required check changesetAssignCategory" do
    changeset = Transactions.changesetAssignCategory(%Transactions{}, Map.delete(@valid_attrs, :category_id))
    assert !changeset.valid?
  end

  @doc "changesetAssignEntertain"


  test "changeset with valid attributes changesetAssignEntertain" do
    changeset = Transactions.changesetAssignEntertain(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetAssignEntertain" do
    changeset = Transactions.changesetAssignEntertain(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "entertain_id required check changesetAssignEntertain" do
    changeset = Transactions.changesetAssignEntertain(%Transactions{}, Map.delete(@valid_attrs, :entertain_id))
    assert !changeset.valid?
  end

  @doc "changesetWebhook"
  test "changeset with valid attributes changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end


  test "company_id required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end


  test "amount required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end
  test "fee_amount required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

    test "final_amount required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

      test "cur_code required check changesetWebhook" do
    changeset = Transactions.changesetWebhook(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

@doc " changesetLostReceipt"

  test "changeset with valid attributes changesetLostReceipt" do
    changeset = Transactions.changesetLostReceipt(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetLostReceipt" do
    changeset = Transactions.changesetLostReceipt(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "lost_receipt required check changesetLostReceipt" do
    changeset = Transactions.changesetLostReceipt(%Transactions{}, Map.delete(@valid_attrs, :lost_receipt))
    assert !changeset.valid?
  end

  test "check if lost_receipt accepts only Yes and No" do
    attrs = %{@valid_attrs | lost_receipt: "R"}
    changeset = Transactions.changesetLostReceipt(%Transactions{}, attrs)
    assert %{lost_receipt: ["is invalid"]} = errors_on(changeset)
  end

  @doc "changesetCategoryInfo"

  test "changeset with valid attributes changesetCategoryInfo" do
    changeset = Transactions.changesetCategoryInfo(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetCategoryInfo" do
    changeset = Transactions.changesetCategoryInfo(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "category_info required check changesetCategoryInfo" do
    changeset = Transactions.changesetCategoryInfo(%Transactions{}, Map.delete(@valid_attrs, :category_info))
    assert !changeset.valid?
  end

  @doc "changesetPayment"


  test "changeset with valid attributes changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "company_id required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :company_id))
    assert !changeset.valid?
  end

  test "amount required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :amount))
    assert !changeset.valid?
  end

  test "fee_amount required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :fee_amount))
    assert !changeset.valid?
  end

  test "final_amount required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :final_amount))
    assert !changeset.valid?
  end

  test "cur_code required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :cur_code))
    assert !changeset.valid?
  end

  test "balance required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :balance))
    assert !changeset.valid?
  end

  test "transaction_id required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_id))
    assert !changeset.valid?
  end

  test "transaction_date required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_date))
    assert !changeset.valid?
  end

  test "transaction_mode required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_mode))
    assert !changeset.valid?
  end

  test "transaction_type required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :transaction_type))
    assert !changeset.valid?
  end

  test "category required check changesetPayment" do
    changeset = Transactions.changesetPayment(%Transactions{}, Map.delete(@valid_attrs, :category))
    assert !changeset.valid?
  end

end