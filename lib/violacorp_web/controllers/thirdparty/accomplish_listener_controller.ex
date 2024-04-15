defmodule ViolacorpWeb.Thirdparty.AccomplishListenerController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  require Logger
  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards

  alias Violacorp.Libraries.Commontools


  def listener(conn, params) do

    Logger.warn "accomplish push Notification Request: #{~s(#{Poison.encode!(params)})}"


    #    user_id = params["host_message"]["transaction_info"]["user_id"]
    user_id = params["info"]["user_id"]
    account_id = params["host_message"]["transaction_info"]["account_id"]
    amount = params["host_message"]["transaction_info"]["amount"]
    #    notes = params["host_message"]["transaction_info"]["notes"]
    notes = params["info"]["host_message_desc"]
    #    source_id = params["host_message"]["transaction_info"]["source_id"]
    source_id = params["info"]["source_id"]
    type = params["host_message"]["transaction_info"]["type"]
    status = params["info"]["status"]
    entity_id = params["info"]["entity_id"]
    entity_data = params["info"]["entity_data"]
    entity = params["info"]["entity"]
    server_date = params["host_message"]["transaction_info"]["server_date"]
    operation = params["host_message"]["transaction_info"]["operation"]
    mcc_code = params["host_message"]["iso_data"]["018"]
    extended_details = params["host_message"]["iso_data"]["043"]
    url = params["webhook"]["url"]
    headers = Poison.decode!(params["webhook"]["headers"])
    response = Poison.encode!(params)

    _data = %{
      user_id: user_id,
      account_id: account_id,
      amount: amount,
      notes: notes,
      source_id: source_id,
      type: type,
      mcc_code: mcc_code,
      extended_details: extended_details,
      status: status,
      server_date: server_date,
      operation: operation,
      url: url,
      entity_id: entity_id,
      entity_data: entity_data,
      entity: entity,
      encrypt_data: headers["Authorization"],
      response: response
    }

    storeTransaction1(params)

#    json conn, %{status_code: "200", message: "Notification founded."}
    json conn,
         %{
           result: %{
             code: "0000",
             message: "Operation Completed Successfully.",
             friendly_message: "Operation Completed Successfully."
           }
         }
  end


#  def store_notification(params) do
#    acc_trans_status_code = params["host_message"]["transaction_data"]["info"]["id"]
#    amount = params["host_message"]["transaction_data"]["info"]["amount"]
#    server_date = params["info"]["server_date"]
#    date_utc = params["info"]["date_utc"]
#    accomplish_card_id = params["host_message"]["transaction_data"]["info"]["account_id"]
#
#    transaction_status = case acc_trans_status_code do
#      0 -> "P"
#      _ -> "S"
#    end
#
#    entity_type = params["info"]["entity"]
#    transaction_id = String.trim(params["info"]["source_id"])
#    [check_transaction_api_id] = Repo.all from a in Transactions,
#                                          where: a.transactions_id_api == ^transaction_id and a.status == "P",
#                                          select: count(a.transactions_id_api)
#    if entity_type == 11 or entity_type == 12 or entity_type == 13 do
#      case check_transaction_api_id do
#        0 ->
#          case Repo.get_by(Employeecards, accomplish_card_id: accomplish_card_id) do
#            nil -> Logger.warn("AF id #{transaction_id} card not found")
#                   :ok
#            card_details ->
#
#              commanall_card_id = card_details.id
#              currency = card_details.currency_code
#              to_card = card_details.last_digit
#              trans_type = params["host_message"]["transaction_data"]["info"]["type"]
#              notes = params["host_message"]["transaction_data"]["info"]["notes"]
#              new_notes = String.replace(notes, ~r/ +/, " ")
#              response_notes = String.split(new_notes, "-", trim: true)
#              notes_last_value = response_notes
#                                 |> Enum.take(-1)
#                                 |> Enum.join()
#              employee_com = Repo.get(Employee, card_details.employee_id)
#              user = Repo.get_by(Commanall, employee_id: employee_com.id)
#
#              commanall_id = user.id
#              card_type = card_details.card_type
#
#              transaction_type = if card_type == "P" do
#                "C2O"
#              else
#                "C2I"
#              end
#
#              remark = %{"from" => to_card, "to" => notes_last_value, "from_info" =>
#                %{"owner_name" => "#{employee_com.first_name} #{employee_com.last_name}", "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""},
#                         "to_info" => %{"owner_name" => notes_last_value, "card_number" => "", "sort_code" => "", "account_number" => ""}}
#
#              api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
#
#
#              # Create POS transaction
#              transaction = %{
#                "commanall_id" => commanall_id,
#                "cards_id" => commanall_card_id,
#                "company_id" => employee_com.company_id,
#                "employee_id" => user.employee_id,
#                "employeecards_id" => commanall_card_id,
#                "pos_id" => 0,
#                "amount" => amount,
#                "fee_amount" => 0.00,
#                "final_amount" => amount,
#                "cur_code" => currency,
#                "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
#                "transactions_id_api" => transaction_id,
#                "server_date" => server_date,
#                "transaction_date" => date_utc,
#                "api_transaction_date" => Poison.encode!(api_transaction_date),
#                "transaction_mode" => "D",
#                "transaction_type" => transaction_type,
#                "api_type" => trans_type,
#                "category" => "POS",
#                "status" => "P",
#                "description" => new_notes,
#                "remark" => Poison.encode!(remark),
#                "inserted_by" => commanall_id
#              }
#              changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
#              Repo.insert(changeset_transaction)
#              updateBalance(accomplish_card_id, params)
#          end
#        1 ->
#          get_transaction = Repo.get_by(Transactions, transactions_id_api: transaction_id)
#          if !is_nil(get_transaction) and get_transaction.status != transaction_status do
#            #        Update Transaction STATUS ONLY
#            changeset_transaction = Transactions.changesetDescription(get_transaction, %{"status" => transaction_status})
#            Repo.update(changeset_transaction)
#
#            updateBalance(accomplish_card_id, params)
#          end
#        _ ->
#          Logger.warn("AF id #{transaction_id} too many transactions")
#          :ok
#      end
#    end
#  end

  defp storeTransaction1(params) do
    acc_trans_status_code = params["host_message"]["transaction_data"]["info"]["id"]
    response_code = params["host_message"]["transaction_data"]["result"]["code"]
    amount = params["host_message"]["transaction_data"]["info"]["amount"]
    server_date = params["info"]["server_date"]
    date_utc = params["info"]["date_utc"]
    accomplish_card_id = params["host_message"]["transaction_data"]["info"]["account_id"]
    extended_details = params["host_message"]["transaction_data"]["custom_field"]["iso_data"]["Message"]["043"]

    if response_code === "0000" do
      transaction_status = if acc_trans_status_code == 0, do: "P", else: "S"

      entity_type = params["info"]["entity"]
      transaction_id = String.trim(params["info"]["source_id"])
      if entity_type == 11 or entity_type == 12 or entity_type == 13 do
        case Repo.get_by(Employeecards, accomplish_card_id: accomplish_card_id) do
          nil -> Logger.warn("AF id #{transaction_id} card not found")
                 :ok
          card_details ->

            commanall_card_id = card_details.id
            to_card = card_details.last_digit
            get_transaction = Repo.get_by(Transactions, transactions_id_api: transaction_id)
            if is_nil(get_transaction) do
              trans_type = params["host_message"]["transaction_data"]["info"]["type"]

              check_transaction = if trans_type == 222 or trans_type == 228 or trans_type == 220 or trans_type == 84  or trans_type == 138, do: "N", else: "Y"
              if check_transaction == "Y" && acc_trans_status_code == 0 && response_code === "0000" do


                employee_com = Repo.get(Employee, card_details.employee_id)
                user = Repo.get_by(Commanall, employee_id: employee_com.id)
                commanall_id = user.id
                card_type = card_details.card_type

                transaction_type = if card_type == "P" do
                  "C2O"
                else
                  "C2I"
                end

                to_user = String.replace(extended_details, ~r/ +/, " ")

                remark = %{"from" => to_card, "to" => to_user, "from_info" =>
                %{"owner_name" => "#{employee_com.first_name} #{employee_com.last_name}", "card_number" => "#{to_card}", "sort_code" => "", "account_number" => ""},
                  "to_info" => %{"owner_name" => to_user, "card_number" => "", "sort_code" => "", "account_number" => ""}}

                api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
                # check notification
                notificationMsg = "You spent £#{amount} at #{to_user}"
                params_data = %{"commanall_id" => commanall_id, "message" => notificationMsg}
                Violacorp.Libraries.Notification.Switch.mob_notification_only(params_data)

                currency = card_details.currency_code

                notes = params["host_message"]["transaction_data"]["info"]["notes"]
                operation = params["host_message"]["transaction_data"]["info"]["operation"]
                transaction_mode = if operation == "Debit", do: "D", else: "C"
                new_notes = String.replace(notes, ~r/ +/, " ")

                balance = if !is_nil(params["host_message"]["account"]["balance"]), do: params["host_message"]["account"]["balance"], else: params["host_message"]["transaction_data"]["info"]["balance"]


                # Create POS transaction
                transaction = %{
                  "commanall_id" => commanall_id,
                  "cards_id" => commanall_card_id,
                  "company_id" => employee_com.company_id,
                  "employee_id" => user.employee_id,
                  "employeecards_id" => commanall_card_id,
                  "pos_id" => 0,
                  "amount" => amount,
                  "fee_amount" => 0.00,
                  "final_amount" => amount,
                  "cur_code" => currency,
                  "balance" => balance,
                  "previous_balance" => card_details.available_balance,
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
                changeset_transaction = Transactions.changeset(%Transactions{}, transaction)
                Repo.insert(changeset_transaction) |> IO.inspect()
                updateBalance(accomplish_card_id, params)
              end
            else

              if acc_trans_status_code != 0 and get_transaction.status != transaction_status and response_code === "0000" do
                #        Update Transaction STATUS ONLY
                changeset_transaction = Transactions.changesetDescription(get_transaction, %{"status" => transaction_status})
                Repo.update(changeset_transaction)

                updateBalance(accomplish_card_id, params)
              end
            end
        end
      end
    end
  end


  defp updateBalance(account_id, params) do
    balance = if !is_nil(params["host_message"]["account"]["balance"]), do: params["host_message"]["account"]["balance"], else: params["host_message"]["transaction_data"]["info"]["balance"]
    available_balance = if !is_nil(params["host_message"]["account"]["available_balance"]), do: params["host_message"]["account"]["available_balance"], else: params["host_message"]["transaction_data"]["info"]["available_balance"]
    getCard = Repo.one(from c in Employeecards, where: c.accomplish_card_id == ^account_id, select: c)
    if !is_nil(getCard) do
      if !is_nil(balance) and !is_nil(available_balance) do
        balance_map = %{
          "available_balance" => available_balance,
          "current_balance" => balance,
        }
        changeset_card = Employeecards.changesetBalance(getCard, balance_map)
        Repo.update(changeset_card)
      end
    end
  end

end