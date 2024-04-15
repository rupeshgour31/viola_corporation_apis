defmodule ViolacorpWeb.Admin.Companies.SuspendedCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Models.Companies.SuspendedCompanies
  @moduledoc false


  @doc" List of Suspended Companies"
  def suspendedCompanies(conn, params) do
    data =  SuspendedCompanies.suspendedCompaniesV1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def suspendedCompanyonlineAccount(conn, params) do
    data = SuspendedCompanies.online_account(params)
    case data do
    nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc" Model Of Get Card Management Account"

  def suspendedCompanyCardManagementAccount(conn, params) do
    data = SuspendedCompanies.card_management_account(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def suspendedCompanyEmployeeList(conn, params) do
    data = SuspendedCompanies.employee_details(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end
  def suspendedCompanydirectorDetails(conn, params) do
    data = SuspendedCompanies.director_details(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end

    end

    def suspendedCompanyContactAddress(conn, params) do
      data = SuspendedCompanies.company_address_contacts(params)
      case data do
        nil ->
          json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
        _data ->
          json conn, %{status_code: "200",data: data}
      end
    end



  def suspendedCompanyDescription(conn, params) do
    data = SuspendedCompanies.company_description(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end


  def suspendedCompanyEmployeeCards(conn, params) do
    data = SuspendedCompanies.employee_card(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def suspendedCompanyKyb(conn, params) do
    data = SuspendedCompanies.company_kyb(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def suspendedcompanyProfile(conn, params) do

    data = SuspendedCompanies.company_info(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end
end
