defmodule Violacorp.Models.Transactions do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
#  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools
#  alias Violacorp.Schemas.Currencies
#  alias Violacorp.Schemas.Transactionsreceipt

  @doc """
    ** Online Business Transaction **
    1. credit debit transaction
  """
  def credit_debit_transaction(params)do
    filtered = params
           |> Map.take(~w(company_id transaction_id transaction_mode status cur_code final_amount))
           |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
     (from t in Transactions,order_by: [desc: t.id],
           where: t. transaction_type == "A2A" and not is_nil(t.bank_id) and like(t.remark, ^"%#{company_name}%"),
           having: ^filtered
     )|>Repo.paginate(params)
  end

  @doc """
    ** Online Business Transaction **
    2. Transfer to card management
  """
  def transfer_to_card_managment(params)do
    filtered = params
               |> Map.take(~w(company_id transaction_id transaction_mode status cur_code final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    (from t in Transactions,order_by: [desc: t.id],
          where: (t.transaction_type == "A2A"  and t.transaction_mode == "D" and like(t.remark, ^"%#{company_name}%")),
          join: c in Company,on: t.company_id == c.id)
    |> having(^filtered)
    |>Repo.paginate(params)
  end

  @doc """
    ** Online Business Transaction **
    3. Fee Transaction
  """
  def getOnlinefeeTransactions(params) do

    filtered = params
               |> Map.take(~w(company_id transaction_id transaction_mode status cur_code final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    (from t in Transactions,order_by: [desc: t.id],
          having: ^filtered,
          where: (t.category == "FEE" and is_nil(t.account_id) and like(t.remark, ^"%#{company_name}%")),
          join: c in Company,on: t.company_id == c.id
      )
    |>Repo.paginate(params)
  end

  @doc """
    ** Card Management Transactions **
    1. Company Transactions
  """
  def company_transaction(params)do
    filtered = params
               |> Map.take(~w(company_id transaction_id status transaction_mode final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    company_name = params["company_name"]

    (from t in Transactions,order_by: [desc: t.id],
      having: ^filtered,
      where:  (t.category == "CT" or t.category =="MV") and  ((t.transaction_type == "A2C" and t.transaction_mode == "D") or t.transaction_type == "C2A")  and like(t.remark, ^"%#{company_name}%")
      )
    |>Repo.paginate(params)
  end

  @doc """
    ** Card Management Transactions **
    2. User Transaction
  """
  def employee_transaction(params) do
    filtered = params
               |> Map.take(~w(employeecards_id company_id transaction_id status transaction_mode cur_code final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    last_name = params["last_name"]
    first_name = params["first_name"]
    name = cond  do
      !is_nil(params["last_name"]) and !is_nil(params["first_name"])  -> "#{first_name} #{last_name}"
      !is_nil(params["last_name"]) and is_nil(params["first_name"]) -> "#{last_name}"
       is_nil(params["last_name"]) and !is_nil(params["first_name"]) -> "#{first_name}"
       true -> ""
    end

    (from t in Transactions,
      having: ^filtered,order_by: [desc: t.id],
      where: (t.category == "POS" or  t.category =="CU" or  t.category == "MV" or t.category == "CT") and
             ((t.transaction_type == "A2C" and t.transaction_mode == "C") or
             (t.transaction_type == "C2A" and t.transaction_mode == "D") or
             (t.transaction_type == "C2O" and t.transaction_mode == "D") or
             (t.transaction_type == "C2I" and t.transaction_mode == "D") or
             (t.transaction_type == "ACF" and t.transaction_mode == "D")) and (like(t.remark, ^"%#{name}%")),
      select: %{
        id: t.id,
        category: t.category,
        employeecards_id: t.employeecards_id,
        company_id: t.company_id,
        cur_code: t.cur_code,
        transaction_id: t.transaction_id,
        transaction_type: t.transaction_type,
        transaction_mode: t.transaction_mode,
        final_amount: t.final_amount,
        status: t.status,
        updated_at: t.updated_at,
        server_date: t.server_date,
        remark: t.remark
      })
      |>Repo.paginate(params)
  end

  @doc """
    ** Card Management Transactions **
    3. POS Transaction
  """
  def pos_transactions(params) do
    filtered = params
               |> Map.take(~w(employeecards_id company_id transaction_id status transaction_mode cur_code final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    last_name = params["last_name"]
    first_name = params["first_name"]
    (from t in Transactions,order_by: [desc: t.id],
      having: ^filtered,
      where: t.category == "POS",
      left_join: e in Employee,
      on: t.employee_id == e.id,
      where: like(e.first_name, ^"%#{first_name}%")  and like(e.last_name, ^"%#{last_name}%") ,
      select: %{
        id: t.id,
        first_name: e.first_name,
        last_name: e.last_name,
        company_id: t.company_id,
        transaction_id: t.transaction_id,
        cur_code: t.cur_code,
        transaction_type: t.transaction_type,
        transaction_mode: t.transaction_mode,
        category: t.category,
        amount: t.final_amount,
        status: t.status,
        updated_at: t.updated_at,
        server_date: t.server_date,
        remark: t.remark
      })
      |> Repo.paginate(params)
  end

  @doc """
    ** Card Management Transactions **
    4. Fee Transaction
  """
  def fee_transactions(params) do
    filtered = params
               |> Map.take(~w(company_id transaction_id status transaction_mode cur_code final_amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    (from t in Transactions, having: ^filtered,order_by: [desc: t.id],
        where: t.category == "FEE",
        left_join: c in Company,
        on: t.company_id == c.id, where: like(c.company_name, ^"%#{company_name}%"),
        select: %{
            id: t.id,
            company_name: c.company_name,
            company_id: t.company_id,
            transaction_id: t.transaction_id,
            transaction_type: t.transaction_type,
            transaction_mode: t.transaction_mode,
            transaction_date: t.transaction_date,
            cur_code: t.cur_code,
            category: t.category,
            final_amount: t.final_amount,
            status: t.status,
            updated_at: t.updated_at,
            server_date: t.server_date,
            remark: t.remark
        })
    |>Repo.paginate(params)
  end

  @doc """
    ** Card Management Transactions **
    5. Accomplish Transaction
  """
  def getAll_accomplish_transactions(params) do

      account_id = params["account_id"]
      from_date = params["from_date"]
      to_date = params["to_date"]
      status = params["status"]
      start_index = params["start_index"]
      page_size = params["page_size"]

      case params["account_id"] do
         nil -> {:error, "account Id is required"}
         _data ->
           user_id = Repo.one(from cd in Employeecards, left_join: com in Commanall, on: com.employee_id == cd.employee_id, where: cd.accomplish_card_id == ^account_id, select: com.accomplish_userid)
           if !is_nil(user_id) do
               request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{
                 status
               }&start_index=#{start_index}&page_size=#{page_size}"
               response = Accomplish.get_success_transaction(request)
               if !is_nil(response) do
                  response_code = response["result"]["code"]
                  response_message = response["result"]["friendly_message"]
                  if response_code === "0000" do
                      _transaction = response["transactions"]
                      result = Enum.map(response["transactions"], fn tra -> tra["info"] end)
                      {:ok, result}
                    else
                      {:thirdparty_error, %{status_code: response_code, errors: %{message: response_message}}}
                  end
                else
                 {:error, "record not found!"}
               end
            else
             {:error, "account id not found!"}
           end
      end
  end


  def getOneTransactionReciept(params) do
          (from a in Transactions, where: a.id == ^params["id"],
                 left_join: r in assoc(a, :transactionsreceipt),
                 preload: [transactionsreceipt: r]
            )
          |> Repo.one
  end

  @doc """
    transfer employee card balance (its for employee section)
    ** use when we are block employee so his card found move to his companies account **
  """
  def trasferEmployeeCardsBalance(params, admin_id) do

    case checkFieldValidation(params) do
      {:ok, _message} ->
        case Commontools.checkOwnPassword(params["password"], admin_id) do
          {:ok, _message} ->
            get_employee = Repo.get_by(Employee, id: params["employee_id"])
            if !is_nil(get_employee) do
              get_card = Repo.one(from e in Employeecards, where: e.id == ^params["card_id"], select: %{id: e.id, accomplish_card_id: e.accomplish_card_id, employee_id: e.employee_id, available_balance: e.available_balance, currency_code: e.currency_code})
              if !is_nil(get_card) do
                get_account = Repo.one(from ca in Companyaccounts, where: ca.company_id == ^get_employee.company_id and ca.currency_code == ^get_card.currency_code, select: %{id: ca.id})
                if !is_nil(get_account) do
                  if get_card.available_balance > Decimal.new(0.00) do
                    get_company = Repo.one(from c in Commanall, where: c.company_id == ^get_employee.company_id, select: %{id: c.id})

                    case enableCardOnThirdParty(get_card.accomplish_card_id, "1") do
                      {:ok, _response_message} ->
                        reclaim_params =
                          %{
                            commanid: get_company.id,
                            companyid: get_employee.company_id,
                            employeeId: get_card.employee_id,
                            card_id: get_card.id,
                            account_id: get_account.id,
                            amount: get_card.available_balance,
                            type: "C2A",
                            description: "Reclaim of all funds due to Employee being blocked"
                          }
                        response = ViolacorpWeb.Main.DashboardController.reclaimFunds(reclaim_params)
                        response_code = response["status_code"]
                        if response_code === "200" do
                          enableCardOnThirdParty(get_card.accomplish_card_id, "4")
                          {:ok, "Funds Transfer Successfully."}
                        else
                          {:ErrorMessage, response}
                        end
                      {:error, error_message} -> {:ErrorMessage, error_message}
                    end

                  else
                    {:ok, "Funds Transfer Successfully."}
                  end
                else
                  {:AccountNotFound, "Company card management account not found."}
                end
              else
                {:InvalidCard, "Invalid Card."}
              end
            else
              {:InvalidEmployee, "Invalid Employee."}
            end
          {:not_matched, message} -> {:field_error, %{password: message}}
        end

      {:validation_errors, changeset} -> {:validation_errors, changeset}
    end
  end

  def checkFieldValidation(params) do
    cond do
      is_nil(params["employee_id"]) && is_nil(params["card_id"]) -> {:validation_errors, %{employee_id: "can't be black", card_id: "can't be black"}}
      params["employee_id"] === "" && params["card_id"] === "" -> {:validation_errors, %{employee_id: "can't be black", card_id: "can't be black"}}
      is_nil(params["employee_id"]) -> {:validation_errors, %{employee_id: "can't be black"}}
      params["employee_id"] === "" -> {:validation_errors, %{employee_id: "can't be black"}}
      is_nil(params["card_id"]) -> {:validation_errors, %{card_id: "can't be black"}}
      params["card_id"] === "" -> {:validation_errors, %{card_id: "can't be black"}}
      true -> {:ok, "ok"}
    end
  end

  defp enableCardOnThirdParty(account_id, status) do
    request = %{urlid: account_id, status: status}
    response = Accomplish.activate_deactive_card(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]
    if response_code === "0000" or response_code == "3055"  or response_code == "3030" do
      {:ok, response_message}
    else
      {:error, %{status_code: "5001", errors: %{message: response_message}}}
    end
  end

end
