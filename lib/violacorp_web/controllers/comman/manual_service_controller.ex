defmodule ViolacorpWeb.Comman.ManualServiceController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  require Logger
  alias Violacorp.Repo

  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Fourstopcallback
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools

  def updateDirectorsSequence(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do

          get_company = Repo.all(from c in Company, order_by: [desc: c.id], select: c.id)
          Enum.each(get_company, fn company_id ->
            get_directors = Repo.all(from d in Directors, where: d.company_id == ^company_id, order_by: [asc: d.id], select: d)
                get_directors
                |> Stream.with_index
                |> Enum.reduce(0, fn(num_idx, _acc) ->
                  {directors, idx} = num_idx

                     if directors.sequence != 1 && idx != 0 do
                        new_map = %{sequence: idx + 1}
                        changeset = Directors.changesetSequence(directors, new_map)
                        Repo.update(changeset)
#                        IO.inspect("Company: #{company_id} - Directors: #{directors.id} - Sequence : #{directors.sequence} - New Sequence : #{idx + 1}")
                     end
                end)
          end)
          json conn, %{status_code: "200", message: "Directors sequence updated."}
      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def storeConfigVariable(conn, params) do
    sec_password = params["sec_password"]
    username = params["username"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      private_key = System.get_env("VC_PRIVATE_KEY")
      api_token = Application.get_env(:violacorp, :api_token)
      api_url = Application.get_env(:violacorp, :api_url)
      otp_mode = Application.get_env(:violacorp, :otp_mode)
      config_map = %{
        "private_key" => private_key,
        "api_token" => api_token,
        "otp_mode" => otp_mode,
        "api_url" => api_url
      }
      encode_data = Poison.encode!(config_map)
      insert_data = %{
        "response" => encode_data,
      }
      changeset = Fourstopcallback.changeset(%Fourstopcallback{}, insert_data)
      case Repo.insert(changeset) do
        {:ok, _data} -> json conn, %{status_code: "200", message: "Store Value Successfully."}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end
  end

  def checkLogger(conn, _params) do
    Logger.warn("Test logger for warn.")

    Logger.info("Test logger for info.")

    text conn, "Check Logger."
  end

  def update_internal_status(conn, _params) do

    all_companies = Repo.all(from c in Commanall, where: not is_nil(c.company_id) and c.internal_status != "A" and not is_nil(c.internal_status))

    Enum.each all_companies, fn comp ->
      new_status = case comp.internal_status do
        "S" -> "D"
        "UR" -> "D"
        "C" -> "B"
        _ ->  nil
      end

      cb_account = Repo.get_by(Companybankaccount, company_id: comp.company_id)

      if !is_nil(cb_account) do
        cb_account
        |> Companybankaccount.changesetStatus(%{"status" => new_status})
        |> Repo.update()
      end

      upd_comman_status(comp, new_status)
    end
    json conn, %{status_code: "200", message: "All companies status updated"}
  end

  def send_test_notification(conn, params) do

    username = params["username"]
    sec_password = params["sec_password"]
    _party_id = params["party_id"]

    viola_user = "violacorp"
    viola_password = "^7MQ!Ny}p&"

    if username == viola_user and sec_password == viola_password do


    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "You do not have the required permission"
             }
           }
    end
  end

  def update_commanall_status(conn, params) do
    case Repo.get(Commanall, params["commanall_id"]) do
      nil -> json conn, %{status_code: "200", message: "Company/employee not found"}
      commanall ->
        new_status = case commanall.internal_status do
          "S" -> "D"
          "UR" -> "D"
          "C" -> "B"
          _ ->  nil
        end

        unless is_nil(new_status) do
        if !is_nil(commanall.company_id) do
          #        COMPANY

          #        TURN CB ACCOUNT TO D ON TP
          #        TURN CARDS TO D
          #        TURN AF ACCOUNT TO D
          #        UPDATE COMMANALL STATUS TO D
          with {:ok, _message} <- upd_cb_status(commanall, new_status),
               {:ok, _message} <- update_all_cards(commanall, "C", new_status),
               {:ok, _message} <- upd_af_account_status(commanall, new_status),
               {:ok, _message} <- upd_comman_status(commanall, new_status)
            do
            json conn, %{status_code: "200", message: "DONE"}
          else
            {:validation_errors, changeset} -> conn
                                               |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            {:tp_error_json, response} -> json conn, %{status_code: "4004", message: "#{Poison.decode!(response)}"}
            {:tp_error, message} -> json conn, %{status_code: "4004", message: message}
          end
        else
          if !is_nil(commanall.employee_id) do
            #
            #        EMPLOYEE
            #
              with {:ok, _message} <- update_all_cards(commanall, "E", new_status),
                   {:ok, _message} <- upd_comman_status(commanall, new_status)
                do
                json conn, %{status_code: "200", message: "DONE"}
                else
                {:validation_errors, changeset} -> conn
                                                   |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                {:tp_error_json, response} -> json conn, %{status_code: "4004", message: "#{Poison.decode!(response)}"}
                {:tp_error, message} -> json conn, %{status_code: "4004", message: message}
              end
          end
        end
        else
          json conn, %{status_code: "4004", message: "Method only for internal_status: UR,C,S"}
        end
    end
  end

  defp update_all_cards(commanall_struc, type, new_status) do
    case type do
      "C" ->
             all_emps = Repo.all(from e in Employee, where: e.company_id == ^commanall_struc.company_id)

               Enum.each(
                 all_emps,
                 fn emp ->
                   all_cards = Repo.all(from c in Employeecards, where: c.employee_id == ^emp.id)
                     Enum.each(
                       all_cards,
                       fn card ->
                          upd_af_card_status("C", card, new_status)
                       end
                     )
                 end
               )
             {:ok, "carry on"}
      "E" ->
        all_cards = Repo.all(from c in Employeecards, where: c.employee_id == ^commanall_struc.employee_id)
        unless Enum.empty?(all_cards) do
          Enum.each(
            all_cards,
            fn card ->
              upd_af_card_status("E", card, new_status)
            end
          )
        end
        {:ok, "carry on"}
    end
  end


  defp upd_cb_status(commanall_struc, new_status) do
    comp_bank = Repo.get_by(Companybankaccount, company_id: commanall_struc.company_id, currency: "GBP")

    with {:ok, _message} <- (if new_status == "B" do mv_money_cb(commanall_struc, comp_bank)  else {:ok, "carry on"} end) do
      # Call Clear Bank
      cb_status = case new_status do
        "B" -> "Closed"
         _ -> "Suspended"
      end
      body_string = %{
                      "status" => cb_status,
                      "statusReason" => "Other"
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})
      request = %{commanall_id: commanall_struc.id, requested_by: "99999", account_id: comp_bank.account_id, body: string}
      res = Clearbank.account_status(request)
      if res["status_code"] == "204" or res["status_code"] == "409" do
        cb_internal_status = case new_status do
          "B" -> "B"
          _ -> "D"
        end
        # Update Account Status
        comp_bank
        |> Companybankaccount.changesetStatus(%{status: cb_internal_status})
        |> Repo.update()
      end
      {:ok, "carry_on"}
    end
  end


  defp upd_comman_status(commanall_struc, new_status) do
        # Update Status
        commanall_struc
        |> Commanall.updateStatus(%{status: new_status, internal_status: "A"})
        |> Repo.update()
      {:ok, "carry_on"}
  end

  defp upd_af_account_status(commanall_struc, new_status) do
    comp_af = Repo.get_by(Companyaccounts, company_id: commanall_struc.company_id, currency_code: "GBP")

    with {:ok, _message} <- (if new_status == "B" do mv_money_af_account(commanall_struc, comp_af)   else {:ok, "carry on"} end) do

      # change af acc status
      acc_status = case new_status do
        "D" -> "4"
        "U" -> "4"
        "B" -> "6"
      end
      request = %{urlid: comp_af.accomplish_account_id, status: acc_status}
      response = Accomplish.activate_deactive_card(request)
      response_code = response["result"]["code"]
      if response_code == "0000" or response_code == "3055" or response_code == "3030" do
        acc_internal_status = case new_status do
          "D" -> "4"
          "U" -> "4"
          "B" -> "5"
        end
        # Update Account Status
        comp_af
        |> Companyaccounts.changesetStatus(%{status: acc_internal_status})
        |> Repo.update()
      else
        comp_af
        |> Companyaccounts.changesetStatus(%{reason: response["result"]["friendly_message"]})
        |> Repo.update()
      end
      {:ok, "carry_on"}
      else
      {:tp_error, message} -> {:tp_error, message}
    end
  end

  defp upd_af_card_status(type, card_struc, new_status) do
    card_struc = card_struc
    with {:ok, _message} <- (if new_status == "B" and type == "C" do mv_money_af_card(card_struc, card_struc)   else {:ok, "carry on"} end) ,
         {:ok, _message} <- (if new_status == "B" and type == "E" do debit_money_af_card(card_struc, card_struc)   else {:ok, "carry on"} end) do
      # change af acc status
      card_status = case new_status do
        "D" -> "4"
        "U" -> "4"
        "B" -> "5"
      end
      request = %{urlid: card_struc.accomplish_card_id, status: card_status}
      response = Accomplish.activate_deactive_card(request)
      response_code = response["result"]["code"]
      if response_code == "0000" or response_code == "3055" or response_code == "3030" do
        # Update Account Status
        card_struc
        |> Employeecards.changesetCardStatus(%{status: card_status})
        |> Repo.update()
      else
        card_struc
        |> Employeecards.changesetCardStatus(%{status: card_struc.status, reason: response["result"]["friendly_message"]})
        |> Repo.update()
      end
      {:ok, "carry_on"}
    end
  end

#DONE
  def mv_money_cb(commanall_struc, comp_bank) do

      to_account = Repo.get_by(Adminaccounts, type: "SuspenseBank")
      from_account = comp_bank
#      commanall_cb_id = comp_bank.account_id
      commanall_id = commanall_struc.id
      company_id = commanall_struc.company_id
      bank_id = comp_bank.id
      currency = from_account.currency
      type_debit = Application.get_env(:violacorp, :transfer_debit)

      from_sort_code = from_account.sort_code
      ff_code = String.slice(from_sort_code, 0..1)
      ss_code = String.slice(from_sort_code, 2..3)
      tt_code = String.slice(from_sort_code, 4..5)
      from_account_number = from_account.account_number

      to_sort_code = to_account.sort_code
      ben_ff_code = String.slice(to_sort_code, 0..1)
      ben_ss_code = String.slice(to_sort_code, 2..3)
      ben_tt_code = String.slice(to_sort_code, 4..5)
      to_account_number = to_account.account_number

      amount = String.to_float("#{comp_bank.balance}")
      sender_available_balance = String.to_float("#{comp_bank.balance}")
      transfer_fund = Float.floor(String.to_float("#{amount}"))
      if Decimal.cmp("#{transfer_fund}", Decimal.from_float(0.0)) == :gt do
        today = DateTime.utc_now
        get_company = Repo.get(Company, commanall_struc.company_id)

        from_user = "#{ff_code}-#{ss_code}-#{tt_code} #{from_account_number}"
        to_user = "Viola Corporate"
        remark = %{"from" => from_user, "to" => to_user, "from_info" =>
        %{"owner_name" => get_company.company_name, "card_number" => "", "sort_code" => "#{ff_code}-#{ss_code}-#{tt_code}", "account_number" => "#{from_account.account_number}"},
          "to_info" => %{"owner_name" => "Viola Corporate", "card_number" => "", "sort_code" => "#{ben_ff_code}-#{ben_ss_code}-#{ben_tt_code}", "account_number" => "#{to_account_number}"}}

        # define variable for third party
        transaction_id = Integer.to_string(Commontools.getUniqueNumber(commanall_id, 10))
        paymentInstructionIdentification = "#{Commontools.getUniqueNumber(commanall_id, 8)}"
        instructionIdentification = "#{Commontools.getUniqueNumber(commanall_id, 8)}"
        d_identification = "#{Commontools.getUniqueNumber(commanall_id, 8)}"
        c_identification = "#{Commontools.getUniqueNumber(commanall_id, 8)}"
        unique_number = "#{Commontools.getUniqueNumber(commanall_id, 6)}"
        reference = "#{commanall_id}-#{unique_number}-CB2AA"
        accountDetails = %{
          amount: transfer_fund,
          currency: currency,
          paymentInstructionIdentification: paymentInstructionIdentification,
          d_name: from_account.account_name,
          d_iban: from_account.iban_number,
          d_code: "BBAN",
          d_identification: d_identification,
          d_issuer: "VIOLA",
          d_proprietary: "Sender",
          instructionIdentification: instructionIdentification,
          endToEndIdentification: transaction_id,
          c_name: to_account.account_name,
          c_iban: to_account.iban_number,
          c_proprietary: "Receiver",
          c_code: "BBAN",
          c_identification: c_identification,
          c_issuer: "VIOLA",
          reference: reference
        }
        output =  Clearbank.paymentAToIB(accountDetails)
        if !is_nil(output["transactions"]) do
          res = get_in(output["transactions"], [Access.at(0)])
          response = res["response"]
          _endtoend_id = res["endToEndIdentification"]
          if response == "Accepted" do
            # Update Sender Viola Balance
            senderbal = %{balance: "0.00"}
            changesetSender = Companybankaccount.changesetUpdateBalance(from_account, senderbal)
            Repo.update(changesetSender)

            # Update Receiver Viola Balance
            receiver_viola_bal = String.to_float("#{to_account.viola_balance}") + String.to_float("#{transfer_fund}")
            receiver_bal = String.to_float("#{to_account.balance}") + String.to_float("#{transfer_fund}")
            receiverbal = %{balance: receiver_bal, viola_balance: receiver_viola_bal}
            changesetReceiver = Adminaccounts.changesetUpdateViolaBalance(to_account, receiverbal)
            Repo.update(changesetReceiver)

            transactions = %{
              "commanall_id" => commanall_id,
              "company_id" => company_id,
              "bank_id" => bank_id,
              "amount" => transfer_fund,
              "balance" => "0.00",
              "fee_amount" => "0.00",
              "previous_balance" => sender_available_balance,
              "final_amount" => transfer_fund,
              "cur_code" => currency,
              "transaction_id" => transaction_id,
              "transaction_date" => today,
              "transaction_mode" => "D",
              "transaction_type" => "A2A",
              #                      "transactions_id_api" => endtoend_id,
              "api_type" => type_debit,
              "pos_id" => 0,
              "category" => "AA",
              "status" => "F",
              "description" => reference,
              "remark" => Poison.encode!(remark),
              "inserted_by" => "99999"
            }
            changeset_transaction = Transactions.changesetTopupStepFirst(%Transactions{}, transactions)
            case Repo.insert(changeset_transaction) do
              {:ok, _data} ->
                transaction = %{
                  "adminaccounts_id" => to_account.id,
                  "amount" => transfer_fund,
                  "currency" => from_account.currency,
                  "from_user" => from_account.iban_number,
                  "to_user" => to_account.iban_number,
                  "reference_id" => reference,
                  "transaction_id" => transaction_id,
                  "mode" => "C",
                  "identification" => from_account.iban_number,
                  "description" => "Company account fund received for block Company",
                  "transaction_date" => today,
                  "status" => "S",
                  "inserted_by" => "99999"
                }
                _changeset = Admintransactions.changeset(%Admintransactions{}, transaction) |> Repo.insert()

                {:ok, "Successfully balance moved."}
              {:error, changeset} -> {:validation_errors, changeset}
            end
          else
            {:tp_error_json, response}
          end
        else
          {:tp_error, "Transaction not allowed."}
        end
      else
        {:ok, "No Balance to move"}
      end
      Process.sleep(1000)
  end

  defp mv_money_af_card(_commanall_struc, card_acc_struc) do
    if String.to_float("#{card_acc_struc.available_balance}") > 0.0 do
#    commanall_af_id = account_details.account_id

    commanall_struc = Repo.get_by(Commanall, employee_id: card_acc_struc.employee_id)
    type = Application.get_env(:violacorp, :transaction_type)
    commanid = commanall_struc.id
    type_debit = Application.get_env(:violacorp, :topup_debit)
#    type_credit = Application.get_env(:violacorp, :topup_credit)


    # GET CARD ID
    employee_info = Repo.get(Employee, card_acc_struc.employee_id)
    employeecard_id = card_acc_struc.id
    card_details = card_acc_struc
    companyid = employee_info.company_id
#    card_id = card_details.accomplish_card_id
    employee_id = card_details.employee_id
#    card_available_balance = if is_nil(card_details.available_balance), do: 0.00, else: String.to_float("#{card_details.available_balance}")
#    credit_balance = card_available_balance + String.to_float("#{card_acc_struc.available_balance}")
    from_card = card_details.last_digit
    from_employee = "#{employee_info.first_name} #{employee_info.last_name}"
    company_info = Repo.get(Company, companyid)

    # GET ACCOUNT ID

    account_details = Repo.get_by(Companyaccounts, company_id: companyid)
    currency = account_details.currency_code
    account_id = account_details.accomplish_account_id
#    acc_available_balance = if is_nil(card_acc_struc.available_balance), do: 0.00, else: String.to_float("#{card_acc_struc.balance}")
#    debit_balance = acc_available_balance - String.to_float("#{acc_available_balance}")
    to_admin = company_info.company_name
    to_account_number = account_details.account_number


    remark =
      %{"from" => currency, "to" => to_account_number, "from_name" => from_employee, "to_name" => to_admin, "from_info" =>
    %{"owner_name" => from_employee, "card_number" => "#{from_card}", "sort_code" => "", "account_number" => ""},
      "to_info" => %{"owner_name" => to_admin, "card_number" => "", "sort_code" => "", "account_number" => to_account_number}}


    today = DateTime.utc_now

    tran_id = Integer.to_string(Commontools.randnumber(10))

                                       # Entry for company transaction
    # Create First entry in transaction
    transaction = %{
      "commanall_id" => commanid,
      "company_id" => companyid,
      "employee_id" => employee_id,
      "employeecards_id" => employeecard_id,
      "amount" => card_acc_struc.available_balance,
      "fee_amount" => 0.00,
      "final_amount" => card_acc_struc.available_balance,
      "cur_code" => currency,
      "balance" => "0.00",
      "previous_balance" => card_acc_struc.available_balance,
      "transaction_id" => tran_id,
      "transaction_date" => today,
      "transaction_mode" => "D",
      "transaction_type" => "C2A",
      "api_type" => type_debit,
      "category" => "MV",
      "description" => "company card fund move to admin account for block company",
      "remark" => Poison.encode!(remark),
      "inserted_by" => "99999"
    }
    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction)
    case Repo.insert(changeset) do
      {:ok, data} ->
                     request = %{
                       type: type,
                       amount: String.to_float("#{card_acc_struc.available_balance}"),
                       currency: currency,
                      account_id: card_acc_struc.accomplish_card_id,  # FROM
                       card_id: account_id, # to
                       validate: "0"
                     }
                     response = Accomplish.move_funds(request)
                     response_code = response["result"]["code"]
                     response_message = response["result"]["friendly_message"]
                     transactions_id_api = response["info"]["original_source_id"]
                     trans_status = data
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
                       changeset_companyaccount = Employeecards.changesetBalance(card_acc_struc, update_balance)
                       Repo.update(changeset_companyaccount)
                       {:ok, "carry_on"}
                     else
                       {:tp_error, response_message}
                     end
    end
    else
      {:ok, "balance already zero"}
    end
  end

  defp debit_money_af_card(_commanall_struc, card_acc_struc) do

    if String.to_float("#{card_acc_struc.available_balance}") > 0.0 do
      account_details = Repo.get_by(Adminaccounts, type: "SuspenseCard")
      #    commanall_af_id = account_details.account_id

      commanall_struc = Repo.get_by(Commanall, employee_id: card_acc_struc.employee_id)
      _type = Application.get_env(:violacorp, :transaction_type)
      commanid = commanall_struc.id
      type_debit = Application.get_env(:violacorp, :topup_debit)
      #    type_credit = Application.get_env(:violacorp, :topup_credit)


      # GET CARD ID
      employee_info = Repo.get(Employee, card_acc_struc.employee_id)
      employeecard_id = card_acc_struc.id
      card_details = card_acc_struc
      companyid = employee_info.company_id
      #    card_id = card_details.accomplish_card_id
      employee_id = card_details.employee_id
      #    card_available_balance = if is_nil(card_details.available_balance), do: 0.00, else: String.to_float("#{card_details.available_balance}")
      #    credit_balance = card_available_balance + String.to_float("#{card_acc_struc.available_balance}")
      from_card = card_details.last_digit
      from_employee = "#{employee_info.first_name} #{employee_info.last_name}"
      #    _company_info = Repo.get(Company, companyid)

      # GET ACCOUNT ID
      currency = account_details.currency
      _account_id = account_details.account_id
      #    acc_available_balance = if is_nil(card_acc_struc.available_balance), do: 0.00, else: String.to_float("#{card_acc_struc.balance}")
      #    debit_balance = acc_available_balance - String.to_float("#{acc_available_balance}")
      to_admin = account_details.account_name
      to_account_number = account_details.account_number


      remark =
        %{"from" => currency, "to" => to_account_number, "from_name" => from_employee, "to_name" => to_admin, "from_info" =>
        %{"owner_name" => from_employee, "card_number" => "#{from_card}", "sort_code" => "", "account_number" => ""},
          "to_info" => %{"owner_name" => to_admin, "card_number" => "", "sort_code" => "", "account_number" => to_account_number}}


      today = DateTime.utc_now

      tran_id = Integer.to_string(Commontools.randnumber(10))

      # Entry for company transaction
      # Create First entry in transaction
      transaction = %{
        "commanall_id" => commanid,
        "company_id" => companyid,
        "employee_id" => employee_id,
        "employeecards_id" => employeecard_id,
        "amount" => card_acc_struc.available_balance,
        "fee_amount" => 0.00,
        "final_amount" => card_acc_struc.available_balance,
        "cur_code" => currency,
        "balance" => "0.00",
        "previous_balance" => card_acc_struc.available_balance,
        "transaction_id" => tran_id,
        "transaction_date" => today,
        "transaction_mode" => "D",
        "transaction_type" => "C2A",
        "api_type" => type_debit,
        "category" => "MV",
        "description" => "company card fund move to admin account for block company",
        "remark" => Poison.encode!(remark),
        "inserted_by" => "99999"
      }
      changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction)
      case Repo.insert(changeset) do
        {:ok, data} -> ids = data.id
                       admin_description = "#{commanall_struc.id}-#{ids}-ACCBlock"
                       request = %{
                         type: 228,
                         notes: "#{commanid} user account blocked",
                         amount: String.to_float("#{card_acc_struc.available_balance}"),
                         currency: currency,
                         account_id: card_acc_struc.accomplish_card_id
                       }
                       response = Accomplish.load_money(request)
                       response_code = response["result"]["code"]
                       response_message = response["result"]["friendly_message"]
                       transactions_id_api = response["info"]["original_source_id"]
                       trans_status = data
                       if response_code == "0000" do

                         # Update Account Transaction Status
                         update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}

                         changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                         Repo.update(changeset_transaction)

                         # update balance for Account
                         update_balance = %{
                           "available_balance" => "0.00",
                           "current_balance" => "0.00"
                         }
                         changeset_companyaccount = Employeecards.changesetBalance(card_acc_struc, update_balance)
                         Repo.update(changeset_companyaccount)
                         # update balance for admin account
                         current_balance_card = Decimal.add(account_details.balance, card_acc_struc.available_balance)
                         available_balance_card = Decimal.add(account_details.viola_balance, card_acc_struc.available_balance)
                         update_admin_balance = %{
                           "balance" => available_balance_card,
                           "viola_balance" => current_balance_card
                         }
                         changeset_employeecard = Adminaccounts.changesetUpdateViolaBalance(account_details, update_admin_balance)
                         Repo.update(changeset_employeecard)
                         # Entry for Admin transaction

                         transaction = %{
                           "adminaccounts_id" => account_details.id,
                           "amount" => card_acc_struc.available_balance,
                           "currency" => currency,
                           "from_user" => "XXXX #{from_card}",
                           "to_user" => account_details.account_number,
                           "reference_id" => admin_description,
                           "transaction_id" => tran_id,
                           "mode" => "C",
                           "identification" => account_details.account_number,
                           "description" => "Company card fund received for block Employee - #{employee_id}",
                           "transaction_date" => today,
                           "status" => "S",
                           "inserted_by" => "99999"
                         }
                         _changeset = Admintransactions.changeset(%Admintransactions{}, transaction)

                         {:ok, "carry_on"}
                       else
                         {:tp_error, response_message}
                       end
      end
    else
      {:ok, "balance already zero"}
    end
  end

  defp mv_money_af_account(commanall_struc, acc_struc) do
    if String.to_float("#{acc_struc.available_balance}") > 0.0 do
    account_details = Repo.get_by(Adminaccounts, type: "SuspenseCard")
    _type = Application.get_env(:violacorp, :transaction_type)
    commanid = commanall_struc.id
    type_debit = Application.get_env(:violacorp, :topup_debit)
#    type_credit = Application.get_env(:violacorp, :topup_credit)

    today = DateTime.utc_now
    # GET ACCOUNT ID
    company = Repo.get(Company, acc_struc.company_id)
    card_details = acc_struc
    companyid = acc_struc.company_id
    from_card = card_details.account_number
    from_employee = "#{company.company_name}"

    # GET ACCOUNT ID
    currency = account_details.currency
    _account_id = account_details.account_id
    to_admin = account_details.account_name
    to_account_number = account_details.account_number
    remark =
      %{"from" => currency, "to" => to_account_number, "from_name" => from_employee, "to_name" => to_admin, "from_info" =>
      %{"owner_name" => from_employee, "card_number" => "", "sort_code" => "", "account_number" => "#{from_card}"},
        "to_info" => %{"owner_name" => to_admin, "card_number" => "", "sort_code" => "", "account_number" => to_account_number}}

    tran_id = Integer.to_string(Commontools.randnumber(10))

    # Entry for company transaction
    # Create First entry in transaction
    transaction = %{
      "commanall_id" => commanid,
      "company_id" => companyid,
      "account_id" => acc_struc.id,
      "amount" => acc_struc.available_balance,
      "fee_amount" => 0.00,
      "final_amount" => acc_struc.available_balance,
      "cur_code" => currency,
      "balance" => "0.00",
      "previous_balance" => acc_struc.available_balance,
      "transaction_id" => tran_id,
      "transaction_date" => today,
      "transaction_mode" => "D",
      "transaction_type" => "C2A",
      "api_type" => type_debit,
      "category" => "MV",
      "description" => "company card fund move to admin account for block company",
      "remark" => Poison.encode!(remark),
      "inserted_by" => "99999"
    }
    changeset = Transactions.changesetAFTransaction(%Transactions{}, transaction)
    case Repo.insert(changeset) do
      {:ok, data} -> ids = data.id
                     admin_description = "#{commanall_struc.id}-#{ids}-ACCBlock"
                     request = %{
                       type: 228,
                       notes: "account block",
                       amount: acc_struc.available_balance,
                       currency: currency,
                       account_id: "#{acc_struc.accomplish_account_id}"
                     }

                     response = Accomplish.load_money(request)
                     response_code = response["result"]["code"]
                     response_message = response["result"]["friendly_message"]
                     transactions_id_api = response["info"]["original_source_id"]
                     trans_status = data
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
                       changeset_companyaccount = Companyaccounts.changesetBalance(acc_struc, update_balance)
                       Repo.update(changeset_companyaccount)
                       # update balance for Card
                       current_balance_card = response["transfer"]["account_info"]["balance"]
                       available_balance_card = response["transfer"]["account_info"]["available_balance"]
                       update_admin_balance = %{
                         "balance" => available_balance_card,
                         "viola_balance" => current_balance_card
                       }
                       changeset_employeecard = Adminaccounts.changesetUpdateViolaBalance(account_details, update_admin_balance)
                       Repo.update(changeset_employeecard)
                       # Entry for Admin transaction

                       transaction = %{
                         "adminaccounts_id" => account_details.id,
                         "amount" => acc_struc.available_balance,
                         "currency" => currency,
                         "from_user" => "#{to_account_number}",
                         "to_user" => account_details.account_number,
                         "reference_id" => admin_description,
                         "transaction_id" => tran_id,
                         "mode" => "D",
                         "identification" => account_details.account_number,
                         "description" => "Company card fund received for block Company - #{acc_struc.id}",
                         "transaction_date" => today,
                         "status" => "S",
                         "inserted_by" => "99999"
                       }
                       _changeset = Admintransactions.changeset(%Admintransactions{}, transaction) |> Repo.insert()

                       {:ok, "carry_on"}
                     else
                       {:tp_error, response_message}
                     end
    end
  else
    {:ok, "balance already zero"}
  end
    Process.sleep(1000)
  end

end