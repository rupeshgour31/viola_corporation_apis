defmodule Violacorp.Libraries.TransactionFee do

  import Ecto.Query
  require Logger
  alias Violacorp.Repo
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Feehead
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Transactionsfee

  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools

  @moduledoc "Transaction Fees Library"

  @doc "Fee calculation for EVERY TRANSACTION"
  def fee_calculation(amount, transaction_mode, transaction_type) do
    # 1. Query to DB to get fee information [Feehead--groupfee]
    # 1.2 if query does not return a value then return amount values without any fee added
    # 2. List of fees applicable and calculation of fee amount depending on fee_type value [F=fixed,P=percentage] and looped for however many fees present
    # 3. Sum of all fees, and Final amount calculation depending on transaction_mode [C: subtract fee from amount,D: add fee on top of amount]
    # 4. Return map with fee applied

    # 1.
    raw_fee = Repo.one(
      from f in Feehead, where: f.title == ^transaction_type,
                         left_join: g in assoc(f, :groupfee),
                         on: g.mode == ^transaction_mode and g.trans_type == "EVERY" and g.status == "A",
                         preload: [
                           groupfee: g
                         ]
    )
    if !is_nil(raw_fee) and !Enum.empty?(raw_fee.groupfee) do
      # 2.
      all_fees = Enum.reduce(
        raw_fee.groupfee,
        [],
        fn (v, empty_list) ->
          fee_amount = if v.fee_type == "P" do
            (String.to_float("#{amount}") * String.to_float("#{v.amount}")) / 100
          else
            String.to_float("#{v.amount}")
          end
          fee = %{
            group_fee_id: v.id,
            fee_amt: Decimal.new(fee_amount)
                     |> Decimal.round(2),
            fee: v.amount,
            type: v.fee_type
          }
          empty_list ++ [fee]
        end
      )

      # 3.
      fee_amount_list = Enum.reduce(
        all_fees,
        0,
        fn (v, empty_list) ->
          Decimal.add(empty_list, v.fee_amt)
        end
      )
      fee_amount = Decimal.new(fee_amount_list)
                   |> Decimal.round(2)
      final_amount = case transaction_mode do
        "D" -> Decimal.add(
                 Decimal.new(amount)
                 |> Decimal.round(2),
                 fee_amount
               )
        "C" -> Decimal.sub(
                 Decimal.new(amount)
                 |> Decimal.round(2),
                 fee_amount
               )
      end
      # 4.
      %{fees: all_fees, amount: amount, fee_amount: "#{fee_amount}", final_amount: "#{final_amount}"}
    else
      # 1.2
      %{fees: [], amount: amount, fee_amount: "0.00", final_amount: amount}
    end
  end

  #
  #
  def charge_fee(transaction_id, fee, from_account) do
    # PARAMS DOC
    # {
    #   transaction_id: id of transaction to charge fee for.
    #   fee: result of TransactionFee.fee_calculation
    #   from_account: Repo struct of account to be charged.
    # }


    # 1. Get Adminaccounts details (DB)
    # 2. Insert Admintransactions (Pending)
    # 3. Transfer Fee to Admin Account
    # 4. Insert Transactionsfee  (loop however many fees charged)
    # 5. if transfer fee = successful do update Admintransactions status to S
    # 6. Update balances

    if !is_nil(transaction_id) and !is_nil(fee) and !is_nil(from_account) do
      bank_details = from_account
      fee_amount = fee.fee_amount
      today = DateTime.utc_now
      # 1.
      receive_party = Repo.get_by(Adminaccounts, account_name: "Fee Corporate Account")
      # 2. Admintransactions entry
      transaction_idd = Integer.to_string(Commontools.randnumber(10))
      reference = "#{Commontools.randnumber(8)}"

      if !is_nil(receive_party) do
        if String.to_float("#{fee_amount}") > String.to_float("0.00") do
          transaction = %{
            "adminaccounts_id" => receive_party.id,
            "amount" => fee_amount,
            "currency" => bank_details.currency,
            "from_user" => bank_details.iban_number,
            "to_user" => receive_party.iban_number,
            "reference_id" => reference,
            "transaction_id" => transaction_idd,
            "mode" => "D",
            "identification" => bank_details.iban_number,
            "api_status" => "CBF",
            "description" => "Transaction fee",
            "transaction_date" => today,
            "status" => "P",
            "end_to_en_identifier" => reference,
            "inserted_by" => receive_party.id
          }

          changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
          case Repo.insert(changeset) do
            {:ok, admin_trans} ->
              if String.to_float("#{from_account.balance}") >= String.to_float("#{fee_amount}") do
                paymentInstructionIdentification = "#{Commontools.randnumber(8)}"
                instructionIdentification = "#{Commontools.randnumber(8)}"
                d_identification = "#{Commontools.randnumber(8)}"
                reference = "#{Commontools.randnumber(8)}"
                # 3.
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
                  endToEndIdentification: "#{Commontools.randnumber(8)}", # CONFIRM WITH KK WHAT TO PUT HERE
                  c_name: receive_party.account_name,
                  c_iban: receive_party.iban_number,
                  c_proprietary: "Receiver",
                  c_code: "BBAN",
                  c_identification: "#{Commontools.randnumber(8)}",
                  c_issuer: "VIOLA",
                  reference: reference
                }
                output = Clearbank.paymentAToIB(accountDetails)

                # 4. Transactionfee entry
                Enum.each fee.fees, fn fee ->
                  transactionfee = %{
                    "transactions_id" => transaction_id,
                    "groupfee_id" => fee.group_fee_id,
                    "fee_amount" => "#{fee.fee_amt}",
                    "fee_type" => fee.type,
                    "inserted_by" => "99999"
                  }

                  transaction_fee_changeset = Transactionsfee.changeset(%Transactionsfee{}, transactionfee)
                  Repo.insert(transaction_fee_changeset)
                end
                if !is_nil(output["transactions"]) do
                  res = get_in(output["transactions"], [Access.at(0)])
                  response = res["response"]
                  reference = res["endToEndIdentification"]
                  # 5.
                  if response == "Accepted" do
                    Repo.update(
                      Admintransactions.changesetUpdateStatus(
                        admin_trans,
                        %{"status" => "S", "end_to_en_identifier" => reference, "response" => response}
                      )
                    )
                  else
                    Logger.warn("Failed to charge fee for Transaction #{transaction_id}, rejected by CB")
                  end
                  # 6.
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
                else
                  Logger.warn("Failed to charge fee for Transaction #{transaction_id}, no response from CB")
                end
              else
                Logger.warn("Failed to charge fee for Transaction #{transaction_id}, insufficient balance")
              end
            {:error, _changeset} ->
                                    Logger.warn("Failed to insert Admin Transaction for Transaction #{transaction_id}")
          end
        end
      else
        Logger.warn("Failed to fetch Admin Account details for TransactionFee, transaction affected: #{transaction_id}")
      end
    else
      Logger.warn("Incomplete params TransactionFee charge_fee")
    end
  end
end