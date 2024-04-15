defmodule  ViolacorpWeb.Admin.Comman.ThirdPartyController do
  use Phoenix.Controller

  alias Violacorp.Repo
#  import Ecto.Query
  alias Violacorp.Models.ThirdParty
  alias Violacorp.Models.Comman
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools

  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Adminaccounts

  # Company Balance Refresh
  def admincompanyRefreshBalance(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
          commanall = ThirdParty.get_accomplish_userid(params)
          if !is_nil(commanall)do
                json conn, commanall
           else
             json conn, %{status_code: "4004",errors: %{message: "Account not found!"}}
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
  end
  def onlineAccountRefreshBalance(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      case ThirdParty.get_company_online_account(params) do
        {:ok, _message} -> json conn, %{status_code: "200", message: "Balance Updated Successfully"}
        {:acoount_not_exist, _message} -> json conn, %{status_code: "4004",errors: %{message: "Account not found!"}}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def onlineAccountRefreshBalanceV1(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      case ThirdParty.get_company_online_account_v1(params) do
        {:ok, _message} -> json conn, %{status_code: "200", message: "Balance Updated Successfully"}
        {:acoount_not_exist, _message} -> json conn, %{status_code: "4004",errors: %{message: "Account not found!"}}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def employeeCardRefreshBalance(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      get_card = ThirdParty.employeeRefreshBalance(params)
      if !is_nil(get_card) do
        json conn, get_card
      else
        json conn, %{status_code: "4004",errors: %{message: "Card not found!"}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def cardManagementManualtop(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  def cardManagementManualtop(conn, params) do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      check =  Comman.checkOwnPassword(params, admin_id)
      if !is_nil(check) do
            response = ThirdParty.manualTopUp(params)
            if !is_nil(response) do
              json conn, response
            else
             json conn, response
            end
      else
        json conn,%{status_code: "4003", errors: %{password: "Not Matched"}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def refundAdminCBTransaction(conn, params) do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      check =  Comman.checkOwnPassword(params, admin_id)
      if !is_nil(check) do


        admin_trans_id = params["admin_transaction_id"]

        case Repo.get_by(Admintransactions, id: admin_trans_id, mode: "c") do
          nil -> json conn, %{status_code: "4004", errors: %{
            message: "Admin transaction not found"}
          }
          admin_transaction ->
          case Repo.get_by(Transactions, transaction_id: admin_transaction.transaction_id) do
            nil -> json conn, %{status_code: "4004", errors: %{
              message: "User transaction not found"}
            }
            user_transaction ->
            case Repo.get_by(Transactions, related_with_id: user_transaction.id) do
              _data ->
                json conn, %{status_code: "4004", errors: %{
                message: "Transaction already refunded."}
              }

              nil -> case Repo.get_by(Adminaccounts, iban_number: admin_transaction.to_user) do

                         nil -> json conn, %{status_code: "4004", errors: %{
                           message: "Admin account not found"}
                         }
                         admin_account ->

                           case Repo.get_by(Companybankaccount, iban_number: admin_transaction.from_user) do

                             nil -> json conn, %{status_code: "4004", errors: %{
                               message: "User account not found"}
                             }
                             user_account ->

                               currency = "GBP"

                               type_credit = Application.get_env(:violacorp, :movefund_credit)

                               unique_id = Integer.to_string(Commontools.randnumber(10))

                               balance = String.to_float("#{admin_account.balance}") - String.to_float("#{user_transaction.final_amount}")
                               user_new_balance = String.to_float("#{user_account.balance}") + String.to_float("#{user_transaction.final_amount}")
                               today = DateTime.utc_now
                               commanid = user_transaction.commanall_id
                               company_id = user_transaction.company_id
                               amount = user_transaction.final_amount
                               transaction = %{
                                 "related_with_id" => user_transaction.id,
                                 "commanall_id" => commanid,
                                 "company_id" => company_id,
                                 "amount" => user_transaction.final_amount,
                                 "bank_id" => user_account.id,
                                 "fee_amount" => 0.00,
                                 "final_amount" => user_transaction.final_amount,
                                 "cur_code" => currency,
                                 "balance" => user_new_balance,
                                 "previous_balance" => user_account.balance,
                                 "transaction_id" => unique_id,
                                 "transaction_date" => today,
                                 "api_type" => type_credit,
                                 "transaction_mode" => "C",
                                 "transaction_type" => "A2A",
                                 "category" => "MV",
                                 "description" => "Refund",
                                 "remark" => user_transaction.remark,
                                 "inserted_by" => commanid
                               }
                               changeset = Transactions.changesetClearbankWorker(%Transactions{}, transaction)
                               case Repo.insert(changeset) do
                                 {:ok, data} -> _ids = data.id
                                                trans_status = data
                                                reference = "#{Commontools.randnumber(8)}"
                                                accountDetails = %{
                                                  amount: amount,
                                                  currency: currency,
                                                  paymentInstructionIdentification: "#{Commontools.randnumber(8)}",
                                                  d_name: admin_account.account_name,
                                                  d_iban: admin_account.iban_number,
                                                  d_code: "BBAN",
                                                  d_identification: "#{Commontools.randnumber(8)}",
                                                  d_issuer: "VIOLA",
                                                  d_proprietary: "Sender",
                                                  instructionIdentification: "#{Commontools.randnumber(8)}",
                                                  endToEndIdentification: unique_id,
                                                  c_name: user_account.account_name,
                                                  c_iban: user_account.iban_number,
                                                  c_proprietary: "Receiver",
                                                  c_code: "BBAN",
                                                  c_identification: "#{Commontools.randnumber(8)}",
                                                  c_issuer: "VIOLA",
                                                  reference: reference
                                                }
                                                output =  Clearbank.paymentAToIB(accountDetails)

                                                if !is_nil(output["transactions"]) do
                                                  res = get_in(output["transactions"], [Access.at(0)])
                                                  reference_end = res["endToEndIdentification"]
                                                  response = res["response"]
                                                  if response == "Accepted" do

                                                    transaction = %{
                                                      "adminaccounts_id" => admin_account.id,
                                                      "from_user" => admin_account.iban_number,
                                                      "to_user" => user_account.iban_number,
                                                      "amount" => amount,
                                                      "currency" => currency,
                                                      "transaction_date" => today,
                                                      "reference_id" => reference,
                                                      "transaction_id" => unique_id,
                                                      "end_to_en_identifier" => reference_end,
                                                      "mode" => "D",
                                                      "identification" => admin_account.iban_number,
                                                      "response" => response,
                                                      "status" => "S",
                                                      "inserted_by" => "99999"
                                                    }

                                                    changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
                                                    Repo.insert(changeset)

                                                    admin_account
                                                    |> Adminaccounts.changesetUpdateBalance(%{"balance" => balance})
                                                    |> Repo.update()

                                                    update_status = %{"status" => "A"}
                                                    changeset_transaction = Transactions.changesetUpdateStatusOnly(trans_status, update_status)
                                                    Repo.update(changeset_transaction)

                                                    json conn, %{status_code: "200", data: %{message: "Transaction has been successfully."}}
                                                  else
                                                    #if transaction failed
                                                    update_status = %{"description" => Poison.encode!(output)}
                                                    changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                                                    Repo.update(changeset_transaction)
                                                    json conn, %{status_code: "5001",errors: %{message: response}}
                                                  end
                                                else
                                                  #if no response from
                                                  update_status = %{"description" => Poison.encode!(output)}
                                                  changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                                                  Repo.update(changeset_transaction)
                                                  json conn, %{status_code: "4004",errors: %{message: "Transaction not allowed."}}
                                                end
                                 {:error, changeset} ->
                                   conn
                                   |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                               end
                           end
                       end

            end
          end
        end
      else
        json conn,%{status_code: "4003", errors: %{password: "Not Matched"}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
end
