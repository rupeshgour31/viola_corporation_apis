defmodule ViolacorpWeb.Transaction.PaymentController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Transactions

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish


  # Accept Money for Viola Pay
  def acceptMoney(conn, params) do

    unless map_size(params) == 0 do

      qr_code = params["qr_code"]
      enter_amount = params["amount"]
      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"

      emaild_id = Base.decode64!(qr_code)

      # check email
      employee_details = Repo.one from c in Commanall, where: c.email_id == ^emaild_id and c.status == "A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                                                 select: %{
                                                  id: c.id,
                                                  employee_id: c.employee_id
                                                 }

      if employee_details == nil do
          json conn, %{status_code: "5001", errors: %{message: "Incorrect QR-Code"}}
      else
          employee_id = employee_details.employee_id

          # get company id
          employee_com = Repo.get(Employee, employee_id)
          company_id = employee_com.company_id

          # get company name
          company_info = Repo.get(Company, company_id)
          company_name = company_info.company_name

          # Get Card
          card_details = Repo.one(from e in Employeecards, where: e.employee_id == ^employee_id and e.card_type == "P" and e.status == "1",
                                    order_by: [
                                      desc: e.id
                                    ],
                                    limit: 1,
                                    select: %{
                                      id: e.id,
                                      last_digit: e.last_digit,
                                      currency_code: e.currency_code,
                                      available_balance: e.available_balance,
                                      current_balance: e.current_balance,
                                      accomplish_card_id: e.accomplish_card_id
                                    }
                                )

          if card_details == nil do
              json conn, %{status_code: "5001", errors: %{message: "Account is not active"}}
          else
              # Check Balance
              card_available_balance = String.to_float("#{card_details.available_balance}")
              card_current_balance = String.to_float("#{card_details.current_balance}")
              transfer_fund = String.to_float("#{amount}")
              currency = card_details.currency_code
              balance = card_available_balance - transfer_fund
              transaction_id = Integer.to_string(Commontools.randnumber(10))
              today = DateTime.utc_now
              remark = %{"from" => card_details.last_digit, "to" => "Viola Pay"}

              type_credit = Application.get_env(:violacorp, :qr_debit)

              if card_available_balance >= transfer_fund and card_current_balance >= transfer_fund do
                  transactions = %{
                    "commanall_id" => employee_details.id,
                    "company_id" => company_id,
                    "employee_id" => employee_id,
                    "employeecards_id" => card_details.id,
                    "amount" => transfer_fund,
                    "balance" => balance,
                    "previous_balance" => card_available_balance,
                    "fee_amount" => 0.00,
                    "final_amount" => transfer_fund,
                    "cur_code" => currency,
                    "transaction_id" => transaction_id,
                    "transaction_date" => today,
                    "transaction_mode" => "D",
                    "transaction_type" => "C2O",
                    "api_type" => type_credit,
                    "pos_id" => 0,
                    "category" => "POS",
                    "status" => "F",
                    "description" => "Payment by QR",
                    "remark" => Poison.encode!(remark),
                    "inserted_by" => employee_details.id
                  }

                  changeset_transaction = Transactions.changeset_pos(%Transactions{}, transactions)
                  case Repo.insert(changeset_transaction) do
                    {:ok, data} -> ids = data.id
                                   account_id = card_details.accomplish_card_id
                                   request = %{
                                     type: "228",
                                     notes: "", # Limited Debit
                                     amount: transfer_fund,
                                     currency: currency,
                                     account_id: account_id
                                   }

                                   # Send to Accomplish
                                   response = Accomplish.load_money(request)

                                   response_code = response["result"]["code"]
                                   response_message = response["result"]["friendly_message"]

                                   if response_code == "0000" do
                                     transactions_id_api = response["info"]["original_source_id"]
                                     server_date = response["info"]["server_date"]
                                     date_utc = response["info"]["date_utc"]
                                     api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}

                                     update_status = %{
                                       "transactions_id_api" => transactions_id_api,
                                       "server_date" => date_utc,
                                       "api_transaction_date" => Poison.encode!(api_transaction_date),
                                       "status" => "S"
                                     }
                                     trans_status = Repo.get(Transactions, ids)
                                     changeset_transaction = Transactions.changesetUpdateStatusQR(trans_status, update_status)
                                     Repo.update(changeset_transaction)

                                     # Update Balance
                                     card_details = Repo.get(Employeecards, card_details.id)
                                     current_balance_card = response["account"]["info"]["balance"]
                                     available_balance_card = response["account"]["info"]["available_balance"]
                                     update_card_balance = %{
                                       "available_balance" => available_balance_card,
                                       "current_balance" => current_balance_card
                                     }
                                     changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                                     Repo.update(changeset_employeecard)

                                     json conn, %{status_code: "200", data: %{message: "Transaction has been successfully.", company_name: company_name, transaction_id: transaction_id}}

                                   else
                                     update_status = %{"description" => response_message}
                                     trans_status = Repo.get(Transactions, ids)
                                     changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
                                     Repo.update(changeset_transaction)

                                     json conn, %{status_code: "5003", errors: %{message: response_message, company_name: company_name, transaction_id: transaction_id}}
                                   end
                    {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
              else

                transactions = %{
                  "commanall_id" => employee_details.id,
                  "company_id" => company_id,
                  "employee_id" => employee_id,
                  "employeecards_id" => card_details.id,
                  "amount" => transfer_fund,
                  "balance" => 0.00,
                  "previous_balance" => 0.00,
                  "fee_amount" => 0.00,
                  "final_amount" => transfer_fund,
                  "cur_code" => currency,
                  "transaction_id" => transaction_id,
                  "transaction_date" => today,
                  "transaction_mode" => "D",
                  "transaction_type" => "C2O",
                  "api_type" => type_credit,
                  "pos_id" => 0,
                  "category" => "POS",
                  "status" => "F",
                  "description" => "Not sufficient funds",
                  "remark" => Poison.encode!(remark),
                  "inserted_by" => employee_details.id
                }
                changeset_transaction = Transactions.changeset_pos(%Transactions{}, transactions)
                case Repo.insert(changeset_transaction) do
                {:ok, _data} ->
                  json conn, %{status_code: "5003", errors: %{message: "Not sufficient funds", transaction_id: transaction_id}}
                {:error, changeset} ->
                    conn
                    |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                end
              end
          end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


end