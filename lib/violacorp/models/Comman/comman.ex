defmodule Violacorp.Models.Comman do
  import Ecto.Query


  alias Violacorp.Repo
  alias Violacorp.Schemas.Intilaze
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Documenttype
#  alias Violacorp.Schemas.Documentcategory
  alias Violacorp.Schemas.Resendmailhistory
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Tags
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Commankyccomments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Kyccomments
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kyclogin

  alias  ViolacorpWeb.Main.V2AlertsController
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools

  @doc""
  def deleteEmployeeKyc(params, admin_id)do

    #CHECK IF SECRET PASSWORD IS CORRECT FOR CURRENT USER
    authorisation = checkOwnPassword(params, admin_id)
    case authorisation do
      #------------------------------------
      #IF SECRET PASSWORD IS NOT CORRECT DO THIS
      nil ->  {:incorrect_password, "Admin Secret Password is Incorrect"}
      #IF SECRET PASSWORD IS CORRECT DO THIS
      _ ->
        record = Repo.one(from k in Kycdocuments, where: k.id == ^params["kyc_id"] and is_nil(k.fourstop_response))
        #IF KYC RECORD HAS BEEN FOUND THEN DO THIS
        if !is_nil(record) do

          kycdocuments_id = record.id
          kyc_data = Repo.all(from c in Commankyccomments, where: c.kycdocuments_id ==  ^kycdocuments_id)

          if kyc_data != [] do
            (from c in Commankyccomments, where: c.kycdocuments_id ==  ^kycdocuments_id)
            |> Repo.delete_all
          end
          case Repo.delete(record) do
            {:ok, _data} -> {:ok, "Employee KYC record has been deleted"}
            {:error, data} -> {:error, data}
          end
        else
          #IF KYC RECORD WAS NOT FOUND THEN DO THIS
          {:error, "KYC can't be deleted"}
        end
    end
  end
  @doc""
  def deleteCompanyKyc(params, admin_id)do
    #1. Check Admin Secret Password Matches with the params
    #2. Check if KYC Records Exist with passed Kyc ID
    #3. If KYC exists, then check if any Comments exist in Commankyccomments table
    #4. first delete related comments
    #5. secondly delete KYC Record
    #6. Return appropriate status messages

    #CHECK IF SECRET PASSWORD IS CORRECT FOR CURRENT USER
    authorisation = checkOwnPassword(params, admin_id)
    case authorisation do
      #------------------------------------
      #IF SECRET PASSWORD IS NOT CORRECT DO THIS
      nil ->  {:incorrect_password, "Admin Secret Password is Incorrect"}

      #IF SECRET PASSWORD IS CORRECT DO THIS
      _ ->
        record = Repo.get_by(Kycdocuments, id: params["kyc_id"])
        #If Record has been found then do this
        if !is_nil(record)do
          comments = Repo.all(from a in Commankyccomments, where: a.kycdocuments_id == ^params["kyc_id"])
          #Delete All Related Comments if any exist
          if comments != [] do
            from(k in Commankyccomments, where: k.kycdocuments_id == ^params["kyc_id"])
            |> Repo.delete_all()
          end
          #Delete kyc Record
          case Repo.delete(record)do
            {:ok, _data} -> {:ok, "Company KYC Record has been deleted"}
            {:error, data} -> {:error, data}
          end
        else
          #If Record has NOT been found then do this
          {:error, "Company KYC record has not been found"}
        end
    end
  end

  @doc""
  def deleteDirectorKyc(params, admin_id)do

    #1. Check Admin Secret Password Matches with the params
    #2. Check if KYC Records Exist with passed Kyc ID
    #3. If KYC exists, then check if any Comments exist in Kyccomments table
    #4. first delete related comments
    #5. secondly delete KYC Record
    #6. Return appropriate status messages

    #CHECK IF SECRET PASSWORD IS CORRECT FOR CURRENT USER
    authorisation = checkOwnPassword(params, admin_id)
    case authorisation do
      #------------------------------------
      #IF SECRET PASSWORD IS NOT CORRECT DO THIS
      nil ->  {:incorrect_password, "Admin Secret Password is Incorrect"}
      #------------------------------------
      #IF SECRET PASSWORD IS CORRECT DO THIS
      _ ->
        record = Repo.one(from k in Kycdirectors, where: k.id == ^params["kyc_id"] and is_nil(k.fourstop_response))

        if !is_nil(record)do
          #If KYC is found do this
          comments = Repo.all(from a in Kyccomments, where: a.kycdirectors_id == ^params["kyc_id"])
          #Delete All Related Comments if any exist
          if comments != [] do
            from(k in Kyccomments, where: k.kycdirectors_id == ^params["kyc_id"])
            |> Repo.delete_all()
          end
          #Delete Kyc Record
          Repo.delete(record)
          {:ok, "Directors KYC has been deleted"}
        else
          #If KYC is not found do this
          {:error, "KYC can't be deleted"}
        end
      #------------------------------------
    end
  end
  @doc""
  def employeeKycIdDocumentTypeList()do
    Repo.all(from a in Documenttype, where: a.documentcategory_id == 2, select: %{id: a.id, title: a.title,documentcategory_id: a.documentcategory_id})
  end

  def employeeKycAddressDocumentTypeList()do
    Repo.all(from a in Documenttype, where: a.documentcategory_id == 1, select: %{id: a.id, title: a.title,documentcategory_id: a.documentcategory_id})
  end

  def add_initlize(params,admin_id)do
      map = %{
         "inserted_by" => params["inserted_by"],
          "commanall_id" => params["commanall_id"],
          "signature"  => params["signature"],
          "feedetail"  => params["feetype"],
          "comment"  => params["comment"],
          "administratorusers_id"  => admin_id,
         }
         get =Repo.one(from i in Intilaze, where: i.commanall_id == ^params["commanall_id"],limit: 1, select: i)
         if is_nil(get) do
              changeset = Intilaze.changeset(%Intilaze{}, map)
            case Repo.insert(changeset) do
              {:ok, _fee} -> {:ok, "Success, initialize"}
              {:error, changeset} -> {:error, changeset}
    end
    else
    {:error_message,"Already Initialize"}
    end
    end


    def resetOtpLimit_button(params)do
    commanall_id = params["commanall_id"]
    data = Repo.one(from a in Commanall, where: a.id == ^commanall_id ,
                                         left_join: b in assoc(a, :company),
                                         left_join: c in assoc(a, :contacts),on: c.commanall_id == a.id and c.is_primary == "Y",
                                         left_join: d in assoc(b, :companyaccounts),
#                                         limit: 30,
                                         select: %{
                                           status: a.status,
                                           email_id: a.email_id,
                                           contact_number: c.contact_number,
                                           company_id: b.id,
                                           company_name: b.company_name,
                                           company_type: b.company_type,
                                           trust_level: a.trust_level,
                                           reg_at: a.inserted_at,
                                           inserted_at: d.inserted_at,
                                           available_balance: d.available_balance,
                                         })
#       IO.inspect(data)
    check_otp = Repo.all(from o in Otp, where: o.commanall_id == ^params["commanall_id"] and o.status == ^"A", select: o.otp_code)
    otp_status = if !is_nil(check_otp) do
      result = Enum.map(check_otp, fn x ->
        decode = Poison.decode!(x)
        _count = decode["otp_attempt"]
      end)
      res = Enum.any?(result, fn x -> x == 0 end)
      if res == true, do: "YES", else: "NO"
    end
    _common_map = %{company_info: data, showReset_otp_button: otp_status}

  end

  def updateTrustLevel(params) do
    commanall_id = params["commanall_id"]
    userdata = Repo.one from c in Commanall, where: c.id == ^commanall_id and not is_nil(c.accomplish_userid), select: c
    if !is_nil(userdata) do
      user_id = userdata.accomplish_userid
      response = Accomplish.get_user(user_id)
      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]

      if response_code == "0000" do

        trust_level = response["security"]["trust_level"]
        partytrust_level = %{trust_level: trust_level}
        changeset_party = Commanall.updateTrustLevel(userdata, partytrust_level)
        case Repo.update(changeset_party) do
          {:ok, _data} -> {:ok, "Trust Level Updated."}
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:third_party_error, %{status_code: response_code, errors: %{ message: response_message }}}
      end
    else
      {:error_message, "Invalid Id"}
    end
  end

  @doc"Generate password for admin Account "
  def generatepassword(params,admin_id) do
    password = params["password"]
    administratorusers = Repo.get!(Administratorusers, admin_id)
    change_password = %{secret_password: password}
    changeset = Administratorusers.generate_password_admin(administratorusers, change_password)
    case Repo.update(changeset) do
      {:ok, _response} -> {:ok ,"Generate password successfully"}
      {:error, changeset} -> {:error,changeset}
    end
  end

  @doc"Generate password for admin Account "
  def generatepasswordv1(params) do
    password = params["password"]
    admin_id = params["admin_id"]
    administratorusers = Repo.get!(Administratorusers, admin_id)
    change_password = %{secret_password: password}
    changeset = Administratorusers.generate_password_admin(administratorusers, change_password)
    case Repo.update(changeset) do
      {:ok, _response} -> {:ok ,"Generate password successfully"}
      {:error, changeset} -> {:error,changeset}
    end
  end

  def checkOwnPassword(params,admin_id) do
    get = Repo.one(from a in Administratorusers, where:  a.secret_password == ^params["password"] and a.id == ^admin_id)
    if !is_nil(get)do
      {:ok, "Password Matched"}
    else
      nil
    end
  end

  def adminredsendEmail(params, admin_id) do
    password = Commontools.random_string(6)
    employee_id =params["employee_id"]
    employee = Repo.one(from e in Employee, where: e.id == ^params["employee_id"], limit: 1)
    if !is_nil(employee) do
            company_id = employee.company_id
            com_commanall_id = Repo.get_by!(Commanall, company_id: company_id)
            commanall = Repo.get_by!(Commanall, employee_id: employee_id)
            change_password = %{password: password}
            changeset = Commanall.changeset_updatepassword(commanall, change_password)
            case Repo.update(changeset) do
              {:ok, _response} ->
                resendmailhistory = %{
                  "commanall_id" => com_commanall_id.id,
                  "employee_id" => commanall.id,
                  "section" => "Resend password with welcome email",
                  "type" => "A",
                  "inserted_by" => admin_id
                }
                _changeset_history = Resendmailhistory.changeset(%Resendmailhistory{}, resendmailhistory)
#                Repo.insert(changeset_history)
                getemployee = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employee_id,
                                                              left_join: m in assoc(cmn, :contacts),
                                                              on: m.is_primary == "Y",
                                                              left_join: d in assoc(cmn, :devicedetails),
                                                              on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                              select: %{
                                                                id: cmn.id,
                                                                commanall_id: cmn.accomplish_userid,
                                                                email_id: cmn.email_id,
                                                                as_login: cmn.as_login,
                                                                code: m.code,
                                                                contact_number: m.contact_number,
                                                                token: d.token,
                                                                token_type: d.type,
                                                              }
               company = Repo.get_by!(Company, id: company_id)

                data = [
                  %{
                    section: "addemployee",
                    type: "E",
                    email_id: getemployee.email_id,
                    data: %{
                      :email => getemployee.id,
                      :employee_name => "#{employee.first_name} #{employee.last_name}",
                      :company_name => company.company_name,
                      :pswd => password
                    }
                    # Content
                  },
                  %{
                    section: "addemployee",
                    type: "S",
                    contact_code: getemployee.code,
                    contact_number: getemployee.contact_number,
                    data: %{
                      :company_name => company.company_name
                    }
                    # Content
                  },
                  %{
                    section: "addemployee",
                    type: "N",
                    token: getemployee.token,
                    push_type: getemployee.token_type, # "I" or "A"
                    login: getemployee.as_login, # "Y" or "N"
                    data: %{}
                    # Content
                  }
                ]
                _get = V2AlertsController.main(data)
                message = "Request to join ViolaCorporate re-sent to #{employee.first_name} #{employee.last_name}"
                notification_details = %{
                  "commanall_id" => com_commanall_id.id,
                  "subject" => "addemployee",
                  "message" => message,
                  "inserted_by" => "99999#{admin_id}"
                }
                insert = Notifications.changeset(%Notifications{}, notification_details)
                case Repo.insert(insert) do
                  {:ok,_data} -> {:ok, "Record Inserted"}
                  {:error,insert} -> {:error,insert}
                end
              {:error,changeset} -> {:error,changeset}
            end
      else
      nil
    end
end

  @doc"add tag"
  def addTag(params, admin_id) do

    add_comments = %{
      administratorusers_id: admin_id,
      commanall_id: params["commanall_id"],
      description: params["comments"],
      status: params["status"]
    }

    tag_changeset = Tags.changeset(%Tags{}, add_comments)
    case Repo.insert(tag_changeset) do
      {:ok, _add} -> {:ok, "Tag Added"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc"view Tag"
  def viewTag(params) do

    _data = (from c in Tags, where: c.commanall_id == ^params["commanall_id"],
                            order_by: [desc: c.id],
                            left_join: a in assoc(c, :administratorusers),
                            select: %{
                              unique_id: a.unique_id,
                              fullname: a.fullname,
                              commanall_id: c.commanall_id,
                              status: c.status,
                              description: c.description,
                              inserted_at: c.inserted_at
                            })
           |> Repo.paginate(params)
  end

  def admin_generate_Card(params,admin_id)do
    employee_id = params["employee_id"]
    currency = params["currency"]
    card_type = params["card_type"]
    description = params["description"]
    request_id = admin_id
    # Get Comman All Data
    commandata = Repo.one from commanall in Commanall, where: commanall.employee_id == ^employee_id and not is_nil(commanall.accomplish_userid),
                                                       select: %{
                                                         id: commanall.id,
                                                         commanall_id: commanall.accomplish_userid
                                                       }

    if is_nil(commandata) do
      {:error_message,"Enter correct employee id"}

    end

    if is_nil(commandata.commanall_id) do

      {:error_message,"Employee account is not active"}

    end

    type = Application.get_env(:violacorp, :card_type)
    accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
    accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)

    fulfilment_config_id = if card_type == "V" do
      Application.get_env(:violacorp, :fulfilment_config_id_v)
    else
      Application.get_env(:violacorp, :fulfilment_config_id_p)
    end

    status = if card_type == "V" do
      1
    else
      12
    end

    bin_id = if currency == "USD" do
      Application.get_env(:violacorp, :usd_card_bin_id)
    else
      if currency == "EUR" do
        Application.get_env(:violacorp, :eur_card_bin_id)
      else
        Application.get_env(:violacorp, :gbp_card_bin_id)
      end
    end

    number = if currency == "USD" do
      Application.get_env(:violacorp, :usd_card_number)
    else
      if currency == "EUR" do
        Application.get_env(:violacorp, :eur_card_number)
      else
        Application.get_env(:violacorp, :gbp_card_number)
      end
    end

    request = %{
      type: type,
      bin_id: bin_id,
      number: number,
      currency: currency,
      user_id: commandata.commanall_id,
      status: status,
      fulfilment_config_id: fulfilment_config_id,
      fulfilment_notes: "create cards for user",
      fulfilment_reason: 1,
      fulfilment_status: 1,
      latitude: accomplish_latitude,
      longitude: accomplish_longitude,
      position_description: "",
      acceptance2: 2,
      acceptance: 1,
      request_id: request_id
    }

    response = Accomplish.create_card(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do

      currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                     select: c.id

      # Insert employee card details
      card_number = response["info"]["number"]
      last_digit = Commontools.lastfour(card_number)
      employeecard = %{
        "employee_id" => employee_id,
        "currencies_id" => currencies_id,
        "currency_code" => response["info"]["currency"],
        "last_digit" => "#{last_digit}",
        "available_balance" => response["info"]["available_balance"],
        "current_balance" => response["info"]["balance"],
        "accomplish_card_id" => response["info"]["id"],
        "bin_id" => response["info"]["bin_id"],
        "accomplish_account_number" => response["info"]["number"],
        "expiry_date" => response["info"]["security"]["expiry_date"],
        "activation_code" => response["info"]["security"]["activation_code"],
        "source_id" => response["info"]["original_source_id"],
        "status" => response["info"]["status"],
        "card_type" => card_type,
        "reason" => description,
        "inserted_by" => admin_id
      }
      changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
      case Repo.insert(changeset_comacc) do
        {:ok, _director} ->
          getemployee = Repo.get!(Employee, employee_id)
          [count_card] = Repo.all from d in Employeecards,
                                  where: d.employee_id == ^employee_id and (
                                    d.status == "1" or d.status == "4" or d.status == "12"),
                                  select: %{
                                    count: count(d.id)
                                  }
          new_number = %{"no_of_cards" => count_card.count}
          cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
          Repo.update(cards_changeset)

          # Update commanall card_requested
          if card_type == "P" do
            commanall_data = Repo.get!(Commanall, commandata.id)
            card_request = %{"card_requested" => "Y"}
            changeset_card_request = Commanall.changesetRequest(commanall_data, card_request)
            Repo.update(changeset_card_request)
          end
          {:ok, "Generate Card."}
#          %{status_code: "200", message: "Generate Card."}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:errors_thirdParty,response_message}

    end
  end

  @doc """
    this function for update contact for both Active and Pending Employee
  """

  def updateEmployeeContact(params, admin_id) do
    commanall_id = params["commanall_id"]

    case checkEmployee(commanall_id) do
      {:ok, commanall, as_director, director_id} ->
        get_contact = Repo.one(from c in Contacts, where: c.commanall_id == ^commanall_id, limit: 1, select: c)
        if !is_nil(get_contact) do
          contact = %{
            "contact_number" => params["contact_number"]
          }
          changeset_contact = Contacts.changeset_number(get_contact, contact)
          if changeset_contact.valid? do
            case Commontools.contact_is_unique?(params["contact_number"]) do
              "Y" ->
                 response = case commanall.accomplish_userid do
                   nil -> %{"status_code" => "200", "message" => "success"}
                   accomplish_user_id ->
                     number = "+#{get_contact.code}#{params["contact_number"]}"

                     verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "0"
                     request_map = %{
                       "commanall_id" => params["commanall_id"],
                       "request_by" => "99999#{admin_id}",
                       "mobile_number" => number,
                       "verify_status" => verify_status
                     }
                     case updateContactOnThirdParty(accomplish_user_id, request_map) do
                       {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                       {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                     end
                 end
                 if response["status_code"] == "200" do
                   case Repo.update(changeset_contact) do
                     {:ok, _data} ->
                       if as_director == "Y" do
                         get_dir_contact = Repo.one(from cd in Contactsdirectors, where: cd.directors_id == ^director_id, limit: 1, select: cd)
                         if !is_nil(get_dir_contact) do
                           dir_changeset = Contactsdirectors.changeset(get_dir_contact, %{contact_number: params["contact_number"]})
                           Repo.update(dir_changeset)
                         end
                       end
                       {:ok,"update"}
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
          {:error_not_found, "employee contact not found"}
        end
      {:error_not_found, message} -> {:error_not_found, message}
    end
  end

  @doc """
    this function for update Email for both Active and Pending Employee
  """
  def updateEmployeeEmail(params, admin_id) do
    commanall_id = params["commanall_id"]
    case checkEmployee(commanall_id) do
      {:ok, commanall, as_director, director_id} ->
        email = %{
          "email_id" => params["email_id"]
        }
        changeset_email = Commanall.changesetEmail(commanall, email)
        if changeset_email.valid? do
          case Commontools.email_is_unique?(params["email_id"]) do
            "Y" ->
               response = case commanall.accomplish_userid do
                 nil -> %{"status_code" => "200", "message" => "success"}
                 accomplish_user_id ->

                   verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "1"
                   request_map = %{
                     "commanall_id" => params["commanall_id"],
                     "request_by" => "99999#{admin_id}",
                     "email_address" => params["email_id"],
                     "verify_status" => verify_status
                   }
                   case updateEmailOnThirdParty(accomplish_user_id, request_map) do
                     {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                     {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                   end
               end

               if response["status_code"] == "200" do
                     case Repo.update(changeset_email) do
                       {:ok, _data} ->
                         if as_director == "Y" do
                           get_dir_email = Repo.one(from d in Directors, where: d.id == ^director_id, limit: 1, select: d)
                           if !is_nil(get_dir_email) do
                             dir_changeset = Directors.update_email(get_dir_email, %{email_id: params["email_id"]})
                             Repo.update(dir_changeset)
                           end
                           get_dir_email = Repo.one(from kd in Kyclogin, where: kd.id == ^director_id, limit: 1, select: kd)
                           if !is_nil(get_dir_email) do
                             dir_email_changeset = Kyclogin.updateEmailID(get_dir_email, %{username: params["email_id"]})
                             Repo.update(dir_email_changeset)
                           end
                         end
                         {:ok,"update"}
                       {:errors, changeset} -> {:errors ,changeset}
                     end
                   else
                     {:thirdparty_error_message, response["message"]}
                   end
            "N" ->
              {:email_existing, "already exist"}
          end
        else
          {:errors , changeset_email}
        end
      {:error_not_found, message} -> {:error_not_found, message}
    end
  end

  @doc """
    this function for change email for active and pending company both
  """

  def editCompanyEmail(params, admin_id) do
    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    case checkCompany(commanall_id, company_id) do
      {:ok, commanall} ->
        email = %{
          "email_id" => params["email_id"]
        }
        changeset_email = Commanall.changesetEmail(commanall, email)
        if changeset_email.valid? do
          case Commontools.email_is_unique?(params["email_id"]) do
            "Y" ->
               response = case commanall.accomplish_userid do
                 nil -> %{"status_code" => "200", "message" => "success"}
                 accomplish_user_id ->
                   verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "1"
                   request_map = %{
                     "commanall_id" => params["commanall_id"],
                     "request_by" => "99999#{admin_id}",
                     "email_address" => params["email_id"],
                     "verify_status" => verify_status
                   }
                   case updateEmailOnThirdParty(accomplish_user_id, request_map) do
                     {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                     {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                   end
               end

               if response["status_code"] == "200" do
                     case Repo.update(changeset_email) do
                       {:ok, _data} ->
                         check_director = Repo.one(from d in Directors, where: d.email_id == ^commanall.email_id and d.company_id == ^params["company_id"], limit: 1, select: d)
                         if !is_nil(check_director) do
                           email_map = %{email_id: params["email_id"]}
                           changeset_email = Directors.update_email(check_director, email_map)
                           Repo.update(changeset_email)
                         end
                         {:ok,"update"}
                       {:errors, changeset} -> {:errors ,changeset}
                     end
                   else
                     {:thirdparty_error_message, response["message"]}
                   end
            "N" ->
              {:email_existing, "already exist"}
          end
        else
          {:errors , changeset_email}
        end
      {:error_not_found, message} -> {:error_not_found, message}
    end
  end

  @doc """
    this function for change contact for active and pending company both
  """
  def editCompanyContact(params, admin_id) do

    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    case checkCompany(commanall_id, company_id) do
      {:ok, commanall} ->
        get_contact = Repo.one(from c in Contacts, where: c.commanall_id == ^commanall_id, limit: 1, select: c)
        if !is_nil(get_contact) do
          contact = %{
            "contact_number" => params["contact"]
          }
          changeset_contact = Contacts.changeset_number(get_contact, contact)
          if changeset_contact.valid? do
            case Commontools.contact_is_unique?(params["contact"]) do
              "Y" ->
                     response = case commanall.accomplish_userid do
                       nil -> %{"status_code" => "200", "message" => "success"}
                       accomplish_user_id ->
                         number = "+#{get_contact.code}#{params["contact"]}"
                         verify_status = if !is_nil(params["verify_status"]), do: params["verify_status"], else: "0"
                         request_map = %{
                           "commanall_id" => params["commanall_id"],
                           "request_by" => "99999#{admin_id}",
                           "mobile_number" => number,
                           "verify_status" => verify_status
                         }
                         case updateContactOnThirdParty(accomplish_user_id, request_map) do
                           {:ok, _message} -> %{"status_code" => "200", "message" => "success"}
                           {:thirdparty_error_message, message} -> %{"status_code" => "5001", "message" => message}
                         end
                     end
                     if response["status_code"] == "200" do
                       case Repo.update(changeset_contact) do
                         {:ok, _data} ->
                           check_director = Repo.one(from d in Contactsdirectors, where: d.contact_number == ^get_contact.contact_number, limit: 1, select: d)
                           if !is_nil(check_director) do
                             contact_map = %{contact_number: contact}
                             changeset_contact = Contactsdirectors.changeset(check_director, contact_map)
                             Repo.update(changeset_contact)
                           end
                           {:ok,"update"}
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
          {:error_not_found, "company contact not found"}
        end
      {:error_not_found, message} -> {:error_not_found, message}
    end
  end

  ###################################
  ## Update Contact On Third Party ##
  ###################################
  defp updateContactOnThirdParty(accomplish_user_id, request) do
    case getAccomplishUserInfo(accomplish_user_id) do
      {:ok, get_details} ->
        mobile_id = get_in(get_details["phone"], [Access.at(0), "id"])
        #        number = "+#{get_contact.code}#{params["contact_number"]}"

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

  ###################################
  ## Update Contact On Third Party ##
  ###################################
  defp updateEmailOnThirdParty(accomplish_user_id, request) do
    case getAccomplishUserInfo(accomplish_user_id) do
      {:ok, get_details} ->
        email_id = get_in(get_details["email"], [Access.at(0), "id"])
        #        number = "+#{get_contact.code}#{params["contact_number"]}"

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

  ######################################################
  ## this function for get user info from third party ##
  ######################################################
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

  ##############################
  ## get employee information ##
  ##############################
  defp checkEmployee(commoanall_id) do
    case Repo.one(from ca in Commanall, where: ca.id == ^commoanall_id and not is_nil(ca.employee_id), select: ca) do
      nil -> {:error_not_found, "employee not found."}
      employee ->
        director_id = Repo.one(from em in Employee, where: em.id == ^employee.employee_id, select: em.director_id)
        as_director = if !is_nil(director_id), do: "Y", else: "N"
        {:ok, employee, as_director, director_id}
    end
  end

  ##############################
  ## get company information  ##
  ##############################
  defp checkCompany(commoanall_id, company_id) do
    case Repo.one(from co in Commanall, where: co.id == ^commoanall_id and co.company_id == ^company_id) do
      nil -> {:error_not_found, "company not found."}
      company -> {:ok, company}
    end
  end
 end
