defmodule Violacorp.Workers.ManualSuccess do
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish


  @moduledoc "success trasactions from accomplish"

  def perform(params) do
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

    request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{start_index}&page_size=#{page_size}"
    #    request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{start_index}&page_size=#{page_size}"

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
end