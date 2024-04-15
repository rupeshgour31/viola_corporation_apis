defmodule ViolacorpWeb.Admin.Companies.PendingCompaniesController do
  use Phoenix.Controller

  alias Violacorp.Models.Companies.PendingCompanies
  alias Violacorp.Models.Comman
#  alias ViolacorpWeb.ErrorView
  @moduledoc false
@doc""

  def getSingleShareholderInfo(conn, params)do
    case PendingCompanies.getSingleShareholderInfo(params) do
      [] -> json conn, %{status_code: "4004", error: "Record Not Found"}
      data -> json conn,  %{status_code: "200", data: data}
    end
  end

  @doc""

  def getShareHolderKyc(conn, params)do

    case PendingCompanies.getShareHolderKyc(params) do
      [] -> json conn, %{status_code: "4004", error: "Record Not Found"}
      data -> json conn,  %{status_code: "200", data: data}
    end

  end

  @doc"add director"
  def addDirectorForCompany(conn, params)do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case PendingCompanies.addDirectorForCompany(params, admin_id)do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:exist_contact, message} -> json conn, %{status_code: "4003", errors: %{contact_number: message}}
      {:exist_email, message} -> json conn, %{status_code: "4003", errors: %{email_id: message}}
      {:position_message, message} -> json conn, %{status_code: "4003", errors: %{position: message}}
      {:error, message} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: message)
    end
  end

  @doc""
  def uploadEmployeeAddress(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case PendingCompanies.employeeKycDocumentUploadAddress(params, admin_id)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc""
  def employeeKycDocumentUploadID(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case PendingCompanies.employeeKycDocumentUploadID(params, admin_id)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc"shareholder kyc document upload"
  def shareholderKycDocumentUpload(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case PendingCompanies.shareholderKycDocumentUpload(params, admin_id)do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc""
  def directorKycDocumentUpload(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
   case PendingCompanies.directorKycDocumentUpload(params, admin_id)do
             {:ok, message} ->
               conn
               |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
             {:error, changeset} ->
               conn
               |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
               {:error_message, message} ->
               json conn, %{status_code: "4004", message: message}
             {:errors, response} -> json conn, %{status_code: "4003", errors: response}
    end
  end

  @doc""
  def companyKybDocumentTypeList(conn, params) do
   {status, data} = PendingCompanies.companyKybDocumentTypeList(params)
   case status do
     :ok -> json conn, %{status_code: "200", data: data}
     :error -> json conn, %{status_code: "4004", error: data}
   end
  end

  @doc""
  def companyKybDocumentUpload(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
      case PendingCompanies.companyKybDocumentUpload(params, admin_id)do
        {:ok, message} -> json conn, %{status_code: "200", message: message}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:exists, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
        {:errors, response} -> json conn, %{status_code: "4003", errors: response}
      end
  end

  @doc""
  def companyActivationOpinionAdd(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    case PendingCompanies.companyActivationOpinionAdd(params, admin_id) do
      {:ok, message} ->
        json conn, %{status_code: "200", message: message}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc" Pending Company Checklist"
  def pendingCompanyCheckList(conn, params) do
    {status, data} = PendingCompanies.pendingCompanyCheckList(params)
    case status do
      :ok -> json conn, %{status_code: "200", data: data}
      :error -> json conn, %{status_code: "4004", error: data}
    end
  end

  @doc" Add Company Document info"
  def pendingCompanyAskMoreDetails(conn, params) do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    if type == "A" do
      {status, message} = PendingCompanies.pendingCompanyAskMoreDetails(params, admin_id)
      case status do
        :ok -> json conn, %{status_code: "200", message: message}
        :error -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: message)
      end
    else
      json conn, %{status_code: "400", message: "Administrator Permission Required"}
    end
  end

  @doc" List of Pending Companies"
  def pendingCompanies(conn, params) do
    data =  PendingCompanies.pending_companies(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def pendingCompanyProfile(conn, params) do

    data =  PendingCompanies.pending_getOne_company(params)
    case data do
    nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end
  end


  def getPendingCompnayAddress(conn, params)do
    company_address = PendingCompanies.getCompanyAddress(params)
    case company_address do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: company_address, }
    end
  end

  def get_cap_kyc_company(conn, params) do

    data =  PendingCompanies.get_cap_kyc_company(params)
    case  data do
      []->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200", data: data}
    end

  end

  def get_directors_kyc_company(conn, params) do

    data =  PendingCompanies.get_directors_kyc_company(params)

    case  data do
      []->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200",data: data}
    end

  end

#  def get_all_directors_for_company(conn, params) do
#
#    data =  PendingCompanies.get_all_directors_for_company(params)
#    case  data do
#      []->
#        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
#      _data ->
#        json conn, %{status_code: "200", data: data}
#    end
#
#  end



  def get_kyc_one_company(conn, params) do

    data =  PendingCompanies.get_kyc_one_company(params)
    case  data do
      []->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      _data ->
        json conn, %{status_code: "200", data: data}
    end

  end

  def insertShareHolder(conn, params)do
     %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
     request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
     if type == "A"  do
         data = PendingCompanies.addShareHolder(request)
          case data do
              {:ok, message} ->
              conn
              |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
              {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
           else
           json conn,
                %{
                  status_code: "4002",
                  errors: %{
                    message: "Update Permission Required, Please Contact Administrator."
                  }
                }
     end
  end

  @doc"remove pending company"
  def removePendingCompany(conn,params)do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    if type == "A" do

      check_password = Comman.checkOwnPassword(params, admin_id)
      if !is_nil(check_password) do
        data = PendingCompanies.remove_pending_company(params,admin_id)
        case data do
          {:ok, message} ->
            conn
            |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
          {:error_message, message} ->
            json conn, %{status_code: "4004", errors: %{message: message}}
        end
      else
        json conn,%{status_code: "4003", errors: %{message: "Password Does not Matched"}}
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end

  @doc"view company details"
  def getCompanyKycDetails(conn, params) do

    data = PendingCompanies.getCompanyKycDetails(params)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", data: data}
     {:not_found, data} -> json conn, %{status_code: "4004", data: data}
    end
  end

  @doc"add director address"
  def addDirectorAddress(conn, params) do
    %{"id" => admin_id, "type" => _type} = conn.assigns[:current_user]
    data = PendingCompanies.addDirectorAddress(params, admin_id)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"edit director address"
  def editDirectorAddress(conn, params) do

    data = PendingCompanies.editDirectorAddress(params)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"add director dob"
  def addDirectorDob(conn, params) do

    data = PendingCompanies.addDirectorDob(params)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"edit director email"
  def editDirectorEmail(conn, params) do

    result = PendingCompanies.editDirectorEmail(params)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  @doc"edit director contact"
  def editDirectorContact(conn, params) do

    result = PendingCompanies.editDirectorContact(params)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  def addDirectorContact(conn, params) do
    %{"id" => admin_id, "type" => _type} = conn.assigns[:current_user]

    result = PendingCompanies.addDirectorContact(params, admin_id)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  @doc"delete pending director"
  def deletePendingDirector(conn, params) do
    %{"id" => admin_id, "type" => _type} = conn.assigns[:current_user]

    check_password = Comman.checkOwnPassword(params, admin_id)
    if !is_nil(check_password) do
      result = PendingCompanies.deletePendingDirector(params)
      case result do
        {:ok, success} -> json conn, %{status_code: "200", message: success}
        {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      end
    else
      json conn,%{status_code: "4003", errors: %{password: "Password Does not Matched"}}
    end
  end

  @doc"delete primary director"
  def deletePrimaryDirector(conn, params) do
    %{"id" => admin_id, "type" => _type} = conn.assigns[:current_user]

    check_password = Comman.checkOwnPassword(params, admin_id)
    if !is_nil(check_password) do
      result = PendingCompanies.deletePrimaryDirector(params)
      case result do
        {:ok, success} -> json conn, %{status_code: "200", message: success}
        {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      end
    else
      json conn,%{status_code: "4003", errors: %{password: "Password Does not Matched"}}
    end
  end

  @doc"add company address"
  def addCompanyAddress(conn, params) do
    %{"id" => admin_id, "type" => _type} = conn.assigns[:current_user]

    data = PendingCompanies.addCompanyAddress(params, admin_id)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"edit company address"
  def editCompanyAddress(conn, params) do

    data = PendingCompanies.editCompanyAddress(params)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"edit registration number"
  def editRegistrationNumber(conn, params) do

    data = PendingCompanies.editRegistrationNumber(params)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
  end

  @doc"add company email"
  def addCompanyEmail(conn, params) do

    result = PendingCompanies.addCompanyEmail(params)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  @doc" this function for edit company email"
  def editCompanyEmail(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Comman.editCompanyEmail(params, admin_id) do
      {:ok, _data} -> json conn, %{status_code: "200", message: "Email Updated"}
      {:errors, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:email_existing, message} -> json(conn,%{status_code: "4003", errors: %{email_id: message}})
    end
  end

  @doc" this function for edit company contact"
  def editCompanyContact(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Comman.editCompanyContact(params, admin_id) do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:errors, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:contact_existing, message} -> json(conn,%{status_code: "4003", errors: %{contact_number: message}})
    end
  end

  @doc"director kyc override"
  def directorKycOverride(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    result = PendingCompanies.directorKycOverride(params, admin_id)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  def registrationStepsArray(conn, params)do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A" do
          data = PendingCompanies.registration_steps_array(params)
          case data do
            {:ok, data} -> json conn, %{status_code: "200", data: data}
            {:not_found, _data} -> json conn, %{status_code: "4004", errrors: %{message: "No record found"}}
          end
     else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end

  def editregistrationStepsArray(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A" do
    result = PendingCompanies.edit_registration_step(params)
    case result do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
    end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
end

end
