defmodule  Violacorp.Models.Dashboard do
  import Ecto.Query

  alias Violacorp.Repo
#  alias Violacorp.Schemas.Employee
  alias Violacorp.Repo
#  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Commanall
#  alias Violacorp.Schemas.Employeenotes
  alias Violacorp.Schemas.Employeecards
#  alias  Violacorp.Schemas.Requestcard
#  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Projects
  alias Violacorp.Schemas.Adminaccounts
#  alias Violacorp.Schemas.Company

   def active_pending_com_count(_params)do

                  get_p_company = Repo.one(from a in Commanall, left_join: b in assoc(a, :company),
                                                                 where: a.status not in ["A", "D", "B"] and like(b.company_name, ^"%%") and like(b.company_type, ^"%%"), select: count(a.id))
                  get_a_company = Repo.one(from co in Commanall, where: co.internal_status == "A"  and  co.status == "A" and not is_nil(co.accomplish_userid), join: b in assoc(co, :company), select: count(co.id) )
                  total= get_a_company + get_p_company
                  total_map = %{total: total}
                  map1 = %{active_company:  get_a_company}
                  map2 = %{pending_company: get_p_company}
                   merge = Map.merge(map1, map2)
                   act_pp = Map.merge(merge,total_map)

               get_archive_company = Repo.one(from a in Commanall, where: a.status == "D", join: b in assoc(a, :company), select: count(a.id))

               get_deleted_company = Repo.one(from a in Commanall,  where: a.status == "B", join: b in assoc(a, :company), select: count(a.id))

               map1 = %{archive_company:  get_archive_company}
               map2 = %{deleted_company: get_deleted_company}
               total = get_archive_company + get_deleted_company
               total_map = %{total: total}
               merge = Map.merge(map1, map2)
               final = Map.merge(merge,total_map)
               _last = %{archive_delete: final, active_pending: act_pp }

               get = Repo.one(from d in Directors, where: d.status == "A" , select: count(d.id))
               director = %{total_director_owner: get}

               active_employee = Repo.one(from comm in Commanall,
                                          left_join:  e in assoc(comm, :employee),
                                          on: e.id == comm.employee_id, where: e.status == "A" and comm.internal_status ==  "A",
                                            select: count(comm.id))
               pending_employee = Repo.one(from c1 in Commanall,
                                         left_join:  e1 in assoc(c1, :employee),
                                         on: e1.id == c1.employee_id, where: e1.status != "A" and e1.status != "D" and e1.status !=  "B",
                                         select: count(c1.id))
               active_emp = %{active_employee: active_employee, pending_employee: pending_employee}
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
               total_e = active_employee + archive_employee + deleted_employee + pending_employee
                  total_map_e = %{total: total_e }
               merge = Map.merge( active_emp,archive_emp)
               emp_merge = Map.merge(merge, delete)
               final_e = Map.merge(merge,total_map_e)
               final_employee = Map.merge(emp_merge, final_e)

            projects = Repo.one(from p in Projects, select: count(p.id))
            project = %{project: projects}

                  acc_account = Repo.all(from adm in Adminaccounts, where: adm.status == ^"A", select: %{balance: adm.balance, type: adm.type})
     _last = %{archive_delete_com: final, active_pending_com: act_pp , Directors: director, Employee: final_employee ,projects: project, account: acc_account}
  end

  def dashboardCount(_params)do

    # get all company
    get_pending_company = Repo.one(from pc in Commanall, right_join: b in assoc(pc, :company), where: pc.status not in ["A", "D", "B", "U", "R"], select: count(pc.id))
    get_active_company = Repo.one(from co in Commanall, right_join: cm in assoc(co, :company), where: co.internal_status == "A"  and  co.status == "A" and not is_nil(co.accomplish_userid), select: count(co.id) )
    get_archive_company = Repo.one(from ar in Commanall, right_join: c in assoc(ar, :company), where: ar.status == "R",  select: count(ar.id))
    get_suspend_company = Repo.one(from s in Commanall, right_join: c2 in assoc(s, :company), where: s.status == "D",  select: count(c2.id))
    get_close_company = Repo.one(from cc in Commanall, right_join: com in assoc(cc, :company), where: cc.status == "B",  select: count(cc.id))
    get_under_company = Repo.one(from ur in Commanall, right_join: com1 in assoc(ur, :company), where: ur.status == "U",  select: count(ur.id))

    total_company = get_active_company + get_pending_company + get_archive_company + get_suspend_company + get_close_company + get_under_company

    company = %{
      total: total_company,
      active: get_active_company,
      pending: get_pending_company,
      suspend: get_suspend_company,
      archive: get_archive_company,
      close: get_close_company,
      under_review: get_under_company,
    }

    count_of_director = Repo.one(from d in Directors, where: d.status == "A" , select: count(d.id))

    active_employee = Repo.one(from comm in Commanall,
                               left_join:  e in assoc(comm, :employee),
                               on: e.id == comm.employee_id, where: e.status == "A" and comm.internal_status ==  "A",
                               select: count(comm.id))
    pending_employee = Repo.one(from c1 in Commanall,
                                left_join:  e1 in assoc(c1, :employee),
                                on: e1.id == c1.employee_id, where: e1.status != "A" and e1.status != "D" and e1.status !=  "B",
                                select: count(c1.id))
    suspend_employee = Repo.one(
      from cm in Commanall, where: cm.status == "D" and not is_nil(cm.employee_id),
                            left_join: e in assoc(cm, :employee),
                            on: e.id == cm.employee_id,
                            select: count(cm.id)
    )
    close_employee = Repo.one(
      from cm in Commanall, where: cm.status == "B" and not is_nil(cm.employee_id),
                            left_join: e in assoc(cm, :employee),
                            on: e.id == cm.employee_id,
                            select: count(cm.id)
    )
    total_employee = active_employee + suspend_employee + close_employee + pending_employee
    employee = %{
      total: total_employee,
      active_employee: active_employee,
      pending_employee: pending_employee,
      suspend_employee: suspend_employee,
      close_employee: close_employee
    }

    projects = Repo.one(from p in Projects, select: count(p.id))
    project = %{project: projects}

    acc_account = Repo.all(from adm in Adminaccounts, where: adm.status == ^"A", select: %{balance: adm.balance, type: adm.type})
    %{company: company, employee: employee , directors: count_of_director, projects: project, account: acc_account}
  end

def cards_count(_params)do
    virtual_card = Repo.all(from card in Employeecards,
                            where: card.status == "1" and card.card_type == "V",
                             left_join: e in assoc(card, :employee),order_by: [desc: card.id],limit: 15,
                                   select: %{
                                     first_name: e.first_name,
                                     company_id: e.company_id,
                                     last_name: e.last_name,
                                      id: card.id,

                                    card_number: card.card_number,
                                    last_digit: card.last_digit,
                                    available_balance: card.available_balance,
                                     expiry_date: card.expiry_date,
                                     accomplish_card_id: card.accomplish_card_id,
                                     })

    physical_card = Repo.all(from card in Employeecards, where: card.status == "1" and card.card_type == "P",
                                                        left_join: e in assoc(card, :employee),order_by: [desc: card.id],limit: 15,
                                                        select: %{
                                                          first_name: e.first_name,
                                                          company_id: e.company_id,
                                                          last_name: e.last_name,
                                                          id: card.id,
                                                          card_number: card.card_number,
                                                          last_digit: card.last_digit,
                                                          available_balance: card.available_balance,
                                                          expiry_date: card.expiry_date,
                                                          accomplish_card_id: card.accomplish_card_id,
                                                        })
     _map = %{physical_card: physical_card, virtual_card: virtual_card}
  end




def archive_deleted_com_count(_params)do
    get_archive_company = Repo.one(from a in Commanall, where: a.status == "D",
                                                        join: b in assoc(a, :company),
                                                        select: count(a.id))

    get_deleted_company = Repo.one(from a in Commanall,  where: a.status == "B",
                                                         join: b in assoc(a, :company),
                                                         select: count(a.id))
    map1 = %{archive_company:  get_archive_company}
    map2 = %{deleted_company: get_deleted_company}
    total = get_archive_company + get_deleted_company
    merge = Map.merge(map1, map2)
    _map = %{data: merge, total: total}
  end


  def total_directors_owner(_params)do

     _get = Repo.one(from d in Directors, where: d.status == "A" , select: count(d.id))
  end
end