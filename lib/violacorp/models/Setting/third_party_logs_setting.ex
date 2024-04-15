defmodule Violacorp.Model.Settings.ThirdPartyLogsSetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Thirdpartylogs
#  alias Violacorp.Schemas.Employee
#  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
  @moduledoc false

  def third_party_logs_list(params) do
              _filtered = params
                         |> Map.take(~w(type))
                         |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

              email_id = params["email_id"]
            _com =    if params["type"] == "C" do
                          _company = (from a in Thirdpartylogs,
#                                    left_join: cml in assoc(a, :commanall),
                                    left_join: cml in Commanall,
                                    on: a.commanall_id == cml.id,
                                    where: like(cml.email_id, ^"%#{email_id}") and  not is_nil(cml.company_id),
                                    left_join: emp in assoc(cml, :employee),
                                    left_join: com in assoc(cml, :company),

                                    select: %{
                                     commanall_id: cml.id,
                                      id: a.id,
                                      status: a.status,
                                      title: emp.title,
                                      email_id: cml.email_id,
                                      first_name: emp.first_name,
                                      last_name: emp.last_name,
                                      company_name: com.company_name,
                                      company_id: com.id,
                                      employee_id: cml.employee_id
                                    })
                          |> Repo.paginate(params)
                          else
                         _emp =  if params["type"] == "E" do
                                    _employee = (from a in Thirdpartylogs,
#                                      left_join: cml in assoc(a, :commanall),
                                      left_join: cml in Commanall,
                                      on: a.commanall_id == cml.id,
                                      where: like(cml.email_id, ^"%#{email_id}") and is_nil(cml.company_id),
                                      left_join: emp in assoc(cml, :employee),
                                      left_join: com in assoc(cml, :company),

                                        #
                                      select: %{
                                        commanall_id: cml.id,
                                        id: a.id,
                                        status: a.status,
                                        title: emp.title,
                                        email_id: cml.email_id,
                                        first_name: emp.first_name,
                                        last_name: emp.last_name,
                                        company_name: com.company_name,
                                        company_id: com.id,
                                        employee_id: cml.employee_id
                                      })
                         |> Repo.paginate(params)
                         else
                          _s = (from a in Thirdpartylogs,
#                                                  left_join: cml in assoc(a, :commanall),
                                                  left_join: cml in Commanall,
                                                  on: a.commanall_id == cml.id,
                                                  where: like(cml.email_id, ^"%#{email_id}"),
                                                  left_join: emp in assoc(cml, :employee),
                                                  left_join: com in assoc(cml, :company),
                                                    #
                                                  select: %{
                                                    commanall_id: cml.id,
                                                    id: a.id,
                                                    status: a.status,
                                                    title: emp.title,
                                                    email_id: cml.email_id,
                                                    first_name: emp.first_name,
                                                    last_name: emp.last_name,
                                                    company_name: com.company_name,
                                                    company_id: com.id,
                                                    employee_id: cml.employee_id
                                                  })
                          |> Repo.paginate(params)
                           end
            end
  end


  def third_party_log_view(params)do
         _view =  Repo.all(from t in Thirdpartylogs,
#                          left_join: cml in Commanall,
#                          on: t.commanall_id == cml.id,
#                          left_join: emp in assoc(cml, :employee),
#                          left_join: com in assoc(cml, :company),
                           where: t.commanall_id ==  ^params["id"],
                      select: %{
                         id: t.id,
                         status: t.status,
                         section: t.section,
                         request: t.request,
                         response: t.response,
                         inserted_at: t.inserted_at})

  end
end
