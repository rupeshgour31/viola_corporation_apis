defmodule ViolacorpWeb.Admin.Companies.UnderReviewCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Companies.UnderReviewCompanies
  @moduledoc false

  @doc" List of Under Review Companies"
  def underReviewCompanies(conn, params) do
    data =  UnderReviewCompanies.underReviewCompaniesV1(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def showCompany_profile(conn, params) do

    data =  UnderReviewCompanies.reviewProfile(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end
  @doc""

  def underReviewCompanyProfile(conn, params) do
    data =  UnderReviewCompanies.underReviewCompanyProfile(params)
    case data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end
  @doc""

  def underReviewCompanyOnlineAccount(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyOnlineAccount(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc""

  def underReviewCompanyCardManagementAccount(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyCardManagementAccount(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end
  @doc""

  def underReviewCompanyEmployeeCards(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyEmployeeCards(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end
  @doc""

  def underReviewCompanyEmployeeList(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyEmployeeList(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc""

  def underReviewCompanyDirectorList(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyDirectorList(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc""

  def underReviewCompanyKyb(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyKyb(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end

  @doc""

  def underReviewCompanyContactAddress(conn, params) do
    primary = UnderReviewCompanies.underReviewCompanyContactAddress(params)
    secondary = UnderReviewCompanies.underReviewCompanyContactAddressSecondary(params)
    contact_p = UnderReviewCompanies.underReviewCompanyContactNumber(params)
    contact_s = UnderReviewCompanies.underReviewCompanyContactNumberSecondary(params)
    case primary do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _primary ->
        json conn, %{status_code: "200",primary_address: primary, secondary_address: secondary, primary_contact: contact_p, secondary_contact: contact_s}
    end
  end

  @doc""

  def underReviewCompanyDescription(conn, params) do
    data = UnderReviewCompanies.underReviewCompanyDescription(params)
    case data do
      [] ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end


end
