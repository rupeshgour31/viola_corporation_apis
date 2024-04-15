defmodule ViolacorpWeb.Admin.Settings.ProjectsController do

  use Phoenix.Controller
 alias Violacorp.Settings.ProjectsSetting
  @moduledoc false

  @doc "Settings Projects  List"

  def projectsList(conn, params) do
    data = ProjectsSetting.projects_list(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def assignProject(conn,params) do
    %{"type" => type, "id" => admin_id} = conn.assigns[:current_user]
    request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
    if type == "A"  do
       data = ProjectsSetting.assign_project(request)
        case data do
          {:ok, message} -> json conn, %{status_code: "200", message: message}
          {:error, changeset}->
            conn
            |>put_view(ErrorView)
            |>render("error.json", changeset: changeset)
          {:employee_error, message}-> json conn, %{status_code: "4003",errors: %{employee_id: message}}
        end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def projectsAssignList(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
          case  ProjectsSetting.projects_assign_list(params) do
            []->
              json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
            data ->
              json conn, %{status_code: "200", data: data}
         end
     else
     json conn, %{status_code: "4002", errors: %{
      message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def companyEmployeeProjectlist(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      case  ProjectsSetting.company_employee_projectlist(params) do
        []->
          json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
        data ->
          json conn, %{status_code: "200", data: data}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def getActiveCompanyList(conn, params) do
    data = ProjectsSetting.getActiveCompanyList(params)
    case  data do
      []->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200", data: data}
    end
  end


  def getActiveUserList(conn, params) do
    data = ProjectsSetting.getActiveUserList(params)
    case  data do
      []->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200", data: data}
    end
  end

end
