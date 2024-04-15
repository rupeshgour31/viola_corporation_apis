defmodule ViolacorpWeb.Main.DashboardController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Departments
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Directors

  alias Violacorp.Libraries.Secure
  #  alias ViolacorpWeb.Main.DashboardView
  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  @doc "gets a list of all accounts of company with token"
  def getAllCompanyAccounts(conn, _params) do
    %{"id" => id, "commanall_id" => commanid} = conn.assigns[:current_user]

    accounts = Repo.all(
      from e in Companyaccounts, where: e.company_id == ^id,
                                 select: %{
                                   id: e.id,
                                   available_balance: e.available_balance,
                                   current_balance: e.available_balance,
                                   currency_code: e.currency_code,
                                   account_number: e.account_number,
                                   accomplish_account_id: e.accomplish_account_id,
                                   user_id: e.accomplish_account_id,
                                   expiry_date: e.expiry_date,
                                   status: e.status
                                 }
    )

    map = Enum.map(
      accounts,
      fn acc ->
        employeecards = Repo.one(
          from f in Employee, left_join: g in assoc(f, :employeecards),
                              where: f.company_id == ^id and g.currency_code == ^acc.currency_code,
                              select: count(g.id)
        )
        Map.put(acc, :Total_Number_of_Cards, employeecards)
        #        map = Map.merge(acc, %{Total_Number_of_Cards: employeecards})
      end
    )

    # Check Boarding Fee
    on_boarding_fee = Repo.one(from c in Commanall, where: c.id == ^commanid, select: c.on_boarding_fee)

    messages = if on_boarding_fee == "Y" do
      company_type = Repo.one(from c in Company, where: c.id == ^id, select: c.company_type)
      _messages = if company_type == "STR" do
        "On Boarding fee GBP 49.00 is due for Sole Trader"
      else
        "On Boarding fee GBP 69.00 is due for Limited Company"
      end
    else
      nil
    end
    json conn, %{status_code: "200", data: map, boarding_fee: on_boarding_fee, messages: messages}

    #    accounts = Repo.all(from e in Companyaccounts, where: e.company_id == ^id)
    #    render(conn, DashboardView, "accounts.json", accounts: accounts)
  end


  @doc "gets a list of all accounts of company with token"
  def getCompanyCurrency(conn, _params) do
    %{"id" => id} = conn.assigns[:current_user]

    accounts = Repo.all(
      from e in Companyaccounts, where: e.company_id == ^id,
                                 select: %{
                                   id: e.currencies_id,
                                   code: e.currency_code
                                 }
    )
    json conn, %{status_code: "200", data: accounts}
  end

  @doc "get employee's cards using employeeid in params"
  def getAllEmployeeCards(conn, params) do

    employeecards = Repo.all (
                               from e in Employeecards,
                                    where: e.employee_id == ^params["employeeId"] and e.status != "5",
                                    left_join: employee in assoc(e, :employee),
                                    select: %{
                                      id: e.id,
                                      first_name: employee.first_name,
                                      last_name: employee.last_name,
                                      currency_code: e.currency_code,
                                      card_number: e.last_digit,
                                      expiry_date: e.expiry_date,
                                      available_balance: e.available_balance,
                                      current_balance: e.available_balance,
                                      card_type: e.card_type,
                                      status: e.status,
                                      activation_code: e.activation_code
                                    })

    json conn, %{status_code: "200", employeecards: employeecards}
  end

  @doc "get employee's cards using employeeid in params"
  def getFilteredEmployeeCards(conn, params) do
    %{"id" => id} = conn.assigns[:current_user]
    unless map_size(params) == 0 do
      employee_id = params["employee_id"]
      last_digit = params["last_digit"]
      card_type = params["card_type"]
      status = params["status"]

      employee_filtered = if employee_id != "" and last_digit != "" and card_type != "" and status != "" do
        params
        |> Map.take(~w( employee_id last_digit card_type status))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      else
        if  employee_id != "" and last_digit != "" and card_type != "" do
          params
          |> Map.take(~w( employee_id last_digit card_type))
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
        else
          if  employee_id != "" and last_digit != "" and status != "" do
            params
            |> Map.take(~w( employee_id last_digit status))
            |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          else
            if  employee_id != "" and card_type != "" and status != "" do
              params
              |> Map.take(~w( employee_id card_type status))
              |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
            else
              if  employee_id != "" and status != "" do
                params
                |> Map.take(~w( employee_id status))
                |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
              else
                if  employee_id != "" and last_digit != "" do
                  params
                  |> Map.take(~w( employee_id last_digit))
                  |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
                else
                  if  employee_id != "" and card_type != "" do
                    params
                    |> Map.take(~w( employee_id card_type))
                    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
                  else
                    params
                    |> Map.take(~w( employee_id))
                    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
                  end
                end
              end
            end
          end
        end
      end

      if employee_id != "" do

        employeecards = if status != nil do
          (from e in Employeecards,
                where: ^employee_filtered,
                left_join: employee in assoc(e, :employee),
                where: employee.company_id == ^id,
                select: %{
                  id: e.id,
                  employee_id: e.employee_id,
                  first_name: employee.first_name,
                  last_name: employee.last_name,
                  currency_code: e.currency_code,
                  card_number: e.last_digit,
                  expiry_date: e.expiry_date,
                  available_balance: e.available_balance,
                  current_balance: e.available_balance,
                  card_type: e.card_type,
                  status: e.status,
                  activation_code: e.activation_code
                })
          |> Repo.paginate(params)
        else
          (from e in Employeecards,
                where: ^employee_filtered,
                left_join: employee in assoc(e, :employee),
                where: employee.company_id == ^id and e.status != "5",
                select: %{
                  id: e.id,
                  employee_id: e.employee_id,
                  first_name: employee.first_name,
                  last_name: employee.last_name,
                  currency_code: e.currency_code,
                  card_number: e.last_digit,
                  expiry_date: e.expiry_date,
                  available_balance: e.available_balance,
                  current_balance: e.available_balance,
                  card_type: e.card_type,
                  status: e.status,
                  activation_code: e.activation_code
                })
          |> Repo.paginate(params)
        end
        total_count = Enum.count(employeecards)
        json conn,
             %{
               status_code: "200",
               total_count: total_count,
               data: employeecards.entries,
               page_number: employeecards.page_number,
               total_pages: employeecards.total_pages
             }
      else
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc  "get employee's cards using employeeid in params"
  def getSingleEmployeeCards(conn, params) do
    employeecards = Repo.all (
                               from e in Employeecards,
                                    where: e.id == ^params["cardId"] and e.status != "5",
                                    left_join: employee in assoc(e, :employee),
                                    left_join: department in assoc(employee, :departments),
                                    select: %{
                                      id: e.id,
                                      first_name: employee.first_name,
                                      last_name: employee.last_name,
                                      employee_id: employee.id,
                                      currency_code: e.currency_code,
                                      card_number: e.last_digit,
                                      expiry_date: e.expiry_date,
                                      available_balance: e.available_balance,
                                      current_balance: e.available_balance,
                                      card_type: e.card_type,
                                      status: e.status,
                                      activation_code: e.activation_code,
                                      department_name: department.department_name
                                    })
    json conn, %{status_code: "200", employeecards: employeecards}
  end

  @doc  "get all employees cards using companyid in token"
  def getCompanyAllEmployeeCards(conn, params) do
    %{"id" => id} = conn.assigns[:current_user]

    employeecards = (from e in Employeecards,
                          where: e.status != "5",
                          left_join: employee in assoc(e, :employee),
                          where: employee.company_id == ^id,
                          order_by: [
                            asc: employee.first_name
                          ],
                          select: %{
                            id: e.id,
                            first_name: employee.first_name,
                            last_name: employee.last_name,
                            currency_code: e.currency_code,
                            card_number: e.last_digit,
                            expiry_date: e.expiry_date,
                            available_balance: e.available_balance,
                            current_balance: e.available_balance,
                            card_type: e.card_type,
                            status: e.status,
                            activation_code: e.activation_code,
                            emp_id: e.employee_id
                          })
                    |> Repo.paginate(params)

    total_count = Enum.count(employeecards)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: employeecards.entries,
           page_number: employeecards.page_number,
           total_pages: employeecards.total_pages
         }
  end

  @doc "gets a list of all employees of logged in company"
  def getAllCompanyEmployees(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]
    employee = (
                 from e in Employee,
                      where: e.company_id == ^compid and e.is_manager == "N",
                      left_join: department in assoc(e, :departments),
                      select: %{
                        id: e.id,
                        title: e.title,
                        first_name: e.first_name,
                        last_name: e.last_name,
                        status: e.status,
                        profile_picture: e.profile_picture,
                        employeeids: e.employeeids,
                        dateofbirth: e.date_of_birth,
                        gender: e.gender,
                        department_id: department.id,
                        department_name: department.department_name,
                        number_of_cards: e.no_of_cards,
                        director_id: e.director_id
                      })
               |> Repo.paginate(params)


    map = Stream.with_index(employee, 1)
          |> Enum.reduce(
               %{},
               fn ({v, k}, emp) ->
                 id = v.id
                 # get all requested card count
                 count_card = Repo.one(
                   from m in Requestcard, where: m.employee_id == ^id and m.status == ^"R", select: count(m.id)
                 )

                 # get all requested money count
                 count_money = Repo.one(
                   from c in Requestmoney, where: c.employee_id == ^id and c.status == ^"R", select: count(c.id)
                 )
                 response_emp = %{
                   id: v.id,
                   title: v.title,
                   first_name: v.first_name,
                   last_name: v.last_name,
                   status: v.status,
                   profile_picture: v.profile_picture,
                   employeeids: v.employeeids,
                   dateofbirth: v.dateofbirth,
                   gender: v.gender,
                   department_id: v.department_id,
                   department_name: v.department_name,
                   number_of_cards: v.number_of_cards,
                   director_id: v.director_id,
                   card_requesed: count_card,
                   money_requesed: count_money
                 }

                 Map.put(emp, k, response_emp)
               end
             )
    json conn, %{status_code: "200", data: map, page_number: employee.page_number, total_pages: employee.total_pages}
  end

  @doc "gets a list of all employees of logged in company"
  def getAllEmployee(conn, _params) do
    %{"id" => compid} = conn.assigns[:current_user]
    employee = Repo.all(
      from e in Employee,
      where: e.company_id == ^compid and e.is_manager == "N",
      left_join: department in assoc(e, :departments),
      select: %{
        id: e.id,
        title: e.title,
        first_name: e.first_name,
        last_name: e.last_name,
        status: e.status,
        profile_picture: e.profile_picture,
        employeeids: e.employeeids,
        dateofbirth: e.date_of_birth,
        gender: e.gender,
        department_id: department.id,
        department_name: department.department_name,
        number_of_cards: e.no_of_cards,
        director_id: e.director_id
      }
    )

    map = Stream.with_index(employee, 1)
          |> Enum.reduce(
               %{},
               fn ({v, k}, emp) ->
                 id = v.id
                 # get all requested card count
                 count_card = Repo.one(
                   from m in Requestmoney, where: m.employee_id == ^id and m.status == ^"R", select: count(m.id)
                 )

                 # get all requested money count
                 count_money = Repo.one(
                   from c in Requestcard, where: c.employee_id == ^id and c.status == ^"R", select: count(c.id)
                 )

                 response_emp = %{
                   id: v.id,
                   title: v.title,
                   first_name: v.first_name,
                   last_name: v.last_name,
                   status: v.status,
                   profile_picture: v.profile_picture,
                   employeeids: v.employeeids,
                   dateofbirth: v.dateofbirth,
                   gender: v.gender,
                   department_id: v.department_id,
                   department_name: v.department_name,
                   number_of_cards: v.number_of_cards,
                   director_id: v.director_id,
                   card_requesed: count_card,
                   money_requesed: count_money
                 }

                 Map.put(emp, k, response_emp)
               end
             )

    json conn, %{status_code: "200", data: map}
  end

  @doc "gets addresses/contacts and employee info with given employeeid"
  def getEmployeeProfile(conn, params) do

    employee_comman_data = Repo.one from commanall in Commanall, where: commanall.employee_id == ^params["employeeId"],
                                                                 left_join: address in assoc(commanall, :address),
                                                                 where: address.is_primary == "Y",
                                                                 left_join: contacts in assoc(commanall, :contacts),
                                                                 where: contacts.is_primary == "Y",
                                                                 left_join: employee in assoc(commanall, :employee),
                                                                 select: %{
                                                                   email_id: commanall.email_id,
                                                                   address_line_one: address.address_line_one,
                                                                   address_line_two: address.address_line_two,
                                                                   address_line_three: address.address_line_three,
                                                                   city: address.city,
                                                                   town: address.town,
                                                                   post_code: address.post_code,
                                                                   county: address.county,
                                                                   contact_number: contacts.contact_number,
                                                                   code: contacts.code,
                                                                   employee_contact_id: contacts.id,
                                                                   first_name: employee.first_name,
                                                                   last_name: employee.last_name,
                                                                   date_of_birth: employee.date_of_birth,
                                                                   gender: employee.gender,
                                                                   title: employee.title,
                                                                   employeeids: employee.employeeids,
                                                                   employee_id: employee.id,
                                                                   position: employee.position,
                                                                   gender: employee.gender,
                                                                   departments_id: employee.departments_id,
                                                                   joining_date: employee.inserted_at,
                                                                   director_id: employee.director_id,
                                                                   status: employee.status
                                                                 }
    employee_cards = Repo.all from e in Employeecards,
                              where: e.employee_id == ^params["employeeId"] and e.status != "5",
                              select: %{
                                id: e.id,
                                currency_code: e.currency_code,
                                card_number: e.last_digit,
                                expiry_date: e.expiry_date,
                                name_on_card: e.name_on_card,
                                available_balance: e.available_balance,
                                current_balance: e.available_balance,
                                card_type: e.card_type,
                                status: e.status
                              }

    employee_department = if !is_nil(employee_comman_data) do
      department_id = employee_comman_data.departments_id
        result_department = if !is_nil(department_id) do
                               Repo.all from d in Departments, where: d.id == ^employee_comman_data.departments_id,
                                          select: %{
                                            id: d.id,
                                            department_name: d.department_name
                                          }
        else
          ''
        end
        email_id = employee_comman_data.email_id
        result_email = if !is_nil(email_id) do
                          director_id = employee_comman_data.director_id
                          if !is_nil(director_id) do
                            director_info = Repo.one(from director in Directors, where: director.id == ^director_id,
                                                                                 left_join: contact in assoc(director, :contactsdirectors),
                                                                                 limit: 1,
                                                                                 select: %{
                                                                                   id: director.id,
                                                                                   director_contact_id: contact.id,
                                                                                   as_employee: director.as_employee
                                                                                 })

                            if !is_nil(director_info) and director_info.as_employee == "Y" do
                              %{id: director_info.id, director_contact_id: director_info.director_contact_id, as_employee: director_info.as_employee}
                            else
                              %{id: nil, director_contact_id: nil, as_employee: nil}
                            end
                          else
                            %{id: nil, director_contact_id: nil, as_employee: nil}
                          end
                        else
                          %{id: nil, director_contact_id: nil, as_employee: nil}
                        end
        _data = %{
          department: result_department,
          director: result_email
        }

    end

    json conn,
         %{
           status_code: "200",
           employee_data: employee_comman_data,
           employee_cards: employee_cards,
           result: employee_department
         }
  end

  @doc "update card status from activate to deactivate and viceversa"
  def updateCardStatus(conn, params) do
    unless map_size(params) == 0 do
    %{"id" => company_id} = conn.assigns[:current_user]

    matchuser = Repo.one(
      from a in Employee, where: a.id == ^params["employee_id"] and a.company_id == ^company_id, select: count(a.id)
    )

    if matchuser == 1 do
      get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])

      changeset = %{status: params["new_status"], reason: params["reason"], change_status: "C"}
      new_changeset = Employeecards.changesetStatus(get_card, changeset)


      if get_card.change_status == "A" and get_card.status == "4" or get_card.status == "5"  do
        json conn, %{status_code: "4003", messages: "Cannot change status of this card, contact Admin!"}
      else

        # Call to accomplish
        request = %{urlid: get_card.accomplish_card_id, status: params["new_status"]}
        response = Accomplish.activate_deactive_card(request)

        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do
          case Repo.update(new_changeset) do
            {:ok, _commanall} -> if params["new_status"] == "1" do
                                   json conn, %{status_code: "200", messages: "Success, Card Activated!"}
                                 else
                                   json conn, %{status_code: "200", messages: "Success, Card Deactivated!"}
                                 end
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn, %{status_code: response_code, errors: %{ messages: response_message }}
        end
      end
    else
      text conn, "no employee found"
    end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc"update employee card status v1"
  def updateCardStatusv1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      vpin = params["vpin"]
      auth = Secure.verifyVPin(commanid, vpin)
      case auth do
        "Active" ->
                  matchuser = Repo.one(
                    from a in Employee, where: a.id == ^params["employee_id"] and a.company_id == ^company_id, select: count(a.id)
                  )

                  if matchuser == 1 do
                    get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])

                    changeset = %{status: params["new_status"], reason: params["reason"], change_status: "C"}
                    new_changeset = Employeecards.changesetStatus(get_card, changeset)


                    if get_card.change_status == "A" and get_card.status == "4" or get_card.status == "5"  do
                      json conn, %{status_code: "4003", messages: "Cannot change status of this card, contact Admin!"}
                    else

                      # Call to accomplish
                      request = %{urlid: get_card.accomplish_card_id, status: params["new_status"]}
                      response = Accomplish.activate_deactive_card(request)

                      response_code = response["result"]["code"]
                      response_message = response["result"]["friendly_message"]

                      if response_code == "0000" or response_code == "3055" do
                        case Repo.update(new_changeset) do
                          {:ok, _commanall} -> if params["new_status"] == "1" do
                                                 json conn, %{status_code: "200", messages: "Success, Card Activated!"}
                                               else
                                                 json conn, %{status_code: "200", messages: "Success, Card Deactivated!"}
                                               end
                          {:error, changeset} ->
                            conn
                            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                        end
                      else
                        json conn, %{status_code: response_code, errors: %{ messages: response_message }}
                      end
                    end
                  else
                    text conn, "no employee found"
                  end
        {:error, message} -> json conn, message
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "block employee card if it is deactivated"
  def blockCard(conn, params) do
    unless map_size(params) == 0 do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]

    matchuser = Repo.one(
      from a in Employee, where: a.id == ^params["employee_id"] and a.company_id == ^company_id,
                          select: %{
                            usercount: count(a.id)
                          }
    )
    if matchuser.usercount == 1 do
      get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])
      if get_card.change_status == "A" and (get_card.status == "4" or get_card.status == "5") do
        json conn, %{status_code: "4003", messages: "Cannot change status of this card, contact Admin!"}
      else
        if get_card.status == "4" do
          changeset = %{status: "5", reason: params["reason"], change_status: "C"}
          new_changeset = Employeecards.changesetStatus(get_card, changeset)

          case Repo.update(new_changeset) do
            {:ok, _commanall} ->
              get_account = Repo.get_by!(Companyaccounts, company_id: company_id, currency_code: get_card.currency_code)
              min_amount = "0.00"
              check_min_amount = String.to_float("#{min_amount}")
              check_max_amount = if is_nil(get_card.available_balance), do: String.to_float("#{min_amount}"), else: String.to_float("#{get_card.available_balance}")
              if check_max_amount > check_min_amount do
                reclaim_params =
                  %{
                    commanid: commanid,
                    companyid: company_id,
                    employeeId: get_card.employee_id,
                    card_id: get_card.id,
                    account_id: get_account.id,
                    amount: get_card.available_balance,
                    type: "C2A",
                    description: "Reclaim of all funds due to card being blocked"
                  }
                _response = reclaimFunds(reclaim_params)
              end

              getemail = Repo.one(from cmn in Commanall, where: cmn.employee_id == ^params["employee_id"], left_join: c in assoc(cmn, :contacts), on: c.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"), preload: [
                contacts: c, devicedetails: d
              ])

              getemployee = Repo.get!(Employee, params["employee_id"])
              [count_card] = Repo.all from dd in Employeecards,
                                      where: dd.employee_id == ^params["employee_id"] and (
                                        dd.status == "1" or dd.status == "4" or dd.status == "12"),
                                      select: %{
                                        count: count(dd.id)
                                      }
              new_number = %{"no_of_cards" => count_card.count}
              cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
              Repo.update(cards_changeset)

              # Call to accomplish
              request = %{urlid: get_card.accomplish_card_id, status: 6}
              response = Accomplish.activate_deactive_card(request)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              if response_code == "0000" do
                #                  # ALERTS DEPRECATED
                #                  data = %{
                #                    :section => "block_card",
                #                    :commanall_id => getemail.id,
                #                    :employee_name => "#{getemployee.first_name} #{getemployee.last_name}",
                #                    :card => get_card.last_digit
                #                  }
                #                  AlertsController.sendEmail(data)
                #                  AlertsController.sendNotification(data)
                #                  AlertsController.sendSms(data)
                #                  AlertsController.storeNotification(data)

                data = [%{
                  section: "block_card",
                  type: "E",
                  email_id: getemail.email_id,
                  data: %{:employee_name => "#{getemployee.first_name} #{getemployee.last_name}", :card => get_card.last_digit}   # Content
                },
                  %{
                    section: "block_card",
                    type: "S",
                    contact_code: if is_nil(Enum.at(getemail.contacts, 0)) do nil else Enum.at(getemail.contacts, 0).code end,
                    contact_number: if is_nil(Enum.at(getemail.contacts, 0)) do nil else Enum.at(getemail.contacts, 0).contact_number end,
                    data: %{:card => get_card.last_digit} # Content
                  },
                  %{
                    section: "block_card",
                    type: "N",
                    token: if is_nil(getemail.devicedetails) do nil else getemail.devicedetails.token end,
                    push_type: if is_nil(getemail.devicedetails) do nil else getemail.devicedetails.type end, # "I" or "A"
                    login: getemail.as_login, # "Y" or "N"
                    data: %{:card => get_card.last_digit} # Content
                  }]
                V2AlertsController.main(data)

                  json conn, %{status_code: "200", messages: "Card has been Blocked"}
              else
                json conn, %{status_code: response_code, errors: %{ messages: response_message }}
              end

            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          if get_card.status == "1" do
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "The card needs to be deactivated"
                   }
                 }
          else
            if get_card.status == "5" do
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "The card is already blocked"
                     }
                   }
            end
          end
        end
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Employee/Card Not Found"
             }
           }
    end
    else
  conn
  |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
  end
  end

  @doc "update notification for un-read to read"
  def updateNotification(conn, params) do
    notifications = Repo.get!(Notifications, params["id"])
    change_status = %{"status" => "R"}
    changeset_notification = Notifications.updatestatus_changeset(notifications, change_status)
    Repo.update(changeset_notification)

    json conn, %{status_code: "200", messages: "status update."}
  end

  @doc "get all cards total balance"
  def cardsBalance(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    [matchuser] = Repo.all(
      from a in Employee, where: a.company_id == ^company_id,
                          left_join: employeecard in assoc(a, :employeecards),
                          select: sum(employeecard.available_balance)
    )

    data = if matchuser != nil do
      matchuser
      else
        "0.00"
    end

    json conn, %{status_code: "200", data: data}
  end

  @doc "Used in conjuction with blockcard, it moves all the funds of the card to main company account"
  def reclaimFunds(params) do

    today = DateTime.utc_now

    commanid = params.commanid
    companyid = params.companyid
    employeecard_id = params.card_id
    account_id = params.account_id
    amount = params.amount
    description = params.description
    type = Application.get_env(:violacorp, :transaction_type)

    type_debit = Application.get_env(:violacorp, :movefund_debit)
    type_credit = Application.get_env(:violacorp, :movefund_credit)

    # GET ACCOUNT ID
    company_info = Repo.get(Company, companyid)
    account_details = Repo.get(Companyaccounts, account_id)
    currency = account_details.currency_code
    account_id = account_details.accomplish_account_id
    acc_available_balance = String.to_float("#{account_details.available_balance}")
    credit_balance = acc_available_balance + String.to_float("#{amount}")
    to_company = company_info.company_name

    # GET CARD ID
    card_details = Repo.get(Employeecards, employeecard_id)
    employee_id = card_details.employee_id
    employee_info = Repo.get(Employee, employee_id)
    card_id = card_details.accomplish_card_id
    card_available_balance = String.to_float("#{card_details.available_balance}")
    debit_balance = card_available_balance - String.to_float("#{amount}")
    from_card = card_details.last_digit
    from_employee = "#{employee_info.first_name} #{employee_info.last_name}"

    remark = %{
      "from" => from_card,
      "from_info" => %{
        "owner_name" => "#{from_employee}",
        "card_number" => "#{from_card}",
        "sort_code" => "",
        "account_number" => ""
      },
      "to" => currency,
      "to_info" => %{
        "owner_name" => "#{to_company}",
        "card_number" => "",
        "sort_code" => "#{account_id}",
        "account_number" => "#{account_details.accomplish_account_number}"
      }
    }

    # Get Employee Comman id
    get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^params.employeeId, select: a.id

    # Entry for employee transaction
    # Create First entry in transaction
    transaction_employee = %{
      "commanall_id" => get_commanall_id,
      "company_id" => companyid,
      "employee_id" => employee_id,
      "employeecards_id" => employeecard_id,
      "amount" => amount,
      "fee_amount" => 0.00,
      "final_amount" => amount,
      "cur_code" => currency,
      "balance" => debit_balance,
      "previous_balance" => card_details.available_balance,
      "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
      "transaction_date" => today,
      "transaction_mode" => "D",
      "api_type" => type_debit,
      "transaction_type" => "C2A",
      "category" => "MV",
      "description" => description,
      "remark" => Poison.encode!(remark),
      "inserted_by" => commanid
    }

    changeset = Transactions.changesetTopupStepSecond(%Transactions{}, transaction_employee)
    case Repo.insert(changeset) do
      {:ok, data} -> ids = data.id
                     request = %{
                       type: type,
                       amount: amount,
                       currency: currency,
                       account_id: card_id,
                       card_id: account_id,
                       validate: "0"
                     }
                     response = Accomplish.move_funds(request)
                     response_code = response["result"]["code"]
                     response_message = response["result"]["friendly_message"]
                     transactions_id_api = response["info"]["original_source_id"]

                     if response_code == "0000" do

                       # Update Account Transaction Status
                       trans_status = Repo.get(Transactions, ids)
                       update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                       changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                       Repo.update(changeset_transaction)
                       # update balance for Account
                       gets_account = Accomplish.get_account(account_id)
                       current_balance = gets_account["info"]["balance"]
                       available_balance = gets_account["info"]["available_balance"]
                       update_balance = %{
                         "available_balance" => available_balance,
                         "current_balance" => current_balance
                       }
                       changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
                       Repo.update(changeset_companyaccount)

                       # update balance for Card
                       get_card = Accomplish.get_account(card_id)
                       current_balance_card = get_card["info"]["balance"]
                       available_balance_card = get_card["info"]["available_balance"]
                       update_card_balance = %{
                         "available_balance" => available_balance_card,
                         "current_balance" => current_balance_card
                       }
                       changeset_employeecard = Employeecards.changesetBalance(card_details, update_card_balance)
                       Repo.update(changeset_employeecard)

                       transaction_employee = %{
                         "commanall_id" => commanid,
                         "company_id" => companyid,
                         "employee_id" => employee_id,
                         "employeecards_id" => employeecard_id,
                         "amount" => amount,
                         "fee_amount" => 0.00,
                         "final_amount" => amount,
                         "cur_code" => currency,
                         "balance" => credit_balance,
                         "previous_balance" => account_details.available_balance,
                         "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                         "transaction_date" => today,
                         "transaction_mode" => "C",
                         "transaction_type" => "C2A",
                         "api_type" => type_credit,
                         "category" => "MV",
                         "description" => description,
                         "status" => "S",
                         "remark" => Poison.encode!(remark),
                         "inserted_by" => commanid
                       }
                       changeset_card = Transactions.changesetTopupStepThird(%Transactions{}, transaction_employee)
                       Repo.insert(changeset_card)
                       %{status_code: "200", message: response_message}
                     else
                       %{status_code: "400", errors: %{message: response_message}}
                     end
    end
  end

end