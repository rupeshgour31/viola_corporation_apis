defmodule ViolacorpWeb.Company.RequestdataController do
  use ViolacorpWeb, :controller
  import Ecto.Query
  require Logger

  alias Violacorp.Repo
  alias Violacorp.Libraries.Commontools

  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Position
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Companybankaccount
  #  alias Violacorp.Schemas.Companyaccounts

  alias ViolacorpWeb.Employees.EmployeeView


  @doc "list of money requests - webapp"
  def companyMoneyRequests(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    requested_money_list = (
                             from r in Requestmoney,
                                  where: r.company_id == ^company_id and r.status == "R",
                                  left_join: cards in assoc(r, :employeecards),
                                  left_join: e in assoc(r, :employee),
                                  order_by: [
                                    desc: r.inserted_At
                                  ],
                                  select: %{
                                    id: r.id,
                                    employee_id: r.employee_id,
                                    employeecards_id: r.employeecards_id,
                                    last_digit: cards.last_digit,
                                    first_name: e.first_name,
                                    last_name: e.last_name,
                                    amount: r.amount,
                                    cur_code: r.cur_code,
                                    reason: r.reason,
                                    status: r.status,
                                    inserted_at: r.inserted_at
                                  }
                             )
                           |> Repo.paginate(params)
    total_count = Enum.count(requested_money_list)
    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: requested_money_list.entries,
           page_number: requested_money_list.page_number,
           total_pages: requested_money_list.total_pages
         }
  end

  @doc "list of money requests - webapp"
  def companyEmployeeMoneyRequests(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    employee_id = params["employeeId"]
    requested_money_list = (
                             from r in Requestmoney,
                                  where: r.company_id == ^company_id and r.status == "R",
                                  left_join: cards in assoc(r, :employeecards),
                                  left_join: e in assoc(r, :employee),
                                  where: e.id == ^employee_id,
                                  order_by: [
                                    desc: r.inserted_At
                                  ],
                                  select: %{
                                    id: r.id,
                                    employee_id: r.employee_id,
                                    employeecards_id: r.employeecards_id,
                                    last_digit: cards.last_digit,
                                    first_name: e.first_name,
                                    last_name: e.last_name,
                                    amount: r.amount,
                                    cur_code: r.cur_code,
                                    reason: r.reason,
                                    status: r.status,
                                    inserted_at: r.inserted_at
                                  }
                             )
                           |> Repo.paginate(params)
    json conn,
         %{
           status_code: "200",
           total_count: requested_money_list.total_entries,
           data: requested_money_list.entries,
           page_number: requested_money_list.page_number,
           total_pages: requested_money_list.total_pages
         }
  end

  @doc "list of card requests - webapp"
  def companyCardRequests(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    requested_card_list = (
                            from r in Requestcard,
                                 where: r.company_id == ^company_id and r.status == "R",
                                 left_join: e in assoc(r, :employee),
                                 order_by: [
                                   desc: r.inserted_At
                                 ],
                                 select: %{
                                   id: r.id,
                                   employee_id: r.employee_id,
                                   currency: r.currency,
                                   card_type: r.card_type,
                                   status: r.status,
                                   reason: r.reason,
                                   inserted_at: r.inserted_at,
                                   first_name: e.first_name,
                                   last_name: e.last_name
                                 }
                            )
                          |> Repo.paginate(params)
    total_count = Enum.count(requested_card_list)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: requested_card_list.entries,
           page_number: requested_card_list.page_number,
           total_pages: requested_card_list.total_pages
         }
  end


  @doc "list of card requests - webapp"
  def companyEmployeeCardRequests(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    employee_id = params["employeeId"]
    requested_card_list = (
                            from r in Requestcard,
                                 where: r.company_id == ^company_id and r.status == "R",
                                 left_join: e in assoc(r, :employee),
                                 where: e.id == ^employee_id,
                                 order_by: [
                                   desc: r.inserted_At
                                 ],
                                 select: %{
                                   id: r.id,
                                   employee_id: r.employee_id,
                                   currency: r.currency,
                                   card_type: r.card_type,
                                   status: r.status,
                                   reason: r.reason,
                                   inserted_at: r.inserted_at,
                                   first_name: e.first_name,
                                   last_name: e.last_name
                                 }
                            )
                          |> Repo.paginate(params)
    json conn,
         %{
           status_code: "200",
           total_count: requested_card_list.total_entries,
           data: requested_card_list.entries,
           page_number: requested_card_list.page_number,
           total_pages: requested_card_list.total_pages
         }
  end

  @doc "gets list of money requests - Mobile app service"
  def employeeMoneyRequests(conn, _params) do
    %{"id" => employee_id} = conn.assigns[:current_user]
    companyid = Repo.one from a in Employee, where: a.id == ^employee_id, select: a.company_id
    requested_money_list = Repo.all(
      from r in Requestmoney, where: r.employee_id == ^employee_id and r.company_id == ^companyid and r.status == "R",
                              left_join: cards in assoc(r, :employeecards),
                              order_by: [
                                desc: r.inserted_At
                              ],
                              select: %{
                                id: r.id,
                                employee_id: r.employee_id,
                                employeecards_id: r.employeecards_id,
                                last_digit: cards.last_digit,
                                amount: r.amount,
                                cur_code: r.cur_code,
                                status: r.status,
                                reason: r.reason,
                                inserted_at: r.inserted_at
                              }
    )
    json conn, %{status_code: "200", data: requested_money_list}
  end

  @doc "gets list of money requests for specific employee - Web app service"
  def employeeWebMoneyRequests(conn, params) do
    %{"id" => companyid} = conn.assigns[:current_user]
    employee_id = params["employeeid"]
    requested_money_list = (
                             from r in Requestmoney,
                                  where: r.employee_id == ^employee_id and r.company_id == ^companyid and r.status == "R",
                                  left_join: cards in assoc(r, :employeecards),
                                  order_by: [
                                    desc: r.inserted_At
                                  ],
                                  select: %{
                                    id: r.id,
                                    employee_id: r.employee_id,
                                    employeecards_id: r.employeecards_id,
                                    last_digit: cards.last_digit,
                                    amount: r.amount,
                                    cur_code: r.cur_code,
                                    status: r.status,
                                    reason: r.reason,
                                    inserted_at: r.inserted_at
                                  }
                             )
                           |> Repo.paginate(params)

    total_count = Enum.count(requested_money_list)
    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: requested_money_list.entries,
           page_number: requested_money_list.page_number,
           total_pages: requested_money_list.total_pages
         }
  end

  def employeeCardRequests(conn, _params) do
    %{"id" => employee_id} = conn.assigns[:current_user]
    companyid = Repo.one from a in Employee, where: a.id == ^employee_id, select: a.company_id
    requested_card_list = Repo.all(
      from r in Requestcard, where: r.employee_id == ^employee_id and r.company_id == ^companyid and r.status == "R",
                             order_by: [
                               desc: r.inserted_At
                             ],
                             select: %{
                               id: r.id,
                               employee_id: r.employee_id,
                               currency: r.currency,
                               card_type: r.card_type,
                               status: r.status,
                               reason: r.reason,
                               inserted_at: r.inserted_at
                             }
    )
    json conn, %{status_code: "200", data: requested_card_list}
  end

  def getPositionList(conn, _params) do
    requested_position_list = Repo.all(
      from p in Position, where: p.show == "Y",
                          select: %{
                            id: p.id,
                            title: p.title,
                            inserted_by: p.inserted_by
                          }
    )
    json conn, %{status_code: "200", data: requested_position_list}
  end

  def getAddress(conn, params) do
    postcode = String.replace(params["postcode"], " ", "")
    data = Commontools.getFromPostcode(postcode)

    status_code = cond do
      data == "404 not found!" -> "404"
      data == "Unauthorized!" -> "401"
      data == "Bad request!" -> "400"
      data == "Limit Reached!" -> "429"
      data == "Getaddress Internal Server Error" -> "429"
      true -> "200"
    end
    data = cond do
      data == "404 not found!" -> "No Results"
      data == "Unauthorized!" -> "Unauthorized"
      data == "Bad request!" -> "Bad request(check your postcode)!"
      data == "Limit Reached!" -> "Limit Reached!"
      data == "Getaddress Internal Server Error" -> "Getaddress Internal Server Error"
      true -> data
    end
    data = if status_code == "200" do

      map = Stream.map(
        data["addresses"],
        fn s ->
          address_info = String.split(s, ",")

          Stream.with_index(address_info, 1)
          |> Enum.reduce(
               %{},
               fn ({j, p}, addr) ->

                 v = String.trim(j)

                 Map.put(addr, "line#{p}", v)
               end
             )
        end
      )
      Map.new %{"longitude" => data["longitude"], "latitude" => data["latitude"], "addresses" => map}
    end

    json conn, %{status_code: status_code, data: data}
  end

  def getRegdata(conn, params) do
    get_data = Repo.one (from n in Commanall, where: n.id == ^params["commanallid"], select: n.reg_data)
    data = get_data
           |> Poison.decode!()

    json conn, %{status_code: "200", data: data}
  end

  @doc "Account History default - shows default screen for Account history"
  # get company's all transactions
  def accountHistoryDefault(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    #    DEPRECATED
    get_transactions = (from t in Transactions,
                             where: t.commanall_id == ^commanid and t.company_id == ^compid and (
                               t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O") and (
                                      (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                                        t.transaction_type == "C2A" and t.transaction_mode == "C")),
                             order_by: [
                               desc: t.transaction_date
                             ],
                             select: %{
                               id: t.id,
                               amount: t.amount,
                               remark: t.remark,
                               fee_amount: t.fee_amount,
                               final_amount: t.final_amount,
                               balance: t.balance,
                               previous_balance: t.previous_balance,
                               transaction_mode: t.transaction_mode,
                               transaction_date: t.transaction_date,
                               transaction_type: t.transaction_type,
                               transaction_id: t.transaction_id,
                               category: t.category,
                               cur_code: t.cur_code,
                               projects_id: t.projects_id,
                               description: t.description,
                               status: t.status
                             })
                       |> Repo.paginate(params)
    total_count = Enum.count(get_transactions)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: get_transactions.entries,
           page_number: get_transactions.page_number,
           total_pages: get_transactions.total_pages
         }
  end

  # get company's all transactions
  def accountHistoryDefaultV1(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]


    get_transactions = Transactions
                       |> where(
                            [t],
                            t.commanall_id == ^commanid and t.company_id == ^compid and (
                            t.transaction_type == "B2A" or t.transaction_type == "A2O" or (t.transaction_type == "A2C" and t.transaction_mode == "D"))
                          )
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> Repo.paginate(params)

    render(conn, EmployeeView, "manytrans_paginate_noReceipt_project.json", transactions: get_transactions)
  end

  # get company's all transactions
  def accountHistoryDefaultSingle(conn, params) do

    %{"commanall_id" => commanid, "id" => _compid} = conn.assigns[:current_user]


    get_transactions = Transactions
                       |> where([t], t.commanall_id == ^commanid and t.id == ^params["transactionId"])
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> Repo.one()
    render(conn, EmployeeView, "singletrans_onlyprojectwithaccount.json", transactions: get_transactions)
  end

  # get company's all transactions
  def bankAccountHistory(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    bank_id = Repo.one from c in Companybankaccount, where: c.company_id == ^compid and c.status == "A", select: c.id

    if !is_nil(bank_id) do
      get_transactions = Transactions
                         |> where(
                              [t],
                              t.commanall_id == ^commanid and t.company_id == ^compid and t.bank_id == ^bank_id
                            )
                         |> order_by(desc: :transaction_date)
                         |> preload(:projects)
                         |> Repo.paginate(params)
      render(conn, EmployeeView, "manytrans_paginate_noReceipt.json", transactions: get_transactions)
    else
      render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
    end
  end


  # get company's all transactions
  def bankAccountHistorySingle(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    bank_id = Repo.one from c in Companybankaccount, where: c.company_id == ^compid and c.status == "A", select: c.id

    get_transactions = Transactions
                       |> where(
                            [t],
                            t.commanall_id == ^commanid and t.id == ^params["transactionId"] and t.company_id == ^compid and t.bank_id == ^bank_id
                          )
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> Repo.one()

    render(conn, EmployeeView, "singletrans_onlyprojectwithaccount.json", transactions: get_transactions)
  end

  @doc "Account History Filtered - Account's transactions with filter (by employee, card, amount, transaction_type, project)"
  def accountHistoryFiltered(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id account_no employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C")),
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     remark: t.remark,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     transaction_mode: t.transaction_mode,
                     transaction_date: t.transaction_date,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C")),
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     remark: t.remark,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C")),
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     amount: t.amount,
                     remark: t.remark,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C")),
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     amount: t.amount,
                     remark: t.remark,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          end
        end

      total_count = Enum.count(query)

      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: query.entries,
             page_number: query.page_number,
             total_pages: query.total_pages
           }

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def accountHistoryFilteredV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id account_no employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
          Transactions
          |> where(^merge_params)
          |> having(
               [t],
               t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                 (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                   t.transaction_type == "C2A" and t.transaction_mode == "C"))
             )
          |> order_by(desc: :transaction_date)
          |> preload(:projects)
          |> Repo.paginate(params)
        else
          if is_nil(params["from_date"]) and !is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date <= ^params["to_date"] and t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "C"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:projects)
            |> Repo.paginate(params)
          else
            if !is_nil(params["from_date"]) and is_nil(params["to_date"]) do
              Transactions
              |> where(^merge_params)
              |> having(
                   [t],
                   t.transaction_date <= ^params["from_date"] and t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C"))
                 )
              |> order_by(desc: :transaction_date)
              |> preload(:projects)
              |> Repo.paginate(params)
            else
              Transactions
              |> where(^merge_params)
              |> having(
                   [t],
                   t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.transaction_type != "C2O" and t.transaction_type != "C2I" and t.transaction_type != "B2A" and t.transaction_type != "A2O" and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "D") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "C"))
                 )
              |> order_by(desc: :transaction_date)
              |> preload(:projects)
              |> Repo.paginate(params)
            end
          end
        end

      render(conn, EmployeeView, "manytrans_paginate_noReceipt_project.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Account History for beneficiary"
  # get company's all transactions
  def singleAccountHistoryFilteredV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]
      filtered_params =
        params
        |> Map.take(~w( beneficiaries_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)
      query = Transactions
              |> where(^merge_params)
              |> having([t], t.transaction_type == "A2A")
              |> order_by(desc: :transaction_date)
              |> preload(:projects)
              |> Repo.paginate(params)
      render(conn, EmployeeView, "manytrans_paginate_noReceipt_project.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "card History default - shows default screen for card history"
  # get company's all transactions
  def cardHistoryDefault(conn, _params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    get_transactions = Repo.all from t in Transactions,
                                where: t.commanall_id != ^commanid and t.company_id == ^compid and t.transaction_type != "B2A",
                                order_by: [
                                  desc: t.transaction_date
                                ],
                                select: %{
                                  id: t.id,
                                  amount: t.amount,
                                  remark: t.remark,
                                  fee_amount: t.fee_amount,
                                  final_amount: t.final_amount,
                                  balance: t.balance,
                                  previous_balance: t.previous_balance,
                                  transaction_mode: t.transaction_mode,
                                  transaction_date: t.transaction_date,
                                  transaction_type: t.transaction_type,
                                  transaction_id: t.transaction_id,
                                  category: t.category,
                                  cur_code: t.cur_code,
                                  projects_id: t.projects_id,
                                  description: t.description,
                                  status: t.status
                                }
    total_count = Enum.count(get_transactions)

    json conn, %{status_code: "200", total_count: total_count, data: get_transactions}
  end

  # get company's all transactions
  def cardHistoryDefaultV1(conn, _params) do

    %{"id" => compid} = conn.assigns[:current_user]

    get_transactions = Transactions
                       |> where(
                            [t],
                            t.company_id == ^compid and (t.transaction_type != "B2A") and (
                              (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                                t.transaction_type == "C2A" and t.transaction_mode == "D") or t.transaction_type == "C2O" or t.transaction_type == "C2I")
                          )
                       |> order_by(desc: :transaction_date)
                       |> preload(:transactionsreceipt)
                       |> Repo.all

    render(conn, EmployeeView, "manytrans_total_count.json", transactions: get_transactions)
  end

  @doc "Card History Filtered - card's transactions with filter (by employee, card, amount, transaction_type, project)"
  def cardHistoryFiltered(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)
      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Repo.all from t in Transactions, where: ^merge_params,
                                             having: t.commanall_id != ^commanid,
                                             order_by: [
                                               desc: t.transaction_date
                                             ],
                                             select: %{
                                               id: t.id,
                                               commanall_id: t.commanall_id,
                                               amount: t.amount,
                                               remark: t.remark,
                                               fee_amount: t.fee_amount,
                                               final_amount: t.final_amount,
                                               transaction_mode: t.transaction_mode,
                                               transaction_date: t.transaction_date,
                                               balance: t.balance,
                                               previous_balance: t.previous_balance,
                                               transaction_type: t.transaction_type,
                                               transaction_id: t.transaction_id,
                                               category: t.category,
                                               cur_code: t.cur_code,
                                               projects_id: t.projects_id,
                                               description: t.description,
                                               status: t.status
                                             }
          else
            Repo.all from t in Transactions, where: ^merge_params,
                                             having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id != ^commanid,
                                             order_by: [
                                               desc: t.transaction_date
                                             ],
                                             select: %{
                                               id: t.id,
                                               commanall_id: t.commanall_id,
                                               amount: t.amount,
                                               remark: t.remark,
                                               fee_amount: t.fee_amount,
                                               final_amount: t.final_amount,
                                               transaction_mode: t.transaction_mode,
                                               balance: t.balance,
                                               previous_balance: t.previous_balance,
                                               transaction_date: t.transaction_date,
                                               transaction_type: t.transaction_type,
                                               transaction_id: t.transaction_id,
                                               category: t.category,
                                               cur_code: t.cur_code,
                                               projects_id: t.projects_id,
                                               description: t.description,
                                               status: t.status
                                             }
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Repo.all from t in Transactions, where: ^merge_params,
                                             having: t.commanall_id != ^commanid,
                                             limit: ^params["results_limit"],
                                             offset: ^params["from_result"],
                                             order_by: [
                                               desc: t.transaction_date
                                             ],
                                             select: %{
                                               id: t.id,
                                               commanall_id: t.commanall_id,
                                               amount: t.amount,
                                               remark: t.remark,
                                               fee_amount: t.fee_amount,
                                               final_amount: t.final_amount,
                                               transaction_mode: t.transaction_mode,
                                               balance: t.balance,
                                               previous_balance: t.previous_balance,
                                               transaction_date: t.transaction_date,
                                               transaction_type: t.transaction_type,
                                               transaction_id: t.transaction_id,
                                               category: t.category,
                                               cur_code: t.cur_code,
                                               projects_id: t.projects_id,
                                               description: t.description,
                                               status: t.status
                                             }
          else
            Repo.all from t in Transactions, where: ^merge_params,
                                             having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id != ^commanid,
                                             limit: ^params["results_limit"],
                                             offset: ^params["from_result"],
                                             order_by: [
                                               desc: t.transaction_date
                                             ],
                                             select: %{
                                               id: t.id,
                                               commanall_id: t.commanall_id,
                                               amount: t.amount,
                                               remark: t.remark,
                                               fee_amount: t.fee_amount,
                                               final_amount: t.final_amount,
                                               transaction_mode: t.transaction_mode,
                                               balance: t.balance,
                                               previous_balance: t.previous_balance,
                                               transaction_date: t.transaction_date,
                                               transaction_type: t.transaction_type,
                                               transaction_id: t.transaction_id,
                                               category: t.category,
                                               cur_code: t.cur_code,
                                               projects_id: t.projects_id,
                                               description: t.description,
                                               status: t.status
                                             }
          end
        end

      total_count = Enum.count(query)
      json conn, %{status_code: "200", total_count: total_count, data: query}
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def cardHistoryFilteredV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)
      query =
        if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
          Transactions
          |> where(^merge_params)
          |> having(
               [t],
               t.company_id == ^company_id and (t.transaction_type != "B2A") and (
                 (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                   t.transaction_type == "C2A" and t.transaction_mode == "D") or t.transaction_type == "C2O" or t.transaction_type == "C2I")
             )
          |> order_by(desc: :transaction_date)
          |> preload(:transactionsreceipt)
          |> Repo.all
        else
          if is_nil(params["from_date"]) and !is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                   t.transaction_type != "B2A") and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D") or t.transaction_type == "C2O" or t.transaction_type == "C2I")
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> Repo.all
          else
            if !is_nil(params["from_date"]) and is_nil(params["to_date"]) do
              Transactions
              |> where(^merge_params)
              |> having(
                   [t],
                   t.transaction_date >= ^params["from_date"] and t.company_id == ^company_id and (
                     t.transaction_type != "B2A") and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "D") or t.transaction_type == "C2O" or t.transaction_type == "C2I")
                 )
              |> order_by(desc: :transaction_date)
              |> preload(:transactionsreceipt)
              |> Repo.all
            else
              Transactions
              |> where(^merge_params)
              |> having(
                   [t],
                   t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                     t.transaction_type != "B2A") and (
                     (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                       t.transaction_type == "C2A" and t.transaction_mode == "D") or t.transaction_type == "C2O" or t.transaction_type == "C2I")
                 )
              |> order_by(desc: :transaction_date)
              |> preload(:transactionsreceipt)
              |> Repo.all
            end
          end
        end

      render(conn, EmployeeView, "manytrans_total_count.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Single card info, issue_date, employee name"
  def singleCardInfo(conn, params) do

    get_transactions = Repo.one (from t in Employeecards,
                                      where: t.id == ^params["cardId"],
                                      left_join: emp in assoc(t, :employee),
                                      select: %{
                                        id: t.id,
                                        title: emp.title,
                                        first_name: emp.first_name,
                                        last_name: emp.last_name,
                                        last_digit: t.last_digit,
                                        employee_id: t.employee_id,
                                        issue_date: t.inserted_at,
                                        expiry_date: t.expiry_date,
                                        available_balance: t.available_balance,
                                        current_balance: t.current_balance,
                                        currencies_id: t.currencies_id,
                                        currency_code: t.currency_code,
                                        card_type: t.card_type,
                                        status: t.status
                                      })
    to_date = %{
      issue_date: NaiveDateTime.to_date(get_transactions.issue_date)
                  |> Date.to_string
    }
    concat = Map.merge(get_transactions, to_date)
    json conn, %{status_code: "200", data: concat}
  end

  @doc "Single card History default - shows default screen for card history"
  def singleCardHistoryDefault(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    #    DEPRECATED
    get_transactions = (from t in Transactions,
                             where: t.commanall_id != ^commanid and t.company_id == ^compid and t.employeecards_id == ^params["cardId"] and t.transaction_type != "B2A",
                             left_join: r in assoc(t, :transactionsreceipt),
                             on: r.transactions_id == t.id,
                             order_by: [
                               desc: t.transaction_date
                             ],
                             select: %{
                               id: t.id,
                               amount: t.amount,
                               fee_amount: t.fee_amount,
                               final_amount: t.final_amount,
                               remark: t.remark,
                               balance: t.balance,
                               previous_balance: t.previous_balance,
                               transaction_mode: t.transaction_mode,
                               transaction_date: t.transaction_date,
                               transaction_type: t.transaction_type,
                               transaction_id: t.transaction_id,
                               category: t.category,
                               cur_code: t.cur_code,
                               projects_id: t.projects_id,
                               description: t.description,
                               status: t.status,
                               transaction_id: t.transaction_id,
                               receipt_url: r.receipt_url
                             })
                       |> Repo.paginate(params)
    total_count = Enum.count(get_transactions.entries)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: get_transactions.entries,
           page_number: get_transactions.page_number,
           total_pages: get_transactions.total_pages
         }
  end

  def singleCardHistoryDefaultV1(conn, params) do

    %{"id" => compid} = conn.assigns[:current_user]

    get_transactions = Transactions
                       |> where(
                            [t],
                            t.company_id == ^compid and t.employeecards_id == ^params["cardId"] and (
                              (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                                t.transaction_type == "C2A" and t.transaction_mode == "D") or (
                                t.transaction_type == "C2I") or (t.transaction_type == "C2O") or (
                                t.transaction_type == "C2F"))
                          )
                       |> order_by(desc: :transaction_date)
                       |> preload(:transactionsreceipt)
                       |> Repo.paginate(params)

    render(conn, EmployeeView, "manytrans_paginate.json", transactions: get_transactions)
  end

  # get company's all transactions
  def cardAccountHistorySingle(conn, params) do

    #    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    get_transactions = Transactions
                       |> where([t], t.id == ^params["transactionId"])
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> preload(:transactionsreceipt)
                       |> Repo.one()
    #    render(conn, EmployeeView, "singletrans_onlyprojectwithaccount.json", transactions: get_transactions)
    render(conn, EmployeeView, "singletrans_project.json", transactions: get_transactions)
  end

  @doc "Single Card History Filtered - card's transactions with filter (by employee, card, amount, transaction_type, project)"
  def singleCardHistoryFiltered(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      # DEPRECATED
      query =
        if is_nil(params["from_date"]) or is_nil(params["to_date"]) do
          (
            from t in Transactions,
                 where: ^merge_params,
                 having: t.commanall_id != ^commanid,
                 left_join: r in assoc(t, :transactionsreceipt),
                 on: r.transactions_id == t.id,
                 order_by: [
                   desc: t.transaction_date
                 ],
                 select: %{
                   id: t.id,
                   commanall_id: t.commanall_id,
                   amount: t.amount,
                   fee_amount: t.fee_amount,
                   final_amount: t.final_amount,
                   remark: t.remark,
                   transaction_mode: t.transaction_mode,
                   transaction_date: t.transaction_date,
                   balance: t.balance,
                   previous_balance: t.previous_balance,
                   transaction_type: t.transaction_type,
                   transaction_id: t.transaction_id,
                   category: t.category,
                   cur_code: t.cur_code,
                   projects_id: t.projects_id,
                   description: t.description,
                   status: t.status,
                   transaction_id: t.transaction_id,
                   receipt_url: r.receipt_url
                 })
          |> Repo.paginate(params)
        else
          (
            from t in Transactions,
                 where: ^merge_params,
                 having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id != ^commanid,
                 left_join: r in assoc(t, :transactionsreceipt),
                 on: r.transactions_id == t.id,
                 order_by: [
                   desc: t.transaction_date
                 ],
                 select: %{
                   id: t.id,
                   commanall_id: t.commanall_id,
                   amount: t.amount,
                   fee_amount: t.fee_amount,
                   final_amount: t.final_amount,
                   remark: t.remark,
                   transaction_mode: t.transaction_mode,
                   balance: t.balance,
                   previous_balance: t.previous_balance,
                   transaction_date: t.transaction_date,
                   transaction_type: t.transaction_type,
                   transaction_id: t.transaction_id,
                   category: t.category,
                   cur_code: t.cur_code,
                   projects_id: t.projects_id,
                   description: t.description,
                   status: t.status,
                   transaction_id: t.transaction_id,
                   receipt_url: r.receipt_url
                 })
          |> Repo.paginate(params)
        end

      total_count = Enum.count(query)
      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: query.entries,
             page_number: query.page_number,
             total_pages: query.total_pages
           }
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def singleCardHistoryFilteredV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
          Transactions
          |> where(^merge_params)
          |> having(
               [t],
               t.company_id == ^company_id and (
                 (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                   t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2I") or (
                   t.transaction_type == "C2O") or (t.transaction_type == "C2F"))
             )
          |> order_by(desc: :transaction_date)
          |> preload(:transactionsreceipt)
          |> Repo.paginate(params)
        else
          Transactions
          |> where(^merge_params)
          |> having(
               [t],
               t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                 (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                   t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2I") or (
                   t.transaction_type == "C2O") or (t.transaction_type == "C2F"))
             )
          |> order_by(desc: :transaction_date)
          |> preload(:transactionsreceipt)
          |> Repo.paginate(params)
        end

      render(conn, EmployeeView, "manytrans_paginate.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Load History default - shows default screen for Load history"
  # get company's all transactions
  def loadHistoryDefault(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    get_transactions = (from t in Transactions,
                             where: t.commanall_id == ^commanid and t.company_id == ^compid and t.transaction_type == "B2A",
                             order_by: [
                               desc: t.transaction_date
                             ],
                             select: %{
                               id: t.id,
                               amount: t.amount,
                               fee_amount: t.fee_amount,
                               final_amount: t.final_amount,
                               remark: t.remark,
                               balance: t.balance,
                               previous_balance: t.previous_balance,
                               transaction_mode: t.transaction_mode,
                               transaction_date: t.transaction_date,
                               transaction_type: t.transaction_type,
                               transaction_id: t.transaction_id,
                               category: t.category,
                               cur_code: t.cur_code,
                               projects_id: t.projects_id,
                               description: t.description,
                               status: t.status
                             })
                       |> Repo.paginate(params)
    total_count = Enum.count(get_transactions)

    json conn, %{status_code: "200", total_count: total_count, data: get_transactions}
  end

  @doc "Load History Filtered - Loading funds transactions with filter (by account, amount, transaction_date)"
  def loadHistoryFiltered(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id account_no employee_id employeecards_id final_amount projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      type = "B2A"
      from_token = [company_id: company_id, commanall_id: commanid, transaction_type: type]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     transaction_date: t.transaction_date,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"],
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status
                   })
            |> Repo.paginate(params)
          end
        end

      total_count = Enum.count(query)
      json conn, %{status_code: "200", total_count: total_count, data: query}
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def loadHistoryFilteredV1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id account_no employee_id employeecards_id final_amount projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      type = "B2A"
      from_token = [company_id: company_id, commanall_id: commanid, transaction_type: type]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
          Transactions
          |> where(^merge_params)
          |> order_by(desc: :transaction_date)
          |> Repo.paginate(params)
        else
          if is_nil(params["from_date"]) and !is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having([t], t.transaction_date <= ^params["to_date"])
            |> order_by(desc: :transaction_date)
            |> Repo.paginate(params)
          else
            if !is_nil(params["from_date"]) and is_nil(params["to_date"]) do
              Transactions
              |> where(^merge_params)
              |> having([t], t.transaction_date <= ^params["from_date"])
              |> order_by(desc: :transaction_date)
              |> Repo.paginate(params)
            else
              Transactions
              |> where(^merge_params)
              |> having([t], t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"])
              |> order_by(desc: :transaction_date)
              |> Repo.paginate(params)
            end
          end
        end

      render(conn, EmployeeView, "manytrans_paginate_noReceipt.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "mandate screen info display"
  def mandateInfo(conn, _params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]
    get_company = Repo.one from c in Company, where: c.id == ^company_id,
                                              left_join: director in assoc(c, :directors),
                                              where: director.sequence == 1,
                                              select: %{
                                                company_name: c.company_name,
                                                d_firstname: director.first_name,
                                                d_lastname: director.last_name,
                                                d_title: director.title,
                                                d_position: director.position,
                                                date_registration: c.inserted_at,
                                                d_signature: director.signature
                                              }
    get_contact = Repo.one from c in Contacts, where: c.commanall_id == ^commanid and c.is_primary == "Y",
                                               select: %{
                                                 company_contact: c.contact_number
                                               }
    merge_data = Map.merge(get_company, get_contact)
    json conn, %{status_code: "200", data: merge_data}
  end

  @doc "total number of requests for company "
  def getAlerts(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    [card_requests] = Repo.all from c in Requestcard, where: c.company_id == ^company_id and c.status == "R",
                                                      select: count(c.id)
    [money_requests] = Repo.all from m in Requestmoney, where: m.company_id == ^company_id and m.status == "R",
                                                        select: count(m.id)
    total = card_requests + money_requests
    json conn,
         %{status_code: "200", total: total, total_cardrequests: card_requests, total_moneyrequests: money_requests}
  end

  @doc "last 5 Alerts of requests for company "
  def getlast5Alerts(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    requested_money_list = Repo.all(
      from r in Requestmoney, where: r.company_id == ^company_id and r.status == "R",
                              left_join: cards in assoc(r, :employeecards),
                              left_join: e in assoc(r, :employee),
                              order_by: [
                                desc: r.inserted_At
                              ],
                              limit: 5,
                              select: %{
                                id: r.id,
                                employee_id: r.employee_id,
                                employeecards_id: r.employeecards_id,
                                last_digit: cards.last_digit,
                                first_name: e.first_name,
                                last_name: e.last_name,
                                amount: r.amount,
                                cur_code: r.cur_code,
                                reason: r.reason,
                                status: r.status,
                                inserted_at: r.inserted_at
                              }
    )


    requested_card_list = Repo.all(
      from c in Requestcard, where: c.company_id == ^company_id and c.status == "R",
                             left_join: ec in assoc(c, :employee),
                             order_by: [
                               desc: c.inserted_At
                             ],
                             limit: 5,
                             select: %{
                               id: c.id,
                               employee_id: c.employee_id,
                               currency: c.currency,
                               card_type: c.card_type,
                               status: c.status,
                               reason: c.reason,
                               inserted_at: c.inserted_at,
                               first_name: ec.first_name,
                               last_name: ec.last_name
                             }
    )

    all = Enum.concat(requested_money_list, requested_card_list)
    sorting = Enum.sort_by(all, &(NaiveDateTime.to_erl(&1.inserted_at)))
              |> Enum.reverse()

    lastfive = Enum.take(sorting, 5)

    json conn,
         %{
           status_code: "200",
           lastfive: lastfive,
           request_card: requested_card_list,
           request_money: requested_money_list
         }
  end

  def companyData(conn, _params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

    company_type = Repo.one from c in Company, where: c.id == ^company_id, select: c.company_type

    trading_address = Repo.one from a in Address, where: a.commanall_id == ^commanid and a.is_primary == "N",
                                                  select: count(a.id)

    get_cap = Repo.one from d in Directors,
                       where: d.company_id == ^company_id and d.position == "CAP" and d.status == "A",
                       select: %{
                         id: d.id,
                         count: count(d.id)
                       }
    trading_value = if trading_address == 0 do
      "No"
    else
      "Yes"
    end

    is_cap = if company_type == "STR" do
      if get_cap.count == 0 do
        "No"
      else
        "Yes"
      end
    else
      if get_cap.count == 0 do
        "No"
      else
        "Yes"
      end
    end




    json conn,
         %{
           status_code: "200",
           company_type: company_type,
           trading_address: trading_value,
           cap: is_cap,
           cap_id: get_cap.id
         }

  end
end