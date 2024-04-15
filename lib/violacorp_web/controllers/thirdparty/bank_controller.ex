defmodule ViolacorpWeb.Thirdparty.BankController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  require Logger

  alias Violacorp.Repo
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools
  #  alias Violacorp.Workers.SuccessMonthlyFee
  #  alias Violacorp.Workers.PendingMonthlyFee

  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Beneficiaries
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Listener

  @doc "Check POST Method"
  def checkMethod(conn, _params) do

    body_string = %{
                    "MachineName" => "DESKTOP-04VG548",
                    "Username" => "inder",
                    "Timestamp" => "2018-10-26T20:58:48.7840832Z"
                  }
                  |> Poison.encode!
    string = ~s(#{body_string})

    request = Clearbank.test_api(string)

    json conn, request
  end

  @doc "Create Account on clear bank"
  def createAccount(conn, params) do

    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      request_id = params["request_id"]
      inserted_by = if !is_nil(request_id) or request_id != "", do: request_id, else: 99999

      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
        _common_id = params["id"]

        # create array data for send to accomplish
        userdata = Repo.one from commanall in Commanall, where: commanall.id == ^params["id"],
                                                         left_join: company in assoc(commanall, :company),
                                                         select: %{
                                                           company_id: company.id,
                                                           company_name: company.company_name,
                                                           email_id: commanall.email_id
                                                         }

        company_id = userdata.company_id

        get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")

        if is_nil(get_card) do

          #              new_comman_id = params["id"]
          owner_name = userdata.company_name
          #              new_company_name = "#{owner_name} #{new_comman_id}"

          send_account_name = String.replace(owner_name, ~r/[-$*?@().'\/#,]/, "");
          send_owner_name = String.replace(owner_name, ~r/[-$*?@().'\/#,]/, "");

          sortcode = Application.get_env(:violacorp, :sortcode)

          body_string = %{
                          "accountName" => send_account_name,
                          "owner" => %{
                            "name" => send_owner_name
                          },
                          "sortCode" => sortcode
                        }
                        |> Poison.encode!
          string = ~s(#{body_string})

          account_info = Repo.get_by(Companybankaccount, account_name: send_account_name, status: "F")
          if !is_nil(account_info) do
            bankAccount = %{"status" => "D"}
            changeset = Companybankaccount.changesetStatus(account_info, bankAccount)
            Repo.update(changeset)
          end

          # Add Data Before Call
          bankAccountFirst = %{
            "company_id" => company_id,
            "account_name" => send_account_name,
            "status" => "F",
            "inserted_by" => inserted_by
          }
          changesetFirstCall = Companybankaccount.changesetFirstCall(%Companybankaccount{}, bankAccountFirst)
          Repo.insert(changesetFirstCall)

          # Call Clear Bank
          response = Clearbank.create_account(string)

          if !is_nil(response["account"]) do

            iban = response["account"]["iban"]
            account_id = response["account"]["id"]
            account_name = response["account"]["name"]
            bban = response["account"]["bban"]
            type = response["account"]["type"]

            res = get_in(response["account"]["balances"], [Access.at(0)])
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
              "company_id" => company_id,
              "account_id" => account_id,
              "account_number" => account_number,
              "account_name" => account_name,
              "iban_number" => iban,
              "bban_number" => bban,
              "currency" => currency,
              "balance" => balance,
              "sort_code" => sort_code,
              "bank_code" => bank_code,
              "bank_type" => type,
              "request" => body_string,
              "status" => "A",
              "response" => Poison.encode!(response),
              "bank_status" => status,
              "inserted_by" => inserted_by
            }

            get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
            if is_nil(get_card) do
              changeset = Companybankaccount.changeset(%Companybankaccount{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Account created successfully"}
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Companybankaccount.changeset(get_card, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Account created successfully"}
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          else
            bankAccount = %{
              "company_id" => company_id,
              "request" => body_string,
              "response" => Poison.encode!(response),
              "status" => "F",
              "inserted_by" => inserted_by
            }
            get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
            if is_nil(get_card) do
              changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, bankAccount)
              case Repo.insert(changeset) do
                {:ok, _bankAccount} ->
                  json conn,
                       %{
                         status_code: "5001",
                         errors: %{
                           message: Poison.encode!(response)
                         }
                       }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              changeset = Companybankaccount.changesetFailed(get_card, bankAccount)
              case Repo.update(changeset) do
                {:ok, _bankAccount} ->
                  json conn,
                       %{
                         status_code: "5001",
                         errors: %{
                           message: Poison.encode!(response)
                         }
                       }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            end
          end

        else
          json conn, %{status_code: "200", message: "Company already, have account"}
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Get Info Account on clear bank"
  def balanceRefresh(conn, params) do
    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
        get_card = Repo.get_by(Companybankaccount, id: params["id"])

        if !is_nil(get_card) do

          accountid = get_card.account_id
          response = Clearbank.view_account(accountid)

          res = get_in(response["account"]["balances"], [Access.at(0)])
          balance = res["amount"]

          accountBalance = %{"balance" => balance}

          changeset = Companybankaccount.changesetUpdateBalance(get_card, accountBalance)
          case Repo.update(changeset) do
            {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Balance Updated Successfully"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn,
               %{
                 status_code: "402",
                 errors: %{
                   message: "Account not found!"
                 }
               }
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end

  end

  @doc "Get Info Account on clear bank"
  def accountBalanceRefresh(conn, params) do

    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    get_card = Repo.get_by(Companybankaccount, id: params["id"])

    if !is_nil(get_card) do

      accountid = get_card.account_id
      response = Clearbank.view_account(accountid)

      res = get_in(response["account"]["balances"], [Access.at(0)])
      balance = res["amount"]

      accountBalance = %{"balance" => balance}

      system_balance = String.to_float("#{get_card.balance}")
      server_balance = balance

      if system_balance != server_balance do
        # Check balance and call worker
        load_params = %{
          "commanall_id" => commanid,
          "worker_type" => "clearbank_transactions"
        }
        Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
      end

      changeset = Companybankaccount.changesetUpdateBalance(get_card, accountBalance)
      case Repo.update(changeset) do
        {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Balance Updated Successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "Account not found!"
             }
           }
    end
  end

  @doc "Get Info Account on clear bank"
  def adminAccountBalanceRefresh(conn, params) do

    sec_password = params["sec_password"]
    username = params["username"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      get_account = Repo.get_by(Adminaccounts, id: params["id"])

      if !is_nil(get_account) do

        accountid = get_account.account_id
        response = Clearbank.view_account(accountid)

        res = get_in(response["account"]["balances"], [Access.at(0)])
        balance = res["amount"]

        accountBalance = %{"balance" => balance}

        changeset = Adminaccounts.changesetUpdateBalance(get_account, accountBalance)
        case Repo.update(changeset) do
          {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Balance Updated Successfully"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "Account not found!"
               }
             }
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

  @doc "Pay to bank beneficiary"
  def beneficiaryPayment(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

      check_valid = validateBeneficiaryPayment(params)
      case check_valid.valid? do
        true ->
          beneficiary_id = params["id"]
          enter_amount = params["amount"]
          amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"

          # Sender Details
          case Repo.get_by(Companybankaccount, company_id: companyid, status: "A") do
            nil -> json conn,
                        %{
                          status_code: "4004",
                          errors: %{
                            message: "Account is not active."
                          }
                        }
            sender_details ->
              sort_code = sender_details.sort_code
              ff_code = String.slice(sort_code, 0..1)
              ss_code = String.slice(sort_code, 2..3)
              tt_code = String.slice(sort_code, 4..5)

              min_amount = Application.get_env(:violacorp, :min_amount)
              check_pay_amount = String.to_float("#{amount}")
              check_min_amount = String.to_float("#{min_amount}")
              check_balance = String.to_float("#{sender_details.balance}")

              if check_balance >= check_pay_amount do
                if check_pay_amount >= check_min_amount do

                  currency = "GBP"
                  notes = if params["notes"], do: params["notes"], else: "Sent from Viola"

                  # Receiver Details
                  receiver_details = Repo.get_by(Beneficiaries, id: beneficiary_id, company_id: companyid, status: "A")
                  if !is_nil(receiver_details) do

                    # API ID
                    type_debit = Application.get_env(:violacorp, :transfer_debit)
                    type_credit = Application.get_env(:violacorp, :transfer_credit)

                    get_company = Repo.get(Company, sender_details.company_id)
                    benificiary_type = receiver_details.type

                    benificiary_sort_code = receiver_details.sort_code
                    ben_ff_code = String.slice(benificiary_sort_code, 0..1)
                    ben_ss_code = String.slice(benificiary_sort_code, 2..3)
                    ben_tt_code = String.slice(benificiary_sort_code, 4..5)
                    benificiary_account_number = receiver_details.account_number

                    transfer_fund = String.to_float("#{amount}")
                    sender_available_balance = String.to_float("#{sender_details.balance}")
                    transaction_id = Integer.to_string(Commontools.randnumber(10))
                    today = DateTime.utc_now
                    from_user = "#{ff_code}-#{ss_code}-#{tt_code} #{sender_details.account_number}"
                    to_user = "#{receiver_details.first_name} -break- #{ben_ff_code}-#{ben_ss_code}-#{ben_tt_code}  #{
                      benificiary_account_number
                    } -break- #{receiver_details.nick_name}"
                    #            remark = %{"from" => from_user, "to" => to_user}
                    remark = %{
                      "from" => from_user,
                      "to" => to_user,
                      "from_info" =>
                      %{
                        "owner_name" => get_company.company_name,
                        "card_number" => "",
                        "sort_code" => "#{ff_code}-#{ss_code}-#{tt_code}",
                        "account_number" => "#{sender_details.account_number}"
                      },
                      "to_info" => %{
                        "owner_name" => "#{receiver_details.first_name} #{receiver_details.last_name}",
                        "card_number" => "",
                        "sort_code" => "#{ben_ff_code}-#{ben_ss_code}-#{ben_tt_code}",
                        "account_number" => "#{benificiary_account_number}"
                      }
                    }
                    balance = sender_available_balance - transfer_fund

                    transactions = %{
                      "commanall_id" => commanid,
                      "company_id" => companyid,
                      "bank_id" => sender_details.id,
                      "beneficiaries_id" => beneficiary_id,
                      "amount" => transfer_fund,
                      "balance" => balance,
                      "previous_balance" => sender_available_balance,
                      "fee_amount" => 0.00,
                      "final_amount" => transfer_fund,
                      "cur_code" => currency,
                      "transaction_id" => transaction_id,
                      "transaction_date" => today,
                      "transaction_mode" => "D",
                      "transaction_type" => "A2A",
                      "api_type" => type_debit,
                      "pos_id" => 0,
                      "category" => "AA",
                      "status" => "F",
                      "description" => notes,
                      "remark" => Poison.encode!(remark),
                      "inserted_by" => commanid
                    }

                    changeset_transaction = Transactions.changesetBeneficiaryPayment(%Transactions{}, transactions)
                    case Repo.insert(changeset_transaction) do
                      {:ok, transaction} ->

                        ids = transaction.id
                        trans_status = Repo.get(Transactions, ids)

                        c_name = "#{receiver_details.first_name}"

                        paymentInstructionIdentification = "#{Commontools.randnumber(8)}"
                        today = DateTime.utc_now
                        instructionIdentification = "#{Commontools.randnumber(8)}"

                        d_identification = "#{Commontools.randnumber(8)}"

                        _reference = "#{Commontools.randnumber(8)}"

                        if benificiary_type == "I" do

                          # Receiver Details
                          re_acc_number = receiver_details.account_number
                          receive_party = Repo.get_by(Companybankaccount, account_number: re_acc_number, status: "A")

                          accountDetails = %{
                            amount: amount,
                            currency: currency,
                            paymentInstructionIdentification: paymentInstructionIdentification,
                            d_name: sender_details.account_name,
                            d_iban: sender_details.iban_number,
                            d_code: "BBAN",
                            d_identification: d_identification,
                            d_issuer: "VIOLA",
                            d_proprietary: "Sender",
                            instructionIdentification: instructionIdentification,
                            endToEndIdentification: transaction_id,
                            c_name: receive_party.account_name,
                            c_iban: receive_party.iban_number,
                            c_proprietary: "Receiver",
                            c_code: "BBAN",
                            c_identification: "#{Commontools.randnumber(8)}",
                            c_issuer: "VIOLA",
                            reference: notes
                          }
                          output = Clearbank.paymentAToIB(accountDetails)

                          if !is_nil(output["transactions"]) do
                            res = get_in(output["transactions"], [Access.at(0)])
                            response = res["response"]
                            reference = res["endToEndIdentification"]

                            if response == "Accepted" do


                              balance = String.to_float("#{receive_party.balance}") + String.to_float("#{amount}")
                              rr_sort_code = receive_party.sort_code
                              rr_ff_code = String.slice(rr_sort_code, 0..1)
                              rr_ss_code = String.slice(rr_sort_code, 2..3)
                              rr_tt_code = String.slice(rr_sort_code, 4..5)

                              sender_data = Repo.get_by(Company, id: companyid)
                              #                      remark_credit = %{"from" => "#{sender_data.company_name} -break- #{from_user}", "to" => "#{rr_ff_code} - #{rr_ss_code} - #{rr_tt_code}   #{receive_party.account_number}"}
                              remark_credit = %{
                                "from" => "#{sender_data.company_name} -break- #{from_user}",
                                "to" => "#{rr_ff_code}-#{rr_ss_code}-#{rr_tt_code}   #{receive_party.account_number}",
                                "to_info" => %{
                                  "owner_name" => "#{receiver_details.first_name} #{receiver_details.last_name}",
                                  "card_number" => "",
                                  "sort_code" => "#{ben_ff_code}-#{ben_ss_code}-#{ben_tt_code}",
                                  "account_number" => "#{benificiary_account_number}"
                                },
                                "from_info" => %{
                                  "owner_name" => get_company.company_name,
                                  "card_number" => "",
                                  "sort_code" => "#{ff_code}-#{ss_code}-#{tt_code}",
                                  "account_number" => "#{sender_details.account_number}"
                                }
                              }

                              # Create Second entry in transaction
                              transaction_id = Integer.to_string(Commontools.randnumber(10))

                              commanall_info = Repo.get_by(Commanall, company_id: receive_party.company_id)

                              transaction = %{
                                "commanall_id" => commanall_info.id,
                                "company_id" => receive_party.company_id,
                                "bank_id" => receive_party.id,
                                "amount" => transfer_fund,
                                "final_amount" => transfer_fund,
                                "cur_code" => currency,
                                "balance" => balance,
                                "previous_balance" => receive_party.balance,
                                "fee_amount" => 0.00,
                                "transaction_id" => transaction_id,
                                "transaction_date" => today,
                                "transaction_mode" => "C",
                                "transaction_type" => "A2A",
                                "category" => "AA",
                                "api_type" => type_credit,
                                "pos_id" => 0,
                                "description" => notes,
                                "remark" => Poison.encode!(remark_credit),
                                "status" => "S",
                                "inserted_by" => commanid
                              }
                              changeset = Transactions.changesetBeneficiaryPayment(%Transactions{}, transaction)
                              case Repo.insert(changeset) do
                                {:ok, _data} ->

                                  # Update Sender Viola Balance
                                  sender_bal = String.to_float("#{sender_details.balance}") - String.to_float(
                                    "#{amount}"
                                  )
                                  senderbal = %{balance: sender_bal}
                                  changesetSender = Companybankaccount.changesetUpdateBalance(sender_details, senderbal)
                                  Repo.update(changesetSender)

                                  # Update Receiver Viola Balance
                                  receiver_bal = String.to_float("#{receive_party.balance}") + String.to_float(
                                    "#{amount}"
                                  )
                                  receiverbal = %{balance: receiver_bal}
                                  changesetReceiver = Companybankaccount.changesetUpdateBalance(
                                    receive_party,
                                    receiverbal
                                  )
                                  Repo.update(changesetReceiver)

                                  update_status = %{"status" => "S", "transactions_id_api" => reference}
                                  changeset_transaction = Transactions.changesetUpdateStatus(
                                    trans_status,
                                    update_status
                                  )
                                  Repo.update(changeset_transaction)

                                  json conn, %{status_code: "200", message: "Transaction Successfully."}

                                {:error, changeset} ->
                                  update_status = %{"status" => "P"}
                                  changeset_transaction = Transactions.changesetUpdateStatus(
                                    trans_status,
                                    update_status
                                  )
                                  Repo.update(changeset_transaction)
                                  conn
                                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                              end
                            else
                              update_status = %{"notes" => response}
                              changeset_transaction = Transactions.changesetNotes(trans_status, update_status)
                              Repo.update(changeset_transaction)
                              json conn,
                                   %{
                                     status_code: "5001",
                                     errors: %{
                                       message: response
                                     }
                                   }
                            end
                          else
                            json conn,
                                 %{
                                   status_code: "4004",
                                   errors: %{
                                     message: "Transaction not allowed."
                                   }
                                 }
                          end

                        else
                          # else external
                          c_iban = "GBR#{receiver_details.sort_code}#{receiver_details.account_number}"
                          accountDetails = %{
                            amount: amount,
                            currency: currency,
                            paymentInstructionIdentification: paymentInstructionIdentification,
                            d_name: sender_details.account_name,
                            d_iban: sender_details.iban_number,
                            d_code: "BBAN",
                            d_identification: d_identification,
                            d_issuer: "VIOLA",
                            d_proprietary: "Sender",
                            instructionIdentification: instructionIdentification,
                            endToEndIdentification: transaction_id,
                            c_name: c_name,
                            c_iban: c_iban,
                            c_proprietary: "PRTY_COUNTRY_SPECIFIC",
                            reference: notes
                          }
                          output = Clearbank.paymentAToEB(accountDetails)

                          if !is_nil(output["transactions"]) do
                            res = get_in(output["transactions"], [Access.at(0)])
                            response = res["response"]
                            reference = res["endToEndIdentification"]

                            if response == "Accepted" do

                              # Update Sender Balance
                              sender_bal = String.to_float("#{sender_details.balance}") - String.to_float("#{amount}")
                              senderbal = %{balance: sender_bal}
                              changesetSender = Companybankaccount.changesetUpdateBalance(sender_details, senderbal)
                              Repo.update(changesetSender)

                              update_status = %{"status" => "S", "transactions_id_api" => reference}
                              changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                              Repo.update(changeset_transaction)

                              json conn, %{status_code: "200", message: "Transaction Successfully."}
                            else
                              update_status = %{"notes" => response}
                              changeset_transaction = Transactions.changesetNotes(trans_status, update_status)
                              Repo.update(changeset_transaction)
                              json conn,
                                   %{
                                     status_code: "5001",
                                     errors: %{
                                       message: response
                                     }
                                   }
                            end
                          else
                            json conn,
                                 %{
                                   status_code: "4004",
                                   errors: %{
                                     message: "Transaction not allowed."
                                   }
                                 }
                          end
                        end
                      {:error, changeset} ->
                        conn
                        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                    end

                  else
                    json conn,
                         %{
                           status_code: "4004",
                           errors: %{
                             message: "Beneficiary not active."
                           }
                         }
                  end
                else
                  json conn,
                       %{
                         status_code: "4004",
                         errors: %{
                           message: "Minimum transaction amount 10.00"
                         }
                       }
                end
              else
                json conn,
                     %{
                       status_code: "4004",
                       errors: %{
                         message: "Insufficient fund."
                       }
                     }
              end
          end
        false ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: check_valid)
      end
    else
      json conn,
           %{
             status_code: "4002",
             message: "No Parameter Found."
           }
    end
  end

  defp validateBeneficiaryPayment(params) do
    bene_id = if is_integer(params["id"]), do: Integer.to_string(params["id"]), else: params["id"]
    fields = params
             |> Map.put("id", bene_id)
    user = %{}
    types = %{id: :string, amount: :string, notes: :string}
    {user, types}
    |> Ecto.Changeset.cast(fields, Map.keys(types))
    |> Ecto.Changeset.validate_required([:id, :amount, :notes])
    |> Ecto.Changeset.validate_format(:notes, ~r/[a-zA-Z0-9-,. ]+$/)
    |> Ecto.Changeset.validate_length(:notes, max: 18)
  end
  
  @doc "Clear Bank to Accomplish Account"
  def account2account(conn, params) do

    %{"commanall_id" => commanid, "id" => id} = conn.assigns[:current_user]

    accomplish_id = params["accountId"]
    clearbank_id = params["bankId"]
    enter_amount = params["amount"]

    amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
    currency = "GBP"

    # Get Sender Details
    sender_details = Repo.get_by(Companybankaccount, id: clearbank_id, company_id: id, status: "A")

    if is_nil(sender_details) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Account not valid."
             }
           }
    end

    # Admin  Receiver Details
    receiver_details = Repo.get_by(Adminaccounts, type: "Accomplish")

    if is_nil(receiver_details) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Third party account not exist."
             }
           }
    end

    # Company Receiver Details
    company_account_details = Repo.get_by(Companyaccounts, id: accomplish_id)
    # get company details
    #    compnay_info = Repo.get_by(Company, id: id)

    sort_code = if !is_nil(sender_details.sort_code) do
      ff_code = String.slice(sender_details.sort_code, 0..1)
      ss_code = String.slice(sender_details.sort_code, 2..3)
      tt_code = String.slice(sender_details.sort_code, 4..5)

      "#{ff_code}-#{ss_code}-#{tt_code}"
    else
      ""
    end

    check_pay_amount = String.to_float("#{amount}")
    check_balance = String.to_float("#{sender_details.balance}")

    _get_company = Repo.get(Company, company_account_details.company_id)

    if check_balance >= check_pay_amount do

      #      remark = %{"from" => "#{compnay_info.company_name} <br> #{ff_code}-#{ss_code}-#{tt_code} #{sender_details.account_number}", "to" => "#{compnay_info.company_name}"}
      remark = %{
        "from" => "Online Business Account",
        "to" => "Card Management Account -break- Fund Transfer",
        "from_info" =>
        %{
          "owner_name" => sender_details.account_name,
          "card_number" => "",
          "sort_code" => sort_code,
          "account_number" => "#{sender_details.account_number}"
        },
        "to_info" =>
        %{
          "owner_name" => "Card Management Account",
          "card_number" => "",
          "sort_code" => "#{company_account_details.accomplish_account_id}",
          "account_number" => "#{company_account_details.accomplish_account_number}"
        }
      }


      _remark_too = %{
        "from" => "Card Management Account -break- Fund Received",
        "to" => "Online Business Account",
        "to_info" =>
        %{
          "owner_name" => sender_details.account_name,
          "card_number" => "",
          "sort_code" => sort_code,
          "account_number" => "#{sender_details.account_number}"
        },
        "from_info" =>
        %{
          "owner_name" => "Card Management Account",
          "card_number" => "",
          "sort_code" => "#{company_account_details.accomplish_account_id}",
          "account_number" => "#{company_account_details.accomplish_account_number}"
        }
      }


      type_debit = Application.get_env(:violacorp, :movefund_debit)
      _type_credit = Application.get_env(:violacorp, :movefund_credit)

      unique_id = Integer.to_string(Commontools.randnumber(10))

      balance = String.to_float("#{sender_details.balance}") - String.to_float("#{amount}")
      today = DateTime.utc_now

      transaction = %{
        "commanall_id" => commanid,
        "company_id" => id,
        "amount" => amount,
        "bank_id" => clearbank_id,
        "fee_amount" => 0.00,
        "final_amount" => amount,
        "cur_code" => currency,
        "balance" => balance,
        "previous_balance" => sender_details.balance,
        "transaction_id" => unique_id,
        "transaction_date" => today,
        "api_type" => type_debit,
        "transaction_mode" => "D",
        "transaction_type" => "A2A",
        "category" => "MV",
        "description" => "Fund deposited into card management account",
        "remark" => Poison.encode!(remark),
        "inserted_by" => commanid
      }

      changeset = Transactions.changesetClearbankWorker(%Transactions{}, transaction)
      case Repo.insert(changeset) do
        {:ok, data} -> ids = data.id
                       trans_status = Repo.get(Transactions, ids)
                       accountDetails = %{
                         amount: amount,
                         currency: currency,
                         paymentInstructionIdentification: "#{Commontools.randnumber(8)}",
                         d_name: sender_details.account_name,
                         d_iban: sender_details.iban_number,
                         d_code: "BBAN",
                         d_identification: "#{Commontools.randnumber(8)}",
                         d_issuer: "VIOLA",
                         d_proprietary: "Sender",
                         instructionIdentification: "#{Commontools.randnumber(8)}",
                         endToEndIdentification: unique_id,
                         c_name: receiver_details.account_name,
                         c_iban: receiver_details.iban_number,
                         c_proprietary: "Receiver",
                         c_code: "BBAN",
                         c_identification: "#{Commontools.randnumber(8)}",
                         c_issuer: "VIOLA",
                         reference: "#{Commontools.randnumber(8)}"
                       }
                       output = Clearbank.paymentAToIB(accountDetails)

                       if !is_nil(output["transactions"]) do
                         res = get_in(output["transactions"], [Access.at(0)])
                         response = res["response"]
                         if response == "Accepted" do
                           sender_details
                           |> Companybankaccount.changesetUpdateBalance(%{"balance" => balance})
                           |> Repo.update()

                           json conn,
                                %{
                                  status_code: "200",
                                  data: %{
                                    message: "Transaction has been successfully."
                                  }
                                }
                         else
                           #if transaction failed
                           update_status = %{"description" => Poison.encode!(output)}
                           changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                           Repo.update(changeset_transaction)
                           json conn,
                                %{
                                  status_code: "5001",
                                  errors: %{
                                    message: response
                                  }
                                }
                         end
                       else
                         #if no response from
                         update_status = %{"description" => Poison.encode!(output)}
                         changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                         Repo.update(changeset_transaction)
                         json conn,
                              %{
                                status_code: "4004",
                                errors: %{
                                  message: "Transaction not allowed."
                                }
                              }
                       end

        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Insufficient fund."
             }
           }
    end
  end

  @doc "Move monmey from Admin Accomplich CB to Comopany CB"
  def adminAccount2CompanyBank(conn, params) do
    clearbank_id = params["bankId"]
    enter_amount = params["amount"]
    username = params["username"]
    sec_password = params["sec_password"]
    viola_user = "violacorp"
    viola_password = "^7MQ!Ny}p&"

    if username == viola_user and sec_password == viola_password do
      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
      currency = "GBP"

      # Receiver Account Details
      receiver_details = Repo.get_by(Companybankaccount, id: clearbank_id, status: "A")

      if is_nil(receiver_details) do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Account not valid."
               }
             }
      end


      company_id = receiver_details.company_id
      # ADMIN sender Account Details
      sender_details = Repo.get_by(Adminaccounts, type: "Accomplish")

      if is_nil(sender_details) do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Third party account not exist."
               }
             }
      end

      # get company details
      comman = Repo.get_by(Commanall, company_id: company_id)
      commanid = comman.id
      sort_code = if !is_nil(sender_details.sort_code) do
        ff_code = String.slice(sender_details.sort_code, 0..1)
        ss_code = String.slice(sender_details.sort_code, 2..3)
        tt_code = String.slice(sender_details.sort_code, 4..5)

        "#{ff_code}-#{ss_code}-#{tt_code}"
      else
        ""
      end

      company_account_details = Repo.get_by(Companyaccounts, company_id: company_id)
      check_pay_amount = String.to_float("#{amount}")
      check_balance = String.to_float("#{sender_details.balance}")


      remark = %{
        "from" => "Card Management Account -break- Fund Transfer",
        "to" => " Online Business Account",
        "to_info" =>
        %{
          "owner_name" => sender_details.account_name,
          "card_number" => "",
          "sort_code" => sort_code,
          "account_number" => "#{sender_details.account_number}"
        },
        "from_info" =>
        %{
          "owner_name" => "Card Management Account",
          "card_number" => "",
          "sort_code" => "#{company_account_details.accomplish_account_id}",
          "account_number" => "#{company_account_details.accomplish_account_number}"
        }
      }


      if check_balance >= check_pay_amount do

        type_debit = Application.get_env(:violacorp, :movefund_debit)

        unique_id = Integer.to_string(Commontools.randnumber(10))

        balance = String.to_float("#{sender_details.balance}") - String.to_float("#{amount}")
        receiver_new_balance = String.to_float("#{receiver_details.balance}") + String.to_float("#{amount}")
        today = DateTime.utc_now

        transaction = %{
          "commanall_id" => commanid,
          "company_id" => company_id,
          "amount" => amount,
          "bank_id" => clearbank_id,
          "fee_amount" => 0.00,
          "final_amount" => amount,
          "cur_code" => currency,
          "balance" => receiver_new_balance,
          "previous_balance" => sender_details.balance,
          "transaction_id" => unique_id,
          "transaction_date" => today,
          "api_type" => type_debit,
          "transaction_mode" => "C",
          "transaction_type" => "A2A",
          "category" => "MV",
          "description" => "Refund",
          "remark" => remark,
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
                           d_name: sender_details.account_name,
                           d_iban: sender_details.iban_number,
                           d_code: "BBAN",
                           d_identification: "#{Commontools.randnumber(8)}",
                           d_issuer: "VIOLA",
                           d_proprietary: "Sender",
                           instructionIdentification: "#{Commontools.randnumber(8)}",
                           endToEndIdentification: unique_id,
                           c_name: receiver_details.account_name,
                           c_iban: receiver_details.iban_number,
                           c_proprietary: "Receiver",
                           c_code: "BBAN",
                           c_identification: "#{Commontools.randnumber(8)}",
                           c_issuer: "VIOLA",
                           reference: reference
                         }
                         output = Clearbank.paymentAToIB(accountDetails)

                         if !is_nil(output["transactions"]) do
                           res = get_in(output["transactions"], [Access.at(0)])
                           reference_end = res["endToEndIdentification"]
                           response = res["response"]
                           if response == "Accepted" do

                             transaction = %{
                               "adminaccounts_id" => sender_details.id,
                               "from_user" => sender_details.iban_number,
                               "to_user" => receiver_details.iban_number,
                               "amount" => amount,
                               "currency" => currency,
                               "transaction_date" => today,
                               "reference_id" => reference,
                               "transaction_id" => unique_id,
                               "end_to_en_identifier" => reference_end,
                               "mode" => "D",
                               "identification" => sender_details.iban_number,
                               "response" => response,
                               "status" => "S",
                               "inserted_by" => "99999"
                             }

                             changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
                             Repo.insert(changeset)

                             sender_details
                             |> Adminaccounts.changesetUpdateBalance(%{"balance" => balance})
                             |> Repo.update()

                             json conn,
                                  %{
                                    status_code: "200",
                                    data: %{
                                      message: "Transaction has been successfully."
                                    }
                                  }
                           else
                             #if transaction failed
                             update_status = %{"description" => Poison.encode!(output)}
                             changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                             Repo.update(changeset_transaction)
                             json conn,
                                  %{
                                    status_code: "5001",
                                    errors: %{
                                      message: response
                                    }
                                  }
                           end
                         else
                           #if no response from
                           update_status = %{"description" => Poison.encode!(output)}
                           changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                           Repo.update(changeset_transaction)
                           json conn,
                                %{
                                  status_code: "4004",
                                  errors: %{
                                    message: "Transaction not allowed."
                                  }
                                }
                         end

          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Insufficient fund."
               }
             }
      end
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

  @doc "Pull All Accounts"
  def pullAccounts(conn, _params) do
    response = Clearbank.get_accounts()

    json conn, response
  end

  @doc "Pull All Transactions"
  def pullAllTransactions(conn, params) do

    accountId = params["accountId"]

    endpoint = "#{accountId}/Transactions"
    response = Clearbank.get_transaction(endpoint)

    json conn, response
  end

  @doc "Pull All Transactions"
  def pullSingleTransactions(conn, params) do

    accountId = params["accountId"]
    transactionId = params["transactionId"]

    endpoint = "#{accountId}/Transactions/#{transactionId}"
    response = Clearbank.get_transaction(endpoint)

    json conn, response
  end

  @doc "write listener data"
  def pullListenerData(conn, _params) do

    # Get listener data
    listenerData = Repo.all(from l in Listener, where: l.type == "TransactionSettled")

    if !is_nil(listenerData) do
      Enum.each listenerData, fn listData ->

        transactionData = listData.request
                          |> Poison.decode!

        #        type = transactionData["Type"]
        #        version = transactionData["Version"]
        #        transactionId = transactionData["Payload"]["TransactionId"]
        #        status = transactionData["Payload"]["Status"]
        scheme = transactionData["Payload"]["Scheme"]
        endToEndTransactionId = transactionData["Payload"]["EndToEndTransactionId"]
        amount = transactionData["Payload"]["Amount"]
        timestampModified = transactionData["Payload"]["TimestampModified"]
        currencyCode = transactionData["Payload"]["CurrencyCode"]
        debitCreditCode = transactionData["Payload"]["DebitCreditCode"]
        reference = transactionData["Payload"]["Reference"]
        #        is_return = transactionData["Payload"]["IsReturn"]

        accountIban = transactionData["Payload"]["Account"]["IBAN"]
        #        accountBban = transactionData["Payload"]["Account"]["BBAN"]
        accountName = transactionData["Payload"]["Account"]["AccountName"]
        #        institutionName = transactionData["Payload"]["Account"]["InstitutionName"]

        counterpart_account_iban = transactionData["Payload"]["CounterpartAccount"]["IBAN"]
        counterpart_account_bban = transactionData["Payload"]["CounterpartAccount"]["BBAN"]
        counterpart_account_name = transactionData["Payload"]["CounterpartAccount"]["AccountName"]
        counterpart_account_institutionName = transactionData["Payload"]["CounterpartAccount"]["InstitutionName"]

        #        actualEndToEndTransactionId = transactionData["Payload"]["ActualEndToEndTransactionId"]

        lan = String.length(accountIban)
        account_number = String.slice(accountIban, 14..lan)

        bban_lan = String.length(counterpart_account_bban)
        sort_code = String.slice(counterpart_account_bban, 4..10)
        accountNumber = String.slice(counterpart_account_bban, 10..bban_lan)
        ff_code = String.slice(sort_code, 0..1)
        ss_code = String.slice(sort_code, 2..3)
        tt_code = String.slice(sort_code, 4..5)
        accountInfo = "#{ff_code}-#{ss_code}-#{tt_code} #{accountNumber}"

        remark = if debitCreditCode == "Credit", do: %{
          "from" => "#{counterpart_account_name} -break- #{accountInfo} #{counterpart_account_institutionName}",
          "to" => accountName,
          "from_account" => accountNumber,
          "to_account" => account_number
        },
                                                 else: %{
                                                   "to" => "#{counterpart_account_name} -break- #{accountInfo} #{
                                                     counterpart_account_institutionName
                                                   }",
                                                   "from" => accountName,
                                                   "to_account" => accountNumber,
                                                   "from_account" => account_number
                                                 }
        description = %{
          scheme: scheme,
          institutionName: counterpart_account_institutionName,
          accountName: counterpart_account_name,
          iban: counterpart_account_iban,
          bban: counterpart_account_bban
        }

        # check enetoend transaction id in db
        check_transaction = Repo.get_by(Transactions, transaction_id: endToEndTransactionId, transaction_type: "A2A")
        if is_nil(check_transaction) do
          # Then Insert
          account_info = Repo.get_by(Companybankaccount, iban_number: accountIban, status: "A")
          if !is_nil(account_info) do
            company_id = account_info.company_id
            common_all = Repo.get_by(Commanall, company_id: company_id)

            transaction_mode = if debitCreditCode == "Debit", do: "D", else: "C"
            type_debit = Application.get_env(:violacorp, :transfer_debit)
            type_credit = Application.get_env(:violacorp, :transfer_credit)
            api_type = if debitCreditCode == "Debit", do: type_debit, else: type_credit

            transaction = %{
              "commanall_id" => common_all.id,
              "company_id" => company_id,
              "bank_id" => account_info.id,
              "amount" => amount,
              "fee_amount" => 0.00,
              "final_amount" => amount,
              "balance" => 0.00,
              "previous_balance" => 0.00,
              "cur_code" => currencyCode,
              "transaction_id" => endToEndTransactionId,
              "transactions_id_api" => reference,
              "transaction_date" => timestampModified,
              "transaction_mode" => transaction_mode,
              "api_type" => api_type,
              "transaction_type" => "A2A",
              "category" => "AA",
              "status" => "S",
              "description" => Poison.encode!(description),
              "remark" => Poison.encode!(remark),
              "inserted_by" => common_all.id
            }
            changeset = Transactions.changesetWebhook(%Transactions{}, transaction)
            case Repo.insert(changeset) do
              {:ok, _data} -> IO.inspect("Record Inserted")
              {:error, changeset} -> IO.inspect(changeset)
            end
          end
        else
          transactionUpdate = %{
            "description" => Poison.encode!(description),
            "remark" => Poison.encode!(remark)
          }
          changeset = Transactions.changesetDescriptionRemark(check_transaction, transactionUpdate)
          case Repo.update(changeset) do
            {:ok, _data} -> IO.inspect("Record Updated")
            {:error, changeset} -> IO.inspect(changeset)
          end
        end
      end
    end

    text conn, "Transaction update successfully."



  end

end