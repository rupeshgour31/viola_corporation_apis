defmodule Violacorp.Workers.ClearbankTransactions do

  alias Violacorp.Repo

  alias Violacorp.Schemas.Beneficiaries
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companybankaccount

  alias Violacorp.Libraries.Clearbank


  def perform(params) do

    commanall = Repo.get(Commanall, params["commanall_id"])
    company_id = commanall.company_id
    get_account = Repo.get_by!(Companybankaccount, company_id: company_id, status: "A")

    if !is_nil(get_account) do
      endpoint = "#{get_account.account_id}/Transactions/"

      response = Clearbank.get_transaction(endpoint)
      Enum.each response["transactions"], fn transactions ->

        already_exists = transaction_exist(commanall, transactions)
        _ok = case already_exists do
          "true" -> ""
          "false" -> add_transaction(commanall, transactions, get_account)
        end
      end
    end
  end


  defp transaction_exist(commanall, clearbank_transaction) do
    check = case clearbank_transaction["debitCreditCode"] do
      "DBIT" ->
        Repo.get_by(Transactions, commanall_id: commanall.id, transaction_id: clearbank_transaction["endToEndIdentifier"], transaction_mode: "D")
      "CRDT" ->
        Repo.get_by(Transactions, commanall_id: commanall.id, transaction_id: clearbank_transaction["endToEndIdentifier"], transaction_mode: "C")
    end
    case check do
      nil -> "false"
      _ -> "true"
    end
  end

  defp add_transaction(commanall, clearbank_transaction, account) do

    type_debit = Application.get_env(:violacorp, :transfer_debit)
    type_credit = Application.get_env(:violacorp, :transfer_credit)
    counterpart = cond do
      Map.has_key?(clearbank_transaction["counterpartAccount"], "identification") -> cond do
                                                                                       Map.has_key?(
                                                                                         clearbank_transaction["counterpartAccount"]["identification"],
                                                                                         "iban"
                                                                                       ) -> "iban available"
                                                                                       true -> "iban not available"
                                                                                     end
      Map.has_key?(clearbank_transaction["counterpartAccount"], "iban") -> "iban available"
      Map.has_key?(clearbank_transaction["Payload"]["CounterpartAccount"], "iban") -> "iban available"
      true -> "identification not available"
    end

    from_sort_code = account.sort_code
    from_ff_code = String.slice(from_sort_code, 0..1)
    from_ss_code = String.slice(from_sort_code, 2..3)
    from_tt_code = String.slice(from_sort_code, 4..5)
    from_user = %{
      all: "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}   #{account.account_number}",
      sortcode: from_sort_code,
      account_number: account.account_number
    }

    transaction_status = case clearbank_transaction["status"] do
      "ACSC" -> "S"
      _ -> "F"
    end

    get_company = Repo.get(Company, commanall.company_id)


    remark = %{"from" => from_user.all, "from_info" =>
    %{"owner_name" => "#{get_company.company_name}", "card_number" => "",
      "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}", "account_number" => "#{account.account_number}"},
      "to_info" => %{"owner_name" => "", "card_number" => "", "sort_code" => "", "account_number" => ""}}

    transaction = %{
      "commanall_id" => commanall.id,
      "company_id" => commanall.company_id,
      "bank_id" => account.id,
      "amount" => clearbank_transaction["amount"]["instructedAmount"],
      "fee_amount" => 0.00,
      "final_amount" => clearbank_transaction["amount"]["instructedAmount"],
      "balance" => 0.00,
      "previous_balance" => 0.00,
      "cur_code" => clearbank_transaction["amount"]["currency"],
      "transaction_id" => clearbank_transaction["endToEndIdentifier"],
      "transaction_date" => clearbank_transaction["transactionTime"],
      "transaction_mode" => "D",
      "transaction_type" => "A2A",
      "category" => "AA",
      "status" => transaction_status,
      "description" => nil,
      "remark" => Poison.encode!(remark),
      "inserted_by" => commanall.id
    }

    new_transaction = case counterpart do
      "iban available" ->
        # ADD TRANSACTION WITH IBAN INFO
        iban = if is_nil(clearbank_transaction["counterpartAccount"]["identification"]["iban"]) do
          clearbank_transaction["Payload"]["CounterpartAccount"]["IBAN"]
        else
          clearbank_transaction["counterpartAccount"]["identification"]["iban"]
        end



            length_iban = String.length(iban)
            account_number = String.slice(iban, -8, length_iban)

            trimmed = String.trim(iban, account_number)
            lenght = String.length(trimmed)
            to_sort_code = String.slice(trimmed, -6, lenght)
            to_ff_code = String.slice(to_sort_code, 0..1)
            to_ss_code = String.slice(to_sort_code, 2..3)
            to_tt_code = String.slice(to_sort_code, 4..5)
        to_user = %{
              all: "#{to_ff_code} - #{to_ss_code} - #{to_tt_code}   #{account_number}",
              sortcode: to_sort_code,
              account_number: account_number
            }

        beneficiary = Repo.get_by(
          Beneficiaries,
          company_id: commanall.company_id,
          first_name: to_user.first_name,
          last_name: to_user.last_name,
          account_number: to_user.account_number,
          sort_code: to_user.sortcode,
          status: "A"
        )
        additional = case clearbank_transaction["debitCreditCode"] do
          "DBIT" ->

          remark = %{"from" => from_user.all, "to" => to_user.all, "from_info" =>
          %{"owner_name" => "#{get_company.company_name}", "card_number" => "",
            "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}", "account_number" => "#{account.account_number}"},
            "to_info" => %{"owner_name" => "#{beneficiary.first_name} #{beneficiary.last_name}", "card_number" => "",
              "sort_code" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code}", "account_number" => "#{account_number}"}}
            %{
              "remark" => Poison.encode!(remark),
              "transactions_id_api" => clearbank_transaction["transactionReference"],
              "api_type" => type_debit,
              "description" => if is_nil(beneficiary) do
                "Transfer to #{to_user.all}"
              else
                "Transfer for my beneficiary"
              end,
              "beneficiaries_id" => if is_nil(beneficiary) do
                nil
              else
                beneficiary.id
              end
            }
          "CRDT" ->

            remark = %{"from" => from_user.all, "to" => to_user.all, "to_info" =>
            %{"owner_name" => "#{get_company.company_name}", "card_number" => "",
              "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}", "account_number" => "#{account.account_number}"},
              "from_info" => %{"owner_name" => "#{beneficiary.first_name} #{beneficiary.last_name}", "card_number" => "",
                "sort_code" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code}", "account_number" => "#{account_number}"}}
            %{
              "remark" => Poison.encode!(remark),
              "transaction_mode" => "C",
              "description" => "Received from #{to_user.all}",
              "api_type" => type_credit,
              "beneficiaries_id" => if is_nil(beneficiary) do
                nil
              else
                beneficiary.id
              end
            }

          _ -> ""
        end

        Map.merge(transaction, additional)

      _ ->
        #"add transactation without iban details"

        notes = Poison.decode!(clearbank_transaction["counterpartAccount"])

        additional = case clearbank_transaction["debitCreditCode"] do
          "DBIT" -> %{
                      "description" => "Transfer money",
                      "transactions_id_api" => clearbank_transaction["transactionReference"],
                      "api_type" => type_debit,
                      "notes" => "#{notes}"
                    }
          "CRDT" ->
            %{
              "transaction_mode" => "C",
              "description" => "Received money",
              "api_type" => type_credit,
              "remark" => "#{notes}"
            }
        end
        Map.merge(transaction, additional)
    end
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, new_transaction)
    Repo.insert(changeset)
  end

end