defmodule ViolacorpWeb.Admin.Employee.DeleteduserController do
  use Phoenix.Controller

  alias  Violacorp.Models.Employee

  @doc "get all Deleted User"
  def getAll_deleted_user(conn, params)do
        data = Employee.deleted_User(params)
            json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
              data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc "deleted user profile"
  def deleted_user_profile_detail(conn, params)do
        data = Employee.deleted__user_profile(params)
        case data do
         nil -> json conn, %{status_code: "4004", msg: "no record found"}
            data ->
            json conn, %{status_code: "200", data: data}
        end
  end

  @doc "deleted user cards"
  def  delted_user_cards_detail(conn, params)do

        data = Employee.deleted_user_cards(params)
        case data do
            [] -> json conn, %{status_code: "4004", msg: "no record  found"}
            data ->
            json conn, %{status_code: "200", data: data}
        end
  end

  @doc "deleted user kyc"
  def  delted_user_kyc_detail(conn, params)do

      data = Employee.deleted_user_kyc(params)
      case data do
          [] -> json conn, %{status_code: "4004", msg: "no record  found"}
          data ->
          json conn, %{status_code: "200", data: data}
      end
  end

  @doc "deleted user address"
  def  deleted_user_address_detail(conn, params)do

        data = Employee.deleted_user_address(params)
        case data do
            nil -> json conn, %{status_code: "4004", msg: "no record  found"}
            data ->
            json conn, %{status_code: "200", data: data}
        end
  end

#  @doc "deleted user address"
#  def  deleted_user_address_detail(conn, params)do
#
#        data = Employee.deleted_user_address(params)
#        case data do
#            [] -> json conn, %{status_code: "4003", msg: "no  record   found"}
#            data ->
#            json conn, %{status_code: "200", data: data}
#        end
#  end

  @doc "deleted user contacts"
  def  deleted_user_contact_detail(conn, params)do

    data = Employee.deleted_user_contacts(params)
    case data do
      [] -> json conn, %{status_code: "4004", msg: "no record found"}
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end


  @doc "deleted user notes/comments"
  def deletd_user_notes_detail(conn, params)do
    data = Employee.deleted_user_notes(params)
    case data do
      [] -> json conn, %{status_code: "4004", msg: "no record found"}
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end




end
