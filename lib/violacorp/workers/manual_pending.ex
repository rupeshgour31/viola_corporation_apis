defmodule Violacorp.Workers.ManualPending do
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
    status = "1" # 1 = Pending
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
end