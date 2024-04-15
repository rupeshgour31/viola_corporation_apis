defmodule ViolacorpWeb.Transaction.TransactionController do
  use ViolacorpWeb, :controller
  import Ecto.Query
  alias Violacorp.Repo
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Secure
  alias Violacorp.Libraries.Commontools
  #  alias Violacorp.Libraries.BusinessLimits
  #  alias Violacorp.Libraries.TransactionLimits
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Duefees
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Transactionsreceipt
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Projects
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Expense
  alias Violacorp.Schemas.Feerules
  alias Violacorp.Schemas.CardTransactionsandReceipts

  alias ViolacorpWeb.Employees.EmployeeView

  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  alias Violacorp.Libraries.Secure
  #  alias Violacorp.Workers.GenerateReport

  # Company Account Topup
  def topupWithoutToken(conn, params) do
    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

        account_details = Repo.get(Companyaccounts, params["id"])
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
          json conn, %{status_code: "200", message: response_message}
        else
          json conn, %{status_code: "5008", message: response_message}
        end
      else
        json conn,
             %{
               status_code: "4002",
               message: "You have not permission to any update, Please contact to administrator."
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             message: "No Parameter Found."
           }
    end
  end

  # Company Account Topup
  def manualWithdraw(conn, params) do
    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

        account_details = Repo.get(Companyaccounts, params["id"])
        reason = params["reason"]
        type = Application.get_env(:violacorp, :limited_debit)
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
          json conn, %{status_code: "200", message: response_message}
        else
          json conn, %{status_code: "5008", message: response_message}
        end
      else
        json conn,
             %{
               status_code: "4002",
               message: "You have not permission to any update, Please contact to administrator."
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             message: "No Parameter Found."
           }
    end
  end

  # Company Account Topup
  def topup(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      account_details = Repo.get(Companyaccounts, params["id"])

      type = Application.get_env(:violacorp, :general_credit)
      enter_amount = params["amount"]
      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
      description = params["description"]
      currency = account_details.currency_code
      account_id = account_details.accomplish_account_id
      available_balance = String.to_float("#{account_details.available_balance}")
      balance = available_balance + String.to_float("#{amount}")

      request = %{
        type: type,
        notes: "General Load",
        amount: amount,
        currency: currency,
        account_id: account_id
      }

      today = DateTime.utc_now

      remark = %{"from" => "Viola", "to" => currency}
      # Create First entry in transaction
      transaction = %{
        "commanall_id" => commanid,
        "company_id" => companyid,
        "amount" => amount,
        "fee_amount" => 0.00,
        "final_amount" => amount,
        "cur_code" => currency,
        "balance" => balance,
        "previous_balance" => account_details.available_balance,
        "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
        "transaction_date" => today,
        "transaction_mode" => "C",
        "transaction_type" => "B2A",
        "category" => "TU",
        "description" => description,
        "remark" => Poison.encode!(remark),
        "inserted_by" => commanid
      }

      changeset = Transactions.changesetTopupStepFirst(%Transactions{}, transaction)
      case Repo.insert(changeset) do
        {:ok, data} -> ids = data.id
                       response = Accomplish.load_money(request)
                       response_code = response["result"]["code"]
                       response_message = response["result"]["friendly_message"]
                       transactions_id_api = response["info"]["original_source_id"]
                       if response_code == "0000" do
                         gets_account = Accomplish.get_account(account_id)
                         current_balance = gets_account["info"]["balance"]
                         available_balance = gets_account["info"]["available_balance"]
                         update_balance = %{
                           "available_balance" => available_balance,
                           "current_balance" => current_balance
                         }
                         changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
                         Repo.update(changeset_companyaccount)

                         trans_status = Repo.get(Transactions, ids)
                         update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                         changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                         Repo.update(changeset_transaction)
                         json conn, %{status_code: "200", data: response_message}
                       else
                         json conn, %{status_code: "5008", data: response_message}
                       end
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  # Employee Card Topup
  def employeeTopup(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      today = DateTime.utc_now
      employee_id = params["employeeId"]
      employeecard_id = params["card_id"]
      account_id = params["account_id"]
      enter_amount = params["amount"]
      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
      description = params["description"]
      type = Application.get_env(:violacorp, :transaction_type)

      type_debit = Application.get_env(:violacorp, :topup_debit)
      type_credit = Application.get_env(:violacorp, :topup_credit)

      # GET ACCOUNT ID
      company_info = Repo.get(Company, companyid)
      account_details = Repo.get(Companyaccounts, account_id)
      currency = account_details.currency_code
      account_id = account_details.accomplish_account_id
      acc_available_balance = if is_nil(account_details.available_balance),
                                 do: 0.00, else: String.to_float("#{account_details.available_balance}")
      debit_balance = acc_available_balance - String.to_float("#{amount}")
      from_company = company_info.company_name

      # GET CARD ID
      employee_info = Repo.get(Employee, employee_id)
      card_details = Repo.get(Employeecards, employeecard_id)
      card_id = card_details.accomplish_card_id
      employee_id = card_details.employee_id
      card_available_balance = if is_nil(card_details.available_balance),
                                  do: 0.00, else: String.to_float("#{card_details.available_balance}")
      credit_balance = card_available_balance + String.to_float("#{amount}")
      to_card = card_details.last_digit
      to_employee = "#{employee_info.first_name} #{employee_info.last_name}"

      remark = %{
        "from" => currency,
        "to" => to_card,
        "from_name" => from_company,
        "to_name" => to_employee,
        "from_info" =>
        %{
          "owner_name" => from_company,
          "card_number" => "",
          "sort_code" => "#{account_id}",
          "account_number" => "#{account_details.accomplish_account_number}"
        },
        "to_info" => %{
          "owner_name" => to_employee,
          "card_number" => "#{to_card}",
          "sort_code" => "",
          "account_number" => ""
        }
      }

      # Entry for company transaction
      # Create First entry in transaction
      transaction_company = %{
        "commanall_id" => commanid,
        "company_id" => companyid,
        "employee_id" => employee_id,
        "employeecards_id" => employeecard_id,
        "amount" => amount,
        "fee_amount" => 0.00,
        "final_amount" => amount,
        "cur_code" => currency,
        "balance" => debit_balance,
        "previous_balance" => account_details.available_balance,
        "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
        "transaction_date" => today,
        "transaction_mode" => "D",
        "transaction_type" => "A2C",
        "api_type" => type_debit,
        "category" => "CT",
        "description" => description,
        "remark" => Poison.encode!(remark),
        "inserted_by" => commanid
      }
      changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_company)
      case Repo.insert(changeset) do
        {:ok, data} -> ids = data.id
                       request = %{
                         type: type,
                         amount: amount,
                         currency: currency,
                         account_id: account_id,
                         card_id: card_id,
                         validate: "0"
                       }
                       response = Accomplish.move_funds(request)
                       response_code = response["result"]["code"]
                       response_message = response["result"]["friendly_message"]
                       transactions_id_api = response["info"]["original_source_id"]
                       trans_status = Repo.get(Transactions, ids)
                       if response_code == "0000" do

                         # Update Account Transaction Status
                         update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}

                         changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                         Repo.update(changeset_transaction)

                         # update balance for Account
                         current_balance = response["info"]["balance"]
                         available_balance = response["info"]["available_balance"]
                         update_balance = %{
                           "available_balance" => available_balance,
                           "current_balance" => current_balance
                         }
                         changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
                         Repo.update(changeset_companyaccount)
                         # update balance for Card
                         current_balance_card = response["transfer"]["account_info"]["balance"]
                         available_balance_card = response["transfer"]["account_info"]["available_balance"]
                         update_card_balance = %{
                           "available_balance" => available_balance_card,
                           "current_balance" => current_balance_card
                         }
                         changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                         Repo.update(changeset_employeecard)
                         # Entry for employee transaction
                         get_commanall_id = Repo.one from cmn in Commanall,
                                                     where: cmn.employee_id == ^params["employeeId"],
                                                     left_join: m in assoc(cmn, :contacts),
                                                     on: m.is_primary == "Y",
                                                     left_join: dd in assoc(cmn, :devicedetails),
                                                     on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                     select: %{
                                                       id: cmn.id,
                                                       email_id: cmn.email_id,
                                                       as_login: cmn.as_login,
                                                       code: m.code,
                                                       contact_number: m.contact_number,
                                                       token: dd.token,
                                                       token_type: dd.type
                                                     }
                         transaction_employee = %{
                           "commanall_id" => get_commanall_id.id,
                           "company_id" => companyid,
                           "employee_id" => employee_id,
                           "employeecards_id" => employeecard_id,
                           "amount" => amount,
                           "fee_amount" => 0.00,
                           "final_amount" => amount,
                           "cur_code" => currency,
                           "balance" => credit_balance,
                           "previous_balance" => card_details.available_balance,
                           "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                           "transaction_date" => today,
                           "transaction_mode" => "C",
                           "transaction_type" => "A2C",
                           "api_type" => type_credit,
                           "category" => "CT",
                           "description" => description,
                           "status" => "S",
                           "remark" => Poison.encode!(remark),
                           "inserted_by" => commanid
                         }
                         changeset_card = Transactions.changesetTopupStepThird(%Transactions{}, transaction_employee)
                         Repo.insert(changeset_card)

                         #                         # ALERTS DEPRECATED
                         #                         data = %{
                         #                           :section => "topup",
                         #                           :commanall_id => get_commanall_id.id,
                         #                           :card => card_details.last_digit,
                         #                           :currency => currency,
                         #                           :company_name => company_info.company_name,
                         #                           :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                         #                           :amount => amount
                         #                         }
                         #                         AlertsController.sendEmail(data)
                         #                         AlertsController.sendNotification(data)
                         #                         AlertsController.sendSms(data)
                         #                         AlertsController.storeNotification(data)

                         data = [
                           %{
                             section: "topup",
                             type: "E",
                             email_id: get_commanall_id.email_id,
                             data: %{
                               :card => card_details.last_digit,
                               :currency => currency,
                               :company_name => company_info.company_name,
                               :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                               :amount => amount
                             }
                             # Content
                           },
                           %{
                             section: "topup",
                             type: "S",
                             contact_code: get_commanall_id.code,
                             contact_number: get_commanall_id.contact_number,
                             data: %{
                               :currency => currency,
                               :amount => amount
                             }
                             # Content# Content
                           },
                           %{
                             section: "topup",
                             type: "N",
                             token: get_commanall_id.token,
                             push_type: get_commanall_id.token_type, # "I" or "A"
                             login: get_commanall_id.as_login, # "Y" or "N"
                             data: %{
                               :currency => currency,
                               :amount => amount
                             }
                             # Content
                           }
                         ]
                         V2AlertsController.main(data)

                         json conn, %{status_code: "200", data: response_message}
                       else
                         json conn, %{status_code: "5008", data: response_message}
                       end
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc"employee top up v1"
  def employeeTopupv1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      vpin = params["vpin"]
      auth = Secure.verifyVPin(commanid, vpin)
      case auth do
        "Active" ->
          today = DateTime.utc_now
          employee_id = params["employeeId"]
          employeecard_id = params["card_id"]
          account_id = params["account_id"]
          enter_amount = params["amount"]
          amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
          description = params["description"]
          type = Application.get_env(:violacorp, :transaction_type)

          type_debit = Application.get_env(:violacorp, :topup_debit)
          type_credit = Application.get_env(:violacorp, :topup_credit)

          # GET ACCOUNT ID
          company_info = Repo.get(Company, companyid)
          account_details = Repo.get(Companyaccounts, account_id)
          currency = account_details.currency_code
          account_id = account_details.accomplish_account_id
          acc_available_balance = if is_nil(account_details.available_balance),
                                     do: 0.00, else: String.to_float("#{account_details.available_balance}")
          debit_balance = acc_available_balance - String.to_float("#{amount}")
          from_company = company_info.company_name

          # GET CARD ID
          employee_info = Repo.get(Employee, employee_id)
          card_details = Repo.get(Employeecards, employeecard_id)
          card_id = card_details.accomplish_card_id
          employee_id = card_details.employee_id
          card_available_balance = if is_nil(card_details.available_balance),
                                      do: 0.00, else: String.to_float("#{card_details.available_balance}")
          credit_balance = card_available_balance + String.to_float("#{amount}")
          to_card = card_details.last_digit
          to_employee = "#{employee_info.first_name} #{employee_info.last_name}"

          remark = %{
            "from" => currency,
            "to" => to_card,
            "from_name" => from_company,
            "to_name" => to_employee,
            "from_info" =>
            %{
              "owner_name" => from_company,
              "card_number" => "",
              "sort_code" => "#{account_id}",
              "account_number" => "#{account_details.accomplish_account_number}"
            },
            "to_info" => %{
              "owner_name" => to_employee,
              "card_number" => "#{to_card}",
              "sort_code" => "",
              "account_number" => ""
            }
          }

          # Entry for company transaction
          # Create First entry in transaction
          transaction_company = %{
            "commanall_id" => commanid,
            "company_id" => companyid,
            "employee_id" => employee_id,
            "employeecards_id" => employeecard_id,
            "amount" => amount,
            "fee_amount" => 0.00,
            "final_amount" => amount,
            "cur_code" => currency,
            "balance" => debit_balance,
            "previous_balance" => account_details.available_balance,
            "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
            "transaction_date" => today,
            "transaction_mode" => "D",
            "transaction_type" => "A2C",
            "api_type" => type_debit,
            "category" => "CT",
            "description" => description,
            "remark" => Poison.encode!(remark),
            "inserted_by" => commanid
          }
          changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_company)
          case Repo.insert(changeset) do
            {:ok, data} -> ids = data.id
                           request = %{
                             type: type,
                             amount: amount,
                             currency: currency,
                             account_id: account_id,
                             card_id: card_id,
                             validate: "0"
                           }
                           response = Accomplish.move_funds(request)
                           response_code = response["result"]["code"]
                           response_message = response["result"]["friendly_message"]
                           transactions_id_api = response["info"]["original_source_id"]
                           trans_status = Repo.get(Transactions, ids)
                           if response_code == "0000" do

                             # Update Account Transaction Status
                             update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}

                             changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                             Repo.update(changeset_transaction)

                             # update balance for Account
                             current_balance = response["info"]["balance"]
                             available_balance = response["info"]["available_balance"]
                             update_balance = %{
                               "available_balance" => available_balance,
                               "current_balance" => current_balance
                             }
                             changeset_companyaccount = Companyaccounts.changesetBalance(
                               account_details,
                               update_balance
                             )
                             Repo.update(changeset_companyaccount)
                             # update balance for Card
                             current_balance_card = response["transfer"]["account_info"]["balance"]
                             available_balance_card = response["transfer"]["account_info"]["available_balance"]
                             update_card_balance = %{
                               "available_balance" => available_balance_card,
                               "current_balance" => current_balance_card
                             }
                             changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                             Repo.update(changeset_employeecard)
                             # Entry for employee transaction
                             get_commanall_id = Repo.one from cmn in Commanall,
                                                         where: cmn.employee_id == ^params["employeeId"],
                                                         left_join: m in assoc(cmn, :contacts),
                                                         on: m.is_primary == "Y",
                                                         left_join: dd in assoc(cmn, :devicedetails),
                                                         on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                         select: %{
                                                           id: cmn.id,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                           code: m.code,
                                                           contact_number: m.contact_number,
                                                           token: dd.token,
                                                           token_type: dd.type
                                                         }
                             transaction_employee = %{
                               "commanall_id" => get_commanall_id.id,
                               "company_id" => companyid,
                               "employee_id" => employee_id,
                               "employeecards_id" => employeecard_id,
                               "amount" => amount,
                               "fee_amount" => 0.00,
                               "final_amount" => amount,
                               "cur_code" => currency,
                               "balance" => credit_balance,
                               "previous_balance" => card_details.available_balance,
                               "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                               "transaction_date" => today,
                               "transaction_mode" => "C",
                               "transaction_type" => "A2C",
                               "api_type" => type_credit,
                               "category" => "CT",
                               "description" => description,
                               "status" => "S",
                               "remark" => Poison.encode!(remark),
                               "inserted_by" => commanid
                             }
                             changeset_card = Transactions.changesetTopupStepThird(
                               %Transactions{},
                               transaction_employee
                             )
                             Repo.insert(changeset_card)

                             data = [
                               %{
                                 section: "topup",
                                 type: "E",
                                 email_id: get_commanall_id.email_id,
                                 data: %{
                                   :card => card_details.last_digit,
                                   :currency => currency,
                                   :company_name => company_info.company_name,
                                   :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                                   :amount => amount
                                 }
                                 # Content
                               },
                               %{
                                 section: "topup",
                                 type: "S",
                                 contact_code: get_commanall_id.code,
                                 contact_number: get_commanall_id.contact_number,
                                 data: %{
                                   :currency => currency,
                                   :amount => amount
                                 }
                                 # Content# Content
                               },
                               %{
                                 section: "topup",
                                 type: "N",
                                 token: get_commanall_id.token,
                                 push_type: get_commanall_id.token_type, # "I" or "A"
                                 login: get_commanall_id.as_login, # "Y" or "N"
                                 data: %{
                                   :currency => currency,
                                   :amount => amount
                                 }
                                 # Content
                               }
                             ]
                             V2AlertsController.main(data)

                             json conn, %{status_code: "200", data: response_message}
                           else
                             json conn, %{status_code: "5008", data: response_message}
                           end
          end
        {:error, message} -> json conn, message
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Employee Card Topup"
  def requestTopup(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      request_info = Repo.get!(Requestmoney, params["request_id"])

      description = params["description"]
      status = params["status"]

      if request_info.status == "R" do
        if status == "A" do
          today = DateTime.utc_now
          employee_id = request_info.employee_id
          employeecard_id = request_info.employeecards_id
          account_id = params["account_id"]
          enter_amount = params["amount"]
          amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
          type = Application.get_env(:violacorp, :transaction_type)

          type_debit = Application.get_env(:violacorp, :topup_debit)
          type_credit = Application.get_env(:violacorp, :topup_credit)


          # GET ACCOUNT ID
          company_info = Repo.get(Company, companyid)
          account_details = Repo.get(Companyaccounts, account_id)
          currency = account_details.currency_code
          account_id = account_details.accomplish_account_id
          acc_available_balance = if is_nil(account_details.available_balance),
                                     do: 0.00, else: String.to_float("#{account_details.available_balance}")
          debit_balance = acc_available_balance - String.to_float("#{amount}")
          from_company = company_info.company_name
          # GET CARD ID
          employee_info = Repo.get(Employee, employee_id)
          card_details = Repo.get(Employeecards, employeecard_id)
          card_id = card_details.accomplish_card_id
          employee_id = card_details.employee_id
          card_available_balance = if is_nil(card_details.available_balance),
                                      do: 0.00, else: String.to_float("#{card_details.available_balance}")
          credit_balance = card_available_balance + String.to_float("#{amount}")
          to_card = card_details.last_digit
          to_employee = "#{employee_info.first_name} #{employee_info.last_name}"
          remark = %{
            "from" => currency,
            "to" => to_card,
            "from_name" => from_company,
            "to_name" => to_employee,
            "from_info" =>
            %{
              "owner_name" => from_company,
              "card_number" => "",
              "sort_code" => account_id,
              "account_number" => "#{account_details.accomplish_account_number}"
            },
            "to_info" => %{
              "owner_name" => to_employee,
              "card_number" => "#{to_card}",
              "sort_code" => "",
              "account_number" => ""
            }
          }
          # Entry for company transaction
          # Create First entry in transaction
          transaction_company = %{
            "commanall_id" => commanid,
            "company_id" => companyid,
            "employee_id" => employee_id,
            "employeecards_id" => employeecard_id,
            "amount" => amount,
            "fee_amount" => 0.00,
            "final_amount" => amount,
            "cur_code" => currency,
            "balance" => debit_balance,
            "previous_balance" => account_details.available_balance,
            "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
            "transaction_date" => today,
            "transaction_mode" => "D",
            "transaction_type" => "A2C",
            "api_type" => type_debit,
            "category" => "CT",
            "description" => description,
            "remark" => Poison.encode!(remark),
            "inserted_by" => commanid
          }
          changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_company)
          case Repo.insert(changeset) do
            {:ok, data} -> ids = data.id
                           request = %{
                             type: type,
                             amount: amount,
                             currency: currency,
                             account_id: account_id,
                             card_id: card_id,
                             validate: "0"
                           }
                           response = Accomplish.move_funds(request)
                           response_code = response["result"]["code"]
                           response_message = response["result"]["friendly_message"]
                           transactions_id_api = response["info"]["original_source_id"]
                           if response_code == "0000" do

                             # Update Account Transaction Status
                             trans_status = Repo.get(Transactions, ids)
                             update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                             changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                             Repo.update(changeset_transaction)
                             # update balance for Account
                             current_balance = response["info"]["balance"]
                             available_balance = response["info"]["available_balance"]
                             update_balance = %{
                               "available_balance" => available_balance,
                               "current_balance" => current_balance
                             }
                             changeset_companyaccount = Companyaccounts.changesetBalance(
                               account_details,
                               update_balance
                             )
                             Repo.update(changeset_companyaccount)
                             # update balance for Card
                             current_balance_card = response["transfer"]["account_info"]["balance"]
                             available_balance_card = response["transfer"]["account_info"]["available_balance"]
                             update_card_balance = %{
                               "available_balance" => available_balance_card,
                               "current_balance" => current_balance_card
                             }
                             changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                             Repo.update(changeset_employeecard)
                             # Entry for employee transaction
                             get_commanall_id = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employee_id,
                                                                                left_join: m in assoc(cmn, :contacts),
                                                                                on: m.is_primary == "Y",
                                                                                left_join: dd in assoc(
                                                                                  cmn,
                                                                                  :devicedetails
                                                                                ),
                                                                                on: dd.is_delete == "N" and (
                                                                                  dd.type == "A" or dd.type == "I"),
                                                                                select: %{
                                                                                  id: cmn.id,
                                                                                  email_id: cmn.email_id,
                                                                                  as_login: cmn.as_login,
                                                                                  code: m.code,
                                                                                  contact_number: m.contact_number,
                                                                                  token: dd.token,
                                                                                  token_type: dd.type
                                                                                }
                             com_get_commanall_id = Repo.one from cmnn in Commanall, where: cmnn.id == ^commanid,
                                                                                     left_join: mn in assoc(
                                                                                       cmnn,
                                                                                       :contacts
                                                                                     ),
                                                                                     on: mn.is_primary == "Y",
                                                                                     left_join: ddn in assoc(
                                                                                       cmnn,
                                                                                       :devicedetails
                                                                                     ),
                                                                                     on: ddn.is_delete == "N" and (
                                                                                       ddn.type == "A" or ddn.type == "I"),
                                                                                     select: %{
                                                                                       id: cmnn.id,
                                                                                       email_id: cmnn.email_id,
                                                                                       as_login: cmnn.as_login,
                                                                                       code: mn.code,
                                                                                       contact_number:
                                                                                         mn.contact_number,
                                                                                       token: ddn.token,
                                                                                       token_type: ddn.type
                                                                                     }
                             transaction_employee = %{
                               "commanall_id" => get_commanall_id.id,
                               "company_id" => companyid,
                               "employee_id" => employee_id,
                               "employeecards_id" => employeecard_id,
                               "amount" => amount,
                               "fee_amount" => 0.00,
                               "final_amount" => amount,
                               "cur_code" => currency,
                               "balance" => credit_balance,
                               "previous_balance" => card_details.available_balance,
                               "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                               "transaction_date" => today,
                               "transaction_mode" => "C",
                               "transaction_type" => "A2C",
                               "api_type" => type_credit,
                               "category" => "CT",
                               "description" => description,
                               "status" => "S",
                               "remark" => Poison.encode!(remark),
                               "inserted_by" => commanid
                             }
                             changeset_card = Transactions.changesetTopupStepThird(
                               %Transactions{},
                               transaction_employee
                             )
                             Repo.insert(changeset_card)
                             update_status = %{status: status, company_reason: description}
                             changeset = Requestmoney.updatestatus_changeset(request_info, update_status)
                             Repo.update(changeset)
                             data = [
                               %{
                                 section: "request_money_approved",
                                 type: "E",
                                 email_id: com_get_commanall_id.email_id,
                                 data: %{
                                   :card => card_details.last_digit,
                                   :currency => currency,
                                   :amount => amount,
                                   :company_reason => description,
                                   :company_name => company_info.company_name,
                                   :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
                                 }
                                 # Content
                               },
                               %{
                                 section: "request_money_approved",
                                 type: "S",
                                 contact_code: com_get_commanall_id.code,
                                 contact_number: com_get_commanall_id.contact_number,
                                 data: %{
                                   :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
                                 }
                                 # Content# Content
                               },
                               %{
                                 section: "request_money_approved",
                                 type: "N",
                                 token: com_get_commanall_id.token,
                                 push_type: com_get_commanall_id.token_type, # "I" or "A"
                                 login: com_get_commanall_id.as_login, # "Y" or "N"
                                 data: %{
                                   :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
                                 }
                                 # Content
                               },
                               %{
                                 section: "request_money_success",
                                 type: "E",
                                 email_id: get_commanall_id.email_id,
                                 data: %{
                                   :card => card_details.last_digit,
                                   :currency => currency,
                                   :company_reason => description,
                                   :amount => amount,
                                   :company_name => company_info.company_name,
                                   :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
                                 }
                                 # Content
                               },
                               %{
                                 section: "request_money_success",
                                 type: "S",
                                 contact_code: get_commanall_id.code,
                                 contact_number: get_commanall_id.contact_number,
                                 data: %{}
                                 # Content# Content
                               },
                               %{
                                 section: "request_money_success",
                                 type: "N",
                                 token: get_commanall_id.token,
                                 push_type: get_commanall_id.token_type, # "I" or "A"
                                 login: get_commanall_id.as_login, # "Y" or "N"
                                 data: %{}
                                 # Content
                               }
                             ]
                             V2AlertsController.main(data)

                             json conn, %{status_code: "200", data: response_message}
                           else
                             json conn, %{status_code: "5008", data: response_message}
                           end
          end
        else
          update_status = %{status: status, company_reason: description}
          changeset = Requestmoney.updatestatus_changeset(request_info, update_status)
          Repo.update(changeset)
          employee_request_money = Repo.get!(Requestmoney, params["request_id"])

          com_commanall_id = Repo.one from cmns in Commanall, where: cmns.id == ^commanid,
                                                              left_join: ms in assoc(cmns, :contacts),
                                                              on: ms.is_primary == "Y",
                                                              left_join: ds in assoc(cmns, :devicedetails),
                                                              on: ds.is_delete == "N" and (
                                                                ds.type == "A" or ds.type == "I"),
                                                              select: %{
                                                                id: cmns.id,
                                                                email_id: cmns.email_id,
                                                                as_login: cmns.as_login,
                                                                code: ms.code,
                                                                contact_number: ms.contact_number,
                                                                token: ds.token,
                                                                token_type: ds.type,
                                                              }
          commanall_id = Repo.one from cmn in Commanall, where: cmn.employee_id == ^request_info.employee_id,
                                                         left_join: m in assoc(cmn, :contacts),
                                                         on: m.is_primary == "Y",
                                                         left_join: dd in assoc(cmn, :devicedetails),
                                                         on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                         select: %{
                                                           id: cmn.id,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                           code: m.code,
                                                           contact_number: m.contact_number,
                                                           token: dd.token,
                                                           token_type: dd.type,
                                                         }
          company_info = Repo.get(Company, request_info.company_id)
          employee_info = Repo.get(Employee, request_info.employee_id)
          card_details = Repo.get(Employeecards, employee_request_money.employeecards_id)
          data = [
            %{
              section: "request_money_rejected",
              type: "E",
              email_id: com_commanall_id.email_id,
              data: %{
                :card => card_details.last_digit,
                :currency => request_info.cur_code,
                :amount => request_info.amount,
                :company_reason => description,
                :company_name => company_info.company_name,
                :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
              }
              # Content
            },
            %{
              section: "request_money_rejected",
              type: "S",
              contact_code: com_commanall_id.code,
              contact_number: com_commanall_id.contact_number,
              data: %{
                :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
              }
              # Content# Content
            },
            %{
              section: "request_money_rejected",
              type: "N",
              token: com_commanall_id.token,
              push_type: com_commanall_id.token_type, # "I" or "A"
              login: com_commanall_id.as_login, # "Y" or "N"
              data: %{
                :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
              }
              # Content
            },
            %{
              section: "request_money_failed",
              type: "E",
              email_id: commanall_id.email_id,
              data: %{
                :card => card_details.last_digit,
                :currency => request_info.cur_code,
                :amount => request_info.amount,
                :company_reason => description,
                :company_name => company_info.company_name,
                :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"
              }
              # Content
            },
            %{
              section: "request_money_failed",
              type: "S",
              contact_code: commanall_id.code,
              contact_number: commanall_id.contact_number,
              data: %{}
              # Content# Content
            },
            %{
              section: "request_money_failed",
              type: "N",
              token: commanall_id.token,
              push_type: commanall_id.token_type, # "I" or "A"
              login: commanall_id.as_login, # "Y" or "N"
              data: %{}
              # Content
            }
          ]
          V2AlertsController.main(data)
          json conn, %{status_code: "200", data: "Requested money rejected."}
        end
      else
        if request_info.status == "A" do
          json conn, %{status_code: "4008", data: "Requested money already approved."}
        else
          json conn, %{status_code: "4009", data: "Requested money already rejected."}
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Account Move Fund"
  def companyTopup(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      today = DateTime.utc_now
      employee_id = params["employeeId"]
      employeecard_id = params["card_id"]
      account_id = params["account_id"]
      enter_amount = params["amount"]
      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
      description = params["description"]
      type = Application.get_env(:violacorp, :transaction_type)

      type_debit = Application.get_env(:violacorp, :movefund_debit)
      type_credit = Application.get_env(:violacorp, :movefund_credit)

      # GET ACCOUNT ID
      company_info = Repo.get(Company, companyid)
      account_details = Repo.get(Companyaccounts, account_id)
      currency = account_details.currency_code
      account_id = account_details.accomplish_account_id
      min_amount = "0.00"
      acc_available_balance = if is_nil(account_details.available_balance),
                                 do: String.to_float("#{min_amount}"),
                                 else: String.to_float("#{account_details.available_balance}")
      #      acc_available_balance = String.to_float("#{account_details.available_balance}")
      credit_balance = acc_available_balance + String.to_float("#{amount}")
      to_company = company_info.company_name

      # GET CARD ID
      employee_info = Repo.get(Employee, employee_id)
      card_details = Repo.get(Employeecards, employeecard_id)
      card_id = card_details.accomplish_card_id
      employee_id = card_details.employee_id
      card_available_balance = String.to_float("#{card_details.available_balance}")
      debit_balance = card_available_balance - String.to_float("#{amount}")
      from_card = card_details.last_digit
      from_employee = "#{employee_info.first_name} #{employee_info.last_name}"

      remark = %{
        "from" => from_card,
        "to" => currency,
        "from_name" => from_employee,
        "to_name" => to_company,
        "from_info" =>
        %{
          "owner_name" => from_employee,
          "card_number" => "#{from_card}",
          "sort_code" => "",
          "account_number" => ""
        },
        "to_info" => %{
          "owner_name" => to_company,
          "card_number" => "",
          "sort_code" => "#{account_id}",
          "account_number" => "#{account_details.accomplish_account_number}"
        }
      }


      #        "to_info" =>
      #      %{"owner_name" => from_company, "card_number" => "", "sort_code" => "#{account_id}", "account_number" => "#{account_details.accomplish_account_number}"},
      #        "from_info" => %{"owner_name" => to_employee, "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""}}

      # Get Employee Comman id
      get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^params["employeeId"], select: a.id

      # Entry for employee transaction
      # Create First entry in transaction
      transaction_employee = %{
        "commanall_id" => get_commanall_id,
        "company_id" => companyid,
        "employee_id" => employee_id,
        "employeecards_id" => employeecard_id,
        "amount" => amount,
        "fee_amount" => 0.00,
        "final_amount" => amount,
        "cur_code" => currency,
        "balance" => debit_balance,
        "previous_balance" => card_details.available_balance,
        "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
        "transaction_date" => today,
        "transaction_mode" => "D",
        "transaction_type" => "C2A",
        "api_type" => type_debit,
        "category" => "MV",
        "description" => description,
        "remark" => Poison.encode!(remark),
        "inserted_by" => commanid
      }
      changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_employee)
      case Repo.insert(changeset) do
        {:ok, data} -> ids = data.id
                       request = %{
                         type: type,
                         amount: amount,
                         currency: currency,
                         account_id: card_id,
                         card_id: account_id,
                         validate: "0"
                       }
                       response = Accomplish.move_funds(request)
                       response_code = response["result"]["code"]
                       response_message = response["result"]["friendly_message"]
                       transactions_id_api = response["info"]["original_source_id"]

                       if response_code == "0000" do

                         # Update Account Transaction Status
                         trans_status = Repo.get(Transactions, ids)
                         update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                         changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                         Repo.update(changeset_transaction)


                         # update balance for Account
                         gets_account = Accomplish.get_account(account_id)
                         current_balance = gets_account["info"]["balance"]
                         available_balance = gets_account["info"]["available_balance"]
                         update_balance = %{
                           "available_balance" => available_balance,
                           "current_balance" => current_balance
                         }
                         changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
                         Repo.update(changeset_companyaccount)

                         # update balance for Card
                         get_card = Accomplish.get_account(card_id)
                         current_balance_card = get_card["info"]["balance"]
                         available_balance_card = get_card["info"]["available_balance"]
                         update_card_balance = %{
                           "available_balance" => available_balance_card,
                           "current_balance" => current_balance_card
                         }
                         changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                         Repo.update(changeset_employeecard)

                         transaction_employee = %{
                           "commanall_id" => commanid,
                           "company_id" => companyid,
                           "employee_id" => employee_id,
                           "employeecards_id" => employeecard_id,
                           "amount" => amount,
                           "fee_amount" => 0.00,
                           "final_amount" => amount,
                           "cur_code" => currency,
                           "balance" => credit_balance,
                           "previous_balance" => account_details.available_balance,
                           "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                           "transaction_date" => today,
                           "transaction_mode" => "C",
                           "transaction_type" => "C2A",
                           "api_type" => type_credit,
                           "category" => "MV",
                           "description" => description,
                           "status" => "S",
                           "remark" => Poison.encode!(remark),
                           "inserted_by" => commanid
                         }

                         changeset_card = Transactions.changesetTopupStepThird(%Transactions{}, transaction_employee)
                         Repo.insert(changeset_card)
                         json conn, %{status_code: "200", data: response_message}

                       else
                         json conn, %{status_code: "5008", data: response_message}
                       end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc"company employee move fund"
  def companyTopupv1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]


      vpin = params["vpin"]
      auth = Secure.verifyVPin(commanid, vpin)
      case auth do
        "Active" ->
          today = DateTime.utc_now
          employee_id = params["employeeId"]
          employeecard_id = params["card_id"]
          account_id = params["account_id"]
          enter_amount = params["amount"]
          amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
          description = params["description"]
          type = Application.get_env(:violacorp, :transaction_type)

          type_debit = Application.get_env(:violacorp, :movefund_debit)
          type_credit = Application.get_env(:violacorp, :movefund_credit)

          # GET ACCOUNT ID
          company_info = Repo.get(Company, companyid)
          account_details = Repo.get(Companyaccounts, account_id)
          currency = account_details.currency_code
          account_id = account_details.accomplish_account_id
          min_amount = "0.00"
          acc_available_balance = if is_nil(account_details.available_balance),
                                     do: String.to_float("#{min_amount}"),
                                     else: String.to_float("#{account_details.available_balance}")
          #      acc_available_balance = String.to_float("#{account_details.available_balance}")
          credit_balance = acc_available_balance + String.to_float("#{amount}")
          to_company = company_info.company_name

          # GET CARD ID
          employee_info = Repo.get(Employee, employee_id)
          card_details = Repo.get(Employeecards, employeecard_id)
          card_id = card_details.accomplish_card_id
          employee_id = card_details.employee_id
          card_available_balance = String.to_float("#{card_details.available_balance}")
          debit_balance = card_available_balance - String.to_float("#{amount}")
          from_card = card_details.last_digit
          from_employee = "#{employee_info.first_name} #{employee_info.last_name}"

          remark = %{
            "from" => from_card,
            "to" => currency,
            "from_name" => from_employee,
            "to_name" => to_company,
            "from_info" =>
            %{
              "owner_name" => from_employee,
              "card_number" => "#{from_card}",
              "sort_code" => "",
              "account_number" => ""
            },
            "to_info" => %{
              "owner_name" => to_company,
              "card_number" => "",
              "sort_code" => "#{account_id}",
              "account_number" => "#{account_details.accomplish_account_number}"
            }
          }


          #        "to_info" =>
          #      %{"owner_name" => from_company, "card_number" => "", "sort_code" => "#{account_id}", "account_number" => "#{account_details.accomplish_account_number}"},
          #        "from_info" => %{"owner_name" => to_employee, "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""}}

          # Get Employee Comman id
          get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^params["employeeId"], select: a.id

          # Entry for employee transaction
          # Create First entry in transaction
          transaction_employee = %{
            "commanall_id" => get_commanall_id,
            "company_id" => companyid,
            "employee_id" => employee_id,
            "employeecards_id" => employeecard_id,
            "amount" => amount,
            "fee_amount" => 0.00,
            "final_amount" => amount,
            "cur_code" => currency,
            "balance" => debit_balance,
            "previous_balance" => card_details.available_balance,
            "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
            "transaction_date" => today,
            "transaction_mode" => "D",
            "transaction_type" => "C2A",
            "api_type" => type_debit,
            "category" => "MV",
            "description" => description,
            "remark" => Poison.encode!(remark),
            "inserted_by" => commanid
          }
          changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_employee)
          case Repo.insert(changeset) do
            {:ok, data} -> ids = data.id
                           request = %{
                             type: type,
                             amount: amount,
                             currency: currency,
                             account_id: card_id,
                             card_id: account_id,
                             validate: "0"
                           }
                           response = Accomplish.move_funds(request)
                           response_code = response["result"]["code"]
                           response_message = response["result"]["friendly_message"]
                           transactions_id_api = response["info"]["original_source_id"]

                           if response_code == "0000" do

                             # Update Account Transaction Status
                             trans_status = Repo.get(Transactions, ids)
                             update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                             changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                             Repo.update(changeset_transaction)


                             # update balance for Account
                             gets_account = Accomplish.get_account(account_id)
                             current_balance = gets_account["info"]["balance"]
                             available_balance = gets_account["info"]["available_balance"]
                             update_balance = %{
                               "available_balance" => available_balance,
                               "current_balance" => current_balance
                             }
                             changeset_companyaccount = Companyaccounts.changesetBalance(
                               account_details,
                               update_balance
                             )
                             Repo.update(changeset_companyaccount)

                             # update balance for Card
                             get_card = Accomplish.get_account(card_id)
                             current_balance_card = get_card["info"]["balance"]
                             available_balance_card = get_card["info"]["available_balance"]
                             update_card_balance = %{
                               "available_balance" => available_balance_card,
                               "current_balance" => current_balance_card
                             }
                             changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                             Repo.update(changeset_employeecard)

                             transaction_employee = %{
                               "commanall_id" => commanid,
                               "company_id" => companyid,
                               "employee_id" => employee_id,
                               "employeecards_id" => employeecard_id,
                               "amount" => amount,
                               "fee_amount" => 0.00,
                               "final_amount" => amount,
                               "cur_code" => currency,
                               "balance" => credit_balance,
                               "previous_balance" => account_details.available_balance,
                               "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                               "transaction_date" => today,
                               "transaction_mode" => "C",
                               "transaction_type" => "C2A",
                               "api_type" => type_credit,
                               "category" => "MV",
                               "description" => description,
                               "status" => "S",
                               "remark" => Poison.encode!(remark),
                               "inserted_by" => commanid
                             }

                             changeset_card = Transactions.changesetTopupStepThird(
                               %Transactions{},
                               transaction_employee
                             )
                             Repo.insert(changeset_card)
                             json conn, %{status_code: "200", data: response_message}
                           else
                             json conn, %{status_code: "5008", data: response_message}
                           end
          end
        {:error, message} -> json conn, message
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Add Transaction Receipt"
  def addReceipt(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      transaction_id = params["transactions_id"]
      transaction = Repo.one(
        from t in Transactions,
        where: t.commanall_id == ^commanid and t.id == ^transaction_id and (
          t.transaction_type == "C2O" or t.transaction_type == "C2I"),
        select: t.employeecards_id
      )
      if is_nil(transaction) do
        json conn, %{status_code: "4003", message: "Transaction not found"}
      else
        file_extension = params["file_extension"]
        file_location_address = if params["content"] != "" do
          image_receipt = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
          if file_extension == "pdf" do
            ViolacorpWeb.Main.Assetstore.upload_document(image_receipt)
          else
            ViolacorpWeb.Main.Assetstore.upload_image(image_receipt)
          end
        else
          nil
        end
        transactionsreceipt = %{
          "transactions_id" => params["transactions_id"],
          #        "content" => String.replace_leading(params["content"], "data:image/jpeg;base64,", ""),
          "receipt_url" => file_location_address,
          "inserted_by" => commanid
        }
        changeset = Transactionsreceipt.changeset(%Transactionsreceipt{}, transactionsreceipt)

        case Repo.insert(changeset) do
          {:ok, data} -> receipt_id = data.id

                         countreceipt = Repo.one(
                           from tr in Transactionsreceipt, where: tr.transactions_id == ^transaction_id,
                                                           select: count(tr.id)
                         )

                         if countreceipt == 1 do
                           cardTransactions = Repo.get_by(CardTransactionsandReceipts, employeecards_id: transaction)
                           if cardTransactions != nil do
                             last_count = cardTransactions.total_receipt_pending - 1
                             update_pending_receipt = %{"total_receipt_pending" => last_count}
                             changeset_card_transaction = CardTransactionsandReceipts.changesetUpdatePending(
                               cardTransactions,
                               update_pending_receipt
                             )
                             Repo.update(changeset_card_transaction)
                           end
                         end

                         json conn,
                              %{
                                status_code: "200",
                                message: "Transaction Receipt Added.",
                                trans_receipt_id: receipt_id,
                                receipt_url: file_location_address
                              }
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Assign Project for selected transaction"
  def assignProject(conn, params) do
    unless map_size(params) == 0 do
      #    %{"commanall_id" => commanid , "id" => employee_id} = conn.assigns[:current_user]

      transaction = Repo.get!(Transactions, params["transactions_id"])

      assign_project = %{"projects_id" => params["project_id"]}
      changeset = Transactions.changesetAssignProject(transaction, assign_project)
      case Repo.update(changeset) do
        {:ok, _currency} -> json conn, %{status_code: "200", message: "Transaction assigned to project"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Assign category for selected transaction"
  def assignCategory(conn, params) do
    unless map_size(params) == 0 do
      #      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      transaction = Repo.get_by(Transactions, id: params["transactions_id"])

      if is_nil(transaction) do
        json conn, %{status_code: "4003", message: "Transaction not found"}
      else
        assign_category = %{"category_id" => params["category_id"]}
        changeset = Transactions.changesetAssignCategory(transaction, assign_category)
        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, _category} -> json conn, %{status_code: "200", message: "Transaction assigned to Category"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Assign category info for selected transaction"
  def assignCategoryInfo(conn, params) do
    unless map_size(params) == 0 do
      #      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      transaction = Repo.get_by(Transactions, id: params["transactions_id"])

      if is_nil(transaction) do
        json conn, %{status_code: "4003", message: "Transaction not found"}
      else
        assign_category = %{"category_info" => params["category_info"]}
        changeset = Transactions.changesetCategoryInfo(transaction, assign_category)
        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, _category} -> json conn, %{status_code: "200", message: "Success! Category Info Add in Transaction"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "lost Receipt for selected transaction"
  def lostReceipt(conn, params) do
    unless map_size(params) == 0 do
      #      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      transaction = Repo.get_by(Transactions, id: params["transactions_id"])

      if is_nil(transaction) do
        json conn, %{status_code: "4003", message: "Transaction not found"}
      else
        assign_category = %{"lost_receipt" => params["lost_receipt"]}
        changeset = Transactions.changesetLostReceipt(transaction, assign_category)
        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, _category} -> json conn, %{status_code: "200", message: "Success! Lost Receipt Add in Transaction"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Assign Entertainment for selected transaction"
  def assignEntertain(conn, params) do
    unless map_size(params) == 0 do
      #      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      transaction = Repo.get_by(Transactions, id: params["transactions_id"])

      if is_nil(transaction) do
        json conn, %{status_code: "4003", message: "Transaction not found"}
      else
        assign_category = %{"entertain_id" => params["entertain_id"]}
        changeset = Transactions.changesetAssignEntertain(transaction, assign_category)
        if changeset.valid? do
          case Repo.update(changeset) do
            {:ok, _category} -> json conn, %{status_code: "200", message: "Transaction assigned to Entertain"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Request Money"
  def requestMoney(conn, params) do

    %{"id" => employee_id} = conn.assigns[:current_user]

    employeecard_id = params["card_id"]
    enter_amount = params["amount"]
    amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
    reason = params["reason"]

    get_company = Repo.get(Employee, employee_id)

    card_details = Repo.get_by(Employeecards, id: employeecard_id, employee_id: employee_id)

    if is_nil(card_details) do
      json conn,
           %{
             status_code: "4005",
             errors: %{
               message: "selected card is unavailable"
             }
           }
    else
      currency = card_details.currency_code
      requestmoney = %{
        "company_id" => get_company.company_id,
        "employee_id" => employee_id,
        "employeecards_id" => employeecard_id,
        "cur_code" => currency,
        "reason" => reason,
        "amount" => amount
      }
      changeset = Requestmoney.changeset(%Requestmoney{}, requestmoney)
      case Repo.insert(changeset) do
        {:ok, _currency} ->
          company = Repo.one from cmn in Commanall, where: cmn.company_id == ^get_company.company_id,
                                                    left_join: m in assoc(cmn, :contacts),
                                                    on: m.is_primary == "Y",
                                                    left_join: d in assoc(cmn, :devicedetails),
                                                    on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                    select: %{
                                                      id: cmn.id,
                                                      email_id: cmn.email_id,
                                                      as_login: cmn.as_login,
                                                      code: m.code,
                                                      contact_number: m.contact_number,
                                                      token: d.token,
                                                      token_type: d.type
                                                    }
          company_name = Repo.one from e in Company, where: e.id == ^get_company.company_id, select: e.company_name
          # ALERTS

          data = [
            %{
              section: "request_money",
              type: "E",
              email_id: company.email_id,
              data: %{
                :currency => card_details.currency_code,
                :card => card_details.last_digit,
                :amount => amount,
                :company_name => company_name,
                :employee_name => "#{get_company.first_name} #{get_company.last_name}"
              }
              # Content
            },
            %{
              section: "request_money",
              type: "S",
              contact_code: company.code,
              contact_number: company.contact_number,
              data: %{
                employee_name: "#{get_company.first_name} #{get_company.last_name}"
              }
              # Content# Content
            },
            %{
              section: "request_money",
              type: "N",
              token: company.token,
              push_type: company.token_type, # "I" or "A"
              login: company.as_login, # "Y" or "N"
              data: %{
                employee_name: "#{get_company.first_name} #{get_company.last_name}"
              }
            }
          ]
          V2AlertsController.main(data)

          json conn, %{status_code: "200", message: "Money Requested."}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  def transactionToProject(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => compid} = conn.assigns[:current_user]

      get_projects = Repo.one from e in Projects, where: e.company_id == ^compid and e.id == ^params["project_id"],
                                                  select: count(e.id)

      get_transaction = Repo.get_by(Transactions, id: params["transaction_id"])

      if get_projects == 1 do
        to_project = %{projects_id: params["project_id"]}
        new_changeset = Transactions.changesetAssignProject(get_transaction, to_project)

        case Repo.update(new_changeset)  do
          {:ok, _response} ->
            render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Transaction assigned to project")
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4003", message: "Project not found"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Account Topup"
  def manual_load(conn, _params) do
    %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
    commanall_data = Repo.get_by!(Commanall, id: commanid)

    last_transaction = Repo.one(
      from t in Transactions,
      where: t.commanall_id == ^commanid and t.transaction_type == ^"B2A" and not is_nil(t.server_date),
      order_by: [
        desc: t.id
      ],
      limit: 1,
      select: %{
        transactions_id_api: t.transactions_id_api,
        transaction_date: t.transaction_date,
        server_date: t.server_date,
        id: t.id
      }
    )

    last_date = if last_transaction !== nil do
      last_transaction.transaction_date
    else
      commanall_data.inserted_at
    end

    today = DateTime.utc_now
    to_date = [today.year, today.month, today.day]
              |> Enum.map(&to_string/1)
              |> Enum.map(&String.pad_leading(&1, 2, "0"))
              |> Enum.join("-")

    from_date = [last_date.year, last_date.month, last_date.day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")


    account_data = Repo.get_by!(Companyaccounts, company_id: companyid)


    user_id = commanall_data.accomplish_userid
    account_id = account_data.accomplish_account_id
    #    status = 1
    #    start_index = 0
    #    page_size = 40
    start_index = "0"
    page_size = "50"

    request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&start_index=#{
      start_index
    }&page_size=#{page_size}"

    response = Accomplish.get_success_transaction(request)

    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do

      Enum.each response["transactions"], fn post ->
        transaction_id = Integer.to_string(post["info"]["id"])
        type = post["info"]["type"]

        transaction_data = Repo.get_by(Transactions, transactions_id_api: transaction_id)

        if transaction_data == nil && type === 84 do
          notes = post["info"]["notes"]
          account_id = account_data.accomplish_account_id
          server_date = post["info"]["server_date"]
          amount = post["info"]["amount"]
          currency = post["info"]["currency"]

          balance = String.to_float("#{account_data.available_balance}") + String.to_float(amount)

          remark = %{"from" => "Bank", "to" => currency}

          # Create First entry in transaction
          transaction = %{
            "commanall_id" => commanid,
            "company_id" => companyid,
            "amount" => amount,
            "fee_amount" => 0.00,
            "final_amount" => amount,
            "cur_code" => currency,
            "balance" => balance,
            "previous_balance" => account_data.available_balance,
            "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
            "transactions_id_api" => transaction_id,
            "server_date" => server_date,
            "transaction_date" => server_date,
            "transaction_mode" => "C",
            "transaction_type" => "B2A",
            "category" => "TU",
            "status" => "S",
            "description" => notes,
            "remark" => Poison.encode!(remark),
            "inserted_by" => commanid
          }

          changeset_transaction = Transactions.changeset(%Transactions{}, transaction)
          Repo.insert(changeset_transaction)

          # update balance for Account
          gets_account = Accomplish.get_account(account_id)
          current_balance = gets_account["info"]["balance"]
          available_balance = gets_account["info"]["available_balance"]
          update_balance = %{
            "available_balance" => available_balance,
            "current_balance" => current_balance
          }
          account_details = Repo.get(Companyaccounts, account_data.id)
          changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
          Repo.update(changeset_companyaccount)
        end
      end
      json conn, %{status_code: "200", data: "Transaction history list uploaded."}
    else
      json conn, %{status_code: "504", data: response_message}
    end
  end

  # view fee reciept for transaction
  def viewReceipt(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]
    get_transactions = Repo.one from t in Transactions,
                                where: t.company_id == ^compid and t.id == ^params["transactionId"],
                                select: %{
                                  id: t.id,
                                  amount: t.amount,
                                  fee_amount: t.fee_amount,
                                  final_amount: t.final_amount,
                                  remark: t.remark,
                                  transaction_date: t.transaction_date,
                                  transaction_id: t.transaction_id,
                                  category: t.category,
                                  cur_code: t.cur_code,
                                  description: t.description,
                                  notes: t.notes,
                                  status: t.status
                                }
    if is_nil(get_transactions) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Transaction Record Not Found!"
             }
           }
    else
      get_fee = Repo.one from f in Duefees,
                         where: f.commanall_id == ^commanid and f.transactions_id == ^get_transactions.id,
                         select: %{
                           d_remark: f.remark,
                           d_totalcards: f.total_cards,
                           d_pay_date: f.pay_date
                         }
      company_info = Repo.one from c in Company, where: c.id == ^compid,
                                                 select: %{
                                                   name: c.company_name,
                                                   type: c.company_type
                                                 }
      chk_address = Repo.one from a in Address, where: a.commanall_id == ^commanid and a.is_primary == ^"Y",
                                                select: %{
                                                  address_line_one: a.address_line_one,
                                                  address_line_two: a.address_line_two,
                                                  address_line_three: a.address_line_three,
                                                  town: a.town,
                                                  county: a.county,
                                                  post_code: a.post_code
                                                }

      # extra_cards_amount = Decimal.sub(get_transactions.final_amount, get_monthly.monthly_fee)
      # extra_cards = Decimal.div(extra_cards_amount, get_monthly.per_card_fee)

      response = if is_nil(get_fee) do
        _response = if get_transactions.description == "On Boarding Fee" do
          %{
            company_name: company_info.name,
            company_type: company_info.type,
            address: chk_address,
            fee_structure: nil,
            transaction: get_transactions
          }
        else
          get_monthly_report = Repo.one from f in Feerules, where: f.type == ^"M" and f.status == ^"A",
                                                            select: %{
                                                              monthly_fee: f.monthly_fee,
                                                              per_card_fee: f.per_card_fee,
                                                              minimum_card: f.minimum_card,
                                                              vat: f.vat
                                                            }
          get_monthly = %{
            per_card_fee: get_monthly_report.per_card_fee,
            monthly_fee: get_monthly_report.monthly_fee,
            minimum_card: get_monthly_report.minimum_card,
            description: "Monthly Minimum Card Fee",
            extra_card_fee: nil,
            extra_quantity: nil,
            extra_total_amount: nil
          }
          %{
            company_name: company_info.name,
            company_type: company_info.type,
            address: chk_address,
            fee_structure: get_monthly,
            transaction: get_transactions
          }
        end

      else
        from_date = if is_nil(get_fee.d_pay_date) do
          ""
        else
          NaiveDateTime.to_date(get_fee.d_pay_date)
          |> Date.add(-30)
        end
        to_date = NaiveDateTime.to_date(get_fee.d_pay_date)

        period = "#{from_date} - #{to_date}"
        card_limit = Poison.decode!(get_fee.d_remark)
                     |> Enum.at(0)
        card_limit1 = card_limit["quantity"]
        extra_card = if get_fee.d_totalcards > card_limit1 do
          get_fee.d_totalcards - card_limit1
        else
          0
        end
        get_monthly = %{
          vat: card_limit["tax"],
          per_card_fee: card_limit["unit_price"],
          monthly_fee: card_limit["total_unit"],
          minimum_card: card_limit["quantity"],

          description: "Monthly Minimum Card Fee #{period}",
          extra_card_fee: if extra_card > 0 do
            extra = Poison.decode!(get_fee.d_remark)
                    |> Enum.at(1)
            extra["unit_price"]
          else
            nil
          end,
          extra_quantity: if extra_card > 0 do
            extra = Poison.decode!(get_fee.d_remark)
                    |> Enum.at(1)
            extra["quantity"]
          else
            nil
          end,
          extra_total_amount: if extra_card > 0 do
            extra = Poison.decode!(get_fee.d_remark)
                    |> Enum.at(1)
            extra["total_unit"]
          else
            nil
          end
        }

        new_fields = %{extra_cards_description: "Additional Card(s) Charges"}
        new_get_monthly = Map.merge(get_monthly, new_fields)

        %{
          company_name: company_info.name,
          company_type: company_info.type,
          address: chk_address,
          fee_structure: new_get_monthly,
          transaction: get_transactions
        }
      end



      json conn, %{status_code: "200", data: response}
    end


  end


  # get all receipt for transaction
  def update_receipt(conn, _params) do

    #  and not is_nil(t.content)
    get_receipt = Repo.all from t in Transactionsreceipt, where: is_nil(t.receipt_url),
                                                          select: %{
                                                            id: t.id,
                                                            content: t.content
                                                          }

    if !is_nil(get_receipt) do
      Enum.each get_receipt, fn post ->
        file_location_address = if !is_nil(post.content) do
          image_receipt = String.replace_leading(post.content, "data:image/jpeg;base64,", "")
          ViolacorpWeb.Main.Assetstore.upload_image(image_receipt)
        else
          nil
        end

        update_receipt = %{
          "receipt_url" => file_location_address
        }
        receipt_details = Repo.get(Transactionsreceipt, post.id)
        changeset_update_receipt = Transactionsreceipt.changesetUpdate(receipt_details, update_receipt)
        Repo.update(changeset_update_receipt)
      end

      text conn, "Update All Reciepts."
    end
  end

  # List of POS transaction
  def posTransactions(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]

    employeelist =
      (from a in Employee,
            where: a.company_id == ^compid and a.status == "A",
            left_join: employeecard in assoc(a, :employeecards),
            where: employeecard.status != "5",
            left_join: cr in assoc(employeecard, :cardtransactionsandreceipts),
            select: %{
              employee_id: a.id,
              first_name: a.first_name,
              last_name: a.last_name,
              card_id: employeecard.id,
              last_digit: employeecard.last_digit,
              status: employeecard.status,
              cur_code: employeecard.currency_code,
              total_amount: cr.total_amount,
              total_transaction: cr.total_transactions,
              pending_receipt: cr.total_receipt_pending
            })
      |> Repo.paginate(params)

    total_count = Enum.count(employeelist)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: employeelist.entries,
           page_number: employeelist.page_number,
           total_pages: employeelist.total_pages
         }
  end


  # Last five transaction for card
  def lastFive(conn, params) do

    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

      card_id = params["card_id"]

      # check this card is blongs to login company
      request = %{"commanall_id" => commanid, "company_id" => compid, "card_id" => card_id}
      response = Secure.secure_card(request)

      if response == "200" do
        # get employee id and comman all id
        get_employee = Repo.one from e in Employeecards, where: e.id == ^card_id, select: e.employee_id
        get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^get_employee, select: a.id

        transactions = Repo.all(
                         from t in Transactions,
                         where: t.commanall_id == ^get_commanall_id and t.employee_id == ^get_employee and t.employeecards_id == ^card_id,
                         order_by: [
                           desc: t.transaction_date
                         ],
                         limit: 5
                       )
                       |> Repo.preload(:transactionsreceipt)

        render(conn, EmployeeView, "manytrans.json", transactions: transactions)

      else
        json conn,
             %{
               status_code: "404",
               error: %{
                 message: "Card not found!"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end

  end

  # Last five transaction for card
  def lastFiveForEmp(conn, params) do

    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "cid" => compid} = conn.assigns[:current_user]

      card_id = params["card_id"]

      # check this card is blongs to login company
      request = %{"commanall_id" => commanid, "company_id" => compid, "card_id" => card_id}
      response = Secure.secure_card(request)

      if response == "200" do
        # get employee id and comman all id
        get_employee = Repo.one from e in Employeecards, where: e.id == ^card_id, select: e.employee_id
        get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^get_employee, select: a.id

        transactions = Repo.all(
                         from t in Transactions,
                         where: t.commanall_id == ^get_commanall_id and t.employee_id == ^get_employee and t.employeecards_id == ^card_id and (
                           t.transaction_type != "B2A" or t.transaction_type != "A20") and (
                                  (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                                    t.transaction_type == "C2A" and t.transaction_mode == "D") or (
                                    t.transaction_type == "C2O")),
                         order_by: [
                           desc: t.transaction_date
                         ],
                         limit: 5
                       )
                       |> Repo.preload(:transactionsreceipt)

        render(conn, EmployeeView, "manytrans.json", transactions: transactions)

      else
        json conn,
             %{
               status_code: "404",
               error: %{
                 message: "Card not found!"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  # Generate Monthly Transaction
  def generateMonthlySeat(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    employee_id = params["employee_id"]
    year = params["year"]
    month = params["month"]
    day = Date.from_iso8601!("#{year}-#{month}-01")
          |> Date.days_in_month()

    # generate date for start and end of month
    last_date = [year, month, day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")
    start_date = [year, month, 01]
                 |> Enum.map(&to_string/1)
                 |> Enum.map(&String.pad_leading(&1, 2, "0"))
                 |> Enum.join("-")

    # Check employee id
    if employee_id == "" or employee_id == "0" do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               card_id: "Employee id is wrong."
             }
           }
    else

      employee_card_list = Repo.all(
        from a in Employee, where: a.id == ^employee_id and a.company_id == ^compid and a.status == "A",
                            left_join: employeecard in assoc(a, :employeecards),
                            select: %{
                              employee_id: a.id,
                              card_id: employeecard.id,
                              last_digit: employeecard.last_digit
                            }
      )
      Enum.each employee_card_list, fn v ->

        card_id = v.card_id
        check_data = if is_nil(employee_id) or is_nil(card_id) do
          1
        else
          Repo.one from e in Expense,
                   where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == ^card_id and e.generate_date == ^start_date,
                   select: count(e.id)
        end

        if check_data == 0 do
          # call generate repport worker
          load_params = %{
            "worker_type" => "generate_report",
            "commanid" => commanid,
            "companyid" => compid,
            "employee_id" => employee_id,
            "card_id" => v.card_id,
            "last_digit" => v.last_digit,
            "start_date" => start_date,
            "last_date" => last_date
          }
          Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
        end
      end
      json conn, %{status_code: "200", message: "Expense sheet generate successfully."}


    end
  end


  # Generate csv for employee card
  def generateCardMonthlySeat(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    card_id = params["card_id"]
    year = params["year"]
    month = params["month"]
    day = Date.from_iso8601!("#{year}-#{month}-01")
          |> Date.days_in_month()

    # generate date for start and end of month
    last_date = [year, month, day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")
    start_date = [year, month, 01]
                 |> Enum.map(&to_string/1)
                 |> Enum.map(&String.pad_leading(&1, 2, "0"))
                 |> Enum.join("-")

    # Check Card id
    if card_id == "" or card_id == "0" do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               card_id: "Card id is wrong."
             }
           }
    else

      # Get card details
      employee = Repo.get_by(Employeecards, id: card_id)
      employee_id = employee.employee_id
      last_digit = employee.last_digit

      check_data = Repo.one from e in Expense,
                            where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == ^card_id and e.generate_date == ^start_date,
                            select: count(e.id)
      if check_data > 0 do
        json conn, %{status_code: "4004", errors: "Record already exist."}
      else
        # call generate repport worker
        load_params = %{
          "worker_type" => "generate_report",
          "commanid" => commanid,
          "companyid" => compid,
          "employee_id" => employee_id,
          "card_id" => card_id,
          "last_digit" => last_digit,
          "start_date" => start_date,
          "last_date" => last_date
        }
        Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
        json conn, %{status_code: "200", message: "Expense sheet generate successfully."}
      end
    end
  end


  def getTransactionUrl(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    card_id = params["card_id"]
    employee_id = params["employee_id"]
    year = params["year"]
    month = params["month"]
    generate_date = "#{year}-#{month}-01"

    # Get transaction Record Url
    query = if employee_id == "0" and card_id == "0" do
      # company Transaction
      from e in Expense,
           where: e.commanall_id == ^commanid and e.employee_id == is_nil(^employee_id) and
                  e.employeecards_id == is_nil(^card_id) and e.generate_date == ^generate_date,
           select: %{
             url: e.aws_url
           }
    else
      if card_id == "0" do
        # Employe Card Transaction
        from e in Expense,
             where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == is_nil(
               ^card_id
             ) and e.generate_date == ^generate_date,
             select: %{
               url: e.aws_url
             }
      else
        # Employe Single Card Transaction
        from e in Expense,
             where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == ^card_id and e.generate_date == ^generate_date,
             select: %{
               url: e.aws_url
             }
      end
    end
    getTransactionurl = Repo.one(query)

    if is_nil(getTransactionurl)do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Record Does Not Exist."
             }
           }
    else
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: getTransactionurl)
    end
  end

  def getExpensesList(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    card_id = params["card_id"]
    employee_id = params["employee_id"]

    # Get transaction Record Url
    query = if employee_id == "0" and card_id == "0" do
      # company Transaction
      from e in Expense,
           where: e.commanall_id == ^commanid and e.employee_id == is_nil(^employee_id)
           and e.employeecards_id == is_nil(^card_id),
           select: %{
             url: e.aws_url,
             generate_date: e.generate_date
           }
    else
      if card_id == "0" do
        # Employe Card Transaction
        from e in Expense,
             where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == is_nil(
               ^card_id
             ),
             select: %{
               url: e.aws_url,
               generate_date: e.generate_date
             }
      else
        # Employe Single Card Transaction
        from e in Expense,
             where: e.commanall_id == ^commanid and e.employee_id == ^employee_id and e.employeecards_id == ^card_id,
             select: %{
               url: e.aws_url,
               generate_date: e.generate_date
             }
      end
    end

    getexpenseslist = Repo.paginate(query)

    if is_nil(getexpenseslist)do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Record Does Not Exist."
             }
           }
    else
      total_count = Enum.count(getexpenseslist)

      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: getexpenseslist.entries,
             page_number: getexpenseslist.page_number,
             total_pages: getexpenseslist.total_pages
           }
    end
  end

  # Transaction Notes Add
  def updateTransactionNote(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    transaction_id = params["transaction_id"]
    note = params["notes"]

    transactions = Repo.get(Transactions, transaction_id)

    if transactions == nil do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Transaction not found!"
             }
           }
    else
      transaction = %{"notes" => note, "notes_inserted" => commanid}
      changeset = Transactions.changesetNotes(transactions, transaction)
      case Repo.update(changeset) do
        {:ok, _response} -> json conn, %{status_code: "200", data: "Notes added Successfully."}
        {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  def menualCardTransactionCount(conn, _params) do

    employeecards = Repo.all(
      from ec in Employeecards, where: ec.status != "12",
                                select: %{
                                  id: ec.id
                                }
    )

    if employeecards != [] do
      response = Enum.each employeecards, fn cards ->
        card_id = cards.id
        cardtransaction = Repo.one(
          from tx in Transactions,
          where: tx.employeecards_id == ^card_id and (
            tx.transaction_type == "C2O" or tx.transaction_type == "C2I") and tx.category == "POS",
          select: %{
            total_trans: count(tx.id),
            total_amount: sum(tx.final_amount)
          }
        )
        if cardtransaction.total_trans > 0 do


          checktrans = Repo.get_by(CardTransactionsandReceipts, employeecards_id: card_id)
          if is_nil(checktrans) do
            cardTransaction = %{
              "employeecards_id" => card_id,
              "total_amount" => cardtransaction.total_amount,
              "total_transactions" => cardtransaction.total_trans
            }

            changeset = CardTransactionsandReceipts.changesetTransactionCount(
              %CardTransactionsandReceipts{},
              cardTransaction
            )
            case Repo.insert(changeset) do
              {:ok, _data} -> true
              {:error, _changeset} -> false
            end
          else
            cardTransaction = %{
              "total_amount" => cardtransaction.total_amount,
              "total_transactions" => cardtransaction.total_trans
            }

            changeset = CardTransactionsandReceipts.changesetTransactionCount(checktrans, cardTransaction)
            case Repo.update(changeset) do
              {:ok, _data} -> true
              {:error, _changeset} -> false
            end
          end
        end
      end

      case response do
        :ok ->
          json conn, %{status_code: "200", data: "Cards Transactions added Successfully."}
        :error ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Employee card transaction not found."
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Cards not found!"
             }
           }
    end
  end

  def menualCardTransactionReceiptCount(conn, _params) do

    employeecards = Repo.all(
      from ec in Employeecards, where: ec.status != "12",
                                select: %{
                                  id: ec.id
                                }
    )

    if employeecards != [] do
      response = Enum.each employeecards, fn cards ->
        card_id = cards.id
        cardtransaction = Repo.all(
          from tx in Transactions,
          where: tx.employeecards_id == ^card_id and (
            tx.transaction_type == "C2O" or tx.transaction_type == "C2I") and tx.category == "POS",
          select: tx.id
        )
        if cardtransaction != [] do

          Enum.each cardtransaction, fn trans_id ->
            countreceipt = Repo.one(
              from tr in Transactionsreceipt, where: tr.transactions_id == ^trans_id, select: count(tr.id)
            )
            if countreceipt == 0 do
              cardTransactions = Repo.get_by!(CardTransactionsandReceipts, employeecards_id: card_id)

              if cardTransactions != nil do
                last_count = cardTransactions.total_receipt_pending + 1
                update_pending_receipt = %{"total_receipt_pending" => last_count}
                changeset_card_transaction = CardTransactionsandReceipts.changesetUpdatePending(
                  cardTransactions,
                  update_pending_receipt
                )

                case Repo.update(changeset_card_transaction) do
                  {:ok, _data} -> true
                  {:error, _changeset} -> false
                end
              end
            end
          end
        end
      end

      case response do
        :ok ->
          json conn, %{status_code: "200", data: "Cards Transactions Update Successfully."}
        :error ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Employee card transaction not found."
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Cards not found!"
             }
           }
    end
  end


  def removeReceipt(conn, params) do
    receipt_id = params["transactionReceiptId"]

    getReceipt = Repo.get_by(Transactionsreceipt, id: receipt_id)

    if is_nil(getReceipt) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Receipt not found!"
             }
           }
    else
      transaction_id = getReceipt.transactions_id
      total_receipt = Repo.one(
        from tr in Transactionsreceipt, where: tr.transactions_id == ^transaction_id, select: count(tr.id)
      )

      case Repo.delete(getReceipt) do
        {:ok, _receipt} ->

          if total_receipt == 1 do
            transaction = Repo.get_by(Transactions, id: transaction_id)
            card_id = transaction.employeecards_id
            cardTransactions = Repo.get_by(CardTransactionsandReceipts, employeecards_id: card_id)

            if cardTransactions != nil do
              last_count = cardTransactions.total_receipt_pending + 1
              update_pending_receipt = %{"total_receipt_pending" => last_count}
              changeset_card_transaction = CardTransactionsandReceipts.changesetUpdatePending(
                cardTransactions,
                update_pending_receipt
              )
              Repo.update(changeset_card_transaction)
            end
          end

          json conn, %{status_code: "200", data: "Receipt Removed."}

        {:error, changeset} ->
          render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  def downloadReceipt(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    receipt_id = params["transacationReceiptId"]

    receipt_url = Repo.get_by(Transactionsreceipt, id: receipt_id)

    if !is_nil(receipt_url) do
      company = Repo.get_by(Transactions, id: receipt_url.transactions_id)

      if !is_nil(company) and company.company_id == company_id do
        %HTTPoison.Response{body: body} = HTTPoison.get!(receipt_url.receipt_url)

        base_64 = Base.encode64(body)
        file_type = image_extension(body)
                    |> String.replace(".", "")
        file_name = "#{Commontools.randnumber(8)}"
        #    conn
        #    |> put_resp_content_type("image/#{file_type}")
        #    |> put_resp_header("content-disposition", "attachment; filename=#{file_name}")
        #    |> send_resp(200, body)

        json conn, %{status_code: "200", content: base_64, type: file_type, title: file_name}
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Receipt not found"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Receipt not found!"
             }
           }
    end
  end


  @doc "Last Five Transaction list by account ID"
  def accountLastFiveTransaction(conn, params) do
    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]
    account_id = params["account_id"]
    get_transactions = Transactions
                       |> where(
                            [t],
                            t.commanall_id == ^commanid and t.company_id == ^compid and t.account_id == ^account_id
                          )
                       |> order_by(desc: :transaction_date)
                       |> limit(5)
                       |> preload(:projects)
                       |> Repo.all()

    render(conn, EmployeeView, "manytrans_noReceipt.json", transactions: get_transactions)
  end

  @doc "Last Five Transaction list by account ID"
  def bankLastFiveTransaction(conn, _params) do
    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    bank_id = Repo.one from c in Companybankaccount, where: c.company_id == ^compid, select: c.id
    if is_nil(bank_id) do
      json conn, %{"response_code" => "404", "response_message" => "Record not found!"}
    else
    get_transactions = Transactions
                       |> where([t], t.commanall_id == ^commanid and t.company_id == ^compid and t.bank_id == ^bank_id)
                       |> order_by(desc: :transaction_date)
                       |> limit(5)
                       |> Repo.all()

    render(conn, EmployeeView, "manytrans_noReceipt.json", transactions: get_transactions)
    end
  end

  # Helper functions to read the binary to determine the image extension
  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _ :: binary>>), do: ".png"
  defp image_extension(<<0xff, 0xD8, _ :: binary>>), do: ".jpg"
  defp image_extension(<<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, _ :: binary>>), do: ".gif"
  defp image_extension(<<0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, _ :: binary>>), do: ".pdf"
end
