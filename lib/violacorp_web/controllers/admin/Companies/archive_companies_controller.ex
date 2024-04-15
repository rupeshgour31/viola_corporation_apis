defmodule ViolacorpWeb.Admin.Companies.ArchiveCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Models.Companies.ArchiveCompanies
  alias Violacorp.Models.Comman
  @moduledoc false

  @doc" List of Archived Companies"
  def archivedCompanies(conn, params) do
    data =  ArchiveCompanies.archivedCompaniesV1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def archivedCompanyProfile(conn, params) do
    data =  ArchiveCompanies.archivedCompanyProfile(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyOnlineAccount(conn, params) do
    data = ArchiveCompanies.archivedCompanyOnlineAccount(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyCardManagementAccount(conn, params) do
    data = ArchiveCompanies.archivedCompanyCardManagementAccount(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyEmployeeCards(conn, params) do
    data = ArchiveCompanies.archivedCompanyEmployeeCards(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyEmployeeList(conn, params) do
    data = ArchiveCompanies.archivedCompanyEmployeeList(params)
    case data.entries do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
    end
  end

  def archivedCompanyDirectorList(conn, params) do
    data = ArchiveCompanies.archivedCompanyDirectorList(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyKyb(conn, params) do
    data = ArchiveCompanies.archivedCompanyKyb(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyContactAddress(conn, params) do
    data = ArchiveCompanies.archivedCompanyContactAddress(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  def archivedCompanyDescription(conn, params) do
    data = ArchiveCompanies.archivedCompanyDescription(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc"Delete Company"
  def deleteArchivedCompany(conn, params) do
    %{"id" => admin_id,"type" => _type} = conn.assigns[:current_user]

    data =  Comman.checkOwnPassword(params, admin_id)

    if !is_nil(data) do
        result = ArchiveCompanies.deleteCompany(params)
        case result do
          {:ok, _response} -> json conn, %{status_code: "200", message: "Company Deleted"}
          {:not_found, error_message} -> json conn, %{status_code: "4004", errors: %{message: error_message}}
        end
    else
      json conn,%{status_code: "4004", errors: %{message: "Password Does not Matched"}}
    end
  end

  @doc """
    list of companies account and employees card
  """
  def getallCompaniesAccountCards(conn, params) do
    result = ArchiveCompanies.getallCompaniesAccountCards(params)
    json conn, %{status_code: "200", data: result}
  end


end
