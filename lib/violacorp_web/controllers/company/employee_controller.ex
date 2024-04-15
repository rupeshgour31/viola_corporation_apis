defmodule ViolacorpWeb.Company.EmployeeController do
  use Phoenix.Controller
  import Ecto.Query, warn: false
  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  #  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Transactions

  def employeeDetailList(conn, _params)do
    %{"id" => company_id} = conn.assigns[:current_user]

    details = Repo.all(
      from e in Employee, where: e.company_id == ^company_id,
                          right_join: c in Commanall,
                          on: c.employee_id == e.id,
                          select: %{
                            firstname: e.first_name,
                            last_name: e.last_name,
                            commanall_id: c.id,
                            employee_id: e.id
                          }
    )
    employee_list = if !is_nil(details)do
      Enum.reduce(
        details,
        [],
        fn (x, acc) ->

#          cards = Repo.all(
#            from s in Employeecards, where: s.employee_id == ^x.employee_id and s.status != "12", select: count(s.id)
#          )
          total_cards = Repo.all(
            from s in Employeecards, where: s.employee_id == ^x.employee_id,
                                     select: %{
                                       card_id: s.id,
                                       last_digits: s.last_digit,
                                       status: s.status,
                                       type: s.card_type
                                     })
          lasttopup = Repo.one(
            from t in Transactions,
            where: t.employee_id == ^x.employee_id and t.category == "CT" and t.transaction_mode == "C",
            order_by: [
              desc: t.inserted_at
            ],
            limit: 1,
            select: t.transaction_date
          )
          cardcount = Map.merge(x, %{cards: total_cards, last_topup: lasttopup, total_cards: Enum.count(total_cards)})
          acc ++ [cardcount]
        end
      )
    else
      details
    end
    json conn, %{status_code: "200", data: employee_list}
  end

  def getEmployeeCardDetails(conn, params)do
    %{"id" => company_id} = conn.assigns[:current_user]
    employee_id = params["employee_id"]
    check_employee = Repo.one(from emp in Employee, where: emp.id == ^employee_id and emp.company_id == ^company_id)
    if !is_nil(check_employee) do
      cards = Repo.all(
        from e in Employeecards, where: e.employee_id == ^employee_id and e.status != "12",
                                 select: %{
                                   employee_id: e.employee_id,
                                   last_digit: e.last_digit,
                                   card_type: e.card_type,
                                   card_balance: e.current_balance,
                                   card_id: e.id
                                 }
      )
      json conn, %{status_code: "200", data: cards}
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               employee_id: "Invalid Id"
             }
           }
    end
  end
end


