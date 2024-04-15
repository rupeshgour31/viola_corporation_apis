defmodule Violacorp.Settings.ProjectsSetting do

  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Projects
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Assignproject
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall


  @moduledoc false


  @doc "Settings Projects List"

  def projects_list(params) do
    _filtered = params
               |> Map.take(~w(project_name, start_date))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

             project_name = params["project_name"]
             start_date = params["start_date"]
           card = (from a in Projects,
                  where: like(a.project_name, ^"%#{project_name}%") and like(a.start_date, ^"%#{start_date}%"),
                   join: c in Company,
                   on: c.id == a.company_id,
                  select: %{
                    id: a.id,
                    company_id: a.company_id,
                    company_name: c.company_name,
                    project_name: a.project_name,
                    start_date: a.start_date,
                    inserted_at: a.inserted_at
                  })
            |> order_by(desc: :id)
            |> Repo.paginate(params)
    map_data =  Enum.map(card, fn q ->
                                 get = Repo.all(from e in Assignproject,where: e.projects_id == ^q.id,
                                                select: count(e.projects_id))
                                     count = List.first(get)
                                      %{
                                         company_id: q.company_id,
                                         project_name: q.project_name,
                                         company_name: q.company_name,
                                         start_date: q.start_date,
                                         inserted_at: q.inserted_at,
                                         count: count,
                                         id: q.id
                                      }
           end)
    %{entries: map_data, page_number: card.page_number,total_entries: card.total_entries, page_size: card.page_size,  total_pages: card.total_pages}
  end


  def projects_assign_list(params) do
      get =  (from e in Assignproject,where: e.projects_id == ^params["projects_id"],
                     join: emp in Employee,
                     on: emp.id == e.employee_id,
                     select: %{
                      employee_id: e.employee_id,
                      first_name: emp.first_name,
                      last_name: emp.last_name,
                      })
                      |> Repo.all
          Enum.map get, fn x ->
            username = "#{x.first_name} #{x.last_name}"
            %{
              username: username,
              employee_id: x.employee_id
            }
          end
  end


  def company_employee_projectlist(params) do
    get =  (from e in Employee,where: e.company_id == ^params["company_id"] and e.status == ^"A",
                                    select: %{
                                      employee_id: e.id,
                                      first_name: e.first_name,
                                      last_name: e.last_name,
                                      company_id: e.company_id
                                    })
           |> Repo.all
                Enum.map get, fn x ->
                username = "#{x.first_name} #{x.last_name}"
                %{
                  username: username,
                  employee_id: x.employee_id,
                  company_id: x.company_id,
                }
                end
    end

  def getActiveCompanyList(_params) do
    _companies = (from c in Commanall, where: not is_nil(c.company_id) and not is_nil(c.accomplish_userid) and c.status == "A",
    left_join: a in assoc(c, :company),
                                         select: %{
                                         company_id: c.company_id,
                                         name: a.company_name
                                         })
    |> Repo.all
  end

  def getActiveUserList(_params) do
   _employee = (from c in Commanall, where: not is_nil(c.employee_id) and not is_nil(c.accomplish_userid) and c.status == "A",
         left_join: e in assoc(c, :employee),
                                select: %{
                                employee_id: e.id,
                                company_id: e.company_id,
                                first_name: e.first_name,
                                last_name: e.last_name
                                })
    |> Repo.all
  end

  def assign_project(params) do
     employee_id = params["employee_id"]
     projects_id = params["projects_id"]
     if employee_id != [] and !is_nil(employee_id) do
            delete = Repo.all(from as in Assignproject, where: as.projects_id == ^projects_id, select: as)
            if delete != [] do
              from(comm in Assignproject, where: comm.projects_id == ^projects_id)
              |> Repo.delete_all
            end
          Enum.each employee_id , fn x ->

                insert = %{ "employee_id" => x, "projects_id" =>  projects_id,"inserted_by" => params["inserted_by"] }
                changeset = Assignproject.changeset(%Assignproject{},insert)
                Repo.insert(changeset)
            end
            {:ok,"Successfully, Assign project"}
          else
            {:employee_error, "Can't be blank"}
     end
  end
end
