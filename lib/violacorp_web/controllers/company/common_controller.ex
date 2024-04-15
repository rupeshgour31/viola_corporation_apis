defmodule ViolacorpWeb.Company.CommonController do
  use ViolacorpWeb, :controller
  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Addressdirectors
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Resendmailhistory
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools
  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController



  # Send again mail
  def resendEmail(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    employee_id = params["employeeId"]
    password = Commontools.generate_password()

    commanall = Repo.get_by!(Commanall, employee_id: employee_id)
    change_password = %{password: password}
    changeset = Commanall.changeset_updatepassword(commanall, change_password)

    case Repo.update(changeset) do
      {:ok, _response} ->
        employee = Repo.get!(Employee, employee_id)
        getcompany = Repo.get!(Company, compid)
        getemployee = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employee_id,
                                                      left_join: m in assoc(cmn, :contacts),
                                                      on: m.is_primary == "Y",
                                                      left_join: d in assoc(cmn, :devicedetails),
                                                      on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                      select: %{
                                                        id: cmn.id,
                                                        email_id: cmn.email_id,
                                                        as_login: cmn.as_login,
                                                        code: m.code,
                                                        contact_number: m.contact_number,
                                                        token: d.token,
                                                        token_type: d.type,
                                                      }
        resendmailhistory = %{
          "commanall_id" => commanid,
          "employee_id" => getemployee.id,
          "section" => "Resend password with welcome email",
          "type" => "C",
          "inserted_by" => commanid
        }
        changeset_history = Resendmailhistory.changeset(%Resendmailhistory{}, resendmailhistory)
        Repo.insert(changeset_history)

        #        # ALERTS DEPRECATED
        #        data = %{
        #          :section => "addemployee",
        #          :commanall_id => getemployee.id,
        #          :employee_name => "#{employee.first_name} #{employee.last_name}",
        #          :company_name => getcompany.company_name,
        #          :pswd => password
        #        }
        #        AlertsController.sendEmail(data)
        #        AlertsController.sendNotification(data)
        #        AlertsController.sendSms(data)
        #        AlertsController.storeNotification(data)

        data = [
          %{
            section: "addemployee",
            type: "E",
            email_id: getemployee.email_id,
            data: %{
              :email => getemployee.email_id,
              :employee_name => "#{employee.first_name} #{employee.last_name}",
              :company_name => getcompany.company_name,
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
              :company_name => getcompany.company_name
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
        V2AlertsController.main(data)

        message = "Request to join ViolaCorporate sent to #{employee.first_name} #{employee.last_name}"
        notification_details = %{
          "commanall_id" => commanid,
          "subject" => "addemployee",
          "message" => message,
          "inserted_by" => commanid
        }


        insert = Notifications.changeset(%Notifications{}, notification_details)
        Repo.insert(insert)
        json conn, %{status_code: "200", response: "Resend email successfully"}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  # Send again mail
  def adminresendEmail(conn, params) do

    sec_password = params["sec_password"]
    username = params["username"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      employee_id = params["employeeId"]
      session_id = params["sessionId"]
      password = Commontools.random_string(6)
      employee = Repo.get!(Employee, employee_id)
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
            "inserted_by" => session_id
          }
          changeset_history = Resendmailhistory.changeset(%Resendmailhistory{}, resendmailhistory)
          Repo.insert(changeset_history)
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
          company = Repo.get(Company, company_id)

          #            # ALERTS DEPRECATED
          #            data = %{
          #              :section => "addemployee",
          #              :commanall_id => commanall.id,
          #              :employee_name => "#{employee.first_name} #{employee.last_name}",
          #              :company_name => getcompany.company_name,
          #              :pswd => password
          #            }
          #            AlertsController.sendEmail(data)
          #            AlertsController.sendNotification(data)
          #            AlertsController.sendSms(data)
          #            AlertsController.storeNotification(data)

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
          V2AlertsController.main(data)
          message = "Request to join ViolaCorporate re-sent to #{employee.first_name} #{employee.last_name}"
          notification_details = %{
            "commanall_id" => com_commanall_id.id,
            "subject" => "addemployee",
            "message" => message,
            "inserted_by" => com_commanall_id.id
          }

          insert = Notifications.changeset(%Notifications{}, notification_details)
          Repo.insert(insert)
          json conn, %{status_code: "200", response: "Resend email successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end


  # Add new director
  def addDirector(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]
    unless map_size(params) == 0 do

      country_code = Application.get_env(:violacorp, :country_code)

      company = Repo.get!(Company, compid)
      access_type = params["accesstype"]
      position = params["position"]

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
        # image upload for address and id proof
        file_address_extension = params["file_address_extension"]
        file_location_address = if params["image_address"] != "" do
          image_address = "#{params["image_address"]}"
          if file_address_extension == "pdf" do
            ViolacorpWeb.Main.Assetstore.upload_document(image_address)
          else
            ViolacorpWeb.Main.Assetstore.upload_image(image_address)
          end
        else
          nil
        end

        file_id_extension = params["file_id_extension"]
        file_location_id = if params["image_id"] != "" do
          image_id = "#{params["image_id"]}"
          if file_id_extension == "pdf" do
            ViolacorpWeb.Main.Assetstore.upload_document(image_id)
          else
            ViolacorpWeb.Main.Assetstore.upload_image(image_id)
          end
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
            town: params["town"],
            countries_id: params["locationId"],
            is_primary: "N"
          }
        }

        contactsdirectors = %{
          contactsdirectors: %{
            contact_number: params["contact_number"],
            code: country_code,
            is_primary: "N"
          }
        }

        kycdirectors = %{
          kycdirectors: %{
            documenttype_id: params["documenttype_id"],
            document_number: params["document_number"],
            issue_date: params["issue_date"],
            expiry_date: params["expiry_date"],
            file_location: file_location_id,
            status: "A",
            type: "I"
          }
        }

        kycdirectorsaddress = %{
          kycdirectors: %{
            documenttype_id: params["documenttype_addressid"],
            file_location: file_location_address,
            status: "A",
            type: "A"
          }
        }

        [count] = Repo.all from a in Directors, where: a.company_id == ^compid, select: count(a.company_id)
        director_number = count + 1

        director_params = if (params["documenttype_addressid"] == "" or is_nil(params["documenttype_addressid"])) or (
          params["image_address"] == "" or is_nil(params["image_address"]))  do
          %{
            company_id: compid,
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
            is_primary: "N",
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors
          }
        else
          %{
            company_id: compid,
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
            is_primary: "N",
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors,
            kycdirectorsaddress: kycdirectorsaddress
          }
        end

        allinsert = Directors.changeset_contact(%Directors{}, director_params)

        #get cap detail repo
        cap_details = if params["position"] == "cap" do
          Repo.get_by(Directors, company_id: compid, position: "cap", status: "A")
        else
          nil
        end

        case Repo.insert(allinsert) do
          {:ok, _director_params} ->
            if !is_nil(cap_details) do

              update_old_dir = Directors.update_status(cap_details, director_params)
              case Repo.update(update_old_dir) do
                {:ok, _response} ->

                  password = Commontools.random_string(6)

                  commanall = Repo.one(
                    from cmn in Commanall, where: cmn.company_id == ^compid,
                                           left_join: c in assoc(cmn, :contacts),
                                           on: c.is_primary == "Y",
                                           left_join: d in assoc(cmn, :devicedetails),
                                           on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                           preload: [
                                             contacts: c,
                                             devicedetails: d
                                           ]
                  )
                  change_password = %{password: password}
                  changeset = Commanall.changeset_updatepassword(commanall, change_password)

                  Repo.update(changeset)

                  #                  # ALERTS DEPRECATED
                  #                  data = %{
                  #                    :section => "new_cap",
                  #                    :email_id => params["contact_email"],
                  #                    :director_name => "#{params["first_name"]} #{params["last_name"]}",
                  #                    :company_name => company.company_name,
                  #                    :pswd => password
                  #                  }
                  #                  AlertsController.sendEmail(data)
                  #                  AlertsController.sendNotification(data)
                  #                  AlertsController.sendSms(data)
                  #                  AlertsController.storeNotification(data)


                  data = [
                    %{
                      section: "new_cap",
                      type: "E",
                      email_id: params["contact_email"],
                      data: %{
                        :director_name => "#{params["first_name"]} #{params["last_name"]}",
                        :company_name => company.company_name,
                        :pswd => password
                      }
                      # Content
                    },
                    %{
                      section: "new_cap",
                      type: "S",
                      contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do
                        nil
                      else
                        Enum.at(commanall.contacts, 0).code
                      end,
                      contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do
                        nil
                      else
                        Enum.at(commanall.contacts, 0).contact_number
                      end,
                      data: %{}
                      # Content
                    },
                    %{
                      section: "new_cap",
                      type: "N",
                      token: if is_nil(commanall.devicedetails) do
                        nil
                      else
                        commanall.devicedetails.token
                      end,
                      push_type: if is_nil(commanall.devicedetails) do
                        nil
                      else
                        commanall.devicedetails.type
                      end, # "I" or "A"
                      login: commanall.as_login, # "Y" or "N"
                      data: %{}
                      # Content
                    }
                  ]
                  V2AlertsController.main(data)


                  json conn, %{status_code: "200", response: "Director inserted successfully"}
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end

            else

              json conn, %{status_code: "200", response: "Director inserted successfully"}
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


  def addNewDirector(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]
    unless map_size(params) == 0 do

      country_code = Application.get_env(:violacorp, :country_code)

      company = Repo.get!(Company, compid)
      access_type = params["accesstype"]
      position = params["position"]

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
        # image upload for address and id proof

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
            town: params["town"],
            countries_id: params["locationId"],
            is_primary: "N"
          }
        }

        contactsdirectors = %{
          contactsdirectors: %{
            contact_number: params["contact_number"],
            code: country_code,
            is_primary: "N"
          }
        }

        kycdirectors = %{
          kycdirectors: %{
            documenttype_id: params["documenttype_id"],
            document_number: params["document_number"],
            issue_date: params["issue_date"],
            expiry_date: params["expiry_date"],
            status: "A",
            type: "I"
          }
        }

        kycdirectorsaddress = %{
          kycdirectors: %{
            documenttype_id: params["documenttype_addressid"],
            status: "A",
            type: "A"
          }
        }

        [count] = Repo.all from a in Directors, where: a.company_id == ^compid, select: count(a.company_id)
        director_number = count + 1

        director_params = if (params["documenttype_addressid"] == "" or is_nil(params["documenttype_addressid"])) or (
          params["image_address"] == "" or is_nil(params["image_address"]))  do
          %{
            company_id: compid,
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
            is_primary: "N",
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors
          }
        else
          %{
            company_id: compid,
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
            is_primary: "N",
            addressdirectors: addressdirectors,
            contactsdirectors: contactsdirectors,
            kycdirectors: kycdirectors,
            kycdirectorsaddress: kycdirectorsaddress
          }
        end

        allinsert = Directors.changeset_contact(%Directors{}, director_params)

        #get cap detail repo
        cap_details = if params["position"] == "cap" do
          Repo.get_by(Directors, company_id: compid, position: "cap", status: "A")
        else
          nil
        end

        case Repo.insert(allinsert) do
          {:ok, _director_params} ->
            if !is_nil(cap_details) do

              update_old_dir = Directors.update_status(cap_details, director_params)
              case Repo.update(update_old_dir) do
                {:ok, _response} ->

                  password = Commontools.random_string(6)

                  commanall = Repo.one(
                    from cmn in Commanall, where: cmn.company_id == ^compid,
                                           left_join: c in assoc(cmn, :contacts),
                                           on: c.is_primary == "Y",
                                           left_join: d in assoc(cmn, :devicedetails),
                                           on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                           preload: [
                                             contacts: c,
                                             devicedetails: d
                                           ]
                  )

                  change_password = %{password: password}
                  changeset = Commanall.changeset_updatepassword(commanall, change_password)

                  Repo.update(changeset)

                  data = [
                    %{
                      section: "new_cap",
                      type: "E",
                      email_id: params["contact_email"],
                      data: %{
                        :director_name => "#{params["first_name"]} #{params["last_name"]}",
                        :company_name => company.company_name,
                        :pswd => password
                      }
                      # Content
                    },
                    %{
                      section: "new_cap",
                      type: "S",
                      contact_code: if is_nil(Enum.at(commanall.contacts, 0)) do
                        nil
                      else
                        Enum.at(commanall.contacts, 0).code
                      end,
                      contact_number: if is_nil(Enum.at(commanall.contacts, 0)) do
                        nil
                      else
                        Enum.at(commanall.contacts, 0).contact_number
                      end,
                      data: %{}
                      # Content
                    },
                    %{
                      section: "new_cap",
                      type: "N",
                      token: if is_nil(commanall.devicedetails) do
                        nil
                      else
                        commanall.devicedetails.token
                      end,
                      push_type: if is_nil(commanall.devicedetails) do
                        nil
                      else
                        commanall.devicedetails.type
                      end, # "I" or "A"
                      login: commanall.as_login, # "Y" or "N"
                      data: %{}
                      # Content
                    }
                  ]
                  V2AlertsController.main(data)


                  json conn, %{status_code: "200", response: "Director inserted successfully"}
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end

            else

              json conn, %{status_code: "200", response: "Director inserted successfully"}
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

  # Edit exist director
  def editDirector(conn, params) do

    %{"id" => compid} = conn.assigns[:current_user]

    unless map_size(params) == 0 do
      director_id = params["directorId"]
      company = Repo.get!(Company, compid)
      access_type = params["accesstype"]
      position = params["position"]

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

        get_directors = Repo.get(Directors, director_id)
        get_addressdirectors = Repo.get_by!(Addressdirectors, directors_id: director_id)
        get_contactsdirectors = Repo.get_by!(Contactsdirectors, directors_id: director_id)

        directorinfo =
          %{
            employeeids: params["employee_ids"],
            email_id: params["contact_email"],
            title: params["title"],
            position: params["position"],
            first_name: params["first_name"],
            last_name: params["last_name"],
            date_of_birth: params["date_of_birth"],
            signature: params["signature"],
            access_type: params["accesstype"]
          }

        addressdirectors = %{
          address_line_one: address_line_one,
          address_line_two: address_line_two,
          address_line_three: address_line_three,
          post_code: params["post_code"],
          countries_id: params["locationId"]
        }

        contactsdirectors = %{
          contact_number: params["contact_number"]
        }

        update_director = Directors.changeset(get_directors, directorinfo)
        update_addressdirectors = Addressdirectors.changeset(get_addressdirectors, addressdirectors)
        update_contactsdirectors = Contactsdirectors.changeset(get_contactsdirectors, contactsdirectors)

        case Repo.update(update_director) do
          {:ok, _director_params} ->
            Repo.update(update_addressdirectors)
            Repo.update(update_contactsdirectors)
            json conn,
                 %{
                   status_code: "200",
                   messages: "Company #{params["position"]} UPDATED."
                 }
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

  # Add new address
  def addAddress(conn, params) do

    %{"commanall_id" => commanid} = conn.assigns[:current_user]

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

      is_primary = "N"
      [count_address] = Repo.all from a in Address, where: a.commanall_id == ^commanid,
                                                    select: count(a.commanall_id)

      address_number = count_address + 1
      address = %{
        "commanall_id" => commanid,
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

      changeset = Address.changeset(%Address{}, address)
      case Repo.insert(changeset) do
        {:ok, _address_params} ->
          json conn, %{status_code: "200", response: "Address inserted successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  # Edit new address
  def editAddress(conn, params) do
    unless map_size(params) == 0 do
      address_id = params["addressId"]
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
        "address_line_one" => address_line_one,
        "address_line_two" => address_line_two,
        "address_line_three" => address_line_three,
        "countries_id" => params["locationId"],
        "post_code" => params["post_code"],
        "town" => params["town"],
        "county" => county
      }

      get_address = Repo.get(Address, address_id)
      changeset = Address.changeset(get_address, address)

      case Repo.update(changeset) do
        {:ok, _address_params} ->
          json conn, %{status_code: "200", response: "Address updated successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end

  end

  # Director List
  def listDirector(conn, _params) do
    %{"id" => compid} = conn.assigns[:current_user]

    company = Repo.one from c in Company, where: c.id == ^compid, select: c.company_type

    company_type = if company == "STR" do
      "owner"
    else
      "director"
    end

    director_list = Repo.all(
      from d in Directors, where: d.company_id == ^compid and d.position == ^company_type and d.status == "A",
                           order_by: [
                             asc: d.inserted_At
                           ],
                           select: %{
                             id: d.id,
                             first_name: d.first_name,
                             last_name: d.last_name,
                             as_employee: d.as_employee
                           }
    )
    json conn, %{status_code: "200", data: director_list}
  end

  # Single director view
  def directorView(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]

    director_id = params["directorId"]

    director_details = Repo.one(
      from d in Directors, where: d.id == ^director_id and d.company_id == ^compid,
                           left_join: address in assoc(d, :addressdirectors),
                           left_join: contact in assoc(d, :contactsdirectors),
                           select: %{
                             id: d.id,
                             employeeids: d.employeeids,
                             position: d.position,
                             title: d.title,
                             first_name: d.first_name,
                             last_name: d.last_name,
                             date_of_birth: d.date_of_birth,
                             email_id: d.email_id,
                             employee_id: d.employee_id,
                             address_line_one: address.address_line_one,
                             address_line_two: address.address_line_two,
                             address_line_three: address.address_line_three,
                             town: address.town,
                             post_code: address.post_code,
                             county: address.county,
                             director_contact_id: contact.id,
                             code: contact.code,
                             contact_number: contact.contact_number,
                             as_employee: d.as_employee
                           }
    )


    director_kyc = Repo.all(
      from k in Kycdirectors, where: k.directors_id == ^director_id and k.status == ^"A",
                              select: %{
                                id: k.id,
                                type: k.type,
                                document_number: k.document_number,
                                expiry_date: k.expiry_date,
                                issue_date: k.issue_date,
                                #                                documenttype_id: k.documenttype_id
                              }
    )
    result = if !is_nil(director_details) do
      as_employee = director_details.as_employee
      if as_employee === "Y" do

        employee_id = director_details.employee_id

        common = Repo.one(
          from commanall in Commanall, where: commanall.employee_id == ^employee_id,
                                       left_join: contacts in assoc(commanall, :contacts),
                                       where: contacts.is_primary == "Y",
                                       select: %{
                                         employee_id: commanall.employee_id,
                                         employee_contact_id: contacts.id
                                       }
        )
        if !is_nil(common) do
          %{employee_id: common.employee_id, employee_contact_id: common.employee_contact_id}
        else
          %{employee_id: nil, employee_contact_id: nil}
        end
      else
        %{employee_id: nil, employee_contact_id: nil}
      end
    end
    data = %{"director_info" => director_details, "kyc_details" => director_kyc, "employee" => result}
    json conn, %{status_code: "200", data: data}

  end

  # Address List
  def addressList(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    address = Repo.one(
      from a in Address, where: a.commanall_id == ^commanid and a.is_primary == ^"Y",
                         select: %{
                           id: a.id,
                           address_line_one: a.address_line_one,
                           address_line_two: a.address_line_two,
                           address_line_three: a.address_line_three,
                           town: a.town,
                           county: a.county,
                           post_code: a.post_code
                         }
    )

    tradingAddress = Repo.all(
      from a in Address, where: a.commanall_id == ^commanid and a.is_primary == ^"N",
                         order_by: [
                           asc: a.inserted_At
                         ],
                         select: %{
                           id: a.id,
                           address_line_one: a.address_line_one,
                           address_line_two: a.address_line_two,
                           address_line_three: a.address_line_three,
                           town: a.town,
                           county: a.county,
                           post_code: a.post_code
                         }
    )

    data = %{"address" => address, "tradingAddress" => tradingAddress}
    json conn, %{status_code: "200", data: data}

  end

  # Pending Transaction List
  def pendingTransactions(conn, params) do

    employee_id = params["employeeId"]

    # get user id
    user = Repo.get_by!(Commanall, employee_id: employee_id)
    user_id = user.accomplish_userid
    commanall_id = user.id

    if is_nil(user_id) do
      json conn, %{status_code: "404", data: "Employee is not active."}
    else

      last_transaction = Repo.one(
        from t in Transactions,
        where: t.commanall_id == ^commanall_id and t.category == ^"POS" and not is_nil(t.server_date),
        order_by: [
          desc: t.id
        ],
        limit: 1,
        select: %{
          transaction_date: t.transaction_date
        }
      )

      last_date = if last_transaction !== nil do
        last_transaction.transaction_date
      else
        user.inserted_at
      end

      today = DateTime.utc_now
      to_date = [today.year, today.month, today.day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")

      from_date = [last_date.year, last_date.month, last_date.day]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")

      status = "1" # 0 = success and 1 = pending
      start_index = "0"
      page_size = "100"

      request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{
        start_index
      }&page_size=#{page_size}"

      response = Accomplish.get_pending_transaction(request)

      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]

      if response_code == "0000" do
        map = Stream.with_index(response["transactions"], 1)
              |> Enum.reduce(
                   %{},
                   fn ({v, k}, trans) ->
                     type = v["info"]["type"]
                     text_msg = if type == 38 do
                       "Purchase ONLINE"
                     else
                       if type == 46 do
                         "ATM Withdrawal"
                       else
                         if type == 48 do
                           "Purchase Offline"
                         else
                           nil
                         end
                       end
                     end
                     if !is_nil(text_msg) do
                       operation = v["info"]["operation"]
                       server_date = v["info"]["server_date"]
                       date_utc = v["info"]["date_utc"]
                       amount = v["info"]["amount"]
                       currency = v["info"]["currency"]
                       notes = v["info"]["notes"]
                       transaction_id = v["info"]["original_source_id"]
                       remark = %{"from" => currency, "to" => "Purchase"}

                       transaction_mode = if operation == "Debit" do
                         "D"
                       else
                         "C"
                       end
                       transaction = %{
                         "amount" => amount,
                         "category" => "POS",
                         "cur_code" => currency,
                         "remark" => remark,
                         "server_date" => server_date,
                         "transaction_date" => date_utc,
                         "transaction_id" => transaction_id,
                         "transaction_mode" => transaction_mode,
                         "transaction_type" => "C2O",
                         "description" => notes,
                         "status" => "P"
                       }
                       Map.put(trans, k, transaction)
                     end
                   end
                 )
        json conn, %{status_code: "200", data: map}
      else
        json conn, %{status_code: "404", error: response_message}
      end
    end
  end

  def changePassword(conn, params) do

    email_id = params["email_id"]
    password = "viola123$ABC"

    commanall = Repo.get_by!(Commanall, email_id: email_id)
    change_password = %{password: password}
    changeset = Commanall.changeset_updatepassword(commanall, change_password)

    case Repo.update(changeset) do
      {:ok, _response} ->
        json conn, %{status_code: "200", response: "Password change successfully"}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  def generatePassword(conn, params) do

    id = params["id"]
    password = params["password"]

    sec_password = params["sec_password"]
    username = params["username"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      administratorusers = Repo.get!(Administratorusers, id)
      change_password = %{secret_password: password}
      changeset = Administratorusers.changeset_updatepassword(administratorusers, change_password)
      case Repo.update(changeset) do
        {:ok, _response} ->
          json conn, %{status_code: "200", response: "Generate password successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end

  def verifyPassword(conn, params) do
    id = params["id"]
    password = params["password"]

    sec_password = params["sec_password"]
    username = params["username"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      administratorusers = Repo.get_by(Administratorusers, id: id, secret_password: password)
      if administratorusers == nil do
        json conn, %{status_code: "4002", errors: "Password is incorrect"}
      else
        json conn, %{status_code: "200", data: "Password is correct"}
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end

  # For testing pending transaction
  def pendingTransactionsTesting(params) do

    employee_id = params["employee_id"]

    # get user id
    user = Repo.get_by!(Commanall, employee_id: employee_id)
    commanall_id = user.id
    user_id = user.accomplish_userid

    # get company id
    employee_com = Repo.get(Employee, employee_id)
    company_id = employee_com.company_id

    if !is_nil(user_id) do

      last_transaction = Repo.one(
        from t in Transactions,
        where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.status == ^"P" and not is_nil(
          t.server_date
        ),
        order_by: [
          desc: t.id
        ],
        limit: 1,
        select: %{
          transaction_date: t.transaction_date
        }
      )

      last_date = if last_transaction !== nil do
        last_transaction.transaction_date
      else
        user.inserted_at
      end

      today = DateTime.utc_now
      to_date = [today.year, today.month, today.day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")

      from_date = [last_date.year, last_date.month, last_date.day]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")

      status = "1" # 0 = success and 1 = pending
      start_index = "0"
      page_size = "100"

      request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{
        start_index
      }&page_size=#{page_size}"
      response = Accomplish.get_success_transaction(request)
      response_code = response["result"]["code"]

      if response_code == "0000" do
        Enum.each response["transactions"], fn v ->
          type = v["info"]["type"]
          text_msg = if type == 38 do
            "Purchase ONLINE"
          else
            if type == 46 do
              "ATM Withdrawal"
            else
              if type == 48 do
                "Purchase Offline"
              else
                nil
              end
            end
          end
          if !is_nil(text_msg) do
            server_date = v["info"]["server_date"]
            amount = v["info"]["amount"]

            accomplish_card_id = v["info"]["account_id"]
            employeecards = Repo.get_by!(Employeecards, accomplish_card_id: accomplish_card_id)
            employeecards_id = employeecards.id
            currency = employeecards.currency_code
            to_card = employeecards.last_digit

            [check_transaction] = Repo.all from a in Transactions,
                                           where: a.server_date == ^server_date and a.amount == ^amount and a.employeecards_id == ^employeecards_id and a.status == ^"P",
                                           select: count(a.pos_id)

            if check_transaction == 0 do
              operation = v["info"]["operation"]
              date_utc = v["info"]["date_utc"]
              transaction_id = v["info"]["original_source_id"]
              notes = v["info"]["notes"]
              response_notes = String.split(notes, "-", trim: true)
              notes_last_value = response_notes
                                 |> Enum.take(-1)
                                 |> Enum.join()

              remark = %{"from" => to_card, "to" => notes_last_value}
              api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
              transaction_mode = if operation == "Debit" do
                "D"
              else
                "C"
              end
              # Create POS transaction
              transaction = %{
                "commanall_id" => commanall_id,
                "company_id" => company_id,
                "employee_id" => employee_id,
                "employeecards_id" => employeecards_id,
                "pos_id" => 0,
                "amount" => amount,
                "fee_amount" => 0.00,
                "final_amount" => amount,
                "cur_code" => currency,
                "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                "transactions_id_api" => transaction_id,
                "server_date" => server_date,
                "transaction_date" => date_utc,
                "api_transaction_date" => Poison.encode!(api_transaction_date),
                "transaction_mode" => transaction_mode,
                "transaction_type" => "C2O",
                "category" => "POS",
                "status" => "P",
                "description" => notes,
                "remark" => Poison.encode!(remark),
                "inserted_by" => commanall_id
              }
              changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
              Repo.insert(changeset_transaction)
            end
          end
        end
      end
    end
  end

  # Testing for Success Transaction
  def successTransactionsTesting(params) do

    employee_id = params["employee_id"]

    # get user id
    user = Repo.get_by!(Commanall, employee_id: employee_id)

    commanall_id = user.id
    user_id = user.accomplish_userid

    # get company id
    employee_com = Repo.get(Employee, employee_id)
    company_id = employee_com.company_id

    if !is_nil(user_id) do

      last_transaction = Repo.one(
        from t in Transactions,
        where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.status == ^"S" and not is_nil(
          t.server_date
        ),
        order_by: [
          desc: t.id
        ],
        limit: 1,
        select: %{
          transaction_date: t.transaction_date
        }
      )

      last_date = if last_transaction !== nil do
        last_transaction.transaction_date
      else
        user.inserted_at
      end

      today = DateTime.utc_now
      to_date = [today.year, today.month, today.day]
                |> Enum.map(&to_string/1)
                |> Enum.map(&String.pad_leading(&1, 2, "0"))
                |> Enum.join("-")

      from_date = [last_date.year, last_date.month, last_date.day]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")

      status = "0" # 0 = success and 1 = pending
      start_index = "0"
      page_size = "100"

      request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{
        start_index
      }&page_size=#{page_size}"

      response = Accomplish.get_success_transaction(request)

      response_code = response["result"]["code"]

      if response_code == "0000" do
        Enum.each response["transactions"], fn v ->
          type = v["info"]["type"]
          text_msg = if type == 38 do
            "Purchase ONLINE"
          else
            if type == 46 do
              "ATM Withdrawal"
            else
              if type == 48 do
                "Purchase Offline"
              else
                nil
              end
            end
          end
          if !is_nil(text_msg) do
            ids = v["info"]["id"]
            [check_transaction] = Repo.all from a in Transactions, where: a.pos_id == ^ids,
                                                                   select: count(a.pos_id)
            if check_transaction == 0 do
              # check pending row
              server_date = v["info"]["server_date"]
              amount = v["info"]["amount"]

              accomplish_card_id = v["info"]["account_id"]
              employeecards = Repo.get_by!(Employeecards, accomplish_card_id: accomplish_card_id)
              employeecards_id = employeecards.id
              currency = employeecards.currency_code
              to_card = employeecards.last_digit

              last_pending_transaction = Repo.one(
                from t in Transactions,
                where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.amount == ^amount and t.employeecards_id == ^employeecards_id and t.status == ^"P",
                order_by: [
                  desc: t.id
                ],
                limit: 1,
                select: %{
                  id: t.id,
                  description: t.description
                }
              )

              notes = v["info"]["notes"]
              response_notes = String.split(notes, "-", trim: true)
              notes_last_value = response_notes
                                 |> Enum.take(-1)
                                 |> Enum.join()
              if is_nil(last_pending_transaction) do
                operation = v["info"]["operation"]
                date_utc = v["info"]["date_utc"]
                transaction_id = v["info"]["original_source_id"]
                remark = %{"from" => to_card, "to" => notes_last_value}
                api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
                transaction_mode = if operation == "Debit" do
                  "D"
                else
                  "C"
                end
                # Create POS transaction
                transaction = %{
                  "commanall_id" => commanall_id,
                  "company_id" => company_id,
                  "employee_id" => employee_id,
                  "employeecards_id" => employeecards_id,
                  "pos_id" => ids,
                  "amount" => amount,
                  "fee_amount" => 0.00,
                  "final_amount" => amount,
                  "cur_code" => currency,
                  "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                  "transactions_id_api" => transaction_id,
                  "server_date" => server_date,
                  "transaction_date" => date_utc,
                  "api_transaction_date" => Poison.encode!(api_transaction_date),
                  "transaction_mode" => transaction_mode,
                  "transaction_type" => "C2O",
                  "category" => "POS",
                  "status" => "S",
                  "description" => notes,
                  "remark" => Poison.encode!(remark),
                  "inserted_by" => commanall_id
                }
                changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
                Repo.insert(changeset_transaction)
              else
                last_notes = last_pending_transaction.description
                response_notes_db = String.split(last_notes, "/", trim: true)
                notes_last_value_db = response_notes_db
                                      |> Enum.take(1)
                                      |> Enum.join()

                response_notes_live = String.split(notes, "/", trim: true)
                notes_last_value_live = response_notes_live
                                        |> Enum.take(1)
                                        |> Enum.join()
                if notes_last_value_db == notes_last_value_live do
                  transaction_id = v["info"]["original_source_id"]
                  trans_status = Repo.get(Transactions, last_pending_transaction.id)
                  update_status = %{"status" => "S", "pos_id" => ids, "transactions_id_api" => transaction_id}
                  changeset_transaction = Transactions.changesetUpdateStatusApi(trans_status, update_status)
                  Repo.update(changeset_transaction)
                end
              end
            end
          end
        end
      end
    end
  end

  # Send again mail
  def changeAdminPassword(conn, params) do

    admin_id = params["id"]
    username = params["username"]
    sec_password = params["sec_password"]
    password = params["password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)


    if username == viola_user and sec_password == viola_password do

      commanall = Repo.get!(Administratorusers, admin_id)
      change_password = %{password: password}
      changeset = Administratorusers.changeset_password(commanall, change_password)

      case Repo.update(changeset) do
        {:ok, _response} ->
          json conn, %{status_code: "200", response: "Password change successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end

  # Send again mail
  def chagePass(conn, params) do
    unless map_size(params) == 0 do
      email_id = params["email_id"]
      password = "viola123$ABC"

      username = params["username"]
      sec_password = params["sec_password"]

      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

        commanall = Repo.get_by!(Commanall, email_id: email_id)
        change_password = %{password: password}
        changeset = Commanall.changeset_updatepassword(commanall, change_password)

        case Repo.update(changeset) do
          {:ok, _response} ->
            json conn, %{status_code: "200", response: "Change password successfully"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  # Send Mail from admin side
  def adminSendmail(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      sec_password = params["sec_password"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

        section = params["section"]

        #          data = if section == "registration_welcome" do
        #                  %{
        #                    :section => section,
        #                    :commanall_id => params["commanall_id"],
        #                    :company_name => params["company_name"]
        #                  }
        #                end
        #          AlertsController.sendEmail(data)
        if section == "registration_welcome" do
          cmn = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"],
                                                left_join: m in assoc(cmn, :contacts),
                                                on: m.is_primary == "Y",
                                                left_join: dd in assoc(cmn, :devicedetails),
                                                on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                                select: %{
                                                  id: cmn.id,
                                                  email_id: cmn.email_id,
                                                  as_login: cmn.as_login,
                                                  code: m.code,
                                                  contact_number: m.contact_number,
                                                  token: dd.token,
                                                  token_type: dd.type
                                                }
          if !is_nil(cmn) do
            data = [
              %{
                section: "registration_welcome",
                type: "E",
                email_id: cmn.email_id,
                data: %{
                  :company_name => params["company_name"]
                }
                # Content
              },
              %{
                section: "registration_welcome",
                type: "S",
                contact_code: cmn.code,
                contact_number: cmn.contact_number,
                data: %{
                  :company_name => params["company_name"]
                }
                # Content
              },
              %{
                section: "registration_welcome",
                type: "N",
                token: cmn.token,
                push_type: cmn.token_type, # "I" or "A"
                login: cmn.as_login, # "Y" or "N"
                data: %{
                  :company_name => params["company_name"]
                }
                # Content
              }
            ]
            V2AlertsController.main(data)
          end
        end
        json conn,
             %{
               status_code: "200",
               messages: "Sent e-mail successfully."
             }

      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

end