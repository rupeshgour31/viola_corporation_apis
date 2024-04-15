defmodule ViolacorpWeb.Company.CapController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish

  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Devicedetails

#  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  @doc "Get All Requested card List for CAP"
  def getAllRequestCardListCAP(conn, params) do
    %{"id" => companyid} = conn.assigns[:current_user]
    type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
    upcaseit = String.upcase(type)

    if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
      requested_card_list = (from r in Requestcard,
                                  where: r.company_id == ^companyid and r.status == ^"R",
                                  left_join: e in assoc(r, :employee),
                                  order_by: [
                                    desc: r.inserted_at
                                  ],
                                  select: %{
                                    id: r.id,
                                    employee_id: r.employee_id,
                                    currency: r.currency,
                                    card_type: r.card_type,
                                    status: r.status,
                                    first_name: e.first_name,
                                    last_name: e.last_name,
                                    inserted_at: r.inserted_at
                                  })
                            |> Repo.paginate(params)
      total_count = Enum.count(requested_card_list)

      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: requested_card_list.entries,
             page_number: requested_card_list.page_number,
             total_pages: requested_card_list.total_pages
           }
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Unauthorized User"
             }
           }
    end
  end

  @doc "list of money requests for CAP"
  def companyMoneyRequestsCAP(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    type = Repo.one(from d in Directors, where: d.company_id == ^company_id and d.sequence == 1, select: d.position)
    upcaseit = String.upcase(type)

    if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
      requested_money_list = (
                               from r in Requestmoney,
                                    where: r.company_id == ^company_id and r.status == "R",
                                    left_join: cards in assoc(r, :employeecards),
                                    left_join: e in assoc(r, :employee),
                                    order_by: [
                                      desc: r.inserted_At
                                    ],
                                    select: %{
                                      id: r.id,
                                      employee_id: r.employee_id,
                                      employeecards_id: r.employeecards_id,
                                      last_digit: cards.last_digit,
                                      first_name: e.first_name,
                                      last_name: e.last_name,
                                      amount: r.amount,
                                      cur_code: r.cur_code,
                                      reason: r.reason,
                                      status: r.status,
                                      inserted_at: r.inserted_at
                                    }
                               )
                             |> Repo.paginate(params)
      total_count = Enum.count(requested_money_list)
      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: requested_money_list.entries,
             page_number: requested_money_list.page_number,
             total_pages: requested_money_list.total_pages
           }
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Unauthorized User"
             }
           }
    end
  end

  @doc "Employee Card Topup for CAP"
  def employeeTopupCAP(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        today = DateTime.utc_now
        employeecard_id = params["card_id"]
        amount = params["amount"]
        description = params["description"]
        type = Application.get_env(:violacorp, :transaction_type)

        type_debit = Application.get_env(:violacorp, :topup_debit)
        type_credit = Application.get_env(:violacorp, :topup_credit)

        # GET ACCOUNT ID
        company_info = Repo.get(Company, companyid)

#        account_details = Repo.get(Companyaccounts, account_id)
        account_details = Repo.get_by(Companyaccounts, company_id: companyid, currency_code: "GBP")
        currency = account_details.currency_code
        account_id = account_details.accomplish_account_id
        acc_available_balance = String.to_float("#{account_details.available_balance}")
        debit_balance = acc_available_balance - String.to_float("#{amount}")
        from_company = company_info.company_name

        # GET CARD ID
        card_details = Repo.get(Employeecards, employeecard_id)
        employee_id = card_details.employee_id
        employee_info = Repo.get(Employee, employee_id)
        card_id = card_details.accomplish_card_id
        card_available_balance = String.to_float("#{card_details.available_balance}")
        credit_balance = card_available_balance + String.to_float("#{amount}")
        to_card = card_details.last_digit
        to_employee = "#{employee_info.first_name} #{employee_info.last_name}"

        remark = %{"from" => currency, "to" => to_card, "from_name" => from_company, "to_name" => to_employee}

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
                           get_commanall_id = Repo.one from a in Commanall,
                                                       where: a.employee_id == ^employee_id,
                                                       select: %{
                                                         id: a.id
                                                       }

                           commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employee_id,
                                                                        select: %{
                                                                          id: cmn.id,
                                                                          commanall_id: cmn.accomplish_userid,
                                                                          email_id: cmn.email_id,
                                                                          as_login: cmn.as_login,
                                                                        }

                           mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
                                                                     select: %{
                                                                       code: m.code,
                                                                       contact_number: m.contact_number
                                                                     }

                           devicedata = Repo.one from d in Devicedetails, where: d.commanall_id == ^commandata.id and d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                                          select: %{
                                                                            token: d.token,
                                                                            token_type: d.type
                                                                          }
                           transaction_employee = %{
                             "commanall_id" => commandata.id,
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

                           #                           # ALERTS DEPRECATED
                           #                           data = %{
                           #                             :section => "topup",
                           #                             :commanall_id => get_commanall_id.id,
                           #                             :card => card_details.last_digit,
                           #                             :currency => currency,
                           #                             :company_name => company_info.company_name,
                           #                             :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                           #                             :amount => amount
                           #                           }
                           #                           AlertsController.sendEmail(data)
                           #                           AlertsController.sendNotification(data)
                           #                           AlertsController.sendSms(data)
                           #                           AlertsController.storeNotification(data)


                           data = [%{
                             section: "topup",
                             type: "E",
                             email_id: get_commanall_id.email_id,
                             data: %{:card => card_details.last_digit, :currency => currency, :company_name => company_info.company_name, :employee_name => "#{employee_info.first_name} #{employee_info.last_name}", :amount => amount}   # Content
                           },
                             %{
                               section: "topup",
                               type: "S",
                               contact_code: mobiledata.code,
                               contact_number: mobiledata.contact_number,
                               data: %{:currency => currency, :amount => amount}   # Content# Content
                             },
                             %{
                               section: "topup",
                               type: "N",
                               token: if is_nil(devicedata) do nil else devicedata.token end,
                               push_type: if is_nil(devicedata) do nil else devicedata.token_type end, # "I" or "A"
                               login: get_commanall_id.as_login, # "Y" or "N"
                               data: %{:currency => currency, :amount => amount} # Content
                             }]
                           V2AlertsController.main(data)


                           json conn, %{status_code: "200", data: response_message}
                         else
                           json conn, %{status_code: "5008", data: response_message}
                         end
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Employee Card request Topup for CAP"
  def requestTopupCAP(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        request_info = Repo.get!(Requestmoney, params["request_id"])

        description = params["description"]
        status = params["status"]

        if request_info.status == "R" do
          if status == "A" do
            today = DateTime.utc_now
            employee_id = request_info.employee_id
            employeecard_id = request_info.employeecards_id
#            account_id = params["account_id"]
            enter_amount = params["amount"]
            amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
            type = Application.get_env(:violacorp, :transaction_type)

            type_debit = Application.get_env(:violacorp, :topup_debit)
            type_credit = Application.get_env(:violacorp, :topup_credit)

            # GET ACCOUNT ID
            company_info = Repo.get(Company, companyid)

#           account_details = Repo.get(Companyaccounts, account_id)
            account_details = Repo.get_by(Companyaccounts, company_id: companyid, currency_code: "GBP")

            if is_nil(account_details.available_balance) or account_details.available_balance == "0.00" do
              json conn, %{status_code: "4004", error: %{message: "Insufficient funds."}}
            else
              currency = account_details.currency_code
              account_id = account_details.accomplish_account_id
              acc_available_balance = String.to_float("#{account_details.available_balance}")

              debit_balance = acc_available_balance - String.to_float("#{amount}")
              from_company = company_info.company_name
              # GET CARD ID
              employee_info = Repo.get(Employee, employee_id)
              card_details = Repo.get(Employeecards, employeecard_id)
              card_id = card_details.accomplish_card_id
              employee_id = card_details.employee_id
              card_available_balance = String.to_float("#{card_details.available_balance}")
              credit_balance = card_available_balance + String.to_float("#{amount}")
              to_card = card_details.last_digit
              to_employee = "#{employee_info.first_name} #{employee_info.last_name}"
              remark = %{"from" => currency, "to" => to_card, "from_name" => from_company, "to_name" => to_employee}
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
                                 changeset_employeecard = Employeecards.changesetBalance(
                                   card_details,
                                   update_card_balance
                                 )
                                 Repo.update(changeset_employeecard)
                                 # Entry for employee transaction
                                 com_commanall_id = Repo.one from cmns in Commanall, where: cmns.id == ^commanid, left_join: ms in assoc(cmns, :contacts), on: ms.is_primary == "Y", left_join: ds in assoc(cmns, :devicedetails), on: ds.is_delete == "N" and (ds.type == "A" or ds.type == "I"),
                                                                                     select: %{
                                                                                       id: cmns.id,
                                                                                       email_id: cmns.email_id,
                                                                                       as_login: cmns.as_login,
                                                                                       code: ms.code,
                                                                                       contact_number: ms.contact_number,
                                                                                       token: ds.token,
                                                                                       token_type: ds.type,
                                                                                     }
                                 get_commanall_id = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employee_id,
                                                                                    select: %{
                                                                                      id: cmn.id,
                                                                                      commanall_id: cmn.accomplish_userid,
                                                                                      email_id: cmn.email_id,
                                                                                      as_login: cmn.as_login
                                                                                    }
                                 mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^get_commanall_id.id and m.is_primary == "Y",
                                                                           select: %{
                                                                             code: m.code,
                                                                             contact_number: m.contact_number
                                                                           }

                                 devicedata = Repo.one from dd in Devicedetails, where: dd.commanall_id == ^get_commanall_id.id and dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                                                 select: %{
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
                                 update_status = %{status: status, company_reason: description}
                                 changeset = Requestmoney.updatestatus_changeset(request_info, update_status)
                                 Repo.update(changeset)
                                 #                               # ALERTS DEPRECATED
                                 #                               data = %{
                                 #                                 :section => "request_money_approved",
                                 #                                 :commanall_id => commanid,
                                 #                                 :card => card_details.last_digit,
                                 #                                 :currency => currency,
                                 #                                 :amount => amount,
                                 #                                 :company_name => company_info.company_name,
                                 #                                 :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                                 #                                 :company_reason => ""
                                 #                               }
                                 #                               AlertsController.sendEmail(data)
                                 #                               AlertsController.sendNotification(data)
                                 #                               AlertsController.sendSms(data)
                                 #                               AlertsController.storeNotification(data)
                                 #                               data = %{
                                 #                                 :section => "request_money_success",
                                 #                                 :commanall_id => get_commanall_id.id,
                                 #                                 :card => card_details.last_digit,
                                 #                                 :currency => currency,
                                 #                                 :amount => amount,
                                 #                                 :company_name => company_info.company_name,
                                 #                                 :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
                                 #                                 :company_reason => ""
                                 #                               }
                                 #                               AlertsController.sendEmail(data)
                                 #                               AlertsController.sendNotification(data)
                                 #                               AlertsController.sendSms(data)
                                 #                               AlertsController.storeNotification(data)

                                 data = [%{
                                   section: "request_money_approved",
                                   type: "E",
                                   email_id: com_commanall_id.email_id,
                                   data: %{:card => card_details.last_digit, :currency => currency, :amount => amount, :company_reason => description, :company_name => company_info.company_name, :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content
                                 },
                                   %{
                                     section: "request_money_approved",
                                     type: "S",
                                     contact_code: com_commanall_id.code,
                                     contact_number: com_commanall_id.contact_number,
                                     data: %{:employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content# Content
                                   },
                                   %{
                                     section: "request_money_approved",
                                     type: "N",
                                     token: com_commanall_id.token,
                                     push_type: com_commanall_id.token_type, # "I" or "A"
                                     login: com_commanall_id.as_login, # "Y" or "N"
                                     data: %{:employee_name => "#{employee_info.first_name} #{employee_info.last_name}"} # Content
                                   },
                                   %{
                                     section: "request_money_success",
                                     type: "E",
                                     email_id: get_commanall_id.email_id,
                                     data: %{:card => card_details.last_digit, :currency => currency, :amount => amount, :company_reason => description, :company_name => company_info.company_name, :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content
                                   },
                                   %{
                                     section: "request_money_success",
                                     type: "S",
                                     contact_code: mobiledata.code,
                                     contact_number: mobiledata.contact_number,
                                     data: %{}   # Content# Content
                                   },
                                   %{
                                     section: "request_money_success",
                                     type: "N",
                                     token: devicedata.token,
                                     push_type: devicedata.token_type, # "I" or "A"
                                     login: get_commanall_id.as_login, # "Y" or "N"
                                     data: %{} # Content
                                   }]
                                 V2AlertsController.main(data)

                                 json conn, %{status_code: "200", data: response_message}
                               else
                                 json conn, %{status_code: "5008", data: response_message}
                               end
              end
            end
          else
            update_status = %{status: status, company_reason: description}
            changeset = Requestmoney.updatestatus_changeset(request_info, update_status)
            Repo.update(changeset)
            employee_request_money = Repo.get!(Requestmoney, params["request_id"])
            com_commanall_id = Repo.one from cmns in Commanall, where: cmns.id == ^commanid, left_join: ms in assoc(cmns, :contacts), on: ms.is_primary == "Y", left_join: ds in assoc(cmns, :devicedetails), on: ds.is_delete == "N" and (ds.type == "A" or ds.type == "I"),
                                                                select: %{
                                                                  id: cmns.id,
                                                                  email_id: cmns.email_id,
                                                                  as_login: cmns.as_login,
                                                                  code: ms.code,
                                                                  contact_number: ms.contact_number,
                                                                  token: ds.token,
                                                                  token_type: ds.type,
                                                                }
            commanall_id = Repo.one from cmn in Commanall, where: cmn.employee_id == ^request_info.employee_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: dd in assoc(cmn, :devicedetails), on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
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
#            # ALERTS
#            data = %{
#              :section => "request_money_rejected",
#              :commanall_id => commanid,
#              :card => card_details.last_digit,
#              :currency => request_info.cur_code,
#              :amount => request_info.amount,
#              :company_name => company_info.company_name,
#              :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
#              :company_reason => ""
#            }
#            AlertsController.sendEmail(data)
#            AlertsController.sendNotification(data)
#            AlertsController.sendSms(data)
#            AlertsController.storeNotification(data)
#            data = %{
#              :section => "request_money_failed",
#              :commanall_id => comman_info.id,
#              :card => card_details.last_digit,
#              :currency => request_info.cur_code,
#              :amount => request_info.amount,
#              :company_name => company_info.company_name,
#              :employee_name => "#{employee_info.first_name} #{employee_info.last_name}",
#              :company_reason => ""
#            }
#            AlertsController.sendEmail(data)
#            AlertsController.sendNotification(data)
#            AlertsController.sendSms(data)
#            AlertsController.storeNotification(data)

            data = [%{
              section: "request_money_rejected",
              type: "E",
              email_id: com_commanall_id.email_id,
              data: %{:card => card_details.last_digit, :currency => request_info.cur_code, :amount => request_info.amount, :company_reason => description, :company_name => company_info.company_name, :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content
            },
              %{
                section: "request_money_rejected",
                type: "S",
                contact_code: com_commanall_id.code,
                contact_number: com_commanall_id.contact_number,
                data: %{:employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content# Content
              },
              %{
                section: "request_money_rejected",
                type: "N",
                token: com_commanall_id.token,
                push_type: com_commanall_id.token_type, # "I" or "A"
                login: com_commanall_id.as_login, # "Y" or "N"
                data: %{:employee_name => "#{employee_info.first_name} #{employee_info.last_name}"} # Content
              },
              %{
                section: "request_money_failed",
                type: "E",
                email_id: commanall_id.email_id,
                data: %{:card => card_details.last_digit, :currency => request_info.cur_code, :amount => request_info.amount, :company_reason => description, :company_name => company_info.company_name, :employee_name => "#{employee_info.first_name} #{employee_info.last_name}"}   # Content
              },
              %{
                section: "request_money_failed",
                type: "S",
                contact_code: commanall_id.code,
                contact_number: commanall_id.contact_number,
                data: %{}   # Content# Content
              },
              %{
                section: "request_money_failed",
                type: "N",
                token: commanall_id.token,
                push_type: commanall_id.token_type, # "I" or "A"
                login: commanall_id.as_login, # "Y" or "N"
                data: %{} # Content
              }]
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
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "action virtual Card request Topup for CAP"
  def actionVirtualCardCAP(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        # get request card details
        requrestcard = Repo.get!(Requestcard, params["id"])

        status = params["status"]

        if requrestcard.status == "R" and status == "A" do

          if requrestcard.card_type == "P" do
            json conn, %{status_code: "4006", message: "Allow only virtual card request."}
          end

          # Get Comman All Data
          commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: dd in assoc(cmn, :devicedetails), on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                       select: %{
                                                         id: cmn.id,
                                                         commanall_id: cmn.accomplish_userid,
                                                         email_id: cmn.email_id,
                                                         as_login: cmn.as_login,
                                                         code: m.code,
                                                         contact_number: m.contact_number,
                                                         token: dd.token,
                                                         token_type: dd.type,
                                                       }

          type = Application.get_env(:violacorp, :card_type)
          accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
          accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)
          fulfilment_config_id = Application.get_env(:violacorp, :fulfilment_config_id_v)

          bin_id = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_bin_id)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_bin_id)
            else
              Application.get_env(:violacorp, :gbp_card_bin_id)
            end
          end

          number = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_number)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_number)
            else
              Application.get_env(:violacorp, :gbp_card_number)
            end
          end

          request = %{
            type: type,
            bin_id: bin_id,
            number: number,
            currency: requrestcard.currency,
            user_id: commandata.commanall_id,
            status: 1,
            fulfilment_config_id: fulfilment_config_id,
            fulfilment_notes: "create cards for user",
            fulfilment_reason: 1,
            fulfilment_status: 1,
            latitude: accomplish_latitude,
            longitude: accomplish_longitude,
            position_description: "",
            acceptance2: 2,
            acceptance: 1
          }

          response = Accomplish.create_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                           select: c.id

            # Insert employee card details
            card_number = response["info"]["number"]
            last_digit = Commontools.lastfour(card_number)
            employeecard = %{
              "employee_id" => requrestcard.employee_id,
              "currencies_id" => currencies_id,
              "currency_code" => response["info"]["currency"],
              "last_digit" => "#{last_digit}",
              "available_balance" => response["info"]["available_balance"],
              "current_balance" => response["info"]["balance"],
              "accomplish_card_id" => response["info"]["id"],
              "bin_id" => response["info"]["bin_id"],
              "accomplish_account_number" => response["info"]["number"],
              "expiry_date" => response["info"]["security"]["expiry_date"],
              "source_id" => response["info"]["original_source_id"],
              "status" => response["info"]["status"],
              "inserted_by" => commanid
            }

            changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)

            request_card_params = %{"status" => "A"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            case Repo.insert(changeset_comacc) do
              {:ok, _director} ->
                getemployee = Repo.get!(Employee, requrestcard.employee_id)
                [count_card] = Repo.all from d in Employeecards,
                                        where: d.employee_id == ^requrestcard.employee_id and (
                                          d.status == "1" or d.status == "4" or d.status == "12"),
                                        select: %{
                                          count: count(d.id)
                                        }
                new_number = %{"no_of_cards" => count_card.count}
                cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                Repo.update(cards_changeset)


                # ALERTS
                card_type = if requrestcard.card_type == "V" do
                  "virtual"
                end
                employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                               select: %{
                                                                 first_name: employee.first_name,
                                                                 last_name: employee.last_name
                                                               }


                #                data = %{
                #                  :section => "cardrequest_approved",
                #                  :commanall_id => commandata.id,
                #                  :card_type => card_type,
                #                  :currency => requrestcard.currency,
                #                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                #                }
                #                AlertsController.sendEmail(data)
                #                AlertsController.sendNotification(data)
                #                AlertsController.sendSms(data)
                #                AlertsController.storeNotification(data)

                data = [%{
                  section: "cardrequest_approved",
                  type: "E",
                  email_id: commandata.email_id,
                  data: %{:card_type => card_type,
                    :currency => requrestcard.currency,
                    :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                },
                  %{
                    section: "cardrequest_approved",
                    type: "S",
                    contact_code: commandata.code,
                    contact_number: commandata.contact_number,
                    data: %{:card_type => card_type,
                      :currency => requrestcard.currency,
                      :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                  },
                  %{
                    section: "cardrequest_approved",
                    type: "N",
                    token: commandata.token,
                    push_type: commandata.token_type, # "I" or "A"
                    login: commandata.as_login, # "Y" or "N"
                    data: %{:card_type => card_type,
                      :currency => requrestcard.currency,
                      :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                  }]
                V2AlertsController.main(data)


                json conn, %{status_code: "200", message: "Card Approved."}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "5001",
                   errors: %{
                     message: response_message
                   }
                 }
          end

        else

          if requrestcard.status == "R" and status == "C" do
            request_card_params = %{"status" => "C"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            # Get Comman All Data
            commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: dd in assoc(cmn, :devicedetails), on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                         select: %{
                                                           id: cmn.id,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                           code: m.code,
                                                           contact_number: m.contact_number,
                                                           token: dd.token,
                                                           token_type: dd.type,
                                                         }

            employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                           select: %{
                                                             first_name: employee.first_name,
                                                             last_name: employee.last_name
                                                           }

            card_type = if requrestcard.card_type == "V" do
              "virtual"
            end

            #            # ALERTS DEPRECATED
            #            data = %{
            #              :section => "cardrequest_rejected",
            #              :commanall_id => commandata.id,
            #              :card_type => card_type,
            #              :currency => requrestcard.currency,
            #              :employee_name => "#{employee.first_name} #{employee.last_name}"
            #            }
            #            AlertsController.sendEmail(data)
            #            AlertsController.sendNotification(data)
            #            AlertsController.sendSms(data)
            #            AlertsController.storeNotification(data)


            data = [%{
              section: "cardrequest_rejected",
              type: "E",
              email_id: commandata.email_id,
              data: %{:card_type => card_type,
                :currency => requrestcard.currency,
                :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
            },
              %{
                section: "cardrequest_rejected",
                type: "S",
                contact_code: commandata.code,
                contact_number: commandata.contact_number,
                data: %{:card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
              },
              %{
                section: "cardrequest_rejected",
                type: "N",
                token: commandata.token,
                push_type: commandata.token_type, # "I" or "A"
                login: commandata.as_login, # "Y" or "N"
                data: %{:card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
              }]
            V2AlertsController.main(data)

            json conn, %{status_code: "200", message: "Card Rejected."}
          else
            json conn, %{status_code: "4006", message: "card already approved."}
          end

        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "action physical card request for CAP"
  def actionPhysicalCardCAP(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        # get request card details
        requrestcard = Repo.get!(Requestcard, params["id"])

        status = params["status"]
        if requrestcard.status == "R" and status == "A" do

          if requrestcard.card_type == "V" do
            json conn, %{status_code: "4006", message: "Allow only physical card request."}
          end

          # Get Comman All Data
          commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: dd in assoc(cmn, :devicedetails), on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                       select: %{
                                                         id: cmn.id,
                                                         commanall_id: cmn.accomplish_userid,
                                                         email_id: cmn.email_id,
                                                         as_login: cmn.as_login,
                                                         code: m.code,
                                                         contact_number: m.contact_number,
                                                         token: dd.token,
                                                         token_type: dd.type,
                                                       }

          type = Application.get_env(:violacorp, :card_type)
          accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
          accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)
          fulfilment_config_id = Application.get_env(:violacorp, :fulfilment_config_id_p)

          bin_id = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_bin_id)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_bin_id)
            else
              Application.get_env(:violacorp, :gbp_card_bin_id)
            end
          end

          number = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_number)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_number)
            else
              Application.get_env(:violacorp, :gbp_card_number)
            end
          end

          request = %{
            type: type,
            bin_id: bin_id,
            number: number,
            currency: requrestcard.currency,
            user_id: commandata.commanall_id,
            status: 12,
            fulfilment_config_id: fulfilment_config_id,
            fulfilment_notes: "create cards for user",
            fulfilment_reason: 1,
            fulfilment_status: 1,
            latitude: accomplish_latitude,
            longitude: accomplish_longitude,
            position_description: "",
            acceptance2: 2,
            acceptance: 1
          }

          response = Accomplish.create_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                           select: c.id
            # Insert employee card details
            card_number = response["info"]["number"]
            last_digit = Commontools.lastfour(card_number)
            employeecard = %{
              "employee_id" => requrestcard.employee_id,
              "currencies_id" => currencies_id,
              "currency_code" => response["info"]["currency"],
              "last_digit" => "#{last_digit}",
              "available_balance" => response["info"]["available_balance"],
              "current_balance" => response["info"]["balance"],
              "accomplish_card_id" => response["info"]["id"],
              "bin_id" => response["info"]["bin_id"],
              "accomplish_account_number" => response["info"]["number"],
              "expiry_date" => response["info"]["security"]["expiry_date"],
              "source_id" => response["info"]["original_source_id"],
              "activation_code" => response["info"]["security"]["activation_code"],
              "status" => response["info"]["status"],
              "card_type" => "P",
              "inserted_by" => commanid
            }

            changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)

            # Update Request card Status
            request_card_params = %{"status" => "A"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            # Update commanall card_requested
            commanall_data = Repo.get!(Commanall, commandata.id)
            card_request = %{"card_requested" => "Y"}
            changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
            Repo.update(changeset_commanall)

            case Repo.insert(changeset_comacc) do
              {:ok, _response} -> getemployee = Repo.get!(Employee, requrestcard.employee_id)
                                  [count_card] = Repo.all from d in Employeecards,
                                                          where: d.employee_id == ^requrestcard.employee_id and (
                                                            d.status == "1" or d.status == "4" or d.status == "12"),
                                                          select: %{
                                                            count: count(d.id)
                                                          }
                                  new_number = %{"no_of_cards" => count_card.count}
                                  cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                                  Repo.update(cards_changeset)

                                  # ALERTS
                                  card_type = if requrestcard.card_type == "V" do
                                    "virtual"
                                  else
                                    "physical"
                                  end
                                  employee = Repo.one from employee in Employee,
                                                      where: employee.id == ^requrestcard.employee_id,
                                                      select: %{
                                                        first_name: employee.first_name,
                                                        last_name: employee.last_name
                                                      }

                                  #                                  data = %{
                                  #                                    :section => "cardrequest_approved",
                                  #                                    :commanall_id => commandata.id,
                                  #                                    :card_type => card_type,
                                  #                                    :currency => requrestcard.currency,
                                  #                                    :employee_name => "#{employee.first_name} #{employee.last_name}"
                                  #                                  }
                                  #                                  AlertsController.sendEmail(data)
                                  #                                  AlertsController.sendNotification(data)
                                  #                                  AlertsController.sendSms(data)
                                  #                                  AlertsController.storeNotification(data)


                                  data = [%{
                                    section: "cardrequest_approved",
                                    type: "E",
                                    email_id: commandata.email_id,
                                    data: %{:card_type => card_type,
                                      :currency => requrestcard.currency,
                                      :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                                  },
                                    %{
                                      section: "cardrequest_approved",
                                      type: "S",
                                      contact_code: commandata.code,
                                      contact_number: commandata.contact_number,
                                      data: %{:card_type => card_type,
                                        :currency => requrestcard.currency,
                                        :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                                    },
                                    %{
                                      section: "cardrequest_approved",
                                      type: "N",
                                      token: commandata.token,
                                      push_type: commandata.token_type, # "I" or "A"
                                      login: commandata.as_login, # "Y" or "N"
                                      data: %{:card_type => card_type,
                                        :currency => requrestcard.currency,
                                        :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
                                    }]
                                  V2AlertsController.main(data)


                                  render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Card Approved.")
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "5002",
                   errors: %{
                     message: response_message
                   }
                 }
          end

        else
          if requrestcard.status == "R" and status == "C" do
            request_card_params = %{"status" => "C"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)
            # Get Comman All Data
            commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: dd in assoc(cmn, :devicedetails), on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                         select: %{
                                                           id: cmn.id,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                           code: m.code,
                                                           contact_number: m.contact_number,
                                                           token: dd.token,
                                                           token_type: dd.type,
                                                         }

            employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                           select: %{
                                                             first_name: employee.first_name,
                                                             last_name: employee.last_name
                                                           }

            card_type = if requrestcard.card_type == "V" do
              "virtual"
            else
              "physical"
            end

#            # ALERTS
#            data = %{
#              :section => "cardrequest_rejected",
#              :commanall_id => commandata.id,
#              :card_type => card_type,
#              :currency => requrestcard.currency,
#              :employee_name => "#{employee.first_name} #{employee.last_name}"
#            }
#            AlertsController.sendEmail(data)
#            AlertsController.sendNotification(data)
#            AlertsController.sendSms(data)
#            AlertsController.storeNotification(data)

            data = [%{
              section: "cardrequest_rejected",
              type: "E",
              email_id: commandata.email_id,
              data: %{:card_type => card_type,
                :currency => requrestcard.currency,
                :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
            },
              %{
                section: "cardrequest_rejected",
                type: "S",
                contact_code: commandata.code,
                contact_number: commandata.contact_number,
                data: %{:card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
              },
              %{
                section: "cardrequest_rejected",
                type: "N",
                token: commandata.token,
                push_type: commandata.token_type, # "I" or "A"
                login: commandata.as_login, # "Y" or "N"
                data: %{:card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"}   # Content
              }]
            V2AlertsController.main(data)
            json conn, %{status_code: "200", message: "Card Rejected."}
          else
            json conn, %{status_code: "4006", message: "card already approved."}
          end
        end

      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "action physical card request for CAP"
  def cardlistwithemployeeCAP(conn, params) do
      %{"id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        query = (
          from e in Employee,
               where: e.company_id == ^companyid,
               right_join: c in assoc(e, :employeecards),
               where: c.employee_id == e.id,
               select: %{
                 id: c.id,
                 employee_id: c.employee_id,
                 currencies_id: c.currencies_id,
                 currency_code: c.currency_code,
                 title: e.title,
                 first_name: e.first_name,
                 last_name: e.last_name,
                 last_digit: c.last_digit,
                 available_balance: c.available_balance,
                 current_balance: c.current_balance,
                 card_type: c.card_type,
                 status: c.status
               }) |> Repo.paginate(params)


        json conn, %{status_code: "200", total_count: query.total_entries, data: query.entries, page_number: query.page_number, total_pages: query.total_pages}

      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end
  end

  @doc "action physical card request for CAP"
  def cardlistwithemployeeCAPNOPagination(conn, _params) do
    %{"id" => companyid} = conn.assigns[:current_user]
    type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
    upcaseit = String.upcase(type)

    if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
      query = Repo.all(
                from e in Employee,
                     where: e.company_id == ^companyid,
                     right_join: c in assoc(e, :employeecards),
                     where: c.employee_id == e.id and c.status == "1",
                     select: %{
                       id: c.id,
                       employee_id: c.employee_id,
                       currencies_id: c.currencies_id,
                       currency_code: c.currency_code,
                       title: e.title,
                       first_name: e.first_name,
                       last_name: e.last_name,
                       last_digit: c.last_digit,
                       available_balance: c.available_balance,
                       card_type: c.card_type,
                       status: c.status
                     })

      json conn, %{status_code: "200", data: query}
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Unauthorized User"
             }
           }
    end
  end

  @doc "action physical card request for CAP"
  def getEmployeeListCAP(conn, _params) do
    %{"id" => companyid} = conn.assigns[:current_user]
    type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
    upcaseit = String.upcase(type)

    if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
      employee = Repo.all (
                            from e in Employee,
                                 where: e.company_id == ^companyid and e.status == "A",
                                 select: %{
                                   id: e.id,
                                   title: e.title,
                                   first_name: e.first_name,
                                   last_name: e.last_name,
                                   status: e.status
                                 })
      json conn, %{status_code: "200", data: employee}
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Unauthorized User"
             }
           }
    end
  end

  @doc "Cards List of single Employee for CAP"
  def cardsListSingleEmployeeCAP(conn, params) do
    unless map_size(params) == 0 do
    %{"id" => companyid} = conn.assigns[:current_user]
    type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
    employee_id = params["employee_id"]
    upcaseit = String.upcase(type)

    if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
      employee = Repo.all (
                            from c in Employeecards,
                                 where: c.employee_id == ^employee_id and c.status == "1",
                                 select: %{
                                   id: c.id,
                                   employee_id: c.employee_id,
                                   currencies_id: c.currencies_id,
                                   currency_code: c.currency_code,
                                   last_digit: c.last_digit,
                                   available_balance: c.available_balance,
                                   current_balance: c.current_balance,
                                   card_type: c.card_type,
                                   status: c.status
                                 })
      json conn, %{status_code: "200", data: employee}

    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Unauthorized User"
             }
           }
    end
  else
    conn
    |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
  end
  end

  @doc "Cards List of single Employee for CAP"
  def transactionsListCAP(conn, params) do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
      type = Repo.one(from d in Directors, where: d.company_id == ^companyid and d.sequence == 1, select: d.position)
      upcaseit = String.upcase(type)

      if upcaseit == "CAP" or upcaseit == "DIRECTOR" or upcaseit == "OWNER" do
        query = (
                  from c in Transactions,
                       where: c.commanall_id == ^commanid and c.company_id == ^companyid and c.transaction_mode == "D" and c.transaction_type == "A2C",
                       order_by: [
                         desc: c.inserted_at
                       ],
                       select: %{
                         id: c.id,
                         commanall_id: c.commanall_id,
                         company_id: c.company_id,
                         employee_id: c.employee_id,
                         projects_id: c.projects_id,
                         currency_code: c.cur_code,
                         amount: c.amount,
                         employeecards_id: c.employeecards_id,
                         transaction_date: c.transaction_date,
                         transaction_mode: c.transaction_mode,
                         transaction_type: c.transaction_type,
                         category: c.category,
                         remark: c.remark,
                         notes: c.notes,
                         status: c.status,
                         inserted_at: c.inserted_at
                       })
                |> Repo.paginate(params)

        json conn, %{status_code: "200", total_count: query.total_entries, data: query.entries, page_number: query.page_number, total_pages: query.total_pages}

      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unauthorized User"
               }
             }
      end

  end

  @doc "For Id Proof and Address Proof information add"
  def uploadKycFirst(conn, params) do
    unless map_size(params) == 0 do

      director = Repo.get_by(Directors, id: params["director_id"])
      if !is_nil(director) do
        company_id = director.company_id
        commanall_data = Repo.get_by(Commanall, company_id: company_id)
        if (commanall_data.reg_step == "IDINFO" and params["type"] == "I") or (commanall_data.reg_step == "ADINFO" and params["type"] == "A") do
          existingKycFirst = Repo.all(from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.type == ^params["type"] and k.status == "A")
          if existingKycFirst do
            from(d in Kycdirectors, where: d.directors_id == ^params["director_id"] and d.type == ^params["type"] and d.status == "A")
            |> Repo.update_all(set: [status: "R"])
          end

            kycdocuments = %{
              "directors_id" => params["director_id"],
              "documenttype_id" => params["documenttype_id"],
              "document_number" => params["document_number"],
              "expiry_date" => params["expiry_date"],
              "issue_date" => params["issue_date"],
              "status" => "A",
              "type" => params["type"], # [I,A]
              "inserted_by" => params["director_id"]
            }
            changeset = case params["type"] do
              "A" -> Kycdirectors.changeset(%Kycdirectors{}, kycdocuments)
              "I" -> Kycdirectors.changeset_addess(%Kycdirectors{}, kycdocuments)
            end
            case Repo.insert(changeset) do
              {:ok, kyc} ->

                user_step = cond do
                  commanall_data.reg_step == "IDINFO" and params["type"] == "I" -> "IDDOC1"
                  commanall_data.reg_step == "ADINFO" and params["type"] == "A" -> "ADDOC1"
                end
                update_status = %{"reg_step" => user_step}
                commanall_changeset = Commanall.changesetSteps(commanall_data, update_status)
                Repo.update(commanall_changeset)

                json conn,
                     %{
                       status_code: "200",
                       data: "Success! Kyc details added.",
                       document_id: kyc.id
                     }
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
        else
          json conn, %{status_code: "4004", errors: %{message: "Please complete your information step first."}}
        end
      else
        json conn, %{status_code: "4003", errors: %{director_id: "Invalid Id"}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For doc upload - mobApp"
  def uploadKycSecond(conn, params) do
    unless map_size(params) == 0 do
      director = Repo.get_by(Directors, id: params["director_id"])
      if !is_nil(director) do
        company_id = director.company_id
        commanall_data = Repo.get_by(Commanall, company_id: company_id)
        if commanall_data.reg_step == "IDDOC1" or commanall_data.reg_step == "IDDOC2" or commanall_data.reg_step == "ADDOC1" do
          document_id = params["document_id"]
          check_data = Repo.one(from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.id == ^document_id and k.status == "A")
          if !is_nil(check_data) do
            file_location_id = if params["content"] != "" do
                                image_id = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
                                ViolacorpWeb.Main.Assetstore.upload_image(image_id)
                              else
                                nil
                              end
            file_name = if !is_nil(file_location_id) do
                          Path.basename(file_location_id)
                        else
                          ""
                        end

            kycdocuments = cond do
              is_nil(check_data.file_location) ->
                %{
                  "file_location" => file_location_id,
                  "file_name" => file_name,
                  "status" => "A",
                }
              is_nil(check_data.file_location_two) -> %{
                                                        "file_location_two" => file_location_id
                                                      }
              true -> %{
                        "file_location" => file_location_id,
                        "file_name" => file_name,
                        "status" => "A",
                      }
            end
            changeset = case check_data.type do
                          "A" -> Kycdirectors.changeset(check_data, kycdocuments)
                          "I" -> Kycdirectors.changeset_addess(check_data, kycdocuments)
                        end
            case Repo.update(changeset) do
              {:ok, _director} ->
                  user_step = cond do
                                commanall_data.reg_step == "IDDOC1" and check_data.type == "I" -> "IDDOC2"
                                commanall_data.reg_step == "IDDOC2" and check_data.type == "I" -> "ADINFO"
                                commanall_data.reg_step == "ADDOC1" and check_data.type == "A" ->

                                  newcount = Repo.one from a in Directors, where: a.company_id == ^commanall_data.company_id, select: count(a.company_id)
                                  director_number = newcount + 1
                                  company_type = Repo.one from c in Company, where: c.id == ^commanall_data.company_id, select: c.company_type
                                      cond do
                                        company_type == "LTD" and newcount == 1 -> "42"
                                        company_type == "LTD" and newcount > 1 -> "5#{director_number}"
                                        company_type == "STR" and newcount == 1 ->  "42"
                                        company_type == "STR" and newcount > 1 -> "5#{director_number}"
                                      end
                              end

                update_status = %{"reg_step" => user_step}
                commanall_changeset = Commanall.changesetSteps(commanall_data, update_status)
                Repo.update(commanall_changeset)

                json conn,
                     %{
                       status_code: "200",
                       data: "Success! Kyc Upload."
                     }
              {:error, changeset} ->
                 conn
                 |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn, %{status_code: "4003", message: "KYC not found"}
          end
        else
          json conn, %{status_code: "4004", errors: %{message: "Please complete your information step first."}}
        end
      else
        json conn, %{status_code: "4003", errors: %{director_id: "Invalid Id"}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def skipStep(conn, params) do
    director = Repo.get_by(Directors, id: params["director_id"])
    if !is_nil(director) do
      commanall_data = Repo.get_by(Commanall, company_id: director.company_id)
      user_step = params["step"]
      update_status = %{"reg_step" => user_step}
      changeset = Commanall.changesetSteps(commanall_data, update_status)
      case Repo.update(changeset) do
        {:ok, _party} -> json conn, %{status_code: "200", message: "Success! Skipped Step."}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4003", errors: %{director_id: "Invalid Id"}}
    end
  end
end
