defmodule ViolacorpWeb.Admin.Employee.ArchivedController do
  use Phoenix.Controller

  alias  Violacorp.Models.Employee
  alias  Violacorp.Models.Comman


  @doc "get all archived user"
  def getAll_archivedUser(conn, params)do

        data = Employee.archived_employee(params)
              json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
              data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end


  @doc "archived user profile "
  def archived_user_profile(conn, params)do
            data = Employee.archive_user_profile(params)
            case data do
                [] -> json conn, %{status_code: "4003", msg: "no  record found"}
                data ->
               json conn, %{status_code: "200", data: data}
            end
  end

  @doc "archived user profile "
  def archived_user_profile_view(conn, params)do
            data = Employee.archive_user_profile_view(params)
            case data do
                nil -> json conn, %{status_code: "4003", msg: "no  record found"}
                data ->
               json conn, %{status_code: "200", data: data}
            end
  end

  @doc"Delete Company"
  def deleteArchivedUser(conn, params) do
    %{"id" => admin_id,"type" => _type} = conn.assigns[:current_user]

    data =  Comman.checkOwnPassword(params, admin_id)

    if !is_nil(data) do
      result = Employee.deleteuser(params)
      case result do
        {:ok, _response} -> json conn, %{status_code: "200", message: "Success, User Deleted."}
        {:not_found, error_message} -> json conn, %{status_code: "4004", errors: %{message: error_message}}
      end
    else
      json conn,%{status_code: "4004", errors: %{message: "Password Does not Matched"}}
    end
  end


end
