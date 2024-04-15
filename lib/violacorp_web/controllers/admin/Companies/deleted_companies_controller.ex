defmodule ViolacorpWeb.Admin.Companies.DeletedCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Models.Companies.DeletedCompanies
#  alias Violacorp.Companies.ActiveCompanies
  @moduledoc false

  def deletedCompanyProfile(conn, params) do
    data =  DeletedCompanies.deletedCompanyProfile(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc" List of Deleted Companies"
  def deletedCompanies(conn, params) do
    data =  DeletedCompanies.deleted_companies(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def deletedCompanyOnlineAccount(conn, params) do
    data = DeletedCompanies.online_account(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyCardManagementAccount(conn, params) do
    data = DeletedCompanies.card_management_account(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyEmployeeCards(conn, params) do
    data = DeletedCompanies.employee_card(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyEmployeeList(conn, params) do
    data = DeletedCompanies.employee_details(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def deletedCompanyDirectorList(conn, params) do
    data = DeletedCompanies.director_details(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyKyb(conn, params) do
    data = DeletedCompanies.company_kyb(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyContactAddress(conn, params) do
    data = DeletedCompanies.company_address_contacts(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def deletedCompanyDescription(conn, params) do
    data = DeletedCompanies.company_description(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end
end
