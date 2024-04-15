defmodule ViolacorpWeb.Admin.Companies.ClosedCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Companies.ClosedCompanies
#  alias Violacorp.Companies.ActiveCompanies


  @moduledoc false

  def closedCompanyProfile(conn, params) do
    data =  ClosedCompanies.closedCompanyProfile(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end


  @doc" List of Closed Companies"
  def closedCompanies(conn, params) do
    data =  ClosedCompanies.closedCompaniesV1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def closedCompanyOnlineAccount(conn, params) do
    data = ClosedCompanies.online_bank_account(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyCardManagementAccount(conn, params) do
    data = ClosedCompanies.card_management_account(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyEmployeeCards(conn, params) do
    data = ClosedCompanies.employee_card(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyEmployeeList(conn, params) do
    data = ClosedCompanies.employee_details(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def closedCompanyDirectorList(conn, params) do
    data = ClosedCompanies.director_details(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyKyb(conn, params) do
    data = ClosedCompanies.company_kyb(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyContactAddress(conn, params) do
    data = ClosedCompanies.company_address_contacts(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def closedCompanyDescription(conn, params) do
    data = ClosedCompanies.company_description(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end


end
