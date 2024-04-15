defmodule Violacorp.Libraries.Fees do

  import Ecto.Query
  alias Violacorp.Repo
  alias Violacorp.Schemas.Groupfee
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Companybankaccount

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Clearbank

  @moduledoc "Fees Library"

  # Fee Calculation
  def pending_monthly_fee(params) do
    # Define variables
    commanid = params.commanid
    total_card = params.total_card
    balance = String.to_float("#{params.balance}")
    compid = params.compid
    accomplish_account_id = params.accomplish_account_id

    # Get default monthly fee
    fee_details = Repo.all(
      from g in Groupfee, where: g.status == "A" and g.as_default == "Yes" and g.trans_type == "MONTH",
                          select: %{
                            rules: g.rules,
                            amount: g.amount,
                            fee_type: g.fee_type
                          }
    )
    Enum.each fee_details, fn v ->
      final_amount = final_amount(v.amount, v.rules, total_card)

      fee_amount = String.to_float("#{final_amount.amount}")

      today = DateTime.utc_now
      remark = %{"from" => "GBP", "to" => "Viola Corporate"}

      available_balance = case Repo.get_by(Companybankaccount, company_id: compid) do
        nil -> accom_acc = Repo.get_by(Companyaccounts, accomplish_account_id: accomplish_account_id)
               String.to_float("#{accom_acc.available_balance}")
        found -> String.to_float("#{found.balance}")
      end
      type_credit = Application.get_env(:violacorp, :internal_fee)

      transaction_id = Integer.to_string(Commontools.randnumber(10))
      transactions = %{
        "commanall_id" => commanid,
        "company_id" => compid,
        "amount" => 0.00,
        "fee_amount" => fee_amount,
        "final_amount" => fee_amount,
        "cur_code" => "GBP",
        "balance" => balance,
        "transaction_id" => transaction_id,
        "transaction_date" => today,
        "transaction_mode" => "D",
        "transaction_type" => "A2O",
        "api_type" => type_credit,
        "category" => "FEE",
        "status" => "P",
        "description" => "Charge monthly fee",
        "remark" => Poison.encode!(remark),
        "notes" => Poison.encode!(final_amount),
        "inserted_by" => commanid
      }
      changeset = Transactions.changesetFee(%Transactions{}, transactions)
      if available_balance > fee_amount do
        case Repo.insert(changeset) do
          {:ok, data} ->
            bank_account = Repo.get_by(Companybankaccount, company_id: compid)
            if !is_nil(bank_account) do
              #                  CHARGE CB ACCOUNT
              trans_status = data
              paymentInstructionIdentification = "#{Commontools.randnumber(8)}"
              today = DateTime.utc_now
              instructionIdentification = "#{Commontools.randnumber(8)}"

              d_identification = "#{Commontools.randnumber(8)}"

              reference = "#{Commontools.randnumber(8)}"

              # Receiver Details
              receive_party = Repo.get(Adminaccounts, 2)

              accountDetails = %{
                amount: fee_amount,
                currency: "GBP",
                paymentInstructionIdentification: paymentInstructionIdentification,
                d_name: bank_account.account_name,
                d_iban: bank_account.iban_number,
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
                reference: reference
              }
              output = Clearbank.paymentAToIB(accountDetails)

              remark = Poison.encode!(
                %{
                  "from" => bank_account.id,
                  "to" => receive_party.id,
                  "from_name" => bank_account.account_name,
                  "to_name" => receive_party.account_name,
                  "from_info" =>
                  %{
                    "owner_name" => bank_account.account_name,
                    "card_number" => "",
                    "sort_code" => "#{bank_account.sort_code}",
                    "account_number" => "#{bank_account.account_number}"
                  },
                  "to_info" => %{
                    "owner_name" => receive_party.account_name,
                    "card_number" => "",
                    "sort_code" => "#{receive_party.sort_code}",
                    "account_number" => "#{receive_party.account_number}"
                  }
                }
              )

              if !is_nil(output["transactions"]) do
                res = get_in(output["transactions"], [Access.at(0)])
                response = res["response"]
                reference = res["endToEndIdentification"]

                if response == "Accepted" do

                  # Admintransactions entry

                  transaction = %{
                    "adminaccounts_id" => receive_party.id,
                    "amount" => fee_amount,
                    "currency" => bank_account.currency,
                    "from_user" => bank_account.iban_number,
                    "to_user" => receive_party.iban_number,
                    "reference_id" => reference,
                    "transaction_id" => transaction_id,
                    "mode" => "C",
                    "identification" => bank_account.iban_number,
                    "description" => "Settlement Transaction",
                    "transaction_date" => today,
                    "api_status" => "CBF", # CONFIRM WHAT TO KEEP HERE KK
                    "status" => "S",
                    "end_to_en_identifier" => reference,
                    "response" => response,
                    "inserted_by" => receive_party.id
                  }
                  changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
                  case Repo.insert(changeset) do
                    {:ok, _data} ->

                      # Update Sender Viola Balance [company]
                      sender_bal = String.to_float("#{bank_account.balance}") - String.to_float("#{fee_amount}")
                      senderbal = %{balance: sender_bal}
                      changesetSender = Companybankaccount.changesetUpdateBalance(bank_account, senderbal)
                      Repo.update(changesetSender)

                      # Update Receiver Balance [Adminaccounts]
                      receiver_bal = String.to_float("#{receive_party.balance}") + String.to_float("#{fee_amount}")
                      receiverbal = %{balance: receiver_bal}
                      changesetReceiver = Adminaccounts.changesetUpdateBalance(receive_party, receiverbal)
                      Repo.update(changesetReceiver)

                      # UPDATE STATUS OF TRANSACTION TO S
                      update_status = %{
                        "status" => "S",
                        "transactions_id_api" => reference,
                        "remark" => remark
                      }
                      changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                      Repo.update(changeset_transaction)

                    {:error, _changeset} ->
                      update_status = %{
                        "status" => "P",
                        "remark" => remark
                      }
                      changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                      Repo.update(changeset_transaction)
                  end
                else
                  update_status = %{
                    "status" => "P",
                    "description" => response,
                    "remark" => remark
                  }
                  changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                  Repo.update(changeset_transaction)
                end
              end
            else

              adminaccount_fee = Repo.get_by(Adminaccounts, account_name: "Account Fee")


              remark = Poison.encode!(
                %{
                  "from" => bank_account.id,
                  "to" => adminaccount_fee.id,
                  "from_name" => bank_account.account_name,
                  "to_name" => adminaccount_fee.account_name,
                  "from_info" =>
                  %{
                    "owner_name" => bank_account.account_name,
                    "card_number" => "",
                    "sort_code" => "#{bank_account.sort_code}",
                    "account_number" => "#{bank_account.account_number}"
                  },
                  "to_info" => %{
                    "owner_name" => adminaccount_fee.account_name,
                    "card_number" => "",
                    "sort_code" => "#{adminaccount_fee.sort_code}",
                    "account_number" => "#{adminaccount_fee.account_number}"
                  }
                }
              )
              request = %{
                type: "228",
                amount: fee_amount,
                currency: "GBP",
                account_id: accomplish_account_id, # from account
                card_id: adminaccount_fee.account_id, # to adminaccount of accomplish
                validate: "0"
              }
              response = Accomplish.move_funds(request)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              transactions_id_api = response["info"]["original_source_id"]

              if response_code == "0000" do

                # Admintransactions entry

                transaction = %{
                  "adminaccounts_id" => adminaccount_fee.id,
                  "amount" => fee_amount,
                  "currency" => bank_account.currency,
                  "from_user" => bank_account.iban_number,
                  "to_user" => adminaccount_fee.iban_number,
                  "reference_id" => transactions_id_api,
                  "transaction_id" => transaction_id,
                  "mode" => "C",
                  "identification" => bank_account.iban_number,
                  "description" => "Settlement Transaction",
                  "transaction_date" => today,
                  "api_status" => "CBF", # CONFIRM WHAT TO KEEP HERE KK
                  "status" => "S",
                  "end_to_en_identifier" => transactions_id_api,
                  "response" => response,
                  "inserted_by" => adminaccount_fee.id
                }

                changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
                case Repo.insert(changeset) do
                  {:ok, _data} ->
                    # UPDATE TRANSACTION STATUS
                    trans_status = data
                    update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api, "remark" => remark}
                    changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                    Repo.update(changeset_transaction)

                    # UPDATE BALANCE OF USER
                    gets_account = Accomplish.get_account(accomplish_account_id)
                    current_balance = gets_account["info"]["balance"]
                    available_balance = gets_account["info"]["available_balance"]
                    update_balance = %{
                      "available_balance" => available_balance,
                      "current_balance" => current_balance
                    }
                    account_details = Repo.get_by(Companyaccounts, accomplish_account_id: accomplish_account_id)
                    changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
                    Repo.update(changeset_companyaccount)

                    # UPDATE BALANCE OF ADMIN ACCOUNT
                    gets_account = Accomplish.get_account(accomplish_account_id)
                    current_balance = gets_account["info"]["balance"]
                    update_balance = %{
                      "balance" => current_balance
                    }
                    account_details = Repo.get_by(Adminaccounts, accomplish_account_id: accomplish_account_id)
                    changeset_companyaccount = Adminaccounts.changesetUpdateBalance(account_details, update_balance)
                    Repo.update(changeset_companyaccount)
                  {:error, _changeset} ->
                    trans_status = data
                    update_status = %{"status" => "P", "remark" => remark}
                    changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                    Repo.update(changeset_transaction)
                end
              else
                # UPDATE TRANSACTION BY ADDING RESPONSE MESSAGE TO DESCRIPTION
                trans_status = data
                update_status = %{"status" => "P", "description" => response_message, "remark" => remark}
                changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                Repo.update(changeset_transaction)
              end
            end
        end
      else
        Repo.insert(changeset)
      end
    end
  end

  def charge_monthly_fee(params) do
    # Define variables
    accomplish_account_id = params.accomplish_account_id
    ids = params.transaction_id
    fee_amount = params.fee_amount

    today = DateTime.utc_now
    bank_details = Repo.get_by(Companybankaccount, company_id: params.compid)
    if !is_nil(bank_details) do
      # 1. Clearbank.paymentAToIB
      # 2. if response = "Accepted"
      # 2.1. Insert successful transaction [admintransactions]
      # 2.2. Update Balance [companybankaccount]
      # 2.3. Update Balance [Adminaccounts]
      # 2.4. Update transaction's status [transactions]
      # 3. else Update transaction's description with response description [transactions]

      receive_party = Repo.get_by(Adminaccounts, account_name: "Fee Corporate Account")

      trans_status = Repo.get(Transactions, ids)

      paymentInstructionIdentification = "#{Commontools.randnumber(8)}"
      instructionIdentification = "#{Commontools.randnumber(8)}"

      d_identification = "#{Commontools.randnumber(8)}"

      reference = "#{Commontools.randnumber(8)}"

      accountDetails = %{
        amount: fee_amount,
        currency: "GBP",
        paymentInstructionIdentification: paymentInstructionIdentification,
        d_name: bank_details.account_name,
        d_iban: bank_details.iban_number,
        d_code: "BBAN",
        d_identification: d_identification,
        d_issuer: "VIOLA",
        d_proprietary: "Sender",
        instructionIdentification: instructionIdentification,
        endToEndIdentification: trans_status.transaction_id,
        c_name: receive_party.account_name,
        c_iban: receive_party.iban_number,
        c_proprietary: "Receiver",
        c_code: "BBAN",
        c_identification: "#{Commontools.randnumber(8)}",
        c_issuer: "VIOLA",
        reference: reference
      }
      output = Clearbank.paymentAToIB(accountDetails)

      remark = Poison.encode!(
        %{
          "from" => bank_details.id,
          "to" => receive_party.id,
          "from_name" => bank_details.account_name,
          "to_name" => receive_party.account_name,
          "from_info" =>
          %{
            "owner_name" => bank_details.account_name,
            "card_number" => "",
            "sort_code" => "#{bank_details.sort_code}",
            "account_number" => "#{bank_details.account_number}"
          },
          "to_info" => %{
            "owner_name" => receive_party.account_name,
            "card_number" => "",
            "sort_code" => "#{receive_party.sort_code}",
            "account_number" => "#{receive_party.account_number}"
          }
        }
      )

      if !is_nil(output["transactions"]) do
        res = get_in(output["transactions"], [Access.at(0)])
        response = res["response"]
        reference = res["endToEndIdentification"]

        if response == "Accepted" do
          # Admintransactions entry
          transaction_id = Integer.to_string(Commontools.randnumber(10))
          transaction = %{
            "adminaccounts_id" => receive_party.id,
            "amount" => fee_amount,
            "currency" => bank_details.currency,
            "from_user" => bank_details.iban_number,
            "to_user" => receive_party.iban_number,
            "reference_id" => reference,
            "transaction_id" => transaction_id,
            "mode" => "D",
            "identification" => bank_details.iban_number,
            "description" => "Settlement Transaction",
            "transaction_date" => today,
            "status" => "S",
            "end_to_en_identifier" => reference,
            "response" => response,
            "inserted_by" => receive_party.id
          }

          changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
          case Repo.insert(changeset) do
            {:ok, _data} ->

              # Update Sender Viola Balance [company]
              sender_bal = String.to_float("#{bank_details.balance}") - String.to_float("#{fee_amount}")
              senderbal = %{balance: sender_bal}
              changesetSender = Companybankaccount.changesetUpdateBalance(bank_details, senderbal)
              Repo.update(changesetSender)

              # Update Receiver Balance [Adminaccounts]
              receiver_bal = String.to_float("#{receive_party.balance}") + String.to_float("#{fee_amount}")
              receiverbal = %{balance: receiver_bal}
              changesetReceiver = Adminaccounts.changesetUpdateBalance(receive_party, receiverbal)
              Repo.update(changesetReceiver)

              # UPDATE STATUS OF TRANSACTION TO S
              update_status = %{"status" => "S", "transactions_id_api" => reference, "remark" => remark}
              changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
              Repo.update(changeset_transaction)

            {:error, _changeset} ->
              update_status = %{"status" => "P", "remark" => remark}
              changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
              Repo.update(changeset_transaction)
          end
        else
          update_status = %{"status" => "P", "description" => response, "remark" => remark}
          changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
          Repo.update(changeset_transaction)
        end
      end
    else
      adminaccount_fee = Repo.get_by(Adminaccounts, account_name: "Account Fee")
      trans_status = Repo.get(Transactions, ids)
      request = %{
        type: "228",
        amount: fee_amount,
        currency: "GBP",
        account_id: accomplish_account_id, # from account
        card_id: adminaccount_fee.account_id, # to adminaccount of accomplish
        validate: "0"
      }
      response = Accomplish.move_funds(request)
      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]
      transactions_id_api = response["info"]["original_source_id"]

      remark = Poison.encode!(
        %{
          "from" => bank_details.id,
          "to" => adminaccount_fee.id,
          "from_name" => bank_details.account_name,
          "to_name" => adminaccount_fee.account_name,
          "from_info" =>
          %{
            "owner_name" => bank_details.account_name,
            "card_number" => "",
            "sort_code" => "#{bank_details.sort_code}",
            "account_number" => "#{bank_details.account_number}"
          },
          "to_info" => %{
            "owner_name" => adminaccount_fee.account_name,
            "card_number" => "",
            "sort_code" => "#{adminaccount_fee.sort_code}",
            "account_number" => "#{adminaccount_fee.account_number}"
          }
        }
      )

      if response_code == "0000" do

        # Admintransactions entry
        reference = "#{Commontools.randnumber(8)}"
        transaction = %{
          "adminaccounts_id" => adminaccount_fee.id,
          "amount" => fee_amount,
          "currency" => bank_details.currency,
          "from_user" => bank_details.iban_number,
          "to_user" => adminaccount_fee.iban_number,
          "reference_id" => reference,
          "transaction_id" => transactions_id_api,
          "mode" => "C",
          "identification" => bank_details.iban_number,
          "description" => "Settlement Transaction",
          "transaction_date" => today,
          "api_status" => "CBF", # CONFIRM WHAT TO KEEP HERE KK
          "status" => "S",
          "end_to_en_identifier" => transactions_id_api,
          "response" => response,
          "inserted_by" => adminaccount_fee.id
        }

        changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
        case Repo.insert(changeset) do
          {:ok, _data} ->
            # UPDATE TRANSACTION STATUS
            update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api, "remark" => remark}
            changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
            Repo.update(changeset_transaction)

            # UPDATE BALANCE OF USER
            gets_account = Accomplish.get_account(accomplish_account_id)
            current_balance = gets_account["info"]["balance"]
            available_balance = gets_account["info"]["available_balance"]
            update_balance = %{
              "available_balance" => available_balance,
              "current_balance" => current_balance
            }
            account_details = Repo.get_by(Companyaccounts, accomplish_account_id: accomplish_account_id)
            changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
            Repo.update(changeset_companyaccount)

            # UPDATE BALANCE OF ADMIN ACCOUNT
            gets_account = Accomplish.get_account(accomplish_account_id)
            current_balance = gets_account["info"]["balance"]
            update_balance = %{
              "balance" => current_balance
            }
            account_details = Repo.get_by(Adminaccounts, accomplish_account_id: accomplish_account_id)
            changeset_companyaccount = Adminaccounts.changesetUpdateBalance(account_details, update_balance)
            Repo.update(changeset_companyaccount)
          {:error, _changeset} ->
            update_status = %{"status" => "P", "remark" => remark}
            changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
            Repo.update(changeset_transaction)
        end
      else
        # UPDATE TRANSACTION BY ADDING RESPONSE MESSAGE TO DESCRIPTION
        update_status = %{"status" => "P", "description" => response_message, "remark" => remark}
        changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
        Repo.update(changeset_transaction)
      end
    end
  end

  def final_amount(amount, rules, total_card) do

    rules = Poison.decode!(rules)  # %{"amt" => "7.00", "limit" => "1", "type" => "A"}

    _response = case rules["type"] do
      "A" -> %{amount: amount, fees: "Account"}
      "C" -> if total_card <= String.to_integer("#{rules["limit"]}") do
               %{amount: amount, fees: "Card"}
             else
               extra_card = total_card - String.to_integer("#{rules["limit"]}")
               extra_amt = String.to_float("#{rules["amt"]}") * String.to_integer("#{extra_card}")
               final_amount = String.to_float("#{extra_amt}") + String.to_float("#{amount}")
               %{amount: final_amount, fees: "Card", extra_card: extra_card, extra_amt: extra_amt}
             end
      _ -> %{amount: amount, fees: "Transaction"}
    end

    #      _response = if rules["type"] == "A" do
    #                    %{amount: amount, fees: "Account"}
    #                  else
    #                      if total_card <= String.to_integer("#{rules["limit"]}") do
    #                        %{amount: amount, fees: "Card"}
    #                      else
    #                        extra_card = total_card - String.to_integer("#{rules["limit"]}")
    #                        extra_amt = String.to_float("#{rules["amt"]}") * String.to_integer("#{extra_card}")
    #                        final_amount = String.to_float("#{extra_amt}") + String.to_float("#{amount}")
    #                        %{amount: final_amount, fees: "Card", extra_card: extra_card, extra_amt: extra_amt}
    #                      end
    #                  end

  end


end