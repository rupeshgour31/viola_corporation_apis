defmodule  ViolacorpWeb.Test.TestController do
  use Phoenix.Controller
  #  import Ecto.Query

  #  alias Violacorp.Repo
  #  alias Violacorp.Schemas.Commanall

  alias  Violacorp.Test.TestModel


  @doc "get all daseboard counts"
  def getall_act_ped_company_daseboard_v1(conn, params)do
    data = TestModel.active_pending_com_count(params)
    case data do
      {} -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "get all active user"
  def getAll_active_User_v1(conn, params)do

    data = TestModel.getAllActiveEmployeeV1(params)
    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
      data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc" List of Pending Companies"
  def pendingCompanies_v1(conn, params) do
    data =  TestModel.pending_companies_v1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc "get all money request "
  def getAllMoneyRequest_v1(conn, params) do
    data = TestModel.money_request_v1(params)
    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
      data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc""
  def recentMails_v1(conn, params) do
    data =  TestModel.recent_mails_v1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end
  @doc""
  def applicationVersion_v1(conn, params) do
    data = TestModel.application_version_v1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end






end