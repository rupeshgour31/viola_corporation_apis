defmodule Violacorp.Models.ThirdParty do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Employeecards

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Clearbank


  #    alias Violacorp.Workers.ManualLoad
  #    alias Violacorp.Workers.PendingTransactionsUpdater
  #    alias Violacorp.Workers.SuccessTransactionsUpdater

  @doc "Update Company Account Balance"
  def update_account_balance(commanid, userid) do
    response = Accomplish.get_user(userid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]
    if response_code == "0000" do
      Enum.each response["account"], fn post ->
        accomplish_acc_id = post["info"]["id"]
        company = Repo.one from c in Companyaccounts, where: c.accomplish_account_id == ^accomplish_acc_id,
                                                      select: %{
                                                        id: c.id,
                                                        company_id: c.company_id,
                                                        accomplish_account_id: c.accomplish_account_id,
                                                        available_balance: c.available_balance,
                                                        current_balance: c.current_balance
                                                      }

        if company != nil do
          db_avi_balance = to_string(company.available_balance)
          db_cur_balance = to_string(company.current_balance)
          ser_avi_balance = post["info"]["available_balance"]
          ser_cur_balance = post["info"]["balance"]
          if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do

            # call manual load method
            load_params = %{
              "worker_type" => "manual_load",
              "commanall_id" => commanid,
              "company_id" => company.company_id
            }
            Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

            companyaccount = Repo.get!(Companyaccounts, company.id)
            update_balance = %{
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"]
            }
            changeset_companyaccount = Companyaccounts.changesetBalance(companyaccount, update_balance)
            Repo.update(changeset_companyaccount)
          end
        end
      end
    end
    _return_response = %{"response_code" => response_code, "response_message" => response_message}
  end

  def get_accomplish_userid(params)do
    commanall = Repo.one from c in Commanall, where: c.company_id == ^params["company_id"],
                                              select: %{
                                                id: c.id,
                                                accomplish_userid: c.accomplish_userid
                                              }
    company = Repo.one from c in Companyaccounts,
                       where: not is_nil(c.accomplish_account_id) and c.company_id == ^params["company_id"]
    if !is_nil(company) do
      response = if commanall.accomplish_userid != nil do
        userid = commanall.accomplish_userid
        commanallid = commanall.id
        update_account_balance(commanallid, userid)
      else
        %{"response_code" => "404", "response_message" => "Record not found!"}
      end
      response_code = if response["response_code"] == "0000" do
        "200"
      else
        response["response_code"]
      end
      response_msg = if response["response_code"] == "0000" do
        "Balance Refreshed"
      else
        response["response_message"]
      end
      %{status_code: response_code, message: response_msg}
    else
      nil
    end
  end

  def get_company_online_account(params) do
    get_account = Repo.one(from a in Companybankaccount, limit: 1, where: a.company_id == ^params["company_id"])
    if !is_nil(get_account) do
      accountid = get_account.account_id
      response = Clearbank.view_account(accountid)
      res = get_in(response["account"]["balances"], [Access.at(0)])
      balance = res["amount"]
      system_balance = String.to_float("#{get_account.balance}")
      server_balance = balance

      ## Pull Transaction
      commanall_id = Repo.one(from c in Commanall, where: c.company_id == ^params["company_id"], select: c.id)
      load_params = %{
        "commanall_id" => commanall_id,
        "worker_type" => "clearbank_transactions",
      }
      Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)

      if system_balance != server_balance do
        accountBalance = %{"balance" => balance}
        changeset = Companybankaccount.changesetUpdateBalance(get_account, accountBalance)
        case Repo.update(changeset) do
          {:ok, _bankAccount} -> {:ok, "Balance Updated Successfully"}
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:ok, "Balance Updated Successfully"}
      end
    else
      {:acoount_not_exist, "account not found"}
    end

  end

  @doc """
  Refresh balance for selected bank account
"""
    def get_company_online_account_v1(params) do
      get_account = Repo.one(from a in Companybankaccount,
                             where: a.id == ^params["id"] and a.company_id == ^params["company_id"])
      if !is_nil(get_account) do
        accountid = get_account.account_id
        response =  Clearbank.view_account(accountid)
        res = get_in(response["account"]["balances"], [Access.at(0)])
        balance = res["amount"]
        system_balance = String.to_float("#{get_account.balance}")
        server_balance = balance

        ## Pull Transaction
        commanall_id = Repo.one(from c in Commanall, where: c.company_id == ^params["company_id"], select: c.id)
        load_params = %{
          "commanall_id" => commanall_id,
          "worker_type" => "clearbank_transactions",
        }
        Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions,  [load_params], max_retries: 1)

        if system_balance != server_balance do
          accountBalance = %{"balance" => balance}
          changeset = Companybankaccount.changesetUpdateBalance(get_account, accountBalance)
          case Repo.update(changeset) do
            {:ok, _bankAccount} -> {:ok, "Balance Updated Successfully"}
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:ok, "Balance Updated Successfully"}
        end
      else
        {:acoount_not_exist, "account not found"}
      end

    end

  def employeeRefreshBalance(params) do
    card = Repo.one from e in Employeecards, where: not is_nil(e.accomplish_card_id) and e.id == ^params["card_id"]
    if !is_nil(card) do
      commanall = Repo.one from c in Commanall, where: c.employee_id == ^card.employee_id,
                                                select: %{
                                                  id: c.id,
                                                  accomplish_userid: c.accomplish_userid
                                                }
      response =
        if commanall.accomplish_userid != nil do
          userid = commanall.accomplish_userid
          update_card_balance(userid)
        else
          %{"response_code" => "404", "response_message" => "Record not found!"}
        end
      response_code = if response["response_code"] == "0000" do
        "200"
      else
        response["response_code"]
      end
      response_msg = if response["response_code"] == "0000" do
        "Balance Refreshed"
      else
        response["response_message"]
      end
      %{status_code: response_code, message: response_msg}
    else
      nil
    end
  end

  @doc "Update Employee Card Balance"
  def update_card_balance(userid) do
    response = Accomplish.get_user(userid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]
    if response_code == "0000" do
      Enum.each response["account"], fn post ->
        accomplish_card_id = post["info"]["id"]
        employee = Repo.one from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id,
                                                     select: %{
                                                       id: e.id,
                                                       employee_id: e.employee_id,
                                                       available_balance: e.available_balance,
                                                       current_balance: e.current_balance
                                                     }
        if employee != nil do
          db_avi_balance = to_string(employee.available_balance)
          db_cur_balance = to_string(employee.current_balance)
          ser_avi_balance = post["info"]["available_balance"]
          ser_cur_balance = post["info"]["balance"]
          if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do
            employeecard = Repo.get!(Employeecards, employee.id)
            update_balance = %{
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"]
            }
            changeset_employeecard = Employeecards.changesetBalance(employeecard, update_balance)
            Repo.update(changeset_employeecard)
          end
        end
      end
    end
    _return_response = %{"response_code" => response_code, "response_message" => response_message}
  end

  @doc"Manual Topup for card management account"
  def manualTopUp(params) do

    if !is_nil(params["id"]) && !is_nil(params["reason"]) && !is_nil(params["amount"]) do
      account_details = Repo.one(from c in Companyaccounts, where: c.id == ^params["id"], limit: 1)
      if !is_nil(account_details) do
        reason = params["reason"]
        type = Application.get_env(:violacorp, :general_credit)
        enter_amount = params["amount"]
        amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
        currency = account_details.currency_code
        account_id = account_details.accomplish_account_id

        request = %{
          type: type,
          notes: reason,
          amount: amount,
          currency: currency,
          account_id: account_id
        }

        # Send to Accomplish
        response = Accomplish.load_money(request)

        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do

          # call manual load method
          company_id = account_details.company_id
          get_commanall_id = Repo.one from a in Commanall, where: a.company_id == ^company_id,
                                                           select: %{
                                                             id: a.id
                                                           }
          load_params = %{
            "worker_type" => "manual_load",
            "commanall_id" => get_commanall_id.id,
            "company_id" => company_id
          }
          Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

          # update balance
          gets_account = Accomplish.get_account(account_id)

          current_balance = gets_account["info"]["balance"]
          available_balance = gets_account["info"]["available_balance"]

          update_balance = %{"available_balance" => available_balance, "current_balance" => current_balance}
          changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
          Repo.update(changeset_companyaccount)
          %{status_code: "200", message: response_message}
        else
          %{
            status_code: "5008",
            errors: %{
              message: response_message
            }
          }
        end
      else
        nil
      end
    else
      cond do
        is_nil(params["id"]) ->
          %{
            status_code: "4003",
            errors: %{
              id: "Can't be blank."
            }
          }
        is_nil(params["reason"]) ->
          %{
            status_code: "4003",
            errors: %{
              reason: "Can't be blank."
            }
          }
        is_nil(params["amount"]) ->
          %{
            status_code: "4003",
            errors: %{
              amount: "Can't be blank."
            }
          }
      end
    end
  end


end