defmodule Violacorp.Models.Registrationv3 do
  import Ecto.Query, warn: false
  alias Violacorp.Repo

  # Step I
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Mandate
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Contacts

  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Feerules
  alias Violacorp.Schemas.Kyclogin

  alias Violacorp.Libraries.Commontools

  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  @doc "Registration Step One"
  def stepOne(params) do

    check_email_phone = verify_value(params["email"])
    check_email_v2 = check_email_phone.check_value
    new_email = check_email_phone.new_value

    country_code = Application.get_env(:violacorp, :country_code)
    viola_id = Commontools.random_string(6)

    position = String.downcase(params["position"])
    # SET IS_PRIMARY VALUE DEPENDING ON POSITION
    is_primary = case position do
      "owner" -> "Y"
      "director" -> "Y"
      "cap" -> "Y"
    end
    access_type = params["accesstype"]
    # CHECK POSITION IF IT IS ALLOWED FOR GIVEN BUSINESS TYPE
    check_position = case params["business_type"] do
      "STR" -> cond do
                 position == "owner" or position == "cap" -> {:ok, "yes"}
                 true -> {:error, "#{params["position"]} is not allowed for your business type."}
               end
      _ -> cond do
             position == "director" and access_type == "Y" -> {:ok, "yes"}
             position == "cap" and access_type == "N" -> {:ok, "yes"}
             true -> {:error, "#{params["position"]} is not allowed for your business type."}
           end
    end
    mobile = case String.first(params["mobile_number"]) do
      "0" -> case String.at(params["mobile_number"], 1) do
               "7" -> {:ok, "yes"}
               _ -> {:error, "Please enter a valid mobile number"}
             end
      "7" -> {:ok, "yes"}
      _ -> {:error, "Please enter a valid mobile number"}
    end

     file_image =  if params["image_one"] !="" and params["address_image_one"] != "" do
                      {:ok, "yes"}
                   else
                      {:error, "Please upload Document"}
                   end
                    get_contact = Repo.one(from c in Contacts, where: c.contact_number == ^params["mobile_number"], limit: 1, select: c.contact_number)
                    contact_data = Repo.one(from con in Contactsdirectors, where: con.contact_number == ^params["mobile_number"], limit: 1, select: con.contact_number)
                  check_mobile = if !is_nil(get_contact) or !is_nil(contact_data) do
                                    {:mobile_number_error, "Mobile number is already registered."}
                                 else
                                    {:ok, "yes"}
                                 end

                  get_email = Repo.one(from co in Commanall, where: co.email_id == ^new_email, limit: 1, select: co.id)
                  email_data = Repo.one(from d in Directors, where: d.email_id == ^new_email, limit: 1, select: d.id)
                  check_email = if !is_nil(get_email) or !is_nil(email_data) do
                    {:email_error, "email is already registered."}
                  else
                    {:ok, "yes"}
                  end

    with {:ok, _value} <- check_position,
         {:ok, _value} <- mobile,
         {:ok, _value} <- check_mobile,
         {:ok, _value} <- check_email,
         {:ok, _value} <- file_image do

      new_step = Map.new(%{"1" => "company detail"})
                 |> Poison.encode!()

      contacts = %{
        contacts: %{
          contact_number: params["mobile_number"],
          code: country_code,
          is_primary: "Y"
        }
      }
      commanall_params = %{
        viola_id: viola_id,
        email_id: new_email,
        password: params["password"],
        ip_address: params["ip_address"],
        step: "company-detail",
        reg_data: new_step,
        reg_step: "1",
        status: "I",
        contacts: contacts
      }

      addressdirectors = %{
        addressdirectors: %{
          address_line_one: Commontools.capitalize(params["address_line_one"]),
          address_line_two: Commontools.capitalize(params["address_line_two"]),
          address_line_three: Commontools.capitalize(params["address_line_three"]),
          town: params["town"],
          county: params["county"],
          post_code: params["post_code"],
          countries_id: params["locationId"],
          is_primary: "Y"
        }
      }

      contactsdirectors = %{
        contactsdirectors: %{
          contact_number: params["mobile_number"],
          code: country_code,
          is_primary: "Y"
        }
      }

      file_location_one = if params["image_one"] != "" do  ViolacorpWeb.Main.Assetstore.upload_image(params["image_one"]) else nil end
      file_location_two = if params["image_two"] != "" do ViolacorpWeb.Main.Assetstore.upload_image(params["image_two"]) else nil end
      address_location_one = if params["address_image_one"] != "" do ViolacorpWeb.Main.Assetstore.upload_image(params["address_image_one"]) else nil end

      file_name = if !is_nil(file_location_one) do
                    Path.basename(file_location_one)
                  else
                    if !is_nil(file_location_two) do
                      Path.basename(file_location_two)
                    else
                      nil
                    end
                  end

      kycdirectors = %{
        kycdirectors: %{
          documenttype_id: params["documenttype_id"],
          document_number: params["document_number"],
          issue_date: params["issue_date"],
          expiry_date: params["expiry_date"],
          country: params["country"],
          file_name: file_name,
          file_location: file_location_one,
          file_location_two: file_location_two,
          status: "D",
          type: "I"
        }
      }

      kycdirectorsaddress = %{
        kycdirectors: %{
          documenttype_id: params["documenttype_addressid"],
          file_location: address_location_one,
          status: "D",
          type: "A"
        }
      }
      gender = case params["title"] do
        "Mr" -> "M"
        "Mrs" -> "F"
        "Miss" -> "F"
        "Ms" -> "F"
        _ -> "M"
      end

      director_params = %{
        directors: %{
          position: position,
          employeeids: params["employeeids"],
          title: params["title"],
          first_name: params["first_name"],
          middle_name: params["middle_name"],
          last_name: params["last_name"],
          date_of_birth: params["date_of_birth"],
          access_type: params["accesstype"],
          email_id: new_email,
          gender: gender,
          is_primary: is_primary,
          verify_kyc: "pending",
          addressdirectors: addressdirectors,
          contactsdirectors: contactsdirectors,
          kycdirectors: kycdirectors,
          kycdirectorsaddress: kycdirectorsaddress
        }
      }

      company = %{
        countries_id: "53",
        company_type: params["business_type"],
        directors: director_params,
        contacts: contacts
      }

      changeset_commanall = Commanall.changeset_first_step(%Commanall{}, commanall_params)

      changeset = Company.changeset_reg_step_oneV3(%Company{}, company)

      bothinsert = Ecto.Changeset.put_assoc(changeset, :commanall, [changeset_commanall])

      case Repo.insert(bothinsert) do
        {:ok, company} ->

          commanall_id = Enum.at(company.commanall, 0).id
          directors_id = Enum.at(company.directors, 0).id

          generate_otp = if check_email_v2 == "Y" do
            Commontools.randnumber(6)
          else
            "222222"
          end

          otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
          otp_code = Poison.encode!(otp_code_map)
          otpmap = %{
            "commanall_id" => commanall_id,
            "otp_code" => otp_code,
            "otp_source" => "Registration",
            "inserted_by" => commanall_id
          }
          otp_changeset = Otp.changeset(%Otp{}, otpmap)
          case Repo.insert(otp_changeset) do
            {:ok, _otp} ->

            if check_email_v2 == "Y" do
              data = [%{
                section: "company_registration_otp",
                type: "E",
                email_id: new_email,
                data: %{:otp_code => generate_otp}   # Content
              }]
              V2AlertsController.main(data)
            end
              response = %{
                commanall_id: Enum.at(company.commanall, 0).id,
                directors_id: directors_id,
                messages: "Success, Registration step one complete"
              }
              {:ok, response}
            {:error, changeset} -> {:error, changeset}
          end
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, value} -> {:not_acceptable, value}
      {:mobile_number_error, value} -> {:mobile_number_error, value}
      {:email_error, value} -> {:email_error, value}
    end
  end

  @doc "Registration Step Two Email Verification"
  def stepTwo(params) do
    #    GET OTP FIRST
    _getotp = case Repo.get_by(Otp, commanall_id: params["commanall_id"], otp_source: "Registration") do
      nil -> {:not_acceptable, "Otp not found"}
      otp -> otpdecode = Poison.decode!(otp.otp_code)
             if otpdecode["otp_code"] == params["otp_code"] do  # Compare User given code with db value
               commanall = Repo.one(from cmn in Commanall, where: cmn.id == ^params["commanall_id"], left_join: c in assoc(cmn, :contacts), on: c.is_primary == "Y", preload: [
                 contacts: c
               ])
               new_step = Map.new(%{"11" => "email-otp-verify"})
                          |> Poison.encode!()
               change_step = %{"reg_step" => "11", "step" => "email-otp-verify", "reg_data" => new_step}
               changeset_commanall = Commanall.changesetSteps(commanall, change_step)
               case Repo.update(changeset_commanall) do # Update step for User
                 {:ok, _company} ->

                   generate_otp = Commontools.randnumber(6)
                   otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
                   otp_code = Poison.encode!(otp_code_map)
                   otpmap = %{
                     "commanall_id" => params["commanall_id"],
                     "otp_code" => otp_code,
                     "otp_source" => "Registration_mobile",
                     "inserted_by" => params["commanall_id"]
                   }

                   data = Repo.one(from o in Otp, where: o.commanall_id == ^params["commanall_id"] and o.otp_source == ^"Registration_mobile", limit: 1, select: o)
                   if !is_nil(data) do
                     otp_changeset = Otp.changeset(data, otpmap)
                     case Repo.update(otp_changeset) do
                       {:ok, _otp} ->
                           data = [%{
                               section: "company_registration_otp_mobile",
                               type: "S",
                               contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).code end,
                               contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).contact_number end,
                               data: %{:otp_code => generate_otp} # Content
                             }]
                           V2AlertsController.main(data)
                       {:ok, "Success, Email verified"}
                       {:error, changeset} -> {:error, changeset}
                     end
                   else
                       otp_changeset = Otp.changeset(%Otp{}, otpmap)
                       case Repo.insert(otp_changeset) do # Generate new Otp for Mobile verification
                         {:ok, _otp} ->
                               data = [
                                 %{
                                   section: "company_registration_otp_mobile",
                                   type: "S",
                                   contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).code end,
                                   contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).contact_number end,
                                   data: %{:otp_code => generate_otp} # Content
                                 }]
                               V2AlertsController.main(data)
                           {:ok, "Success, Email verified"}
                         {:error, changeset} -> {:error, changeset}
                       end
                   end
                 {:error, changeset} -> {:error, changeset}
               end
             else
               {:not_acceptable, "Incorrect OTP please re-enter or request a new OTP"}
             end
    end
  end

  @doc "Registration Step Two Email Verification"
  def stepTwoV2(params) do
    #    GET OTP FIRST
    _getotp = case Repo.get_by(Otp, commanall_id: params["commanall_id"], otp_source: "Registration") do
      nil -> {:not_acceptable, "Otp not found"}
      otp -> otpdecode = Poison.decode!(otp.otp_code)
             if otpdecode["otp_code"] == params["otp_code"] do  # Compare User given code with db value
               commanall = Repo.one(from cmn in Commanall, where: cmn.id == ^params["commanall_id"], left_join: c in assoc(cmn, :contacts), on: c.is_primary == "Y", preload: [
                 contacts: c
               ])
               phone_number = Enum.at(commanall.contacts, 0).contact_number
               check_email_phone = verify_value(phone_number)
               check_phone_v2 = check_email_phone.check_value
               new_phone = check_email_phone.new_value

               new_step = Map.new(%{"11" => "email-otp-verify"})
                          |> Poison.encode!()

               change_step = %{"reg_step" => "11", "step" => "email-otp-verify", "reg_data" => new_step}
               changeset_commanall = Commanall.changesetSteps(commanall, change_step)
               case Repo.update(changeset_commanall) do # Update step for User
                 {:ok, _company} ->

                   generate_otp = if check_phone_v2 == "Y" do
                     Commontools.randnumber(6)
                   else
                     "222222"
                   end
                   otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
                   otp_code = Poison.encode!(otp_code_map)
                   otpmap = %{
                     "commanall_id" => params["commanall_id"],
                     "otp_code" => otp_code,
                     "otp_source" => "Registration_mobile",
                     "inserted_by" => params["commanall_id"]
                   }

                   if check_phone_v2 == "N" do
                       director_data = Repo.get_by(Contactsdirectors, directors_id: params["directors_id"])
                       contact_data = Repo.get_by(Contacts, commanall_id: params["commanall_id"])
                       changeset = Contactsdirectors.changeset(director_data, %{"contact_number" => new_phone})
                       changeset_contact = Contacts.changeset_number(contact_data, %{"contact_number" => new_phone})
                       Repo.update(changeset)
                       Repo.update(changeset_contact)
                    end
                   data = Repo.one(from o in Otp, where: o.commanall_id == ^params["commanall_id"] and o.otp_source == ^"Registration_mobile", limit: 1, select: o)
                   if !is_nil(data) do
                     otp_changeset = Otp.changeset(data, otpmap)
                     case Repo.update(otp_changeset) do
                       {:ok, _otp} ->
                         if check_phone_v2 == "Y" do
                           data = [%{
                             section: "company_registration_otp_mobile",
                             type: "S",
                             contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).code end,
                             contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).contact_number end,
                             data: %{:otp_code => generate_otp} # Content
                           }]
                           V2AlertsController.main(data)
                         end
                         {:ok, "Success, Email verified"}
                       {:error, changeset} -> {:error, changeset}
                     end
                   else
                     otp_changeset = Otp.changeset(%Otp{}, otpmap)
                     case Repo.insert(otp_changeset) do # Generate new Otp for Mobile verification
                       {:ok, _otp} ->
                         if check_phone_v2 == "Y" do
                           data = [
                             %{
                               section: "company_registration_otp_mobile",
                               type: "S",
                               contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).code end,
                               contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do nil else Enum.at(commanall.contacts, 0).contact_number end,
                               data: %{:otp_code => generate_otp} # Content
                             }]
                           V2AlertsController.main(data)
                         end
                         {:ok, "Success, Email verified"}
                       {:error, changeset} -> {:error, changeset}
                     end
                   end
                 {:error, changeset} -> {:error, changeset}
               end
             else
               {:not_acceptable, "Incorrect OTP please re-enter or request a new OTP"}
             end
    end
  end

  @doc "Registration Step three Mobile Verification"
  def stepThree(params) do
    #    GET OTP FIRST
    _getotp = case Repo.get_by(Otp, commanall_id: params["commanall_id"], otp_source: "Registration_mobile") do
      nil -> {:not_acceptable, "Otp not found"}
      otp -> otpdecode = Poison.decode!(otp.otp_code)
             if otpdecode["otp_code"] == params["otp_code"] do  # Compare User given code with db value

               if !is_nil(params["mobile_number"]) do
                 check_email_phone = verify_value(params["mobile_number"])
                 check_phone_v2 = check_email_phone.check_value
                 new_phone = check_email_phone.new_value

                 director_data = Repo.get_by(Contactsdirectors, directors_id: params["directors_id"])
                 contact_data = Repo.get_by(Contacts, commanall_id: params["commanall_id"])

                 changeset = Contactsdirectors.changeset(director_data, %{"contact_number" => new_phone})
                 changeset_contact = Contacts.changeset_number(contact_data, %{"contact_number" => new_phone})

                 Repo.update(changeset)
                 Repo.update(changeset_contact)
               end

               commanall = Repo.get(Commanall, params["commanall_id"])

               new_step = Map.new(%{"12" => "mobile-otp-verify"})
                          |> Poison.encode!()

               change_step = %{"reg_step" => "12", "step" => "mobile-otp-verify", "reg_data" => new_step}
               changeset_commanall = Commanall.changesetSteps(commanall, change_step)
               case Repo.update(changeset_commanall) do # Update step for User
                 {:ok, _company} -> {:ok, "Success, Mobile Number verified"}
                 {:error, changeset} -> {:error, changeset}
               end
             else
               {:not_acceptable, "Incorrect OTP please re-enter or request a new OTP"}
             end
    end
  end

  def changeMobileNumber(params) do

    getotp = Repo.get_by(Otp, commanall_id: params["commanall_id"], otp_source: "Registration_mobile")

     if is_nil(getotp) do
       {:not_acceptable, "no record found"}
     else

        changeset_contact = Contacts.changeset_number(%Contacts{}, %{"contact_number" => params["mobile_number"]})
        if changeset_contact.valid? do

          get_contact = Repo.get_by(Contacts, contact_number: params["mobile_number"])
          contact_data = Repo.get_by(Contactsdirectors, contact_number: params["mobile_number"])

          check_mobile = if !is_nil(get_contact) or !is_nil(contact_data) do
            {:error, "Mobile number is already registered."}
          else
            {:ok, "yes"}
          end
          mobile = case String.first(params["mobile_number"]) do
            "0" -> case String.at(params["mobile_number"], 1) do
                     "7" -> {:ok, "yes"}
                     _ -> {:error, "Please enter a valid mobile number"}
                   end
            "7" -> {:ok, "yes"}
            _ -> {:error, "Please enter a valid mobile number"}
          end
          with {:ok, _value} <- check_mobile,
               {:ok, _value} <- mobile do

            generate_otp = Commontools.randnumber(6)
            otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
            otp_code = Poison.encode!(otp_code_map)

            otpmap = %{
              "commanall_id" => params["commanall_id"],
              "otp_code" => otp_code,
              "otp_source" => "Registration_mobile",
              "inserted_by" => params["commanall_id"]
            }
            otp_changeset = Otp.changeset(getotp, otpmap)
            case Repo.update(otp_changeset) do # Generate new Otp for Mobile verification
              {:ok, _otp} ->
                contacts = Repo.one(from d in Contactsdirectors, where: d.directors_id == ^params["directors_id"],
                                                            select: %{code: d.code})

                if is_nil(contacts) do

                  {:not_acceptable, "no record found"}
                else
                  data = %{
                    :section => "company_registration_otp_mobile",
                    :contact_number => params["mobile_number"],
                    :code => contacts.code,
                    :commanall_id => params["commanall_id"],
                    :otp_code => "#{generate_otp}"
                  }
                  AlertsController.storeNotification(data)
                  data = [%{
                    section: "company_registration_otp_mobile",
                    type: "S",
                    contact_code: contacts.code,
                    contact_number: params["mobile_number"],
                    data: %{
                      :otp_code => "#{generate_otp}"} # Content
                  }]
                  V2AlertsController.main(data)
                end
                {:ok, "Otp sent to new number"}
              {:error, changeset} -> {:error, changeset}
            end
          else
            {:error, value} -> {:not_acceptable, value}
          end
        else
          {:error, changeset_contact}
        end
    end
  end

  @doc "Registration Step Three"
  def stepFour(params) do
    commanall = Repo.get(Commanall, params["commanall_id"])

    if !is_nil(commanall) and is_nil(commanall.vpin) do
      change_step = %{
        "vpin" => params["vpin"],
      }
      changeset_commanall = Commanall.changeset_updatepin(commanall, change_step)
      case Repo.update(changeset_commanall) do
        {:ok, _response} ->
          change_step = %{"reg_step" => "2", "step" => "vpin"}
          changeset_commanall = Commanall.changesetSteps(commanall, change_step)
          Repo.update(changeset_commanall)
          {:ok, "Passcode inserted."}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:not_acceptable, "Passcode already set"}
    end
  end

  @doc "Registration Step Four"
  def stepFive(params) do
    commanall = Repo.get!(Commanall, params["commanall_id"])


    old_company = Repo.get!(Company, commanall.company_id)

    company = %{
      "sector_id" => params["sector_id"],
      "sector_details" => params["sector_details"],
      "monthly_transfer" => params["monthly_transfer"],
      "company_name" => params["company_name"],
      "landline_number" => params["landline_number"],
      "date_of_registration" => params["registration_date"],
      "registration_number" => params["registration_number"],
      "company_website" => params["company_website"],
    }
    changeset = if old_company.company_type == "LTD" do
      Company.changeset_reg_step_four_limited_company(old_company, company)
    else
      Company.changeset_reg_step_four(old_company, company)
    end

    address_line_one = Commontools.capitalize(params["r_address_line_one"])
    address_line_two = Commontools.capitalize(params["r_address_line_two"])
    address_line_three = Commontools.capitalize(params["r_address_line_three"])
    county = Commontools.capitalize(params["r_county"])

    [find] = Repo.all from d in Address, where: d.commanall_id == ^params["commanall_id"] and d.is_primary == "Y",
                                         select: count(d.id)

    is_primary = if find > 0 do
      "N"
    else
      "Y"
    end

    [count_address] = Repo.all from a in Address, where: a.commanall_id == ^params["commanall_id"],
                                                  select: count(a.commanall_id)

    address_number = count_address + 1

    address = %{
      "commanall_id" => params["commanall_id"],
      "address_line_one" => address_line_one,
      "address_line_two" => address_line_two,
      "address_line_three" => address_line_three,
      "countries_id" => params["r_locationId"],
      "post_code" => params["r_post_code"],
      "town" => params["r_town"],
      "county" => county,
      "is_primary" => is_primary,
      "sequence" => address_number
    }
    changeset_address = Address.changeset(%Address{}, address)


    check_trading_validation = if params["trading_address"] == "Y" do
      address_number = 2
      address_line_one = Commontools.capitalize(params["t_address_line_one"])
      address_line_two = Commontools.capitalize(params["t_address_line_two"])
      address_line_three = Commontools.capitalize(params["t_address_line_three"])
      county = Commontools.capitalize(params["t_county"])

      address = %{
        "commanall_id" => params["commanall_id"],
        "t_address_line_one" => address_line_one,
        "t_address_line_two" => address_line_two,
        "t_address_line_three" => address_line_three,
        "t_countries_id" => params["t_locationId"],
        "t_post_code" => params["t_post_code"],
        "t_town" => params["t_town"],
        "t_county" => county,
        "is_primary" => "N",
        "sequence" => address_number
      }
      changeset_additional_address = Address.changeset_trading(%Address{}, address)
      if !changeset_additional_address.valid? do
        changeset_additional_address
      else
        "Yes"
      end
    else
      "Yes"
    end

    # check Company land-line number unique
    case checkUniqueLandlineNumber(params["landline_number"]) do
      "Y" ->
          if changeset.valid? do
            if changeset_address.valid? do
              if check_trading_validation == "Yes" do
                if find > 0 do
                  exist = Repo.get_by(Address, commanall_id: commanall.id, is_primary: "Y")
                  address = %{
                    "commanall_id" => params["commanall_id"],
                    "address_line_one" => address_line_one,
                    "address_line_two" => address_line_two,
                    "address_line_three" => address_line_three,
                    "countries_id" => params["r_locationId"],
                    "post_code" => params["r_post_code"],
                    "town" => params["r_town"],
                    "county" => params["r_county"]
                  }
                  changeset_address = Address.changeset(exist, address)
                  Repo.update(changeset_address)
                else
                  Repo.insert(changeset_address)
                end


                if params["trading_address"] == "Y" do

                  [count_address] = Repo.all from ad in Address, where: ad.commanall_id == ^params["commanall_id"],
                                                                 select: count(ad.commanall_id)

                  address_number = count_address + 1

                  address_line_one = Commontools.capitalize(params["t_address_line_one"])
                  address_line_two = Commontools.capitalize(params["t_address_line_two"])
                  address_line_three = Commontools.capitalize(params["t_address_line_three"])
                  county = Commontools.capitalize(params["t_county"])

                  address = %{
                    "commanall_id" => params["commanall_id"],
                    "t_address_line_one" => address_line_one,
                    "t_address_line_two" => address_line_two,
                    "t_address_line_three" => address_line_three,
                    "t_countries_id" => params["t_locationId"],
                    "t_post_code" => params["t_post_code"],
                    "t_town" => params["t_town"],
                    "t_county" => county,
                    "is_primary" => "N",
                    "sequence" => address_number
                  }
                  changeset_additional_address = Address.changeset_trading(%Address{}, address)

                  if changeset_additional_address.valid? do
                    Repo.insert(changeset_additional_address)
                  else
                    {:error, changeset_additional_address}
                  end
                end



                director = Repo.get_by(Directors, company_id: commanall.company_id, sequence: 1)
                reg = cond do
                  old_company.company_type == "STR" and String.downcase(director.position) == "owner" ->
                    %{reg_step: "5"}
                  true ->
                    %{reg_step: "3"}
                end
                regs_data = commanall.reg_data
                new_step = Map.new(%{"#{reg.reg_step}" => params})
                old_step = Poison.decode!(regs_data)
                merge_steps = Map.merge(old_step, new_step)
                              |> Poison.encode!()

                change_step = %{"reg_step" => reg.reg_step, "reg_data" => merge_steps}

                changeset_commanall = Commanall.changesetSteps(commanall, change_step)
                if changeset.valid? do
                  Repo.update(changeset)
                  Repo.update(changeset_commanall)
                end

                response = %{commanall_id: commanall.id, reg_step: reg.reg_step}
                {:ok, response}
              else
                {:error, check_trading_validation}
              end
            else
              {:error, changeset_address}
            end
          else
            {:error, changeset}
          end
      "N" -> {:landlineNumber_error, "Already someone used."}
    end
  end

  def checkUniqueLandlineNumber(landline_number) do
    chk_landline = Repo.one(from c in Company, where: c.landline_number == ^landline_number, limit: 1, select: c.id)
    case chk_landline do
      nil -> "Y"
      _data -> "N"
    end
  end

  @doc "Registration Step Five"
  def stepSix(params) do
    commanall = Repo.get!(Commanall, params["commanall_id"])
    skip = params["skip"]
    more_available = params["more_available"]
    company = Repo.get_by(Company, id: commanall.company_id)
    main_dir = Repo.one(from d in Directors, where: d.company_id == ^commanall.company_id and d.sequence == 1 and (like(d.position, "Cap") or like(d.position, "Director") or  like(d.position, "Owner")))
    if skip == "Y" and company.company_type != "STR" do
      if main_dir.position == "director" do
        change_step = %{
          "reg_step" => "4"
        }
        changeset_commanall = Commanall.changesetSteps(commanall, change_step)

        case Repo.update(changeset_commanall) do
          {:ok, _director_params} ->
            response = %{
              reg_step: "4",
              messages: "Skipped extra directors."
            }
            {:ok, response}
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:not_acceptable, "You have to enter at least one director's details"}
      end
    else
      position = String.downcase(params["position"])

      [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)

      director_number = count + 1
      access_type = "Y"
      check_position = if company.company_type == "STR" do
        if position == "owner" or position == "cap" do
          "yes"
        else
          "#{params["position"]} is not allowed for your business type."
        end
      else
        if position == "director" and access_type == "Y"  do
          "yes"
        else
          if position == "cap" and access_type == "N"  do
            "yes"
          else
            "#{params["position"]} is not allowed for your business type."
          end
        end
      end

      if check_position != "yes" do
        {:not_acceptable, check_position}
      else
        password = Commontools.generate_password()

        kyclogin = %{
          kyclogin: %{
            username: params["contact_email"],
            password: password,
            inserted_by: params["commanall_id"],
            directors_company_id: commanall.company_id
          }
        }
        full_director_params = %{
          company_id: commanall.company_id,
          email_id: params["contact_email"],
          position: position,
          first_name: params["first_name"],
          last_name: params["last_name"],
          sequence: director_number,
          verify_kyc: "pending",
          access_type: params["accesstype"],
          kyclogin: kyclogin
        }

          changeset = Directors.reg_step_fiveV3(%Directors{}, full_director_params)
          check_kyc_email = check_existing_email(params)
        if check_kyc_email == "Y"  do

          case Repo.insert(changeset) do
            {:ok, _director_params} ->

            app_url = Application.get_env(:violacorp, :app_url)
            first_Director = Repo.get_by(Directors, company_id: company.id, sequence: 1)

            random = Commontools.randnumberlimit(15)
            link_data = "#{company.id}.#{random}" |> Base.encode64(padding: false)
              data = [%{
                section: "company_director_login",
                type: "E",
                email_id: params["contact_email"],
                data: %{:company_name => company.company_name, :first_director_name =>  "#{first_Director.first_name} #{first_Director.last_name}", :director_name => "#{params["first_name"]} #{params["last_name"]}", :email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"}  # Content
              },
                %{
                  section: "company_director_login",
                  type: "S",
                  contact_code: nil,
                  contact_number: nil,
                  data: %{:email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"} # Content
                },
                %{
                  section: "company_director_login",
                  type: "N",
                  token: nil,
                  push_type: nil, # "I" or "A"
                  login: "N", # "Y" or "N"
                  data: %{:email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"} # Content
                }]


              V2AlertsController.main(data)
              newcount = Repo.one(
                from d in Directors, where: d.company_id == ^commanall.company_id,
                                     limit: 1,
                                     order_by: [
                                       desc: d.inserted_at
                                     ],
                                     select: %{
                                       count: count(d.company_id)
                                     }
              )


              reg = cond do
                company.company_type == "STR" ->
                  "5"
                company.company_type == "LTD" and String.downcase(main_dir.position) == "dir" ->
                  if more_available == "Y" do
                    "4#{newcount.count}"
                  else
                    "4"
                  end
                company.company_type == "LTD" and String.downcase(main_dir.position) == "cap" ->
                  if more_available == "Y" do
                    "4#{newcount.count}"
                  else
                    "4"
                  end
                true ->
                  if more_available == "Y" do
                    "4#{newcount.count}"
                  else
                    "4"
                  end
              end


              change_step = %{"reg_step" => reg}

              changeset_commanall = Commanall.changesetSteps(commanall, change_step)

              case Repo.update(changeset_commanall) do
                {:ok, _director_params} ->
                  response = %{
                    reg_step: reg,
                    sequence: director_number,
                    messages: "Company #{params["position"]} inserted."
                  }
                  {:ok, response}
              end
            {:error, changeset} -> {:error, changeset}
          end
          else
          {:invalid, %{email_id: "Email id Already Used."}}
        end
      end
    end
  end

  @doc "Registration Step Five"
  def stepSeven(params) do
    commanall = Repo.get!(Commanall, params["commanall_id"])

    company = Repo.get_by(Company, id: commanall.company_id)

    skip = params["skip"]

    if skip == "Y" do
      change_step = %{
          "reg_step" => "5"
        }
      changeset_commanall = Commanall.changesetSteps(commanall, change_step)

      case Repo.update(changeset_commanall) do
        {:ok, _director_params} ->
          response = %{
            reg_step: "5",
            messages: "Skipped extra significants."
          }
          {:ok, response}
        {:error, changeset} -> {:error, changeset}
      end
    else
      [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)

      director_number = count + 1

      company_type = if company.company_type == "STR" do
        {:error, company.company_type}
      else
        {:ok, company.company_type}
      end

      with {:ok, _company_type} <- company_type
        do

        password = Commontools.generate_password()

          kyclogin = %{
          kyclogin: %{
            username: params["contact_email"],
            password: password,
            inserted_by: params["commanall_id"],
            directors_company_id: commanall.company_id
          }
        }

        full_director_params = %{
          company_id: commanall.company_id,
          email_id: params["contact_email"],
          position: "significant",
          first_name: params["first_name"],
          middle_name: params["middle_name"],
          last_name: params["last_name"],
          sequence: director_number,
          verify_kyc: "pending",
          access_type: params["accesstype"],
          kyclogin: kyclogin
        }


        changeset = Directors.reg_step_fiveV3(%Directors{}, full_director_params)
        check_existing_email = check_existing_email(params)
        if check_existing_email == "Y" do
            case Repo.insert(changeset) do
              {:ok, _director_params} ->
                newcount = Repo.one(
                  from d in Directors, where: d.company_id == ^commanall.company_id and d.position == "significant",
                                       limit: 1,
                                       order_by: [
                                         desc: d.inserted_at
                                       ],
                                       select: %{
                                         count: count(d.company_id)
                                       }
                )

                more_available = params["more_available"]

                change_step = if more_available == "Y" do
                  %{
                    "reg_step" => "5#{newcount.count}"
                  }
                else
                  %{
                    "reg_step" => "5"
                  }
                end

                changeset_commanall = Commanall.changesetSteps(commanall, change_step)

                case Repo.update(changeset_commanall) do
                  {:ok, _director_params} ->
                    response = %{
                      reg_step: change_step["reg_step"],
                      sequence: director_number,
                      messages: "Company Significant Person inserted."
                    }
                    {:ok, response}
                  {:error, changeset} -> {:error, changeset}
                end
              {:error, changeset} -> {:error, changeset}
            end
           else
          {:invalid, %{email_id: "Email id Already Used."}}
         end
      else
        {:error, company_type} -> {:not_acceptable, "Cannot add Significant persons for #{company_type} company"}
      end
    end
  end



  @doc "Registration Step Seven"
  def stepEight(params) do

    check = Repo.one from m in Mandate, where: m.commanall_id == ^params["commanall_id"], select: count(m.id)
    if check > 0 do
      {:not_acceptable, "Mandate already exists"}
    else
      if (!is_nil(params["terms"]) and params["terms"] == "yes") do

        mandate_data = %{
          terms_of_service: params["terms"],
          terms_and_conditions: params["terms"],
          cookies_policy: params["terms"],
          privacy_policy: params["terms"],
        }

        all = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                              left_join: c in assoc(cmn, :company),
                                              left_join: director in assoc(c, :directors),
                                              on: director.sequence == 1,
                                              select: %{
                                                commanall: cmn,
                                                director: director,
                                                company_name: c.company_name
                                              }

        director = all.director
        mandate = %{
          "commanall_id" => params["commanall_id"],
          "directors_id" => director.id,
          "response_data" => Poison.encode!(mandate_data),
          "inserted_by" => params["commanall_id"]
        }
        mandate_changeset = Mandate.changeset(%Mandate{}, mandate)

        sign = %{
          "signature" => params["signature"],
        }
        director_changeset = Directors.changesetSignature(director, sign)

        with {:ok, _mandate} <- Repo.insert(mandate_changeset),
             {:ok, _signature} <- Repo.update(director_changeset)
          do
          commanall = all.commanall
          change_step = %{"status" => "P", "reg_step" => "6", "step" => "done"}

          changeset_commanall = Commanall.changesetSteps(commanall, change_step)
          Repo.update(changeset_commanall)
          dir_full_name = "#{director.first_name} #{director.last_name}"
          data = %{
            :section => "registration_pending",
            :commanall_id => params["commanall_id"],
            :company_name => all.company_name,
            :director_name => dir_full_name,
          }
          AlertsController.storeNotification(data)
          data = [%{
            section: "registration_pending",
            type: "E",
            email_id: all.commanall.email_id,
            data: %{
              :company_name => all.company_name, :director_name => dir_full_name}  # Content
          },
            %{
              section: "registration_pending",
              type: "S",
              contact_code: nil,
              contact_number: nil,
              data: %{
                :company_name => all.company_name, :director_name => dir_full_name} # Content
            },
            %{
              section: "registration_pending",
              type: "N",
              token: nil,
              push_type: nil, # "I" or "A"
              login: all.commanall.as_login, # "Y" or "N"
              data: %{
                :company_name => all.company_name, :director_name => dir_full_name} # Content
            }]
          V2AlertsController.main(data)

          {:ok, "Mandate inserted successfully"}

        else
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:not_acceptable, "Terms not accepted, please accept terms."}
      end
    end
  end

  def directorsList(params) do
    directors = Repo.all from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                left_join: c in assoc(cmn, :company),
                                                left_join: d in assoc(c, :directors),
                                                select: %{
                                                  id: d.id,
                                                  position: d.position,
                                                  title: d.title,
                                                  first_name: d.first_name,
                                                  last_name: d.last_name
                                                }
    {:ok, directors}
  end


  def firstDirector(params) do
    directors = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                left_join: c in assoc(cmn, :company),
                                                left_join: d in assoc(c, :directors),
                                                on: d.sequence == 1,
                                                select: %{
                                                  id: d.id,
                                                  position: d.position,
                                                  title: d.title,
                                                  first_name: d.first_name,
                                                  last_name: d.last_name
                                                }
    {:ok, directors}
  end

  def firstCompanyDirector(params) do

    if is_nil(params["company_id"]) do
      {:not_acceptable, "company id not valid"}
    else
    base_value = Base.decode64!(params["company_id"], padding: false)
    company_id = String.replace(base_value, ~r/\.(.*)/, "")

    if is_nil(base_value) or is_nil(company_id) do
      {:not_acceptable, "company id not valid"}
      else
    directors = Repo.one from cmn in Company, where: cmn.id == ^company_id,
                                                left_join: d in assoc(cmn, :directors),
                                                on: d.sequence == 1,
                                                select: %{
                                                  id: d.id,
                                                  position: d.position,
                                                  title: d.title,
                                                  first_name: d.first_name,
                                                  last_name: d.last_name,
                                                  company_name: cmn.company_name
                                                }
    {:ok, directors}
    end
    end
  end

  def monthlyFeeRule do
    fee_rule = Repo.one from f in Feerules, where: f.id == 1 and f.status == "A" and f.type == "M",
                                            select: %{
                                              id: f.id,
                                              monthly_fee: f.monthly_fee,
                                              per_card_fee: f.per_card_fee,
                                              minimum_card: f.minimum_card,
                                              vat: f.vat,
                                              status: f.status,
                                              type: f.type
                                            }
    {:ok, fee_rule}
  end

  def addNewDirector(params, commanall_id) do

    commanall = Repo.get!(Commanall, commanall_id)
    company = Repo.get_by(Company, id: commanall.company_id)

    position = String.downcase(params["position"])
    [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)
    director_number = count + 1

    check_position = if company.company_type == "STR" do
      if position == "owner" or position == "cap" do
        "yes"
      else
        "#{params["position"]} is not allowed for your business type."
      end
    else
      if position == "director" or position == "cap" or position == "significant" do
        "yes"
      else
          "#{params["position"]} is not allowed for your business type."
      end
    end
    if check_position != "yes" do
      {:not_acceptable, check_position}
    else
      password = Commontools.generate_password()

      kyclogin = %{
        kyclogin: %{
          username: params["contact_email"],
          password: password,
          inserted_by: commanall_id,
          directors_company_id: commanall.company_id
        }
      }
      full_director_params = %{
        company_id: commanall.company_id,
        email_id: params["contact_email"],
        position: position,
        first_name: params["first_name"],
        last_name: params["last_name"],
        middle_name: params["middle_name"],
        sequence: director_number,
        verify_kyc: "pending",
        access_type: "N",
        kyclogin: kyclogin
      }

      changeset = Directors.reg_step_fiveV3(%Directors{}, full_director_params)
      check_kyc_email = check_existing_email(params)

      if check_kyc_email == "Y"  do
        case Repo.insert(changeset) do
          {:ok, _director_params} ->

            app_url = Application.get_env(:violacorp, :app_url)
            first_Director = Repo.get_by(Directors, company_id: company.id, sequence: 1)
            #
            random = Commontools.randnumberlimit(15)
            link_data = "#{company.id}.#{random}" |> Base.encode64(padding: false)
            data = [%{
              section: "company_director_login",
              type: "E",
              email_id: params["contact_email"],
              data: %{:company_name => company.company_name, :first_director_name =>  "#{first_Director.first_name} #{first_Director.last_name}", :director_name => "#{params["first_name"]} #{params["last_name"]}", :email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"}  # Content
            },
              %{
                section: "company_director_login",
                type: "S",
                contact_code: nil,
                contact_number: nil,
                data: %{:email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"} # Content
              },
              %{
                section: "company_director_login",
                type: "N",
                token: nil,
                push_type: nil, # "I" or "A"
                login: "N", # "Y" or "N"
                data: %{:email => params["contact_email"], :password => password, link: "#{app_url}/login/#{link_data}"} # Content
              }]

            V2AlertsController.main(data)
            response = %{
              sequence: director_number,
              messages: "Company #{params["position"]} inserted."
            }
          {:ok, response}
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:invalid, %{email_id: "Email id Already Used."}}
      end
    end
  end

  defp verify_value(input_value) do
    value_length = String.length(input_value) - 2
    new_value = String.downcase(String.slice(input_value, value_length..-1))

    # Check Email
    _output = if (new_value == "-l") do
                # Remove -l
                new_value = String.slice(input_value, 0..-3)
                %{check_value: "N", new_value: new_value}
              else
                %{check_value: "Y", new_value: input_value}
              end
  end

  defp check_existing_email(params)do
    check = Repo.one(from k in Kyclogin, where: k.username == ^params["contact_email"], limit: 1, select: k)
    check_email = Repo.one(from com in Directors, where: com.email_id == ^params["contact_email"], limit: 1, select: com)
    check_coman = Repo.one(from co in Commanall, where: co.email_id == ^params["contact_email"], limit: 1, select: co)
    if is_nil(check_email) and is_nil(check) and is_nil(check_coman) do
        "Y"
    else
        "N"
    end
  end
end
