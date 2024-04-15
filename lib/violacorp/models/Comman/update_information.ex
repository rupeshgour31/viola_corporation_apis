defmodule Violacorp.Models.Comman.UpdateInformation do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Contacts

#  alias Violacorp.Models.Comman

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools

  @doc """
    this function for update dob for both Active and Pending Employee
  """
  def updateEmployeeDob(params, admin_id)do
    commanall_id = params["commanall_id"]
    case checkEmployee(commanall_id) do
    {:ok,commanall, as_director, employee_info} ->
        dob = %{"date_of_birth" => params["date_of_birth"]}
        changeset_dob = Employee.changesetDob(employee_info, dob)
        if changeset_dob.valid? do
          response = case commanall.accomplish_userid do
                nil -> %{"status_code" => "200", "message" => "success"}
                accomplish_user_id ->
                date_of_birth = params["date_of_birth"]
                request_map = %{
                  "commanall_id" => params["commanall_id"],
                  "request_by" => "99999#{admin_id}",
                  "date_of_birth" => date_of_birth,
                }
                case updateDobOnThirdParty(accomplish_user_id, request_map) do
                {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                end
          end
          if response["status_code"] == "200" do
                case Repo.update(changeset_dob) do
                {:ok, _data} ->
                    if as_director == "Y" do
                        get_dir_dob = Repo.one(from cd in Directors, where: cd.id == ^employee_info.director_id, limit: 1, select: cd)
                        if !is_nil(get_dir_dob) do
                            dir_changeset = Directors.updateDob(get_dir_dob, %{date_of_birth: params["date_of_birth"]})
                            Repo.update(dir_changeset)
                        end
                    end
                    {:ok,"update"}
                {:errors, changeset} -> {:errors ,changeset}
                end
           else
            {:thirdparty_error_message, response["message"]}
          end
        else
          {:errors ,changeset_dob}
        end
     {:error_not_found, message} -> {:error_not_found, message}
    end
  end

  @doc """
    this function for update email  for  director
  """
   def editDirectorEmail(params,admin_id)do
      director_id = params["director_id"]
      case directorAsEmployee(director_id) do
         {:ok,director, as_employee, employee_info} ->
            email = %{"email_id" => params["email_id"]}
            changeset_email = Directors.update_director_email(director, email)
            if changeset_email.valid? do
               case Commontools.email_is_unique?(params["email_id"]) do
                 "Y" ->
                    response = case as_employee do
                                 "Y" ->
                                   commanall = Repo.one(from co in Commanall, where: co.employee_id == ^employee_info.id,limit: 1)
                                   case commanall.accomplish_userid do
                                     nil -> %{"status_code" => "200", "message" => "success"}
                                     accomplish_user_id ->
                                       verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "1"
                                       request_map = %{
                                         "commanall_id" => commanall.id,
                                         "request_by" => "99999#{admin_id}",
                                         "email_address" => params["email_id"],
                                         "verify_status" => verify_status
                                       }

                                       case updateEmailOnThirdParty(accomplish_user_id, request_map) do
                                         {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                                         {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                                       end
                                   end
                                 "N" -> %{"status_code" => "200", "message" => "success"}
                               end

                   if response["status_code"] == "200" do
                     case Repo.update(changeset_email) do
                       {:ok, _data} ->
#
                          if as_employee == "Y" do
                            commanall = Repo.one(from co in Commanall, where: co.employee_id == ^employee_info.id,limit: 1)
                            changeset_employee = Commanall.changesetEmailUpdate(commanall, email)
                            Repo.update(changeset_employee)
                          else
                            ## check if director have main owner
                            main_director = Repo.one(from co in Commanall, where: co.email_id == ^director.email_id, limit: 1)
                            if !is_nil(main_director) do
                              changeset_employee = Commanall.changesetEmailUpdate(main_director, email)
                              Repo.update(changeset_employee)
                            end
                          end
                          get_dir_email = Repo.one(from kd in Kyclogin, where: kd.directors_id == ^director_id, limit: 1, select: kd)
                          if !is_nil(get_dir_email) do
                             kyc_login = Kyclogin.updateEmailID(get_dir_email, %{"username" => params["email_id"]})
                             Repo.update(kyc_login)
                          end
                         {:ok,"email updated"}
                       {:errors, changeset} -> {:errors ,changeset}
                     end
                   else
                     {:thirdparty_error_message, response["message"]}
                   end
                 "N" ->
                   {:email_existing, "already exist"}
               end
              else
              {:errors, changeset_email}
            end
         {:error_not_found, message} -> {:error_not_found, message}
      end
  end

  @doc """
    this function for update contact  for  director
  """
  def editDirectorContact(params,admin_id)do
    director_id = params["director_id"]
    case  directorAsEmployee(director_id) do
      {:ok, director, as_employee, employee_info} ->

          get_dir_contact = Repo.one(from cd in Contactsdirectors, where: cd.directors_id == ^director_id, limit: 1, select: cd)
          if !is_nil(get_dir_contact) do
             contact = %{
               "contact_number" => params["contact_number"]
             }
             changeset_contact = Contactsdirectors.changeset_number(get_dir_contact, %{contact_number: params["contact_number"]})
             if changeset_contact.valid? do
               case Commontools.contact_is_unique?(params["contact_number"]) do
                 "Y" ->
                   response = case as_employee do
                     "Y" ->
                       commanall = Repo.one(from co in Commanall, where: co.employee_id == ^employee_info.id, limit: 1)
                       case commanall.accomplish_userid do
                         nil -> %{"status_code" => "200", "message" => "success"}
                         accomplish_user_id ->
                           number = "+#{get_dir_contact.code}#{params["contact_number"]}"
                           verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "0"
                           request_map = %{
                             "commanall_id" => commanall.id,
                             "request_by" => "99999#{admin_id}",
                             "mobile_number" => number,
                             "verify_status" => verify_status
                           }
                           case updateContactOnThirdParty(accomplish_user_id, request_map) do
                             {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                             {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                           end
                       end
                     "N" -> %{"status_code" => "200", "message" => "success"}
                   end

                   if response["status_code"] == "200" do
                       case Repo.update(changeset_contact) do
                         {:ok, _data} ->
                           if as_employee == "Y" do
                             commanall = Repo.one(from co in Commanall, where: co.employee_id == ^employee_info.id, limit: 1)
                             get_contact = Repo.one(from c in Contacts, where: c.commanall_id == ^commanall.id, limit: 1, select: c)
                             changeset_econtact = Contacts.changeset_number(get_contact, contact)
                             Repo.update(changeset_econtact)
                           else
                              ## check if director have main
                             commanall = Repo.one(from co in Commanall, where: co.email_id == ^director.email_id, limit: 1)
                             if !is_nil(commanall) do
                               get_contact = Repo.one(from c in Contacts, where: c.commanall_id == ^commanall.id, limit: 1, select: c)
                               if !is_nil(get_contact) do
                                 changeset_econtact = Contacts.changeset_number(get_contact, contact)
                                 Repo.update(changeset_econtact)
                               end
                             end
                           end
                           {:ok,"success! update contact."}
                         {:errors, changeset} -> {:errors ,changeset}
                       end
                    else
                     {:thirdparty_error_message, response["message"]}
                   end
                 "N" ->
                   {:contact_existing, "already exist"}
               end
              else
               {:errors ,changeset_contact}
             end
          else
            {:error_not_found, "director contact not found"}
          end
      {:error_not_found, message} -> {:error_not_found, message}
    end
  end
  @doc """
    this function for update director  for  director
  """
  def editDirectorDob(params,admin_id) do
    director_id = params["director_id"]
    case  directorAsEmployee(director_id) do
      {:ok, director, as_employee, employee_info} ->
         dob = %{"date_of_birth" => params["date_of_birth"]}
         changeset_dob = Directors.updateDob(director, dob)
         if changeset_dob.valid? do
           response = case as_employee do
                       "Y" ->
                         commanall = Repo.one(from co in Commanall, where: co.employee_id == ^employee_info.id, limit: 1)
                         case commanall.accomplish_userid do
                           nil -> %{"status_code" => "200", "message" => "success"}
                           accomplish_user_id ->
                             date_of_birth = params["date_of_birth"]
                             request_map = %{
                               "commanall_id" => commanall.id,
                               "request_by" => "99999#{admin_id}",
                               "date_of_birth" => date_of_birth,
                             }
                             case updateDobOnThirdParty(accomplish_user_id, request_map) do
                               {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                               {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                             end
                         end
                       "N" -> %{"status_code" => "200", "message" => "success"}
                     end

           if response["status_code"] == "200" do
             case Repo.update(changeset_dob) do
               {:ok, _data} ->
                  if as_employee == "Y" do
                    dir_changeset = Employee.changesetDob(employee_info, dob)
                    Repo.update(dir_changeset)
                  end
                 {:ok,"Date of birth updated"}
               {:errors, changeset} -> {:errors ,changeset}
             end
           else
             {:thirdparty_error_message, response["message"]}
           end
         else
           {:errors , changeset_dob}
         end
      {:error_not_found, message} -> {:error_not_found, message}
     end
  end


   ## get employee information ##
  defp checkEmployee(commanall_id) do
    case Repo.one(from ca in Commanall, where: ca.id == ^commanall_id and not is_nil(ca.employee_id), select: ca) do
      nil -> {:error_not_found, "employee not found."}
      employee ->
        employee_info = Repo.one(from em in Employee, where: em.id == ^employee.employee_id, select: em)
        as_director = if !is_nil(employee_info.director_id), do: "Y", else: "N"
        {:ok, employee, as_director, employee_info}
    end
  end


  ## get director as employee information ##
  defp directorAsEmployee(director_id) do
    case  Repo.one(from em in Directors, where: em.id == ^director_id, select: em) do
      nil -> {:error_not_found, "director  not found."}
      director ->
        employee_info = Repo.one(from ca in Employee, where: ca.director_id == ^director_id, select: ca)
        as_employee = if !is_nil(employee_info), do: "Y", else: "N"
        {:ok, director, as_employee, employee_info}
    end
  end


  ## Update director email_id On Third Party ##
  defp updateEmailOnThirdParty(accomplish_user_id, request) do
    case getAccomplishUserInfo(accomplish_user_id) do
      {:ok, get_details} ->
        email_id = get_in(get_details["email"], [Access.at(0), "id"])
        request_map = %{
          common_id: request["commanall_id"],
          request_by: request["request_by"],
          urlid: accomplish_user_id,
          email_address: request["email_address"],
          verify_status: request["verify_status"],
          id: email_id
        }

        response = Accomplish.change_email(request_map)
        if response["result"]["code"] == "0000", do: {:ok, "success"}, else: {:thirdparty_error_message, response["result"]["friendly_message"]}
      {:thirdparty_error_message, result_message} -> {:thirdparty_error_message, result_message}
    end
  end
  ## Update director contact On Third Party ##
  defp updateContactOnThirdParty(accomplish_user_id, request) do
    case getAccomplishUserInfo(accomplish_user_id) do
      {:ok, get_details} ->
        mobile_id = get_in(get_details["phone"], [Access.at(0), "id"])

        request_map = %{
          common_id: request["commanall_id"],
          request_by: request["request_by"],
          urlid: accomplish_user_id,
          mobile_number: request["mobile_number"],
          verify_status: request["verify_status"],
          id: mobile_id
        }

        response = Accomplish.change_mobile(request_map)
        if response["result"]["code"] == "0000", do: {:ok, "success"}, else: {:thirdparty_error_message, response["result"]["friendly_message"]}
      {:thirdparty_error_message, result_message} -> {:thirdparty_error_message, result_message}
    end
  end
  ## Update employee Date of birth On Third Party ##
  defp updateDobOnThirdParty(accomplish_user_id, request) do
    case getAccomplishUserInfo(accomplish_user_id) do
      {:ok, _get_details} ->
        request_map = %{
          common_id: request["commanall_id"],
          request_by: request["request_by"],
          urlid: accomplish_user_id,
          date_of_birth: request["date_of_birth"],
        }
        response = Accomplish.change_Dob(request_map)
        if response["result"]["code"] == "0000", do: {:ok, "success"}, else: {:thirdparty_error_message, response["result"]["friendly_message"]}
      {:thirdparty_error_message, result_message} -> {:thirdparty_error_message, result_message}
    end
  end

  ## this function for get user info from third party ##
  defp getAccomplishUserInfo(user_id) do
    get_details = Accomplish.get_user(user_id)
    result_code = get_details["result"]["code"]
    result_message = get_details["result"]["friendly_message"]
    if result_code == "0000" do
      {:ok, get_details}
    else
      {:thirdparty_error_message, result_message}
    end
  end
end
