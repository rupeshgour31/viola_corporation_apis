defmodule Violacorp.Models.Registration do

  import Ecto.Query, warn: false
  alias Violacorp.Repo

  # Step I
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Mandate

  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Addressdirectors
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Feerules

  alias Violacorp.Libraries.Commontools

  alias ViolacorpWeb.Main.AlertsController

  @doc "Registration Step One"
  def stepOne(params) do

      country_code = Application.get_env(:violacorp, :country_code)

      viola_id = Commontools.random_string(6)

      contacts = %{
        contacts: %{
          contact_number: params["company_contact"],
          code: country_code,
          is_primary: "Y",
          inserted_by: "99999"
        }
      }

      contact_params = %{
        viola_id: viola_id,
        email_id: params["email"],
        reg_step: "1",
        status: "I",
        password: params["password"],
        ip_address: params["ip_address"],
        contacts: contacts
      }

      director_params = %{
        directors: %{
          position: params["user_type"],
          title: params["title"],
          first_name: params["first_name"],
          last_name: params["last_name"],
          is_primary: "Y",
          signature: params["signature"]
        }
      }

      company = %{
        countries_id: "53",
        company_type: params["business_type"],
        company_name: params["business_name"],
        directors: director_params
      }

      changeset_commanall = Commanall.changeset_first_step(%Commanall{}, contact_params)

      changeset = Company.changeset_reg_step_one(%Company{}, company)

      bothinsert = Ecto.Changeset.put_assoc(changeset, :commanall, [changeset_commanall])

    case Repo.insert(bothinsert) do
      {:ok, _company} ->

        commanall_id = Repo.one from o in Commanall, where: o.email_id == ^params["email"], select: o.id
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)
        otpmap = %{
          "commanall_id" => commanall_id,
          "otp_code" => otp_code,
          "otp_source" => "Registration",
          "inserted_by" => commanall_id
        }
        changeset = Otp.changeset(%Otp{}, otpmap)
        case Repo.insert(changeset) do
          {:ok, _company} -> commanall = Repo.get_by(Commanall, email_id: params["email"])
                             new_step = Map.new(%{"1" => "email verify pending"})
                                        |> Poison.encode!()

                             change_step = %{
                               "reg_step" => "1",
                               "step" => "email-otp-verify",
                               "reg_data" => new_step
                             }
                             changeset_commanall = Commanall.changesetSteps(commanall, change_step)
                             case Repo.update(changeset_commanall) do
                               {:ok, _company} ->

                                 data = %{
                                   :section => "company_registration_otp",
                                   :commanall_id => commanall_id,
                                   :otp_code => "#{generate_otp}"
                                 }
                                 AlertsController.sendEmail(data)
                                 AlertsController.storeNotification(data)

                                 response = %{commanall_id: commanall_id, messages: "Success, OTP sent to user" }
                                 {:ok, response}

                               {:error, changeset} ->{:error, changeset}
                             end
          {:error, changeset} ->{:error, changeset}
        end
      {:error, changeset} ->{:error, changeset}
    end
  end

  @doc "Registration Step Two"
  def stepTwo(params) do
    getotp = Repo.one from o in Otp,
                      where: o.commanall_id == ^params["commanall_id"] and o.otp_source == "Registration",
                      select: o.otp_code
    otpdecode = Poison.decode!(getotp)

    if otpdecode["otp_code"] == params["otp_code"] do
      commanall = Repo.get(Commanall, params["commanall_id"])

      new_step = Map.new(%{"1" => "email verified"})
                 |> Poison.encode!()

      change_step = %{"reg_step" => "11", "step" => "email-otp-verify", "reg_data" => new_step}
      changeset_commanall = Commanall.changesetSteps(commanall, change_step)
      case Repo.update(changeset_commanall) do
        {:ok, _company} -> {:ok, "Success, Email verified"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:not_acceptable, "Incorrect OTP please re-enter or request a new OTP"}
    end
  end

  @doc "Registration Step Three"
  def stepThree(params) do
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
          {:ok, "VPIN inserted."}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:not_acceptable, "VPIN already set"}
    end
  end

  @doc "Registration Step Four"
  def stepFour(params) do
    commanall = Repo.get!(Commanall, params["commanall_id"])


    old_company = Repo.get!(Company, commanall.company_id)
    company = %{
      "sector_id" => params["sector_id"],
      "sector_details" => params["sector_details"],
      "monthly_transfer" => params["monthly_transfer"],
      "landline_number" => params["landline_number"],
      "date_of_registration" => params["registration_date"],
      "registration_number" => params["registration_number"],
      "company_website" => params["company_website"],
    }
    changeset = Company.changeset_reg_step_four(old_company, company)



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
            regs_data = commanall.reg_data
            new_step = Map.new(%{"2" => params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()
            change_step = %{"reg_step" => "4", "step" => "company-detail", "reg_data" => merge_steps}

            changeset_commanall = Commanall.changesetSteps(commanall, change_step)
            if changeset.valid? do
              Repo.update(changeset)
              Repo.update(changeset_commanall)
            end
            reg_step = "2"
            step = "company-detail"

            response = %{ commanall_id: commanall.id, reg_step: reg_step, step: step}
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


  end

  @doc "Registration Step Five"
  def stepFive(params) do
    commanall = Repo.get!(Commanall, params["commanall_id"])
    [find] = Repo.all from d in Directors, where: d.company_id == ^commanall.company_id and d.is_primary == "Y",
                                           select: count(d.id)

    position = String.downcase(params["position"])

    is_primary = case position do
      "owner" -> if find > 0 do "N" else "Y" end
      "director" -> if find > 0 do "N" else "Y" end
      "cap" -> "N"
    end

    [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)

    director_number = count + 1

    company = Repo.get!(Company, commanall.company_id)

    access_type = params["accesstype"]
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

      country_code = Application.get_env(:violacorp, :country_code)

      address_line_one = if is_nil(params["address_line_one"]) do
      else
        params["address_line_one"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end
      address_line_two = if is_nil(params["address_line_two"]) do
      else
        params["address_line_two"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end
      address_line_three = if is_nil(params["address_line_three"]) do
      else
        params["address_line_three"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end

      addressdirectors = %{
        addressdirectors: %{
          address_line_one: address_line_one,
          address_line_two: address_line_two,
          address_line_three: address_line_three,
          town: params["town"],
          county: params["county"],
          post_code: params["post_code"],
          countries_id: params["locationId"],
          is_primary: is_primary
        }
      }

      contactsdirectors = %{
        contactsdirectors: %{
          contact_number: params["contact_number"],
          code: country_code,
          is_primary: is_primary
        }
      }

      kycdirectors = %{
        kycdirectors: %{
          documenttype_id: params["documenttype_id"],
          document_number: params["document_number"],
          issue_date: params["issue_date"],
          expiry_date: params["expiry_date"],
          status: "D",
          type: "I"
        }
      }

      full_director_params = %{
          company_id: commanall.company_id,
          employeeids: params["employee_ids"],
          email_id: params["contact_email"],
          title: params["title"],
          position: params["position"],
          first_name: params["first_name"],
          last_name: params["last_name"],
          date_of_birth: params["date_of_birth"],
          sequence: director_number,
          access_type: params["accesstype"],
          is_primary: is_primary,
          addressdirectors: addressdirectors,
          contactsdirectors: contactsdirectors,
          kycdirectors: kycdirectors
        }

      _new_params = %{
        commanall_id: params["commanall_id"],
        employeeids: params["employee_ids"],
        email_id: params["contact_email"],
        position: params["position"],
        title: params["title"],
        first_name: params["first_name"],
        last_name: params["last_name"],
        date_of_birth: params["date_of_birth"],
        contact_number: params["contact_number"],
        address_line_one: params["address_line_one"],
        address_line_two: params["address_line_two"],
        address_line_three: params["address_line_three"],
        town: params["town"],
        county: params["county"],
        post_code: params["post_code"],
        documenttype_id: params["documenttype_id"],
        document_number: params["document_number"],
        expiry_date: params["expiry_date"],
        issue_date: params["issue_date"],
        panother: params["panother"],
        locationId: params["locationId"],
        accesstype: params["accesstype"],
        signature: params["signature"]
      }

      allinsert = if params["first"] == "Y" do
        director = Repo.get_by(Directors, company_id: commanall.company_id, sequence: "1")
        director_params =
          %{
            company_id: commanall.company_id,
            employeeids: params["employee_ids"],
            email_id: params["contact_email"],
            title: params["title"],
            position: params["position"],
            first_name: params["first_name"],
            last_name: params["last_name"],
            date_of_birth: params["date_of_birth"],
          }

        addressdirectors = %{
          directors_id: director.id,
          address_line_one: address_line_one,
          address_line_two: address_line_two,
          address_line_three: address_line_three,
          town: params["town"],
          county: params["county"],
          post_code: params["post_code"],
          countries_id: params["locationId"],
          is_primary: is_primary
        }

        contactsdirectors = %{
          directors_id: director.id,
          contact_number: params["contact_number"],
          code: country_code,
          is_primary: is_primary
        }

        kycdirectors = %{
          directors_id: director.id,
          documenttype_id: params["documenttype_id"],
          document_number: params["document_number"],
          issue_date: params["issue_date"],
          expiry_date: params["expiry_date"],
          status: "D",
          type: "I"
        }

        changeset_director = Directors.changeset_contact(director, director_params)
        changeset_addressdirector = Addressdirectors.changeset(%Addressdirectors{}, addressdirectors)
        changeset_contactdirector = Contactsdirectors.changeset(%Contactsdirectors{}, contactsdirectors)
        changeset_kycdirector = Kycdirectors.changeset(%Kycdirectors{}, kycdirectors)

        changeset_global = Directors.reg_step_five(%Directors{}, full_director_params)

        if changeset_global.valid? do
                                    Repo.update(changeset_director)
                                    Repo.insert(changeset_addressdirector)
                                    Repo.insert(changeset_contactdirector)
                                    Repo.insert(changeset_kycdirector)
          else
          {:error, changeset_global}
        end
      else
        changeset = Directors.reg_step_five(%Directors{}, full_director_params)
        if changeset.valid? do
        Repo.insert(changeset)
        else
          {:error, changeset}
        end
      end

      case allinsert do
        {:ok, _director_params} ->
          newcount = Repo.one(from d in Directors, where: d.company_id == ^commanall.company_id, limit: 1, order_by: [desc: d.inserted_at], select: %{director_id: d.id, count: count(d.company_id)})
#          reg_step = cond do
#                        company.company_type == "LTD" and newcount.count == 1 -> "42"
#                        company.company_type == "LTD" and newcount.count > 1 -> "5#{director_number}"
#                        company.company_type == "STR" and newcount.count == 1 ->  "42"
#                        company.company_type == "STR" and newcount.count > 1 -> "5#{director_number}"
#                     end

          reg_step = "IDINFO"
          step = cond do
                  company.company_type == "LTD" and newcount.count == 1 -> "company-signature"
                  company.company_type == "LTD" and newcount.count > 1 -> "company-director"
                  company.company_type == "LTD" -> "company-director"
                  company.company_type == "STR" -> "company-owner"
                end

          change_step = case params["lastdirector"] do
                          "N" -> %{"reg_step" => reg_step, "step" => step}
                          "Y" -> %{"reg_step" => reg_step, "status" => "I", "step" => step}
                        end

         changeset_commanall = Commanall.changesetSteps(commanall, change_step)

          case Repo.update(changeset_commanall) do
            {:ok, _director_params} ->
                response = %{reg_step: reg_step, step: step, sequence: director_number, director_id: newcount.director_id, messages: "Company #{params["position"]} inserted."}
                {:ok, response}
          end
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc "Registration Step Six"
  def stepSix(params) do

    commanall = Repo.get(Commanall, params["commanall_id"])

    Enum.each params["directors"], fn dir ->

      get_dir = Repo.get(Directors, dir["id"])

      allocations = %{"P" => dir["physical"], "V" => dir["virtual"]} |> Poison.encode!()

      mapit = %{"allocating_cards" => allocations}

      changeset = Directors.allocating_cards(get_dir, mapit)

      if changeset.valid? do
        Repo.update(changeset)
      else
        {:error, changeset}
      end
    end
    change_step = %{"reg_step" => "6", "step" => "cards_allocation"}
    changeset_commanall = Commanall.changesetSteps(commanall, change_step)
    Repo.update(changeset_commanall)
    {:ok, "Cards Allocated Successfully"}
  end

  @doc "Registration Step Seven"
  def stepSeven(params) do

    check = Repo.one from m in Mandate, where: m.commanall_id == ^params["commanall_id"], select: count(m.id)
    if check > 0 do
      {:not_acceptable, "Mandate already exists"}
    else
      if (
           is_nil(params["terms_of_service"]) or is_nil(params["terms_and_conditions"]) or is_nil(
             params["cookies_policy"]
           ) or is_nil(params["privacy_policy"])) or (
           params["terms_of_service"] != "yes" or params["terms_and_conditions"] != "yes" or params["cookies_policy"] != "yes" or params["privacy_policy"] != "yes") do

        {:not_acceptable, "Missing params/not ticked all checkboxes"}
      else
        mandate_data = %{
          terms_of_service: params["terms_of_service"],
          terms_and_conditions: params["terms_and_conditions"],
          cookies_policy: params["cookies_policy"],
          privacy_policy: params["privacy_policy"],
        }

        director = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                       left_join: c in assoc(cmn, :company),
                                                       left_join: director in assoc(c, :directors),
                                                       where: director.sequence == 1,
                                                       select: %{dir_id: director.id, dir_first_name: director.first_name, dir_last_name: director.last_name, c_id: c.id, c_company_name: c.company_name}

        mandate = %{
          "commanall_id" => params["commanall_id"],
          "directors_id" => director.dir_id,
          "response_data" => Poison.encode!(mandate_data),
          "inserted_by" => params["commanall_id"]
        }
        changeset = Mandate.changeset(%Mandate{}, mandate)
        case Repo.insert(changeset) do
          {:ok, _mandate} ->

            commanall = Repo.get(Commanall, params["commanall_id"])
            change_step =  %{"status" => "P", "step" => "done"}

            changeset_commanall = Commanall.changesetSteps(commanall, change_step)
            Repo.update(changeset_commanall)
            dir_full_name = "#{director.dir_first_name} #{director.dir_last_name}"
            data = %{
              :section => "registration_pending",
              :commanall_id => params["commanall_id"],
              :company_name => director.c_company_name,
              :director_name => dir_full_name,
            }
            AlertsController.sendEmail(data)
            AlertsController.storeNotification(data)

            {:ok, "Mandate inserted successfully"}
          {:error, changeset} -> {:error, changeset}
        end
      end
    end
  end

  def directorsList(params) do
    directors = Repo.all from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                left_join: c in assoc(cmn, :company),
                                                left_join: d in assoc(c, :directors),
                                                select: %{id: d.id, position: d.position, title: d.title, first_name: d.first_name, last_name: d.last_name}
    {:ok, directors}
  end


  def firstDirector(params) do
    directors = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                left_join: c in assoc(cmn, :company),
                                                left_join: d in assoc(c, :directors),
                                                where: d.sequence == 1,
                                                select: %{id: d.id, position: d.position, title: d.title, first_name: d.first_name, last_name: d.last_name}
    {:ok, directors}
  end

  def monthlyFeeRule do
    fee_rule = Repo.one from f in Feerules, where: f.id == 1 and f.status == "A" and f.type == "M",
                                                select: %{id: f.id, monthly_fee: f.monthly_fee, per_card_fee: f.per_card_fee, minimum_card: f.minimum_card, vat: f.vat, status: f.status, type: f.type}
    {:ok, fee_rule}
  end
end
