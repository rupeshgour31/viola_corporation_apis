defmodule ViolacorpWeb.Admin.Transaction.TransactionController do
  use Phoenix.Controller
  alias  Violacorp.Models.Transactions

  @doc """
    ** Online Business Transaction **
    1. credit debit transaction
  """
  def getCreaditAndDebitTransaction(conn, params)do
    data = Transactions.credit_debit_transaction(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("credit_debit_transaction.json", data: data)
  end

  @doc """
    ** Online Business Transaction **
    2. Transfer to card management
  """
  def getAllTransferTocardManagemet(conn, params)do
    data = Transactions.transfer_to_card_managment(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("transfer_to_card_management.json", data: data)
  end

  @doc """
    ** Online Business Transaction **
    3. Fee Transaction
  """
  def getAllonlineFeeTransactions(conn, params) do
    data = Transactions.getOnlinefeeTransactions(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("online_fee_transaction.json", data: data)
  end

  @doc """
    ** Card Management Transactions **
    1. Company Transactions
  """
  def getAllcomapnyTransaction(conn, params)do
    data = Transactions.company_transaction(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("company_transaction.json", data: data)
  end

  @doc """
    ** Card Management Transactions **
    2. User Transaction
  """
  def getAllemployeeTransaction(conn, params) do
      data = Transactions.employee_transaction(params)

      conn
      |>put_view(ViolacorpWeb.TransactionsView)
      |>render("employee_transaction.json", data: data)
  end

  @doc """
    ** Card Management Transactions **
    3. POS Transaction
  """
  def getAllposTransactions(conn, params) do
    data = Transactions.pos_transactions(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("pos.json", data: data)
  end

  @doc """
    ** Card Management Transactions **
    4. Fee Transaction
  """
  def getAllfeeTransactions(conn, params) do
    data = Transactions.fee_transactions(params)
    conn
    |>put_view(ViolacorpWeb.TransactionsView)
    |>render("card_management_fee_tx.json", data: data)
  end

  @doc """
    ** Card Management Transactions **
    5. Accomplish Transaction
  """
  def getAllaccomplishTransactions(conn, params) do
    response = Transactions.getAll_accomplish_transactions(params)
    case response do
      {:error, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:thirdparty_error, message} -> json conn, message
      {:ok, data} -> json conn, %{status_code: "200", data: data}
    end
  end

  def getTransactionReciept(conn, params) do
    data = Transactions.getOneTransactionReciept(params)
     case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        conn
        |>put_view(ViolacorpWeb.TransactionsView)
        |>render("indexTransactionReciept.json", data: data)
    end
  end

  @doc """
    transfer employee card balance (its for employee section)
    ** use when we are block employee so his card found move to his companies account **
  """
  def trasferEmployeeCardsBalance(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Transactions.trasferEmployeeCardsBalance(params, admin_id) do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:InvalidEmployee, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:field_error, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:InvalidCard, message} -> json conn, %{status_code: "4003", errors: %{message: message}}
      {:validation_errors, message} -> json conn, %{status_code: "4003", errors: message}
      {:AccountNotFound, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:ErrorMessage, errors_massage} -> json conn, errors_massage
    end
  end

end
