defmodule Violacorp.Workers.GenerateReport do
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Transactions
#  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Expense

  @moduledoc "perform function - generate expense sheet"

  # Company generate transaction report for all cards.
  def perform(params) do

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
        get_transactions = Repo.all (from t in Transactions, where: t.employeecards_id == ^card_id  and t.category == "POS",
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

          main_heading = [['VIOLA'], ['EXPENSE FORM'], [], ['Individual', '#{company_name}'], [], ['Period', '#{period}'], []]
          total_amount = Repo.one from t in Transactions, where: t.employeecards_id == ^card_id and t.category == "POS" and (t.transaction_date >= ^from_date and t.transaction_date <= ^to_date),
                                                          select: sum(t.final_amount)

          heading = [['Card Number: ', '#{last_digit}'], [], ['#', 'Description', 'Currency', 'Amount', 'Transaction Id', 'Server Date', 'Status']]

          map = Stream.with_index(get_transactions)
                |> Enum.reduce(%{}, fn ({w, k}, emp) ->
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

            new = ['#{k+1}', '#{description}', '#{cur_code}', '#{final_amount}', '#{transaction_id}', '#{server_date}', '#{status_msg}']
            Map.put(emp, k, new)
          end)

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