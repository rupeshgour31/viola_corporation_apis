defmodule Violacorp.Workers.V1.Transactions do
  import Ecto.Query
  require Logger
  alias Violacorp.Repo

  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Schemas.CardTransactionsandReceipts
  alias Violacorp.Schemas.Beneficiaries
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Expense

  def perform(params) do
    case params["worker_type"] do
      "pending_single_transactions_updater" ->
        Map.delete(params, "worker_type")
        |> pending_single_transactions_updater()
      "pending_transactions_updater" ->
        Map.delete(params, "worker_type")
        |> pending_transactions_updater()
      "success_transactions_updater" ->
        Map.delete(params, "worker_type")
        |> success_transactions_updater()
      "clearbank_transactions" ->
        Map.delete(params, "worker_type")
        |> clearbank_transactions()
      "clearbank_transactions_date_range" ->
        Map.delete(params, "worker_type")
        |> clearbank_transactions_date_range()
      "manual_pending" ->
        Map.delete(params, "worker_type")
        |> manual_pending()
      "manual_success" ->
        Map.delete(params, "worker_type")
        |> manual_success()
      "generate_report" ->
        Map.delete(params, "worker_type")
        |> generate_report()
      _ ->
        Logger.warn("Worker: #{params["worker_type"]} not found in Transactions")
        :ok
    end
  end

  @doc """
    Pending transactions updater function - updates pending trasactions from accomplish
  """
  def pending_single_transactions_updater(params) do
    employee_id = params["employee_id"]
    account_id = params["accomplish_card_id"]

    # get user id
    user = Repo.get_by!(Commanall, employee_id: employee_id)
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

      request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{
        status
      }&start_index=#{
        start_index
      }&page_size=#{page_size}"
      response = Accomplish.get_success_transaction(request)
      if !is_nil(response) do
        response_code = response["result"]["code"]
        if response_code == "0000" do
          Enum.each response["transactions"], fn v ->
            type = v["info"]["type"]
            text_msg = if type == 222 or type == 228 or type == 220 or type == 84 or type == 138 do
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

              transaction_id = v["info"]["original_source_id"]

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

                remark = %{"from" => to_card, "to" => notes_last_value}
                api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
                transaction_mode = if operation == "Debit" do
                  "D"
                else
                  "C"
                end
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

  @doc """
    Pending transactions updater function - updates pending trasactions from accomplish
  """
  def pending_transactions_updater(params) do
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
              text_msg = if type == 222 or type == 228 or type == 220 or type == 84 or type == 138 do
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
                  new_notes = if !is_nil(notes) do
                    String.replace(notes, ~r/ +/, " ")
                  else
                    ""
                  end
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
                    "C" ->
                      %{
                        "to" => to_card,
                        "from" => notes_last_value,
                        "to_info" =>
                        %{
                          "owner_name" => "#{employee_com.first_name} #{employee_com.last_name}",
                          "card_number" => "#{to_card}",
                          "sort_code" => "",
                          "account_number" => ""
                        },
                        "from_info" => %{
                          "owner_name" => notes_last_value,
                          "card_number" => "",
                          "sort_code" => "",
                          "account_number" => ""
                        }
                      }
                    "D" ->
                      %{
                        "from" => to_card,
                        "to" => notes_last_value,
                        "from_info" =>
                        %{
                          "owner_name" => "#{employee_com.first_name} #{employee_com.last_name}",
                          "card_number" => "#{to_card}",
                          "sort_code" => "",
                          "account_number" => ""
                        },
                        "to_info" => %{
                          "owner_name" => notes_last_value,
                          "card_number" => "",
                          "sort_code" => "",
                          "account_number" => ""
                        }
                      }
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
                    new_total_amount = Decimal.add(check_existing.total_amount, amount)
                    new_total_transactions = check_existing.total_transactions + 1
                    update_card_records = %{
                      "total_amount" => new_total_amount,
                      "total_transactions" => new_total_transactions
                    }
                    changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(
                      check_existing,
                      update_card_records
                    )
                    Repo.update(changeset_card_records)
                  else
                    #If card records does not exist then add it
                    add_card_records = %{
                      "employeecards_id" => employeecards_id,
                      "total_amount" => amount,
                      "total_transactions" => 1
                    }
                    changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(
                      %CardTransactionsandReceipts{},
                      add_card_records
                    )
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
      ios_messagebody = %{
        "worker_type" => "send_android",
        "token" => get_platform.token,
        "msg" => %{
          "body" => "#{params["currency"]}#{params["amount"]} at #{params["shopname"]}"
        }
      }
      android_messagebody = %{
        "worker_type" => "send_ios",
        "token" => get_platform.token,
        "msg" => %{
          "body" => "#{params["currency"]}#{params["amount"]} at #{params["shopname"]}"
        }
      }
      if get_platform.type == "A" and !is_nil(android_messagebody["token"]) do
        Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [android_messagebody], max_retries: 1)
      else
        if get_platform.type == "I" and !is_nil(ios_messagebody["token"]) do
          Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [ios_messagebody], max_retries: 1)
        end
      end
    end
  end

  @doc """
    Success transactions updater function - updates success trasactions from accomplish
  """
  def success_transactions_updater(params) do
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
          where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.status == ^"S" and not is_nil(
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

        status = "0" # 0 = success and 1 = pending
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
              text_msg = if type == 222 or type == 228 or type == 220 or type == 84 or type == 138 do
                nil
              else
                "Transaction"
              end

              if !is_nil(text_msg) do
                ids = v["info"]["id"]
                [check_transaction] = Repo.all from a in Transactions, where: a.pos_id == ^ids,
                                                                       select: count(a.pos_id)
                if check_transaction == 0 do
                  # check pending row
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

                  transaction_type_new = if trans_type == 123 do
                    "C2F"
                  else
                    transaction_type
                  end

                  transaction_category = if trans_type == 123 do
                    "FEE"
                  else
                    "POS"
                  end
                  transaction_id = String.trim(v["info"]["original_source_id"])
                  last_pending_transaction = Repo.one(
                    from t in Transactions,
                    where: t.commanall_id == ^commanall_id and t.transactions_id_api == ^transaction_id and t.category == ^"POS" and t.employeecards_id == ^employeecards_id and t.status == ^"P",
                    order_by: [
                      desc: t.id
                    ],
                    limit: 1,
                    select: %{
                      id: t.id,
                      description: t.description
                    }
                  )

                  notes = v["info"]["notes"]
                  new_notes = String.replace(notes, ~r/ +/, " ")
                  response_notes = String.split(new_notes, "-", trim: true)
                  notes_last_value = response_notes
                                     |> Enum.take(-1)
                                     |> Enum.join()
                  if is_nil(last_pending_transaction) do
                    operation = v["info"]["operation"]
                    date_utc = v["info"]["date_utc"]
                    transaction_mode = if operation == "Debit" do
                      "D"
                    else
                      "C"
                    end
                    #                  remark = %{"from" => to_card, "to" => notes_last_value}
                    remark = case transaction_mode do
                      "C" ->
                        %{
                          "to" => to_card,
                          "from" => notes_last_value,
                          "to_info" =>
                          %{
                            "owner_name" => "#{employee_com.first_name} #{employee_com.last_name}",
                            "card_number" => "#{to_card}",
                            "sort_code" => "",
                            "account_number" => ""
                          },
                          "from_info" => %{
                            "owner_name" => notes_last_value,
                            "card_number" => "",
                            "sort_code" => "",
                            "account_number" => ""
                          }
                        }
                      "D" ->
                        %{
                          "from" => to_card,
                          "to" => notes_last_value,
                          "from_info" =>
                          %{
                            "owner_name" => "#{employee_com.first_name} #{employee_com.last_name}",
                            "card_number" => "#{to_card}",
                            "sort_code" => "",
                            "account_number" => ""
                          },
                          "to_info" => %{
                            "owner_name" => notes_last_value,
                            "card_number" => "",
                            "sort_code" => "",
                            "account_number" => ""
                          }
                        }
                    end
                    api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}

                    # Create POS transaction
                    transaction = %{
                      "commanall_id" => commanall_id,
                      "company_id" => company_id,
                      "employee_id" => employee_id,
                      "employeecards_id" => employeecards_id,
                      "pos_id" => ids,
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
                      "transaction_type" => transaction_type_new,
                      "category" => transaction_category,
                      "api_type" => trans_type,
                      "status" => "S",
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
                      new_total_amount = Decimal.add(check_existing.total_amount, amount)
                      new_total_transactions = check_existing.total_transactions + 1
                      update_card_records = %{
                        "total_amount" => new_total_amount,
                        "total_transactions" => new_total_transactions
                      }
                      changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(
                        check_existing,
                        update_card_records
                      )
                      Repo.update(changeset_card_records)
                    else
                      #If card records does not exist then add it
                      add_card_records = %{
                        "employeecards_id" => employeecards_id,
                        "total_amount" => amount,
                        "total_transactions" => 1
                      }
                      changeset_card_records = CardTransactionsandReceipts.changesetInsertorUpdate(
                        %CardTransactionsandReceipts{},
                        add_card_records
                      )
                      Repo.insert(changeset_card_records)
                    end
                  else
                    last_notes = last_pending_transaction.description
                    last_new_notes = String.replace(last_notes, ~r/ +/, " ")
                    response_notes_db = String.split(last_new_notes, "/", trim: true)
                    notes_last_value_db = response_notes_db
                                          |> Enum.take(1)
                                          |> Enum.join()

                    response_notes_live = String.split(new_notes, "/", trim: true)
                    notes_last_value_live = response_notes_live
                                            |> Enum.take(1)
                                            |> Enum.join()
                    if notes_last_value_db == notes_last_value_live do
                      trans_status = Repo.get(Transactions, last_pending_transaction.id)
                      update_status = %{
                        "status" => "S",
                        "pos_id" => ids,
                        "previous_amount" => trans_status.amount,
                        "amount" => amount
                      }
                      changeset_transaction = Transactions.changesetUpdateStatusApi(trans_status, update_status)
                      Repo.update(changeset_transaction)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end


  @doc """
    Clearbank Transactions Worker
  """
  def clearbank_transactions(params) do

    commanall = Repo.get(Commanall, params["commanall_id"])
    company_id = commanall.company_id
    get_account = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")

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
  @doc """
    Clearbank Transactions Worker for given date range
  """
  def clearbank_transactions_date_range(params) do
    commanall = Repo.get(Commanall, params["commanall_id"])
    company_id = commanall.company_id
    get_account = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")
    if !is_nil(get_account) do
      endpoint = "#{get_account.account_id}/Transactions/"
      response = Clearbank.get_transaction_for_date_range(endpoint, params)
      Enum.each response["transactions"], fn transactions ->

        already_exists = transaction_exist_and_status_check(commanall, transactions)
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
        Repo.get_by(
          Transactions,
          commanall_id: commanall.id,
          transaction_id: clearbank_transaction["endToEndIdentifier"],
          transaction_mode: "D"
        )
      "CRDT" ->
        Repo.get_by(
          Transactions,
          commanall_id: commanall.id,
          transaction_id: clearbank_transaction["endToEndIdentifier"],
          transaction_mode: "C"
        )
    end
    case check do
      nil -> "false"
      _ -> "true"
    end
  end

  defp transaction_exist_and_status_check(commanall, clearbank_transaction) do
    check = case clearbank_transaction["debitCreditCode"] do
      "DBIT" ->
        transaction = Repo.get_by(
          Transactions,
          commanall_id: commanall.id,
          transaction_id: clearbank_transaction["endToEndIdentifier"],
          transaction_mode: "D"
        )
        cond do
          is_nil(transaction) -> transaction
          transaction.status !== "S" ->
            update_status = %{"status" => "S"}
            changeset = Transactions.changesetUpdateStatusOnly(transaction, update_status)
            Repo.update(changeset)
            "true"
          true -> transaction
        end
      "CRDT" ->
        transaction = Repo.get_by(
          Transactions,
          commanall_id: commanall.id,
          transaction_id: clearbank_transaction["endToEndIdentifier"],
          transaction_mode: "C"
        )
        cond do
          is_nil(transaction) -> transaction
          transaction.status !== "S" ->
            update_status = %{"status" => "S"}
            changeset = Transactions.changesetUpdateStatusOnly(transaction, update_status)
            Repo.update(changeset)
            "true"
          true -> transaction
        end
    end
    case check do
      nil -> "false"
      _ -> "true"
    end
  end

  defp add_transaction(commanall, clearbank_transaction, account) do

    Logger.warn("Pull Transaction date-wise response: #{Poison.encode!(clearbank_transaction)}")
    type_debit = Application.get_env(:violacorp, :transfer_debit)
    type_credit = Application.get_env(:violacorp, :transfer_credit)
    counterpart = cond do
      clearbank_transaction["debitCreditCode"] == "CRDT" -> "iban not available"
      Map.has_key?(clearbank_transaction["counterpartAccount"], "identification") -> cond do
                                                                                       Map.has_key?(
                                                                                         clearbank_transaction["counterpartAccount"]["identification"],
                                                                                         "iban"
                                                                                       ) -> "iban available"
                                                                                       true -> "iban not available"
                                                                                     end
      true -> "identification not available"
    end

    #    counterpart = cond do
    #      Map.has_key?(clearbank_transaction["counterpartAccount"], "identification") -> cond do
    #                                                                                       Map.has_key?(
    #                                                                                         clearbank_transaction["counterpartAccount"]["identification"],
    #                                                                                         "iban"
    #                                                                                       ) -> "iban available"
    #                                                                                       true -> "iban not available"
    #                                                                                     end
    #      Map.has_key?(clearbank_transaction["counterpartAccount"], "iban") -> "iban available"
    #      Map.has_key?(clearbank_transaction["Payload"]["CounterpartAccount"], "iban") -> "iban available"
    #      true -> "identification not available"
    #    end

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

    remark = %{
      "from" => from_user.all,
      "from_info" =>
      %{
        "owner_name" => "#{get_company.company_name}",
        "card_number" => "",
        "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}",
        "account_number" => "#{account.account_number}"
      },
      "to_info" => %{
        "owner_name" => "",
        "card_number" => "",
        "sort_code" => "",
        "account_number" => ""
      }
    }

    transaction_amt = clearbank_transaction["amount"]["instructedAmount"]
    trans_amt = Decimal.new(transaction_amt)
                |> Decimal.round(2, :down)
    transaction = %{
      "commanall_id" => commanall.id,
      "company_id" => commanall.company_id,
      "bank_id" => account.id,
      "amount" => trans_amt,
      "fee_amount" => 0.00,
      "final_amount" => trans_amt,
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
          #          first_name: to_user.first_name,
          #          last_name: to_user.last_name,
          account_number: to_user.account_number,
          sort_code: to_user.sortcode,
          status: "A"
        )

        owner_name = if is_nil(beneficiary), do: "", else: "#{beneficiary.first_name} #{beneficiary.last_name}"
        additional = case clearbank_transaction["debitCreditCode"] do
          "DBIT" ->

            remark = %{
              "from" => from_user.all,
              "to" => to_user.all,
              "from_info" =>
              %{
                "owner_name" => "#{get_company.company_name}",
                "card_number" => "",
                "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}",
                "account_number" => "#{account.account_number}"
              },
              "to_info" => %{
                "owner_name" => owner_name,
                "card_number" => "",
                "sort_code" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code}",
                "account_number" => "#{account_number}"
              }
            }

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

            remark = %{
              "from" => from_user.all,
              "to" => to_user.all,
              "to_info" =>
              %{
                "owner_name" => "#{get_company.company_name}",
                "card_number" => "",
                "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}",
                "account_number" => "#{account.account_number}"
              },
              "from_info" => %{
                "owner_name" => owner_name,
                "card_number" => "",
                "sort_code" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code}",
                "account_number" => "#{account_number}"
              }
            }
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

        notes = Poison.encode!(clearbank_transaction["counterpartAccount"])
        bban = clearbank_transaction["counterpartAccount"]["identification"]["other"]["identification"]
        account_number = if !is_nil(bban) do
          length_iban = String.length(bban)
          String.slice(bban, -8, length_iban)
        else
          ""
        end

        to_sort_code = if account_number != "" do
          trimmed = String.trim(bban, account_number)
          lenght = String.length(trimmed)
          String.slice(trimmed, -6, lenght)
        else
          ""
        end

        to_ff_code = if to_sort_code != "", do: String.slice(to_sort_code, 0..1), else: ""
        to_ss_code = if to_sort_code != "", do: String.slice(to_sort_code, 2..3), else: ""
        to_tt_code = if to_sort_code != "", do: String.slice(to_sort_code, 4..5), else: ""

        #        remark = %{"from" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code} #{account_number}", "to" => from_user.all}
        remark = %{
          "from" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code} #{account_number}",
          "from_info" => %{
            "owner_name" => "",
            "card_number" => "",
            "sort_code" => "#{to_ff_code}-#{to_ss_code}-#{to_tt_code}",
            "account_number" => "#{account_number}"
          },
          "to" => from_user.all,
          "to_info" => %{
            "owner_name" => get_company.company_name,
            "card_number" => "",
            "sort_code" => "#{from_ff_code}-#{from_ss_code}-#{from_tt_code}",
            "account_number" => "#{account.account_number}"
          }
        }

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
              "transactions_id_api" => clearbank_transaction["transactionReference"],
              "api_type" => type_credit,
              "remark" => Poison.encode!(remark),
              "notes" => "#{notes}"
            }
        end

        Map.merge(transaction, additional)
    end
    changeset = Transactions.changesetClearbankWorker(%Transactions{}, new_transaction)
    Repo.insert(changeset)
  end

  @doc """
     Manual Pending Worker
  """
  def manual_pending(params) do
    employee_card_id = params["id"]
    employee_card_details = Repo.get(Employeecards, employee_card_id)
    employee_id = employee_card_details.employee_id

    # get comman all id and accomplish id
    user = Repo.get_by!(Commanall, employee_id: employee_id)

    # get company id
    employee_com = Repo.get(Employee, employee_id)
    company_id = employee_com.company_id


    commanall_id = user.id
    user_id = user.accomplish_userid
    account_id = employee_card_details.accomplish_card_id
    from_date = params["from_date"]
    to_date = params["to_date"]
    status = "1" # 1 = Pending
    start_index = "0"
    page_size = "200"

    request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{
      status
    }&start_index=#{start_index}&page_size=#{page_size}"
    #    request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{start_index}&page_size=#{page_size}"

    response = Accomplish.get_success_transaction(request)
    if !is_nil(response) do
      response_code = response["result"]["code"]
      if response_code == "0000" do
        Enum.each response["transactions"], fn v ->
          type = v["info"]["type"]
          text_msg = if type == 222 or type == 228 or type == 220 or type == 84 or type == 138 do
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

            transaction_id = v["info"]["original_source_id"]

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

              remark = %{"from" => to_card, "to" => notes_last_value}
              api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
              transaction_mode = if operation == "Debit" do
                "D"
              else
                "C"
              end
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

            end
          end
        end
      end
    end
  end

  @doc """
     Manual Success Worker
  """
  def manual_success(params) do
    employee_card_id = params["id"]
    employee_card_details = Repo.get(Employeecards, employee_card_id)
    employee_id = employee_card_details.employee_id

    # get comman all id and accomplish id
    user = Repo.get_by!(Commanall, employee_id: employee_id)

    # get company id
    employee_com = Repo.get(Employee, employee_id)
    company_id = employee_com.company_id


    commanall_id = user.id
    user_id = user.accomplish_userid
    account_id = employee_card_details.accomplish_card_id
    from_date = params["from_date"]
    to_date = params["to_date"]
    status = "0" # 0 = Success
    start_index = "0"
    page_size = "200"

    request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{
      status
    }&start_index=#{start_index}&page_size=#{page_size}"
    #    request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{start_index}&page_size=#{page_size}"

    response = Accomplish.get_success_transaction(request)
    if !is_nil(response) do
      response_code = response["result"]["code"]
      if response_code == "0000" do
        Enum.each response["transactions"], fn v ->
          type = v["info"]["type"]
          text_msg = if type == 222 or type == 228 or type == 220 or type == 84 or type == 138 do
            nil
          else
            "Transaction"
          end

          if !is_nil(text_msg) do
            ids = v["info"]["id"]
            [check_transaction] = Repo.all from a in Transactions, where: a.pos_id == ^ids,
                                                                   select: count(a.pos_id)
            if check_transaction == 0 do
              # check pending row
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

              transaction_type_new = if trans_type == 123 do
                "C2F"
              else
                transaction_type
              end

              transaction_category = if trans_type == 123 do
                "FEE"
              else
                "POS"
              end

              last_pending_transaction = Repo.one(
                from t in Transactions,
                where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.amount == ^amount and t.employeecards_id == ^employeecards_id and t.status == ^"P",
                order_by: [
                  desc: t.id
                ],
                limit: 1,
                select: %{
                  id: t.id,
                  description: t.description
                }
              )

              notes = v["info"]["notes"]
              new_notes = String.replace(notes, ~r/ +/, " ")
              response_notes = String.split(new_notes, "-", trim: true)
              notes_last_value = response_notes
                                 |> Enum.take(-1)
                                 |> Enum.join()
              if is_nil(last_pending_transaction) do
                operation = v["info"]["operation"]
                date_utc = v["info"]["date_utc"]
                transaction_id = v["info"]["original_source_id"]
                remark = %{"from" => to_card, "to" => notes_last_value}
                api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
                transaction_mode = if operation == "Debit" do
                  "D"
                else
                  "C"
                end
                # Create POS transaction
                transaction = %{
                  "commanall_id" => commanall_id,
                  "company_id" => company_id,
                  "employee_id" => employee_id,
                  "employeecards_id" => employeecards_id,
                  "pos_id" => ids,
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
                  "transaction_type" => transaction_type_new,
                  "category" => transaction_category,
                  "api_type" => trans_type,
                  "status" => "S",
                  "description" => new_notes,
                  "remark" => Poison.encode!(remark),
                  "inserted_by" => commanall_id
                }
                changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
                Repo.insert(changeset_transaction)
              else
                last_notes = last_pending_transaction.description
                last_new_notes = String.replace(last_notes, ~r/ +/, " ")
                response_notes_db = String.split(last_new_notes, "/", trim: true)
                notes_last_value_db = response_notes_db
                                      |> Enum.take(1)
                                      |> Enum.join()

                response_notes_live = String.split(new_notes, "/", trim: true)
                notes_last_value_live = response_notes_live
                                        |> Enum.take(1)
                                        |> Enum.join()
                if notes_last_value_db == notes_last_value_live do
                  transaction_id = v["info"]["original_source_id"]
                  trans_status = Repo.get(Transactions, last_pending_transaction.id)
                  update_status = %{"status" => "S", "pos_id" => ids, "transactions_id_api" => transaction_id}
                  changeset_transaction = Transactions.changesetUpdateStatusApi(trans_status, update_status)
                  Repo.update(changeset_transaction)
                end
              end
            end
          end
        end
      end
    end
  end

  @doc """
     Generate Report Worker - generate expense sheet
  """
  def generate_report(params) do

    commanid = params["commanid"]
    #        companyid = params["company_id"]
    employee_id = params["employee_id"]
    card_id = params["card_id"]
    last_digit = params["last_digit"]
    start_date = params["start_date"]
    last_date = params["last_date"]

    from_date = "#{start_date} 00:00:00"
    to_date = "#{last_date} 23:59:00"

    # Get Transactions
    get_transactions = Repo.all (
                                  from t in Transactions,
                                       where: t.employeecards_id == ^card_id and t.category == "POS",
                                       having: t.transaction_date >= ^from_date and t.transaction_date <= ^to_date,
                                       order_by: [
                                         desc: t.transaction_date
                                       ],
                                       select: %{
                                         transaction_date: t.transaction_date,
                                         server_date: t.server_date,
                                         employee_id: t.employee_id,
                                         transaction_id: t.transaction_id,
                                         final_amount: t.final_amount,
                                         cur_code: t.cur_code,
                                         remark: t.remark,
                                         card_id: t.employeecards_id,
                                         description: t.description,
                                         status: t.status,
                                         row_id: t.id
                                       })

    response_data = Poison.encode!(get_transactions)
    if response_data != "[]" do

      # Get company name
      #          com_details = Repo.one from c in Company, where: c.id == ^companyid,
      #                                                    select: %{
      #                                                      company_name: c.company_name
      #                                                    }
      #          company_name = com_details.company_name
      company_name = ""
      period = "#{start_date} to #{last_date}"

      main_heading = [
        ['VIOLA'],
        ['EXPENSE FORM'],
        [],
        ['Individual', '#{company_name}'],
        [],
        ['Period', '#{period}'],
        []
      ]
      total_amount = Repo.one from t in Transactions,
                              where: t.employeecards_id == ^card_id and t.category == "POS" and (
                                t.transaction_date >= ^from_date and t.transaction_date <= ^to_date),
                              select: sum(t.final_amount)

      heading = [
        ['Card Number: ', '#{last_digit}'],
        [],
        ['#', 'Description', 'Currency', 'Amount', 'Transaction Id', 'Server Date', 'Status']
      ]

      map = Stream.with_index(get_transactions)
            |> Enum.reduce(
                 %{},
                 fn ({w, k}, emp) ->
                   transaction_id = w.transaction_id
                   final_amount = w.final_amount
                   status = w.status
                   server_date = w.server_date
                   description = w.description
                   cur_code = w.cur_code

                   status_msg = if status == "S" do
                     "Success"
                   else
                     if status == "P" do
                       "Pending"
                     else
                       "Failed"
                     end
                   end

                   new = [
                     '#{k + 1}',
                     '#{description}',
                     '#{cur_code}',
                     '#{final_amount}',
                     '#{transaction_id}',
                     '#{server_date}',
                     '#{status_msg}'
                   ]
                   Map.put(emp, k, new)
                 end
               )

      new_data = Map.values(map)

      footer = [['', '', 'Total', '#{total_amount}']]

      csv_content = main_heading ++ heading ++ new_data ++ footer
                    |> CSV.encode
                    |> Enum.to_list
                    |> to_string

      csv_img = Base.encode64(to_string(csv_content))
      file_location = ViolacorpWeb.Main.Assetstore.upload_file(csv_img)

      expense =
        %{
          "commanall_id" => commanid,
          "employee_id" => employee_id,
          "employeecards_id" => card_id,
          "aws_url" => file_location,
          "generate_date" => from_date
        }

      expense_changeset = Expense.changeset(%Expense{}, expense)
      case Repo.insert(expense_changeset) do
        {:ok, _expense} -> "Inserted"
        {:error, _changeset} -> "Error"
      end
    end
  end

end