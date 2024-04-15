defmodule ViolacorpWeb.Thirdparty.ThirdpartyController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  require Logger

  alias Violacorp.Repo
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Companieshouse.Company

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Fourstopcallback
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Otp

  @doc"COMPANIES HOUSE"

  def getCompanyDetails(conn, params)do

    a = params["companyid"]
    b = Company.getCompanyDetails(a)
    json conn, b
  end

  def getCompanyOfficers(conn, params)do
    a = params["companyid"]
    b = Company.getCompanyOfficers(a)
    json conn, b
  end

  def getCompanyAddress(conn, params)do
    a = params["companyid"]
    b = Company.getCompanyAddress(a)
    json conn, b
  end

  def getCompanyInsolvency(conn, params)do
    a = params["companyid"]
    b = Company.getCompanyInsolvency(a)
    json conn, b
  end

  def getCompanyFilingHistory(conn, params)do
    a = params["companyid"]
    b = Company.getCompanyFilingHistory(a)
    json conn, b
  end

  @doc "Get Details for exist Employee"
  def check_cards(conn, params) do
    unless map_size(params) == 0 do

      username = params["username"]
      password = params["sec_password"]
      commanall_id = params["commanall_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

          commandata = Repo.one from commanall in Commanall, where: commanall.id == ^commanall_id and not is_nil(commanall.employee_id) and not is_nil(commanall.accomplish_userid),
                                                             select: %{
                                                               id: commanall.id,
                                                               acc_id: commanall.accomplish_userid,
                                                               employee_id: commanall.employee_id
                                                             }
          if commandata == nil do
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Employee not Found!"
                   }
                 }
          else
            employee_id = commandata.employee_id
            response = Accomplish.get_user(commandata.acc_id)

            response_code = response["result"]["code"]
            response_message = response["result"]["friendly_message"]

            if response_code == "0000" do

              Enum.each response["account"], fn post ->
                accomplish_card_id = post["info"]["id"]
                employee = Repo.one from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id,
                                                             select: %{
                                                               id: e.id
                                                             }

                if employee == nil do
                  currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^post["info"]["currency"],
                                                                 select: c.id
                  card_number = post["info"]["number"]
                  last_digit = Commontools.lastfour(card_number)
                  status = post["info"]["status"]
                  employeecard = %{
                    "employee_id" => employee_id,
                    "currencies_id" => currencies_id,
                    "currency_code" => post["info"]["currency"],
                    "last_digit" => "#{last_digit}",
                    "available_balance" => post["info"]["available_balance"],
                    "current_balance" => post["info"]["balance"],
                    "accomplish_card_id" => post["info"]["id"],
                    "bin_id" => post["info"]["bin_id"],
                    "expiry_date" => post["info"]["security"]["expiry_date"],
                    "source_id" => post["info"]["original_source_id"],
                    "activation_code" => post["info"]["security"]["activation_code"],
                    "status" => status,
                    "card_type" => "P",
                    "inserted_by" => commandata.id
                  }
                  changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
                  Repo.insert(changeset_comacc)
                  if status == "12" do
                    commanall_data = Repo.get!(Commanall, commandata.id)
                    card_request = %{"card_requested" => "Y"}
                    changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
                    Repo.update(changeset_commanall)
                  end
                  getemployee = Repo.get!(Employee, employee_id)
                  [count_card] = Repo.all from d in Employeecards,
                                          where: d.employee_id == ^employee_id and (
                                            d.status == "1" or d.status == "4" or d.status == "12"),
                                          select: %{
                                            count: count(d.id)
                                          }
                  new_number = %{"no_of_cards" => count_card.count}
                  cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                  Repo.update(cards_changeset)
                end
              end
              json conn,
                   %{
                     status_code: "200",
                     data: %{
                       message: response_message
                     }
                   }
            else
              json conn,
                   %{
                     status_code: "5004",
                     errors: %{
                       message: response_message
                     }
                   }
            end
          end
      else
        json conn, %{status_code: "4002", errors: %{message: "You have not permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Fee Account on Clear Bank"
  def feeAccount(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        admin_id = params["id"]
        acc_type = "Fee"

        # Call to Clear Bank for Account Create
        checkAccount = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "A")

        if is_nil(checkAccount) do

          sortcode =  Application.get_env(:violacorp, :sortcode)

          # Call Clear Bank
          body_string = %{
                          "accountName" => "Fee Corporate Account",
                          "owner" => %{"name" => "Fee Viola Corporate"},
                          "sortCode" => sortcode
                        }
                        |> Poison.encode!
          string = ~s(#{body_string})
          response_bank =  Clearbank.create_admin_account(string)

          if !is_nil(response_bank["account"]) do

            iban = response_bank["account"]["iban"]
            account_id = response_bank["account"]["id"]
            account_name = response_bank["account"]["name"]
            bban = response_bank["account"]["bban"]
            type = response_bank["account"]["type"]

            res = get_in(response_bank["account"]["balances"], [Access.at(0)])
            status = res["status"]
            currency = res["currency"]
            balance = res["amount"]

            lan = String.length(iban)
            #    iso = String.slice(string, 0..1)
            #    iban = String.slice(string, 2..3)
            bank_code = String.slice(iban, 4..7)
            sort_code = String.slice(iban, 8..13)
            account_number = String.slice(iban, 14..lan)

            bankAccount = %{
              "administratorusers_id" => admin_id,
              "account_id" => account_id,
              "account_number" => account_number,
              "account_name" => account_name,
              "iban_number" => iban,
              "bban_number" => bban,
              "currency" => currency,
              "balance" => balance,
              "viola_balance" => balance,
              "sort_code" => sort_code,
              "bank_code" => bank_code,
              "bank_type" => type,
              "bank_status" => status,
              "status" => "A",
              "type" => acc_type,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "inserted_by" => admin_id
            }

            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changeset(%Adminaccounts{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} ->
                  json conn, %{ status_code: "200", message: "Fee Account Created." }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Adminaccounts.changeset(get_account, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} ->
                  "success"
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          else
            bankAccount = %{
              "administratorusers_id" => admin_id,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "status" => "F",
              "type" => acc_type,
              "inserted_by" => admin_id
            }
            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, bankAccount)
              Repo.insert(changeset)
            else
              changeset = Adminaccounts.changesetFailed(get_account, bankAccount)
              Repo.update(changeset)
            end
            response = response_bank["title"]
            json conn, %{status_code: "5001", errors: %{message: response}}
          end
        else
          json conn, %{status_code: "4002", errors: %{message: "Fee Account already exist."}}
        end

      else
        json conn, %{status_code: "4002", errors: %{message: "You have not permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Accomplish Account on Clear Bank"
  def accomplishAccount(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        admin_id = params["id"]
        acc_type = "Accomplish"

        # Call to Clear Bank for Account Create
        checkAccount = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "A")

        if is_nil(checkAccount) do

          sortcode =  Application.get_env(:violacorp, :sortcode)
          # Call Clear Bank
          body_string = %{
                          "accountName" => "Accomplish Corporate Account",
                          "owner" => %{"name" => "Acc Viola Corporate"},
                          "sortCode" => sortcode
                        }
                        |> Poison.encode!
          string = ~s(#{body_string})
          response_bank =  Clearbank.create_admin_account(string)

          if !is_nil(response_bank["account"]) do

            iban = response_bank["account"]["iban"]
            account_id = response_bank["account"]["id"]
            account_name = response_bank["account"]["name"]
            bban = response_bank["account"]["bban"]
            type = response_bank["account"]["type"]

            res = get_in(response_bank["account"]["balances"], [Access.at(0)])
            status = res["status"]
            currency = res["currency"]
            balance = res["amount"]

            lan = String.length(iban)
            #    iso = String.slice(string, 0..1)
            #    iban = String.slice(string, 2..3)
            bank_code = String.slice(iban, 4..7)
            sort_code = String.slice(iban, 8..13)
            account_number = String.slice(iban, 14..lan)

            bankAccount = %{
              "administratorusers_id" => admin_id,
              "account_id" => account_id,
              "account_number" => account_number,
              "account_name" => account_name,
              "iban_number" => iban,
              "bban_number" => bban,
              "currency" => currency,
              "balance" => balance,
              "viola_balance" => balance,
              "sort_code" => sort_code,
              "bank_code" => bank_code,
              "bank_type" => type,
              "bank_status" => status,
              "status" => "A",
              "type" => acc_type,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "inserted_by" => admin_id
            }

            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changeset(%Adminaccounts{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} ->
                  json conn, %{ status_code: "200", message: "Accomplish Account Created." }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Adminaccounts.changeset(get_account, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} ->
                  "success"
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          else
            bankAccount = %{
              "administratorusers_id" => admin_id,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "status" => "F",
              "type" => acc_type,
              "inserted_by" => admin_id
            }
            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, bankAccount)
              Repo.insert(changeset)
            else
              changeset = Adminaccounts.changesetFailed(get_account, bankAccount)
              Repo.update(changeset)
            end
            response = response_bank["title"]
            json conn, %{status_code: "5001", errors: %{message: response}}
          end
        else
          json conn, %{status_code: "4002", errors: %{message: "Accomplish Account already exist."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You have not permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Violamoney Account on Clear Bank"
  def violamoneyAccount(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        admin_id = params["id"]
        acc_type = "Violamoney"

        # Call to Clear Bank for Account Create
        checkAccount = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "A")

        if is_nil(checkAccount) do

          sortcode =  Application.get_env(:violacorp, :sortcode)
          # Call Clear Bank
          body_string = %{
                          "accountName" => "Violamoney",
                          "owner" => %{"name" => "Violamoney Corporate"},
                          "sortCode" => sortcode
                        }
                        |> Poison.encode!
          string = ~s(#{body_string})
          response_bank =  Clearbank.create_admin_account(string)

          if !is_nil(response_bank["account"]) do

            iban = response_bank["account"]["iban"]
            account_id = response_bank["account"]["id"]
            account_name = response_bank["account"]["name"]
            bban = response_bank["account"]["bban"]
            type = response_bank["account"]["type"]

            res = get_in(response_bank["account"]["balances"], [Access.at(0)])
            status = res["status"]
            currency = res["currency"]
            balance = res["amount"]

            lan = String.length(iban)
            #    iso = String.slice(string, 0..1)
            #    iban = String.slice(string, 2..3)
            bank_code = String.slice(iban, 4..7)
            sort_code = String.slice(iban, 8..13)
            account_number = String.slice(iban, 14..lan)

            bankAccount = %{
              "administratorusers_id" => admin_id,
              "account_id" => account_id,
              "account_number" => account_number,
              "account_name" => account_name,
              "iban_number" => iban,
              "bban_number" => bban,
              "currency" => currency,
              "balance" => balance,
              "viola_balance" => balance,
              "sort_code" => sort_code,
              "bank_code" => bank_code,
              "bank_type" => type,
              "bank_status" => status,
              "status" => "A",
              "type" => acc_type,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "inserted_by" => admin_id
            }

            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changeset(%Adminaccounts{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} ->
                  json conn, %{ status_code: "200", message: "Violamoney Account Created." }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Adminaccounts.changeset(get_account, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} ->
                  "success"
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          else
            bankAccount = %{
              "administratorusers_id" => admin_id,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "status" => "F",
              "type" => acc_type,
              "inserted_by" => admin_id
            }
            get_account = Repo.get_by(Adminaccounts, administratorusers_id: admin_id, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, bankAccount)
              Repo.insert(changeset)
            else
              changeset = Adminaccounts.changesetFailed(get_account, bankAccount)
              Repo.update(changeset)
            end
            response = response_bank["title"]
            json conn, %{status_code: "5001", errors: %{message: response}}
          end
        else
          json conn, %{status_code: "4002", errors: %{message: "Violamoney Account already exist."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You have not permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Suspense Account on Clear Bank"
  def suspenseAccount(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        admin_id = params["id"]
        acc_type = "SuspenseBank"

        # Call to Clear Bank for Account Create
        checkAccount = Repo.get_by(Adminaccounts, type: acc_type, status: "A")

        if is_nil(checkAccount) do

          sortcode =  Application.get_env(:violacorp, :sortcode)
          # Call Clear Bank
          body_string = %{
                          "accountName" => "Suspense Corporate Account",
                          "owner" => %{"name" => "Viola Corporate Suspense"},
                          "sortCode" => sortcode
                        }
                        |> Poison.encode!
          string = ~s(#{body_string})
          response_bank =  Clearbank.create_admin_account(string)

          if !is_nil(response_bank["account"]) do

            iban = response_bank["account"]["iban"]
            account_id = response_bank["account"]["id"]
            account_name = response_bank["account"]["name"]
            bban = response_bank["account"]["bban"]
            type = response_bank["account"]["type"]

            res = get_in(response_bank["account"]["balances"], [Access.at(0)])
            status = res["status"]
            currency = res["currency"]
            balance = res["amount"]

            lan = String.length(iban)
            #    iso = String.slice(string, 0..1)
            #    iban = String.slice(string, 2..3)
            bank_code = String.slice(iban, 4..7)
            sort_code = String.slice(iban, 8..13)
            account_number = String.slice(iban, 14..lan)

            bankAccount = %{
              "administratorusers_id" => admin_id,
              "account_id" => account_id,
              "account_number" => account_number,
              "account_name" => account_name,
              "iban_number" => iban,
              "bban_number" => bban,
              "currency" => currency,
              "balance" => balance,
              "viola_balance" => balance,
              "sort_code" => sort_code,
              "bank_code" => bank_code,
              "bank_type" => type,
              "bank_status" => status,
              "status" => "A",
              "type" => acc_type,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "inserted_by" => admin_id
            }

            get_account = Repo.get_by(Adminaccounts, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changeset(%Adminaccounts{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} ->
                  json conn, %{ status_code: "200", message: "Viola Corporate Suspense Account Created." }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Adminaccounts.changeset(get_account, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} ->
                  "success"
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          else
            bankAccount = %{
              "administratorusers_id" => admin_id,
              "request" => body_string,
              "response" => Poison.encode!(response_bank),
              "status" => "F",
              "type" => acc_type,
              "inserted_by" => admin_id
            }
            get_account = Repo.get_by(Adminaccounts, type: acc_type, status: "F")
            if is_nil(get_account) do
              changeset = Adminaccounts.changesetFailed(%Adminaccounts{}, bankAccount)
              Repo.insert(changeset)
            else
              changeset = Adminaccounts.changesetFailed(get_account, bankAccount)
              Repo.update(changeset)
            end
            response = response_bank["title"]
            json conn, %{status_code: "5001", errors: %{message: response}}
          end
        else
          json conn, %{status_code: "4002", errors: %{message: "Viola Corporate Suspense Account already exist."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You have not permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def resetOtpLimit(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_username and password == viola_password do

        getinfo = Repo.all(from o in Otp, where: o.commanall_id == ^params["commanall_id"] and o.status == "A", select: o)
        if getinfo != [] do

          Enum.each getinfo, fn data ->
            generate_otp = Commontools.randnumber(6)

            otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
            new_otp = Poison.encode!(otp_code_map)

            otpmap = %{
              "otp_code" => new_otp,
            }
            changeset = Otp.attempt_changeset(data, otpmap)

            Repo.update(changeset)
          end
          json conn, %{status_code: "200", message: "Success! OTP limit reset done"}
        else
          conn
          |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :otpNotFound)
        end
      else
        json conn,
             %{
               status_code: "4002",
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

  def get_accomplish_cb_transactions(conn, params) do
    username = params["username"]
    password = params["sec_password"]
    request_id = params["request_id"]
    viola_username = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_username and password == viola_password do
      case Repo.get_by(Adminaccounts, type: "Accomplish") do
        nil -> json conn, %{status_code: "4004", errors: %{message: "account not found"}}
        account -> with true <- !is_nil(account.account_id) do

                     endpoint = "#{account.account_id}/Transactions/"

                     response = Clearbank.get_transaction(endpoint)
                     Enum.each response["transactions"], fn transactions ->

                       already_exists = transaction_exist(account.id, transactions)
                       case already_exists do
                         "true" -> ""
                         "false" -> add_transaction(transactions, account, request_id)
                       end
                     end

                     json conn, %{status_code: "200", message: "Success! Transaction Refreshed."}
                   else
                     false -> json conn, %{status_code: "4004", errors: %{message: "account id not found"}}
                   end
      end
    else
      json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
    end
  end

  def get_fee_cb_transactions(conn, params) do
    username = params["username"]
    password = params["sec_password"]
    request_id = params["request_id"]
    viola_username = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_username and password == viola_password do
      case Repo.get_by(Adminaccounts, type: "Fee") do
        nil -> json conn, %{status_code: "4004", errors: %{message: "account not found"}}
        account -> with true <- !is_nil(account.account_id) do

                     endpoint = "#{account.account_id}/Transactions/"

                     response = Clearbank.get_transaction(endpoint)
                     Enum.each response["transactions"], fn transactions ->

                       already_exists = transaction_exist(account.id, transactions)
                       case already_exists do
                         "true" -> ""
                         "false" -> add_transaction(transactions, account, request_id)
                       end
                     end

                     json conn, %{status_code: "200", message: "Success! Transaction Refreshed."}
                   else
                     false -> json conn, %{status_code: "4004", errors: %{message: "account id not found"}}
                   end
      end
    else
      json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
    end
  end

  defp add_transaction(clearbank_transaction, account, request_id) do

    counterpart = cond do
      Map.has_key?(clearbank_transaction["counterpartAccount"], "identification") ->
        cond do
          Map.has_key?(
            clearbank_transaction["counterpartAccount"]["identification"],
            "iban"
          ) -> "iban available"
          true -> "iban not available"
        end
      true -> "identification not available"
    end

    transaction_status = case clearbank_transaction["status"] do
                          "ACSC" -> "S"
                          _ -> "D"
                        end

    transaction_mode = case clearbank_transaction["debitCreditCode"] do
                        "DBIT" -> "D"
                        "CRDT" -> "C"
                      end

    inserted_by = if !is_nil(request_id) or request_id != "", do: request_id, else: account.administratorusers_id
    transaction = %{
      "adminaccounts_id" => account.id,
      "amount" => clearbank_transaction["amount"]["instructedAmount"],
      "currency" => clearbank_transaction["amount"]["currency"],
      "transaction_date" => clearbank_transaction["transactionTime"],
      "reference_id" => clearbank_transaction["transactionReference"],
      "transaction_id" => clearbank_transaction["transactionId"],
      "api_status" => clearbank_transaction["status"],
      "end_to_en_identifier" => clearbank_transaction["endToEndIdentifier"],
      "mode" => transaction_mode,
      "response" => Poison.encode!(clearbank_transaction),
      "status" => transaction_status,
      "inserted_by" => inserted_by
    }
    new_transaction = case counterpart do
      "iban available" ->

        # ADD TRANSACTION WITH IBAN INFO
        iban = clearbank_transaction["counterpartAccount"]["identification"]["iban"]

        additional = case clearbank_transaction["debitCreditCode"] do
          "DBIT" -> %{"from_user" => account.iban_number, "to_user" => iban, "identification" => iban}
          "CRDT" -> %{"from_user" => iban, "to_user" => account.iban_number, "identification" => iban}
          _ -> ""
        end

        Map.merge(transaction, additional)
      _ -> transaction
    end
    changeset = Admintransactions.changeset(%Admintransactions{}, new_transaction)
    Repo.insert(changeset)
  end

  defp transaction_exist(adminaccount_id, clearbank_transaction) do
    check = case clearbank_transaction["debitCreditCode"] do
      "DBIT" ->
        Repo.get_by(Admintransactions, adminaccounts_id: adminaccount_id, reference_id: clearbank_transaction["transactionReference"], mode: "D")
      "CRDT" ->
        Repo.get_by(Admintransactions, adminaccounts_id: adminaccount_id, reference_id: clearbank_transaction["transactionReference"], mode: "C")
    end
    case check do
      nil -> "false"
      _ -> "true"
    end
  end


  def fourstop_callback(conn, params) do
    Logger.warn "4Stop Listener: #{~s(#{Poison.encode!(params)})}"
    reference_id = params["reference_id"]
#    if File.exists?("tmp_kyc_callback/") do
#      :ok
#    else
#      File.mkdir("tmp_kyc_callback/")
#    end

    filename = "tmp_kyc_callback/#{reference_id}.txt"
    # file read
    today = DateTime.utc_now()
    response = if File.exists?(filename) do
                  output = File.read!(filename)
                  Poison.decode!(output) ++ [%{"#{today}" => params}]
               else
                  [%{"#{today}" => params}]
               end
    File.write(filename, Poison.encode!(response))

    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)

    local_image = File.read!("#{filename}")

    ExAws.S3.put_object(image_bucket, "#{mode}/#{reference_id}.txt", local_image)
    |> ExAws.request()

    aws_path = "https://#{image_bucket}.#{region}/#{mode}/#{reference_id}.txt"

    case Repo.get_by(Fourstopcallback, reference_id: reference_id) do
      nil ->
        Logger.warn("#{reference_id} 4stop not found kyc")
        :ok
      kyc ->

      [doc] = Poison.decode!(kyc.response) |> Enum.filter(fn x -> kyc.reference_id == reference_id end)
      if !Enum.empty?(doc) do
        doc_id = doc["doc_id"]
        decision = params["data"]["decision"]

        fstop_record = Repo.get_by(Fourstop, stopid: kyc.stopid)

        status = case decision do
          "Approved" -> "A"
          "Alert" -> "R"
          "Refer" -> "RF"
          _ -> "R"
        end

        fstop_record
        |> Fourstop.update_status(%{"status" => status})
        |> Repo.update()

        if is_nil(fstop_record.director_id) do
          %Kycdocuments{id: doc_id}
          else
          %Kycdirectors{id: doc_id}
          end   |> Ecto.Changeset.cast(
                                   %{
                                     "status" => status
                                   },
                                   [:status]
                         )
        |> Repo.update()
        end
    end
    json conn, %{status_code: "200", message: "Done"}
  end
end