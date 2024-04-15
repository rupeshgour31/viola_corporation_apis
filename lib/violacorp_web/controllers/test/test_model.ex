defmodule  Violacorp.Test.TestModel do
  import Ecto.Query

  alias Violacorp.Repo
#  alias Violacorp.Schemas.Employee
  alias Violacorp.Repo
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Resendmailhistory
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  #  alias Violacorp.Schemas.Employeenotes
#  alias Violacorp.Schemas.Employeecards
  #  alias  Violacorp.Schemas.Requestcard
  #  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Projects
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Appversions




  def active_pending_com_count(_params)do

    get_p_company = Repo.one(
      from a in Commanall, left_join: b in assoc(a, :company),
                           left_join: c in assoc(a, :contacts),
        #where: a.status not in ["A", "D", "B"] and like(b.company_name, ^"%%") and like(b.company_type, ^"%%"), select: count(a.id))
                           where: is_nil(a.accomplish_userid) and not is_nil(a.company_id) and a.status not in [
                             "A",
                             "D",
                             "B"
                           ] and c.is_primary == "Y",
                           select: count(a.id)
    )
    get_a_company = Repo.one(
      from co in Commanall, where: co.internal_status == "A" and co.status == "A" and not is_nil(co.accomplish_userid),
                            join: b in assoc(co, :company),
                            select: count(co.id)
    )
    total = get_a_company + get_p_company
    total_map = %{total: total}
    map1 = %{active_company: get_a_company}
    map2 = %{pending_company: get_p_company}
    merge = Map.merge(map1, map2)
    act_pp = Map.merge(merge, total_map)

    get_archive_company = Repo.one(
      from a in Commanall, where: a.status == "D", join: b in assoc(a, :company), select: count(a.id)
    )

    get_deleted_company = Repo.one(
      from a in Commanall, where: a.status == "B", join: b in assoc(a, :company), select: count(a.id)
    )

    map1 = %{archive_company: get_archive_company}
    map2 = %{deleted_company: get_deleted_company}
    total = get_archive_company + get_deleted_company
    total_map = %{total: total}
    merge = Map.merge(map1, map2)
    final = Map.merge(merge, total_map)
    _last = %{archive_delete: final, active_pending: act_pp}

    get = Repo.one(from d in Directors, where: d.status == "A", select: count(d.id))
    director = %{total_director_owner: get}

    active_employee = Repo.one(
      from comm in Commanall,
      left_join: e in assoc(comm, :employee),
        #                                          on: e.id == comm.employee_id, where: e.status != "D" and comm.status !=  "B",
      on: e.id == comm.employee_id,
      where: e.status != "D" and e.status != "B" and comm.status == "A" and comm.internal_status == "A",
      select: count(comm.id)
    )
    active_emp = %{active_employee: active_employee}
    archive_employee = Repo.one(
      from cm in Commanall, where: cm.status == "D" and not is_nil(cm.employee_id),
                            left_join: e in assoc(cm, :employee),
                            on: e.id == cm.employee_id,
                            select: count(cm.id)
    )
    deleted_employee = Repo.one(
      from cm in Commanall, where: cm.status == "B" and not is_nil(cm.employee_id),
                            left_join: e in assoc(cm, :employee),
                            on: e.id == cm.employee_id,
                            select: count(cm.id)
    )
    delete = %{deleted_employee: deleted_employee}

    archive_emp = %{archive_employee: archive_employee}
    total_e = active_employee + archive_employee + deleted_employee
    total_map_e = %{total: total_e}
    merge = Map.merge(active_emp, archive_emp)
    emp_merge = Map.merge(merge, delete)
    final_e = Map.merge(merge, total_map_e)
    final_employee = Map.merge(emp_merge, final_e)

    projects = Repo.one(from p in Projects, select: count(p.id))
    project = %{project: projects}

    acc_account = Repo.all(
      from adm in Adminaccounts, where: adm.status == ^"A",
                                 select: %{
                                   balance: adm.balance,
                                   type: adm.type
                                 }
    )
    _last = %{
      archive_delete_com: final,
      active_pending_com: act_pp,
      Directors: director,
      Employee: final_employee,
      projects: project,
      account: acc_account
    }
  end


  @doc " Get All Active User Of Company From  employee table"
  def getAllActiveEmployeeV1(params)do
    filter = params
             |> Map.take(~w(email_id))
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    status = params
             |> Map.take(~w(status))
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    first_name = params["first_name"]
    last_name = params["last_name"]
    contact_number = params["contact_number"]
    gender = params["gender"]

    _active_user = (
                     from c in Commanall,
                          having: ^filter,
                          left_join: e in assoc(c, :employee),
                          on: (^status),
                          left_join: con in assoc(c, :contacts),
                          on: e.id == c.employee_id,
                          right_join: com in Company,
                          on: com.id == e.company_id,
                          where: e.status != "D" and e.status != "B" and c.status == "A" and c.internal_status == "A"
                                 and like(e.first_name, ^"%#{first_name}%")
                                 and like(e.last_name, ^"%#{last_name}%")
                                 and like(e.gender, ^"%#{gender}%")
                          and like(con.contact_number, ^"%#{contact_number}"),
                          order_by: [
                            asc: e.first_name
                          ],
                          select: %{
                            commanall_id: c.id,
                            employee_id: e.id,
                            title: e.title,
                            first_name: e.first_name,
                            last_name: e.last_name,
                            position: e.position,
                            contact_number: con.contact_number,
                            trust_level: c.trust_level,
                            date_of_birth: e.date_of_birth,
                            status: e.status,
                            company_id: e.company_id,
                            company_name: com.company_name,
                            email_id: c.email_id,
                            gender: e.gender
                          })
                   |> Repo.paginate(params)
  end
  @doc""

  def pending_companies_v1(params) do
    filtered = params
               |> Map.take(~w(  email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    _company_name = params["company_name"]
    _contact_number = params["contact_number"]
    _company_type = params["company_type"]
    _active_companies = (
                          from a in Commanall,
                               left_join: b in assoc(a, :company),
                               order_by: [
                                 desc: a.id
                               ],
                               left_join: c in assoc(a, :contacts),
                               where: is_nil(a.accomplish_userid) and not is_nil(a.company_id) and a.status not in [
                                 "A",
                                 "D",
                                 "B"
                               ] and c.is_primary == "Y",
                                 #                               where: a.status not in ["A", "D", "B"] and like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%"),
                               having: ^filtered,
                               select: %{
                                 commanall_id: a.id,
                                 company_id: b.id,
                                 email_id: a.email_id,
                                 company_name: b.company_name,
                                 contact_number: c.contact_number, #"n/a",
                                 company_type: b.company_type,
                                 date_added: a.inserted_at,
                                 status: a.status
                               })
                        |> order_by(desc: :id)
                        |> Repo.paginate(params)

  end
  @doc " money request "
  def money_request_v1(params)do
    first_name = params["first_name"]
    last_name = params["last_name"]
    status = params["status"]
    filtered = params
               |> Map.take(~w(amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    _data = (from m in Requestmoney,
                  left_join: e in assoc(m, :employee),
                  where: like(e.first_name, ^"%#{first_name}%") and like(e.last_name, ^"%#{last_name}%") and like(
                    m.status,
                    ^"%#{status}%"
                         ),
                  order_by: [
                    asc: m.status
                  ],
                  having: ^filtered,
                  select: %{
                    first_name: e.first_name,
                    last_name: e.last_name,
                    amount: m.amount,
                    cur_code: m.cur_code,
                    status: m.status,
                    company_comment: m.company_reason,
                    user_comment: m.reason
                  }
              )
            |> Repo.paginate
  end

  @doc" Model Of List of Recent Mails"
  def recent_mails_v1(params) do
    filtered = params
               |> Map.take(~w(type))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    (from a in Resendmailhistory,
          left_join: b in assoc(a, :commanall),
          left_join: d in assoc(b, :employee),
          left_join: c in assoc(b, :company),
          on: c.id == b.company_id,
          select: %{
            id: a.id,
            type: a.type,
            date_added: a.inserted_at,
            company_name: c.company_name,
            title: d.title,
            first_name: d.first_name,
            last_name: d.last_name,
          })
    |> where(^filtered)
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(params)
  end

  @doc""
  def application_version_v1(params) do
    filtered = params
               |> Map.take(~w(type is_active))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    (from a in Appversions,
          having: ^filtered,
          select: %{
            id: a.id,
            type: a.type,
            is_active: a.is_active,
            date_added: a.inserted_at,
            version: a.version
          })
    |> order_by(asc: :is_active)
    |> Repo.paginate(params)
  end

end