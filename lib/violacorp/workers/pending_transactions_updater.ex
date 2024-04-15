defmodule Violacorp.Workers.PendingTransactionsUpdater do
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.CardTransactionsandReceipts

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish

  alias Violacorp.Workers.SendIos
  alias Violacorp.Workers.SendAndroid



  @moduledoc "Pending transactions updater function - updates pending trasactions from accomplish"

  def perform(params) do
    employee_id = params["employee_id"]

    # get user id
    user = Repo.get_by!(Commanall, employee_id: employee_id)
    if !is_nil(user) do
      commanall_id = user.id
      user_id = user.accomplish_userid

      # get company id
      employee_com = Repo.get(Employee, employee_id)
      company_id = employee_com.company_id

      if !is_nil(user_id) do

        last_transaction = Repo.one(
          from t in Transactions,
          where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.status == ^"P" and not is_nil(
            t.server_date
          ),
          order_by: [
            desc: t.id
          ],
          limit: 1,
          select: %{
            transaction_date: t.transaction_date
          }
        )

        last_date = if last_transaction !== nil do
          last_transaction.transaction_date
        else
          user.inserted_at
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

        status = "1" # 0 = success and 1 = pending
        start_index = "0"
        page_size = "50"

        request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{
          start_index
        }&page_size=#{page_size}"
        response = Accomplish.get_success_transaction(request)

        if !is_nil(response) do
          response_code = response["result"]["code"]
          if response_code == "0000" do
            Enum.each response["transactions"], fn v ->
              type = v["info"]["type"]
              text_msg = if type == 222 or type == 228 or type == 220 or type == 84  or type == 138 do
                nil
              else
                "Transaction"
              end

              if !is_nil(text_msg) do
                server_date = v["info"]["server_date"]
                amount = v["info"]["amount"]
                trans_type = v["info"]["type"]

                accomplish_card_id = v["info"]["account_id"]
                employeecards = Repo.get_by!(Employeecards, accomplish_card_id: accomplish_card_id)
                employeecards_id = employeecards.id
                currency = employeecards.currency_code
                to_card = employeecards.last_digit
                card_type = employeecards.card_type

                transaction_type = if card_type == "P" do
                  "C2O"
                else
                  "C2I"
                end

                transaction_id = String.trim(v["info"]["original_source_id"])

                [check_transaction_api_id] = Repo.all from a in Transactions,
                                                      where: a.transactions_id_api == ^transaction_id and a.status == "P",
                                                      select: count(a.transactions_id_api)
                if check_transaction_api_id == 0 do
                  operation = v["info"]["operation"]
                  date_utc = v["info"]["date_utc"]
                  notes = v["info"]["notes"]
                  new_notes = String.replace(notes, ~r/ +/, " ")
                  response_notes = String.split(new_notes, "-", trim: true)
                  notes_last_value = response_notes
                                     |> Enum.take(-1)
                                     |> Enum.join()
                  transaction_mode = if operation == "Debit" do
                    "D"
                  else
                    "C"
                  end
                  #                    remark = %{"from" => to_card, "to" => notes_last_value}
                  remark = case transaction_mode do
                    "C" -> %{"to" => to_card, "from" => notes_last_value, "to_info" =>
                    %{"owner_name" => "#{employee_com.first_name} #{employee_com.last_name}", "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""},
                             "from_info" => %{"owner_name" => notes_last_value, "card_number" => "", "sort_code" => "", "account_number" => ""}}
                    "D" -> %{"from" => to_card, "to" => notes_last_value, "from_info" =>
                    %{"owner_name" => "#{employee_com.first_name} #{employee_com.last_name}", "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""},
                             "to_info" => %{"owner_name" => notes_last_value, "card_number" => "", "sort_code" => "", "account_number" => ""}}
                  end





                  api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}

                  # Create POS transaction
                  transaction = %{
                    "commanall_id" => commanall_id,
                    "company_id" => company_id,
                    "employee_id" => employee_id,
                    "employeecards_id" => employeecards_id,
                    "pos_id" => 0,
                    "amount" => amount,
                    "fee_amount" => 0.00,
                    "final_amount" => amount,
                    "cur_code" => currency,
                    "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                    "transactions_id_api" => transaction_id,
                    "server_date" => server_date,
                    "transaction_date" => date_utc,
                    "api_transaction_date" => Poison.encode!(api_transaction_date),
                    "transaction_mode" => transaction_mode,
                    "transaction_type" => transaction_type,
                    "api_type" => trans_type,
                    "category" => "POS",
                    "status" => "P",
                    "description" => new_notes,
                    "remark" => Poison.encode!(remark),
                    "inserted_by" => commanall_id
                  }
                  changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
                  Repo.insert(changeset_transaction)

                  # Store total Card Transactions
                  check_existing = Repo.get_by(CardTransactionsandReceipts, employeecards_id: employeecards_id)
                  if check_existing do
                    #If card records exists then update it
                    new_total_amount =  Decimal.add(check_existing.total_amount, amount)
                    new_total_transactions = check_existing.total_transactions + 1
                    update_card_records = %{
                      "total_amount" => new_total_amount,
                      "total_transactions" => new_total_transactions
                    }
                    changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(check_existing,update_card_records)
                    Repo.update(changeset_card_records)
                  else
                    #If card records does not exist then add it
                    add_card_records = %{
                      "employeecards_id" => employeecards_id,
                      "total_amount" => amount,
                      "total_transactions" => 1
                    }
                    changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(%CardTransactionsandReceipts{},add_card_records)
                    Repo.insert(changeset_card_records)
                  end

                  currency_symbol = if currency == "GBP" do
                    "£"
                  else
                    if currency == "USD" do
                      "$"
                    else
                      if currency == "EUR" do
                        "€"
                      else
                        currency
                      end
                    end
                  end

                  notification_params = %{
                    "commanall_id" => commanall_id,
                    "currency" => currency_symbol,
                    "amount" => amount,
                    "shopname" => notes_last_value
                  }
                  sendNotification(notification_params)
                end

              end
            end
          end
        end
      end
    end
  end


  def sendNotification(params) do

    get_platform = Repo.get_by(Devicedetails, commanall_id: params["commanall_id"], status: "A", is_delete: "N")

    _send = if is_nil(get_platform) do
    else
      messagebody = %{
        "token" => get_platform.token,
        "msg" => %{
          "body" => "#{params["currency"]}#{params["amount"]} at #{params["shopname"]}"
        }
      }
      if get_platform.type == "A" do
        Exq.enqueue(Exq, "notification", SendAndroid, [messagebody], max_retries: 1)
      else
        if get_platform.type == "I" do
          Exq.enqueue(Exq, "notification", SendIos, [messagebody], max_retries: 1)
        end
      end
    end
  end
end
