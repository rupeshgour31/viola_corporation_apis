defmodule Violacorp.Workers.ManualLoad do


  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Versions

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish
  import Ecto.Query

  alias Violacorp.Repo

  @moduledoc "SendAndroid function - send notifications to android"

  # Company Account Topup
def perform(params) do
commanid = params["commanall_id"]
companyid = params["company_id"]

  commanall_data = Repo.get_by!(Commanall, id: commanid)

  if is_nil(commanall_data.accomplish_userid) do
    %{"status_code" => "404", "data" => "Account not active."}
  end

  last_transaction = Repo.one(
    from t in Transactions, where: t.commanall_id == ^commanid and t.transaction_type == ^"B2A" and not is_nil(t.server_date),
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


  account_data = Repo.get_by(Companyaccounts, company_id: companyid)


  user_id = commanall_data.accomplish_userid
  start_index = "0"
  page_size = "50"

  request = if !is_nil(account_data) do
                "?user_id=#{user_id}&account_id=#{account_data.accomplish_account_id}&from_date=#{from_date}&to_date=#{to_date}&start_index=#{start_index}&page_size=#{page_size}"
            else
                "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&start_index=#{start_index}&page_size=#{page_size}"
            end


  response = Accomplish.get_success_transaction(request)

    if !is_nil(response) do
      if is_nil(response["result"]) do
        %{"status_code" => "404", "data" => "Server not responding."}
      else
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do

          Enum.each response["transactions"], fn post ->
            transaction_id = Integer.to_string(post["info"]["id"])
            type = post["info"]["type"]

            transaction_data = Repo.get_by(Transactions, transactions_id_api: transaction_id)

            transaction_unique = Repo.get_by(Transactions, transactions_id_api: post["info"]["original_source_id"])
            text_msg = if type == 222 or type == 228 or type == 220  do
              "not"
            else
              "ok"
            end

            if transaction_data == nil && transaction_unique == nil && text_msg == "ok" do
              notes = post["info"]["notes"]
              new_notes = String.replace(notes, ~r/ +/, " ")

              val = String.replace(notes, ~r[((.*?)(- on).(.+?-))], "")
              val = String.replace(val, ~r/\s+/, " ")
              val = String.replace(val, "General Credit: ", " ")


              get_company = Repo.get!(Company, companyid)
              server_date = post["info"]["server_date"]
              date_utc = post["info"]["date_utc"]
              amount = post["info"]["amount"]
              currency = post["info"]["currency"]

              balance = String.to_float("#{account_data.available_balance}") + String.to_float(amount)
#              remark = %{"from" => "#{val}", "to" => currency}
              remark = %{"from" => "#{val}", "to" => currency, "from_info" =>
              %{"owner_name" => val, "card_number" => "", "sort_code" => "", "account_number" => ""},
                "to_info" => %{"owner_name" => get_company.company_name, "card_number" => "", "sort_code" => "#{account_data.accomplish_account_id}", "account_number" => "#{account_data.accomplish_account_number}"}}

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
                "transaction_date" => date_utc,
                "transaction_mode" => "C",
                "transaction_type" => "B2A",
                "api_type" => type,
                "category" => "TU",
                "status" => "S",
                "description" => new_notes,
                "remark" => Poison.encode!(remark),
                "inserted_by" => commanid
              }

              changeset_transaction = Transactions.changeset(%Transactions{}, transaction)
              Repo.insert(changeset_transaction)
            end
          end

          #check on_boarding_fee
          if commanall_data.on_boarding_fee == "Y" do

            company_type = Repo.one(from ct in Company, where: ct.id == ^companyid, select: ct.company_type)

            version = Repo.get(Versions, "1")

            fee_amount = if company_type == "STR" do
              version.fee_sole_trade
            else
              version.fee_limited
            end

            # Call to accomplish
            request = %{
              type: "228",
              notes: "Charge onboarding fee", # Limited Debit   or  Monthly Fee Charges
              amount: fee_amount,
              currency: account_data.currency_code,
              account_id: account_data.accomplish_account_id
            }
            # Send to Accomplish
            response = Accomplish.load_money(request)

            response_code = response["result"]["code"]
            transactions_id_api = response["info"]["original_source_id"]

            if response_code == "0000" do
                # Check Available Balance
                account_balance = Repo.get_by(Companyaccounts, company_id: companyid)
                available_balance = account_balance.available_balance
                #check available balance is more than the fee amount, if true condition runs
                difference = Decimal.cmp(available_balance, fee_amount)

                if difference == :gt do
                  #Get new balance and update in table
                  new_balance = Decimal.sub(available_balance, fee_amount)
                  update_balance = %{available_balance: new_balance}
                  balance_changeset = Companyaccounts.changeset(account_balance, update_balance)
                  Repo.update(balance_changeset)
                  date_utc = DateTime.utc_now

                  get_company = Repo.get!(Company, companyid)
#                  remark = %{"from" => account_data.currency_code, "to" => "Viola Corporate"}
                  remark = %{"from" => account_data.currency_code, "to" => "Viola Corporate", "to_info" =>
                  %{"owner_name" => "Viola Corporate", "card_number" => "", "sort_code" => "", "account_number" => ""},
                    "from_info" => %{"owner_name" => get_company.company_name, "card_number" => "", "sort_code" => "#{account_data.accomplish_account_id}", "account_number" => "#{account_data.accomplish_account_number}"}}

                  # New transaction
                  transaction = %{
                    "commanall_id" => commanid,
                    "company_id" => companyid,
                    "amount" => 0.00,
                    "fee_amount" => fee_amount,
                    "final_amount" => fee_amount,
                    "cur_code" => account_data.currency_code,
                    "balance" => new_balance,
                    "previous_balance" => account_balance.available_balance,
                    "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                    "transactions_id_api" => transactions_id_api,
                    "transaction_date" => date_utc,
                    "transaction_mode" => "D",
                    "transaction_type" => "A2O",
                    "api_type" => "3001",
                    "category" => "FEE",
                    "status" => "S",
                    "description" => "On Boarding Fee",
                    "remark" => Poison.encode!(remark),
                    "inserted_by" => commanid
                  }
                  changeset_transaction = Transactions.changeset(%Transactions{}, transaction)
                  Repo.insert(changeset_transaction)

                  #update on_boarding_fee field
                  on_boarding = %{on_boarding_fee: "N"}
                  comman_changeset = Commanall.changesetFee(commanall_data, on_boarding)
                  Repo.update(comman_changeset)
                end
            end

          end
        else
          %{"status_code" => "504", "data" => response_message}
        end
      end

    else
        %{"status_code" => "404", "data" => "Server not responding."}
    end

  end
end