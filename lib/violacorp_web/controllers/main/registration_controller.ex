defmodule ViolacorpWeb.Main.RegistrationController do
  use ViolacorpWeb, :controller
  alias Violacorp.Repo
  import Ecto.Query

  # Step I
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp

  # Step II
  alias Violacorp.Schemas.Address

  # Step III
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Addressdirectors
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Kycdirectors

  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController
  alias Violacorp.Libraries.Commontools


  @doc "Company Registration { Step-1 }"
  def companyNew(conn, params) do
    unless map_size(params) == 0 do
      commanall = Repo.get_by(Commanall, email_id: params["email"])

      if commanall do
        json conn, %{status_code: "202", messages: "Email Id already exist."}
      else

        country_code = Application.get_env(:violacorp, :country_code)

        contacts = %{
          contacts: %{
            contact_number: params["company_contact"],
            code: country_code,
            is_primary: "Y",
            inserted_by: "99999"
          }
        }

        viola_id = Commontools.random_string(6)
        reg_data = Poison.encode!%{
          "1" => %{
            "email_id" => params["email"],
            "company_contact" => params["company_contact"]
          }
        }
        ex_ip_address = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
        ht_ip_address = get_req_header(conn, "ip_address")|> List.first
        new_ip_address = %{ex_ip: ex_ip_address, ht_ip: ht_ip_address} |> Poison.encode!()

        contact_params = %{
          viola_id: viola_id,
          email_id: params["email"],
          reg_data: reg_data,
          reg_step: "1",
          status: "I",
          password: params["password"],
          vpin: params["vpin"],
          ip_address: new_ip_address,
          contacts: contacts
        }
        changeset_commanall = Commanall.changeset_first_step(%Commanall{}, contact_params)

        company = %{
          "countries_id" => "53"
        }
        changeset = Company.changeset_empty(%Company{}, company)

        bothinsert = Ecto.Changeset.put_assoc(changeset, :commanall, [changeset_commanall])

        case Repo.insert(bothinsert) do
          {:ok, _company} ->

            commanall_id = Repo.one from o in Commanall, where: o.email_id == ^params["email"], select: o.id
            generate_otp = Commontools.randnumber(6)
            otp_code_map = %{"otp_code" => generate_otp, "otp_attempt" => 3}
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
                                       :otp_code => generate_otp
                                     }
                                     AlertsController.sendEmail(data)
                                     AlertsController.storeNotification(data)
                                     json conn,
                                          %{
                                            status_code: "200",
                                            commanall_id: commanall_id,
                                            messages: "Success, OTP sent to user"
                                          }
                                   {:error, changeset} ->
                                     conn
                                     |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                                 end
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Registration OTP Verify {Step-1}"
  def companyNewVerify(conn, params) do
    unless map_size(params) == 0 do
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
          {:ok, _company} ->
            json conn, %{status_code: "200", messages: "Success, Email verified"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4003", errors: "Incorrect OTP please re-enter or request a new OTP"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Details Registration {Step-2}"
  def companyDetails(conn, params) do
    unless map_size(params) == 0 do

      commanall = Repo.get!(Commanall, params["commanall_id"])

      company_name = if is_nil(params["company_name"]) do
      else
        params["company_name"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end

      old_company = Repo.get!(Company, commanall.company_id)
      company = %{
        "countries_id" => params["locationId"],
        "company_type" => params["company_type"],
        "company_name" => company_name,
        "registration_number" => params["registration_number"],
        "date_of_registration" => params["registration_date"],
        "landline_number" => params["landline_number"]
      }
      changeset = Company.changeset(old_company, company)

      regs_data = commanall.reg_data
      new_step = Map.new(%{"2" => params})
      old_step = Poison.decode!(regs_data)
      merge_steps = Map.merge(old_step, new_step)
                    |> Poison.encode!()
      change_step = case params["edit"] do
        "No" -> %{"reg_step" => "2", "step" => "company-detail", "reg_data" => merge_steps}
        "Yes" -> %{"reg_data" => merge_steps}
      end
      changeset_commanall = Commanall.changesetSteps(commanall, change_step)

      reg_step = "2"
      step = "company-detail"

      output = %{
        status_code: "200",
        company_name: params["company_name"],
        registration_number: params["registration_number"],
        company_type: params["company_type"],
        date_of_registration: params["registration_date"],
        commanall_id: commanall.id,
        reg_step: reg_step,
        step: step
      }

      if changeset.valid? do
        Repo.update(changeset)
        Repo.update(changeset_commanall)

        json conn, output
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Registered Address Registration {Step-3}"
  def companyAddressContact(conn, params) do
    unless map_size(params) == 0 do
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
      county = if is_nil(params["county"]) do
      else
        params["county"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end

      if is_nil(params["edit"]) or params["edit"] == "No" do

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
          "countries_id" => params["locationId"],
          "post_code" => params["post_code"],
          "town" => params["town"],
          "county" => county,
          "is_primary" => is_primary,
          "sequence" => address_number
        }
        changeset_address = Address.changeset(%Address{}, address)

        if changeset_address.valid? do


            # update company schema
            commanall = Repo.get!(Commanall, params["commanall_id"])
            company = Repo.get!(Company, commanall.company_id)

            company_website = %{"company_website" => params["company_website"]}
            changeset = Company.changesetWebsite(company, company_website)


            regs_data = commanall.reg_data
            new_step = Map.new(%{"3" => params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()

            reg_step = "3"

            step = "company-address"

            change_step = %{"reg_step" => reg_step, "step" => step, "reg_data" => merge_steps}

            changeset_commanall = Commanall.changesetSteps(commanall, change_step)

            if changeset.valid? do
              Repo.update(changeset)
              Repo.insert(changeset_address)
              Repo.update(changeset_commanall)
              json conn,
                   %{
                     status_code: "200",
                     reg_step: reg_step,
                     step: step,
                     messages: "Company address inserted."
                   }
            else
              render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
        else
          render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset_address)
        end
      else
        get_address = Repo.get_by(Address, commanall_id: params["commanall_id"], sequence: 1)

        address = %{
          "commanall_id" => params["commanall_id"],
          "address_line_one" => address_line_one,
          "address_line_two" => address_line_two,
          "address_line_three" => address_line_three,
          "countries_id" => params["locationId"],
          "post_code" => params["post_code"],
          "town" => params["town"],
          "county" => county,
          "is_primary" => "Y",
          "sequence" => 1
        }
        changeset_address = Address.changeset(get_address, address)

        if changeset_address.valid? do


            # update company schema
            commanall = Repo.get!(Commanall, params["commanall_id"])
            company = Repo.get!(Company, commanall.company_id)
            company_website = %{"company_website" => params["company_website"]}
            changeset = Company.changesetWebsite(company, company_website)

            regs_data = commanall.reg_data
            new_step = Map.new(%{"3" => params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()

            change_step = %{"reg_data" => merge_steps}
            reg_step = "3"

            step = "company-address"

            changeset_commanall = Commanall.changesetSteps(commanall, change_step)

            if changeset.valid? do
              Repo.update(changeset)
              Repo.update(changeset_address)
              Repo.update(changeset_commanall)
              json conn,
                   %{status_code: "200", reg_step: reg_step, step: step, messages: "Company address Updated."}
            else
              render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
        else
          render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset_address)
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Trading Address {Step-41}"
  def companyAddress(conn, params) do
    unless map_size(params) == 0 do
      commanall = Repo.get!(Commanall, params["commanall_id"])

      [count] = Repo.all from a in Address, where: a.commanall_id == ^params["commanall_id"],
                                            select: count(a.commanall_id)

      address_number = count + 1

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
      county = if is_nil(params["county"]) do
      else
        params["county"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end

      address = %{
        "commanall_id" => params["commanall_id"],
        "address_line_one" => address_line_one,
        "address_line_two" => address_line_two,
        "address_line_three" => address_line_three,
        "countries_id" => params["locationId"],
        "town" => params["town"],
        "county" => county,
        "post_code" => params["post_code"],
        "sequence" => address_number,
        "is_primary" => "N"

      }
      if is_nil(params["edit"]) or params["edit"] == "No" do
        changeset = Address.changeset(%Address{}, address)

        case Repo.insert(changeset) do
          {:ok, _address} ->
            regs_data = commanall.reg_data
            new_step = Map.new(%{"41" => params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()
            reg_step = "41"

            step = "company-trading-address"

            change_step = %{"reg_step" => reg_step, "step" => step, "reg_data" => merge_steps}

            changeset_commanall = Commanall.changesetSteps(commanall, change_step)

            case Repo.update(changeset_commanall) do
              {:ok, _address} ->
                json conn, %{status_code: "200", reg_step: reg_step, step: step, messages: "Company address inserted."}

              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        get_address = Repo.get_by(Address, commanall_id: params["commanall_id"], is_primary: "N")
        if is_nil(get_address) do
          json conn, %{status_code: "4003", messages: "No existing trading address."}
        else

          changeset = Address.changeset(get_address, address)

          case Repo.update(changeset) do
            {:ok, _address} ->
              regs_data = commanall.reg_data
              new_step = Map.new(%{"41" => params})
              old_step = Poison.decode!(regs_data)
              merge_steps = Map.merge(old_step, new_step)
                            |> Poison.encode!()

              change_step = %{"reg_data" => merge_steps}

              changeset_commanall = Commanall.changesetSteps(commanall, change_step)

              step = "company-trading-address"
              case Repo.update(changeset_commanall) do
                {:ok, _address} ->
                  json conn, %{status_code: "200", reg_step: "41", step: step, messages: "Company address inserted."}

                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end

      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Directors Registration {Step-5 & Step-51}"
  def companyDirectors(conn, params) do
    unless map_size(params) == 0 do

      commanall = Repo.get!(Commanall, params["commanall_id"])

      [find] = Repo.all from d in Directors, where: d.company_id == ^commanall.company_id and d.is_primary == "Y",
                                             select: count(d.id)

      position = String.downcase(params["position"])
      is_primary = case position do
        "owner" -> if find > 0 do
                     "N"
                   else
                     "Y"
                   end
        "director" -> if find > 0 do
                        "N"
                      else
                        "Y"
                      end
        "cap" -> "N"
      end

      [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)

      director_number = if params["edit"] == "No" do
        count + 1
      else
        count
      end

      company = Repo.get!(Company, commanall.company_id)
      access_type = params["accesstype"]
      check_position = if company.company_type == "STR" do
        if position == "owner" do
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
        json conn, %{status_code: "4003", messages: check_position}
      else

        country_code = Application.get_env(:violacorp, :country_code)

        # image upload for address and id proof
        file_location_address = if params["image_address"] != "" do
          image_address = "#{params["image_address"]}"
          ViolacorpWeb.Main.Assetstore.upload_image(image_address)
        else
          nil
        end

        file_location_id = if params["image_id"] != "" do
          image_id = "#{params["image_id"]}"
          ViolacorpWeb.Main.Assetstore.upload_image(image_id)
        else
          nil
        end

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
            file_location: file_location_id,
            status: "D",
            type: "I"
          }
        }

        kycdirectorsaddress = %{
          kycdirectors: %{
            documenttype_id: params["documenttype_addressid"],
            file_location: file_location_address,
            status: "D",
            type: "A"
          }
        }

        director_params = if (params["documenttype_addressid"] == "" or is_nil(params["documenttype_addressid"])) or (
          params["image_address"] == "" or is_nil(params["image_address"]))  do
          %{
            company_id: commanall.company_id,
            employeeids: params["employee_ids"],
            email_id: params["contact_email"],
            title: params["title"],
            position: params["position"],
            first_name: params["first_name"],
            last_name: params["last_name"],
            date_of_birth: params["date_of_birth"],
            signature: params["signature"],
            sequence: director_number,
            access_type: params["accesstype"],
            is_primary: is_primary,
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors
          }
        else
          %{
            company_id: commanall.company_id,
            employeeids: params["employee_ids"],
            email_id: params["contact_email"],
            title: params["title"],
            position: params["position"],
            first_name: params["first_name"],
            last_name: params["last_name"],
            date_of_birth: params["date_of_birth"],
            signature: params["signature"],
            sequence: director_number,
            access_type: params["accesstype"],
            is_primary: is_primary,
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors,
            kycdirectorsaddress: kycdirectorsaddress
          }
        end


        new_params = %{
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
          documenttype_addressid: params["documenttype_addressid"],
          signature: params["signature"]
        }

        if is_nil(params["edit"]) or params["edit"] == "No" do
          director_exists = Repo.get_by(Directors, company_id: commanall.company_id, first_name: params["first_name"], last_name: params["last_name"], date_of_birth: params["date_of_birth"])

          if is_nil(director_exists) do
          allinsert = Directors.changeset_contact(%Directors{}, director_params)

          case Repo.insert(allinsert) do
            {:ok, _director_params} ->
              [newcount] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id,
                                                         select: count(a.company_id)


              regs_data = commanall.reg_data
              new_step = if company.company_type == "LTD" or "PLC" do
                if newcount == 1 do
                  Map.new(%{"42" => new_params})
                else
                  Map.new(%{"5#{director_number}" => new_params})
                end
              else
                if company.company_type == "STR" do
                  if newcount == 1 do
                    Map.new(%{"42" => new_params})
                  else
                    Map.new(%{"5#{director_number}" => new_params})
                  end
                end
              end

              old_step = Poison.decode!(regs_data)
              merge_steps = Map.merge(old_step, new_step)
                            |> Poison.encode!()
              reg_step = if company.company_type == "LTD" or company.company_type == "PLC" do
                if newcount == 1 do
                  "42"
                else
                  if newcount > 1 do
                    "5#{director_number}"
                  end
                end
              else
                if company.company_type == "STR" do
                  if newcount == 1 do
                    "42"
                  else
                    if newcount > 1 do
                      "5#{director_number}"
                    end
                  end
                end
              end


              step = if company.company_type == "LTD" or company.company_type == "PLC" do
                if newcount == 1 do
                  "company-signature"
                else
                  if newcount > 1 do
                    "company-director"
                  end
                end
              else
                "company-director"
              end

              change_step = case params["lastdirector"] do
                "N" -> %{"reg_step" => reg_step, "reg_data" => merge_steps, "step" => step}
                "Y" -> %{"reg_step" => reg_step, "reg_data" => merge_steps, "status" => "P", "step" => step}
              end

              changeset_commanall = Commanall.changesetSteps(commanall, change_step)
              case Repo.update(changeset_commanall) do
                {:ok, _director_params} ->
                  if params["lastdirector"] == "Y" do
                    getcompany = Repo.get(Company, commanall.company_id)
                    getdirector = Repo.get_by(Directors, company_id: commanall.company_id, sequence: "1")
                    dir_full_name = "#{getdirector.first_name} #{getdirector.last_name}"
                    data = %{
                      :section => "registration_pending",
                      :commanall_id => commanall.id,
                      :company_name => getcompany.company_name,
                      :director_name => dir_full_name,
                    }
                    AlertsController.sendEmail(data)
                    AlertsController.sendNotification(data)
                    AlertsController.sendSms(data)
                    AlertsController.storeNotification(data)
                  end
                  json conn,
                       %{
                         status_code: "200",
                         reg_step: reg_step,
                         step: step,
                         sequence: director_number,
                         messages: "Company #{params["position"]} inserted."
                       }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end

            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
          else
            json conn, %{status_code: "4003", message: "Director already exists for this company"}
          end

        else

          get_directors = Repo.get_by(Directors, company_id: commanall.company_id, sequence: params["sequence"])
          get_addressdirectors = Repo.get_by(Addressdirectors, directors_id: get_directors.id)
          get_contactsdirectors = Repo.get_by(Contactsdirectors, directors_id: get_directors.id)
          get_kycdirectors_id = Repo.get_by(Kycdirectors, directors_id: get_directors.id, type: "I")
          get_kycdirectors_address = Repo.get_by(Kycdirectors, directors_id: get_directors.id, type: "A")

          new_director_params =
            %{
              company_id: commanall.company_id,
              employeeids: params["employee_ids"],
              email_id: params["contact_email"],
              title: params["title"],
              position: params["position"],
              first_name: params["first_name"],
              last_name: params["last_name"],
              date_of_birth: params["date_of_birth"],
              signature: params["signature"],
              sequence: get_directors.sequence,
              access_type: params["accesstype"],
              is_primary: get_directors.is_primary
            }

          addressdirectors = %{
            address_line_one: address_line_one,
            address_line_two: address_line_two,
            address_line_three: address_line_three,
            post_code: params["post_code"],
            countries_id: params["locationId"],
            is_primary: get_addressdirectors.is_primary
          }

          contactsdirectors = %{
            contact_number: params["contact_number"],
            code: country_code,
            is_primary: get_contactsdirectors.is_primary
          }

          kycdirectors = %{
            documenttype_id: params["documenttype_id"],
            document_number: params["document_number"],
            issue_date: params["issue_date"],
            expiry_date: params["expiry_date"],
            file_location: file_location_id,
            status: "D",
            type: "I"
          }

          kycdirectorsaddress = %{
            documenttype_id: params["documenttype_addressid"],
            file_location: file_location_address,
            status: "D",
            type: "A"
          }


          update_director = Directors.changeset(get_directors, new_director_params)
          update_addressdirectors = Addressdirectors.changeset(get_addressdirectors, addressdirectors)
          update_contactsdirectors = Contactsdirectors.changeset(get_contactsdirectors, contactsdirectors)
          update_kycdirectors_id = Kycdirectors.changeset(get_kycdirectors_id, kycdirectors)
          update_kycdirectors_address = if get_kycdirectors_address do
            Kycdirectors.changeset(get_kycdirectors_address, kycdirectorsaddress)
          end
          if update_director.valid? do
            Repo.update(update_director)
            Repo.update(update_addressdirectors)
            Repo.update(update_contactsdirectors)
            Repo.update(update_kycdirectors_id)
            if get_kycdirectors_address do
              Repo.update(update_kycdirectors_address)
            end
            regs_data = commanall.reg_data
            new_step = Map.new(%{"#{commanall.reg_step}" => new_params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()
            reg_step = "#{commanall.reg_step}"
            change_step = case params["lastdirector"] do
              "N" -> %{"reg_data" => merge_steps}
              "Y" -> %{"reg_data" => merge_steps, "status" => "P"}
            end
            changeset_commanall = Commanall.changesetSteps(commanall, change_step)
            case Repo.update(changeset_commanall) do
              {:ok, _director_params} ->
                if params["lastdirector"] == "Y" do
                  getcompany = Repo.get(Company, commanall.company_id)
                  getdirector = Repo.get_by(Directors, company_id: commanall.company_id, sequence: "1")
                  dir_full_name = "#{getdirector.first_name} #{getdirector.last_name}"
                  data = %{
                    :section => "registration_pending",
                    :commanall_id => commanall.id,
                    :company_name => getcompany.company_name,
                    :director_name => dir_full_name,
                  }
                  AlertsController.sendEmail(data)
                  AlertsController.sendNotification(data)
                  AlertsController.sendSms(data)
                  AlertsController.storeNotification(data)
                end
                json conn,
                     %{
                       status_code: "200",
                       reg_step: reg_step,
                       step: "company-director",
                       sequence: get_directors.sequence,
                       messages: "Company #{params["position"]} UPDATED."
                     }
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          end
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def companyDirectorsNew(conn, params) do
    unless map_size(params) == 0 do
      commanall = Repo.get!(Commanall, params["commanall_id"])

      [find] = Repo.all from d in Directors, where: d.company_id == ^commanall.company_id and d.is_primary == "Y",
                                             select: count(d.id)

      position = String.downcase(params["position"])
      is_primary = case position do
        "owner" -> if find > 0 do
                     "N"
                   else
                     "Y"
                   end
        "director" -> if find > 0 do
                        "N"
                      else
                        "Y"
                      end
        "cap" -> "N"
      end

      [count] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id, select: count(a.company_id)

      director_number = if params["edit"] == "No" do
        count + 1
      else
        count
      end

      company = Repo.get!(Company, commanall.company_id)

      access_type = params["accesstype"]
      check_position = if company.company_type == "STR" do
        if position == "owner" do
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
        json conn, %{status_code: "4003", messages: check_position}
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

#        kycdirectorsaddress = %{
#          kycdirectors: %{
#            documenttype_id: params["documenttype_addressid"],
#            status: "D",
#            type: "A"
#          }
#        }

        director_params =
#          if (params["documenttype_addressid"] == "" or is_nil(params["documenttype_addressid"]))  do
          %{
            company_id: commanall.company_id,
            employeeids: params["employee_ids"],
            email_id: params["contact_email"],
            title: params["title"],
            position: params["position"],
            first_name: params["first_name"],
            last_name: params["last_name"],
            date_of_birth: params["date_of_birth"],
            signature: params["signature"],
            sequence: director_number,
            access_type: params["accesstype"],
            is_primary: is_primary,
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors
          }
#        else
#          %{
#            company_id: commanall.company_id,
#            employeeids: params["employee_ids"],
#            email_id: params["contact_email"],
#            title: params["title"],
#            position: params["position"],
#            first_name: params["first_name"],
#            last_name: params["last_name"],
#            date_of_birth: params["date_of_birth"],
#            signature: params["signature"],
#            sequence: director_number,
#            access_type: params["accesstype"],
#            is_primary: is_primary,
#            addressdirectors: addressdirectors,
#            contactsdirectors: contactsdirectors,
#            kycdirectors: kycdirectors,
#            kycdirectorsaddress: kycdirectorsaddress
#          }
#        end


        new_params = %{
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
#          documenttype_addressid: params["documenttype_addressid"],
          signature: params["signature"]
        }

        if is_nil(params["edit"]) or params["edit"] == "No" do

          allinsert = Directors.changeset_contact(%Directors{}, director_params)

          case Repo.insert(allinsert) do
            {:ok, _director_params} ->
              [newcount] = Repo.all from a in Directors, where: a.company_id == ^commanall.company_id,
                                                         select: count(a.company_id)


              regs_data = commanall.reg_data
              new_step = if company.company_type == "LTD" or "PLC" do
                if newcount == 1 do
                  Map.new(%{"42" => new_params})
                else
                  Map.new(%{"5#{director_number}" => new_params})
                end
              else
                if company.company_type == "STR" do
                  if newcount == 1 do
                    Map.new(%{"42" => new_params})
                  else
                    Map.new(%{"5#{director_number}" => new_params})
                  end
                end
              end

              old_step = Poison.decode!(regs_data)
              merge_steps = Map.merge(old_step, new_step)
                            |> Poison.encode!()
              reg_step = if company.company_type == "LTD" or company.company_type == "PLC" do
                if newcount == 1 do
                  "42"
                else
                  if newcount > 1 do
                    "5#{director_number}"
                  end
                end
              else
                if company.company_type == "STR" do
                  if newcount == 1 do
                    "42"
                  else
                    if newcount > 1 do
                      "5#{director_number}"
                    end
                  end
                end
              end


              step = if company.company_type == "LTD" or company.company_type == "PLC" do
                if newcount == 1 do
                  "company-signature"
                else
                  if newcount > 1 do
                    "company-director"
                  end
                end
              else
                "company-director"
              end

              change_step = case params["lastdirector"] do
                "N" -> %{"reg_step" => reg_step, "reg_data" => merge_steps, "step" => step}
                "Y" -> %{"reg_step" => reg_step, "reg_data" => merge_steps, "status" => "P", "step" => step}
              end

              changeset_commanall = Commanall.changesetSteps(commanall, change_step)
              case Repo.update(changeset_commanall) do
                {:ok, _director_params} ->
                  if params["lastdirector"] == "Y" do
                    getcompany = Repo.get(Company, commanall.company_id)
                    getdirector = Repo.get_by(Directors, company_id: commanall.company_id, sequence: "1")
                    dir_full_name = "#{getdirector.first_name} #{getdirector.last_name}"
                    data = %{
                      :section => "registration_pending",
                      :commanall_id => commanall.id,
                      :company_name => getcompany.company_name,
                      :director_name => dir_full_name,
                    }
                    AlertsController.sendEmail(data)
                    AlertsController.sendNotification(data)
                    AlertsController.sendSms(data)
                    AlertsController.storeNotification(data)
                  end
                  json conn,
                       %{
                         status_code: "200",
                         reg_step: reg_step,
                         step: step,
                         sequence: director_number,
                         messages: "Company #{params["position"]} inserted."
                       }
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end

            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end

        else

          get_directors = Repo.get_by(Directors, company_id: commanall.company_id, sequence: params["sequence"])
          get_addressdirectors = Repo.get_by(Addressdirectors, directors_id: get_directors.id)
          get_contactsdirectors = Repo.get_by(Contactsdirectors, directors_id: get_directors.id)
          get_kycdirectors_id = Repo.get_by(Kycdirectors, directors_id: get_directors.id, type: "I")
#          get_kycdirectors_address = Repo.get_by(Kycdirectors, directors_id: get_directors.id, type: "A")

          new_director_params =
            %{
              company_id: commanall.company_id,
              employeeids: params["employee_ids"],
              email_id: params["contact_email"],
              title: params["title"],
              position: params["position"],
              first_name: params["first_name"],
              last_name: params["last_name"],
              date_of_birth: params["date_of_birth"],
              signature: params["signature"],
              sequence: get_directors.sequence,
              access_type: params["accesstype"],
              is_primary: get_directors.is_primary
            }

          addressdirectors = %{
            address_line_one: address_line_one,
            address_line_two: address_line_two,
            address_line_three: address_line_three,
            post_code: params["post_code"],
            countries_id: params["locationId"],
            is_primary: get_addressdirectors.is_primary
          }

          contactsdirectors = %{
            contact_number: params["contact_number"],
            code: country_code,
            is_primary: get_contactsdirectors.is_primary
          }

          kycdirectors = %{
            documenttype_id: params["documenttype_id"],
            document_number: params["document_number"],
            issue_date: params["issue_date"],
            expiry_date: params["expiry_date"],
            status: "D",
            type: "I"
          }

#          kycdirectorsaddress = %{
#            documenttype_id: params["documenttype_addressid"],
#            status: "D",
#            type: "A"
#          }


          update_director = Directors.changeset(get_directors, new_director_params)
          update_addressdirectors = Addressdirectors.changeset(get_addressdirectors, addressdirectors)
          update_contactsdirectors = Contactsdirectors.changeset(get_contactsdirectors, contactsdirectors)
          update_kycdirectors_id = Kycdirectors.changeset(get_kycdirectors_id, kycdirectors)
#          update_kycdirectors_address = if get_kycdirectors_address do
#            Kycdirectors.changeset(get_kycdirectors_address, kycdirectorsaddress)
#          end
          if update_director.valid? do
            Repo.update(update_director)
            Repo.update(update_addressdirectors)
            Repo.update(update_contactsdirectors)
            Repo.update(update_kycdirectors_id)
#            if get_kycdirectors_address do
#              Repo.update(update_kycdirectors_address)
#            end
            regs_data = commanall.reg_data
            new_step = Map.new(%{"#{commanall.reg_step}" => new_params})
            old_step = Poison.decode!(regs_data)
            merge_steps = Map.merge(old_step, new_step)
                          |> Poison.encode!()
            reg_step = "#{commanall.reg_step}"
            change_step = case params["lastdirector"] do
              "N" -> %{"reg_data" => merge_steps}
              "Y" -> %{"reg_data" => merge_steps, "status" => "P"}
            end
            changeset_commanall = Commanall.changesetSteps(commanall, change_step)
            case Repo.update(changeset_commanall) do
              {:ok, _director_params} ->
                if params["lastdirector"] == "Y" do
                  getcompany = Repo.get(Company, commanall.company_id)
                  getdirector = Repo.get_by(Directors, company_id: commanall.company_id, sequence: "1")
                  dir_full_name = "#{getdirector.first_name} #{getdirector.last_name}"
                  data = %{
                    :section => "registration_pending",
                    :commanall_id => commanall.id,
                    :company_name => getcompany.company_name,
                    :director_name => dir_full_name,
                  }
                  AlertsController.sendEmail(data)
                  AlertsController.sendNotification(data)
                  AlertsController.sendSms(data)
                  AlertsController.storeNotification(data)
                end
                json conn,
                     %{
                       status_code: "200",
                       reg_step: reg_step,
                       step: "company-director",
                       sequence: get_directors.sequence,
                       messages: "Company #{params["position"]} UPDATED."
                     }
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          end
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def uploadKyc(conn, params) do
    unless map_size(params) == 0 do
      #    url = "https://violacorp-docs.s3.eu-west-2.amazonaws.com/d18bfd12185547c89a4e1b1b23e5b96d.jpg"
      #
      #    newdt = url
      #            |> String.split("/", trim: true)
      #
      #    String path = newdt.getPath();
      #    String idStr = path.substring(path.lastIndexOf('/') + 1);
      #    IO.inspect(newdt)
      #    text conn, filename

      image_base64 = "#{params["image_base64"]}"
      s3_url = ViolacorpWeb.Main.Assetstore.upload_image(image_base64)
      conn
      |> put_status(201)
      |> json(%{"url" => s3_url})
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def get_or_create_address(attrs) do
    Repo.insert!(Address.changeset(%Address{}, attrs))
  end

  def resend_registration_otp(conn, params) do
    unless map_size(params) == 0 do
      getinfo = Repo.one from o in Otp,
                         where: o.commanall_id == ^params["commanall_id"] and o.otp_source == "Registration",
                         select: %{
                           commanall_id: o.commanall_id,
                           otp_code: o.otp_code,
                           otp_source: o.otp_source,
                           updated_at: o.updated_at
                         }
      otp_code_attempt = Poison.decode!(getinfo.otp_code)

      if otp_code_attempt["otp_attempt"] == 0 do

        current_datetime = NaiveDateTime.utc_now()
        diff = NaiveDateTime.diff(current_datetime, getinfo.updated_at)

        if diff >= 1800 do
            generate_otp = Commontools.randnumber(6)

                  otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 2}
                  new_otp = Poison.encode!(otp_code_map)

                  oldotp = Repo.get_by!(Otp, commanall_id: params["commanall_id"], otp_source: "Registration")
                  email_id = Repo.one(from c in Commanall, where: c.id == ^getinfo.commanall_id, select: c.email_id)
                  otpmap = %{
                    "commanall_id" => getinfo.commanall_id,
                    "otp_code" => new_otp,
                    "otp_source" => getinfo.otp_source
                  }
                  changeset = Otp.attempt_changeset(oldotp, otpmap)

                  case Repo.update(changeset) do
                    {:ok, _otpmap} ->
                      data = %{
                        :section => "resend_registration_otp",
                        :commanall_id => getinfo.commanall_id,
                        :generate_otp => generate_otp
                      }
                      AlertsController.storeNotification(data)
                        data = [%{
                          section: "resend_registration_otp",
                          type: "E",
                          email_id: email_id,
                          data: %{:otp_code => generate_otp}  # Content
                        }]
                        V2AlertsController.main(data)
                      json conn, %{status_code: "200", messages: "OTP resent Successfully"}
                    {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
          else
              json conn, %{status_code: "4004", errors: %{message: "No more attempts left, please contact customer support"}}
          end
      else
        if otp_code_attempt["otp_attempt"] == 1 or otp_code_attempt["otp_attempt"] == 2 or otp_code_attempt["otp_attempt"] == 3 do

          reduced_attempt = otp_code_attempt["otp_attempt"] - 1

          generate_otp = Commontools.randnumber(6)

          otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => reduced_attempt}
          new_otp = Poison.encode!(otp_code_map)

          email_id = Repo.one(from c in Commanall, where: c.id == ^getinfo.commanall_id, select: c.email_id)
          oldotp = Repo.get_by!(Otp, commanall_id: params["commanall_id"], otp_source: "Registration")
          otpmap = %{
            "commanall_id" => getinfo.commanall_id,
            "otp_code" => new_otp,
            "otp_source" => getinfo.otp_source
          }
          changeset = Otp.attempt_changeset(oldotp, otpmap)

          case Repo.update(changeset) do
            {:ok, _otpmap} ->
              data = %{
                :section => "resend_registration_otp",
                :commanall_id => getinfo.commanall_id,
                :generate_otp => generate_otp
              }
              AlertsController.storeNotification(data)
              data = [%{
                section: "resend_registration_otp",
                type: "E",
                email_id: email_id,
                data: %{:otp_code => generate_otp}  # Content
              }]
              V2AlertsController.main(data)
              json conn, %{status_code: "200", messages: "OTP resent Successfully"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end
end
