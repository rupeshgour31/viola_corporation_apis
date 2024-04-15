defmodule ViolacorpWeb.Company.CompanyController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Libraries.Accomplish
  alias ViolacorpWeb.Comman.TestController
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Departments
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Mandate
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Assignproject
  alias Violacorp.Schemas.Versions
  alias Violacorp.Schemas.Appversions
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Contactsdirectors
  #  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Kycdirectors

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.HistoryManagement
  alias ViolacorpWeb.Employees.EmployeeView
  alias ViolacorpWeb.Companies.CompanyView
  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController


  def insertCompanyDepartment(conn, params) do
    text  conn, "insertCompanyDepartment #{params["companyId"]}"
  end

  def insertCompanyProject(conn, params) do
    text  conn, "insertCompanyProject #{params["companyId"]}"
  end

  @doc "insert company employee"
  def insertCompanyEmployee(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      country_id = Application.get_env(:violacorp, :country_id)
      country_code = Application.get_env(:violacorp, :country_code)

      # Check if Password or Mobile_Number are already used
      user_exists = Repo.all(
        from p in Commanall, where: p.email_id == ^params["email"]
      )

      # if user_exists return's a value this condition if true will return error 4002 with below message
      if Enum.count(user_exists) > 0 do
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 email: "Email already registered"
               }
             }
      else

        contact_number = if String.first(params["contact_number"]) == "0" do
          params["contact_number"]
        else
          "0#{params["contact_number"]}"
        end

        user_mobile_exists = Repo.all(
          from con in Contacts, where: con.contact_number == ^contact_number and con.is_primary == "Y"
        )

        if Enum.count(user_mobile_exists) > 0 do
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   mobile: "Mobile number already registered"
                 }
               }
        else
          gender = case params["title"] do
            "Mr" -> "M"
            "Mrs" -> "F"
            "Miss" -> "F"
            "Ms" -> "F"
            _ -> "M"
          end
          employee = %{
            "company_id" => company_id,
            "employeeids" => params["employee_ids"],
            "departments_id" => params["departments_id"],
            "title" => params["title"],
            "position" => params["position"],
            "first_name" => params["first_name"],
            "last_name" => params["last_name"],
            "date_of_birth" => params["date_of_birth"],
            "gender" => gender,
            "is_manager" => params["is_manager"],
            "inserted_by" => commanid
          }
          employee_changeset = Employee.changeset(%Employee{}, employee)

          #
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
            address: %{
              address_line_one: address_line_one,
              address_line_two: address_line_two,
              address_line_three: address_line_three,
              post_code: params["post_code"],
              town: params["town"],
              county: county,
              countries_id: country_id,
              is_primary: "Y",
              inserted_by: commanid
            }
          }

          contacts = %{
            contacts: %{
              contact_number: params["contact_number"],
              code: country_code,
              is_primary: "Y",
              inserted_by: commanid
            }
          }
          viola_id = Commontools.random_string(6)
          password = Commontools.generate_password()
          contact_params = %{
            viola_id: viola_id,
            email_id: params["email"],
            vpin: params["vpin"],
            password: password,
            status: "A",
            address: address,
            contacts: contacts
          }

          commanall_changeset = Commanall.changeset_contact(%Commanall{}, contact_params)

          bothinsert = Ecto.Changeset.put_assoc(employee_changeset, :commanall, [commanall_changeset])

          case Repo.insert(bothinsert) do
            {:ok, _response} ->
              getemployee = Repo.one(
                from cmn in Commanall, where: cmn.email_id == ^params["email"],
                                       left_join: c in assoc(cmn, :contacts),
                                       on: c.is_primary == "Y",
                                       left_join: d in assoc(cmn, :devicedetails),
                                       on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                       preload: [
                                         contacts: c,
                                         devicedetails: d
                                       ]
              )
              getcompany = Repo.get!(Company, company_id)
              employeeId = getemployee.employee_id
              #                            # ALERTS DEPRECATED
              #                            data = %{
              #                              :section => "addemployee",
              #                              :commanall_id => getemployee.id,
              #                              :employee_name => "#{params["first_name"]} #{params["last_name"]}",
              #                              :company_name => getcompany.company_name,
              #                              :pswd => password
              #                            }
              #                            AlertsController.sendEmail(data)
              #                            AlertsController.sendNotification(data)
              #                            AlertsController.sendSms(data)
              #                            AlertsController.storeNotification(data)

              data = [
                %{
                  section: "addemployee",
                  type: "E",
                  email_id: getemployee.email_id,
                  data: %{
                    :employee_name => "#{params["first_name"]} #{params["last_name"]}",
                    :email => getemployee.email_id,
                    :company_name => getcompany.company_name,
                    :pswd => password
                  }
                  # Content
                },
                %{
                  section: "addemployee",
                  type: "S",
                  contact_code: if is_nil(Enum.at(getemployee.contacts, 0)) do
                    nil
                  else
                    Enum.at(getemployee.contacts, 0).code
                  end,
                  contact_number: if is_nil(Enum.at(getemployee.contacts, 0)) do
                    nil
                  else
                    Enum.at(getemployee.contacts, 0).contact_number
                  end,
                  data: %{
                    :company_name => getcompany.company_name
                  }
                  # Content
                },
                %{
                  section: "addemployee",
                  type: "N",
                  token: if is_nil(getemployee.devicedetails) do
                    nil
                  else
                    getemployee.devicedetails.token
                  end,
                  push_type: if is_nil(getemployee.devicedetails) do
                    nil
                  else
                    getemployee.devicedetails.type
                  end, # "I" or "A"
                  login: getemployee.as_login, # "Y" or "N"
                  data: %{}
                  # Content
                }
              ]
              V2AlertsController.main(data)

              message = "Request to join ViolaCorporate sent to #{params["first_name"]} #{params["last_name"]}"
              notification_details = %{
                "commanall_id" => commanid,
                "subject" => "addemployee",
                "message" => message,
                "inserted_by" => commanid
              }
              insert = Notifications.changeset(%Notifications{}, notification_details)
              Repo.insert(insert)
              if is_nil(params["departments_id"]) or params["departments_id"] == "" do
                json conn, %{status_code: "200", data: "Employee registration is done.", employeeId: employeeId}
              else
                department = Repo.get_by(
                  Departments,
                  id: params["departments_id"],
                  company_id: company_id
                )
                if is_nil(department) do
                  json conn, %{status_code: "200", data: "Employee registration is done.", employeeId: employeeId}
                else


                  [count_dep] = Repo.all from d in Employee,
                                         where: d.departments_id == ^params["departments_id"] and d.company_id == ^company_id,
                                         select: count(d.id)

                  new_number = %{"number_of_employee" => count_dep}
                  dep_changeset = Departments.updateEmployeeNumberchangeset(department, new_number)
                  case Repo.update(dep_changeset) do
                    {:ok, _response} ->
                      json conn, %{status_code: "200", data: "Employee registration is done.", employeeId: employeeId}
                    {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
                end
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


  @doc "inserts company employee info - address - contact"
  def insertCompanyEmployeeInfo(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      address = %{
        "company_id" => company_id,
        "commanall_id" => params["commanall_id"],
        "address_line_one" => params["address_line_one"],
        "address_line_two" => params["address_line_two"],
        "address_line_three" => params["address_line_three"],
        "post_code" => params["post_code"],
        "inserted_by" => commanid
      }
      address_changeset = Address.changeset(%Address{}, address)

      contact = %{
        "commanall_id" => params["commanall_id"],
        "contact_number" => params["contact_number"],
        "inserted_by" => commanid
      }
      contact_changeset = Contacts.changeset(%Contacts{}, contact)

      checkchangeset = (address_changeset.valid? && contact_changeset.valid?)

      if checkchangeset do
        case Repo.insert(address_changeset) && Repo.insert(contact_changeset)  do
          {:ok, _response} -> render(conn, ViolacorpWeb.SuccessView, "success.json", response: "all ok.")
          {:error, changeset} -> conn
                                 |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        error_changeset = if address_changeset.valid? == false do
          address_changeset
        else
          if contact_changeset.valid? == false do
            contact_changeset
          else
            %{}
          end
        end

        render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: error_changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "get employees of company with filters"
  def getEmployeesFiltered(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      employee_filtered =
        params
        |> Map.take(~w( first_name last_name employee_id gender status employeeids))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(employee_filtered, from_token)

      query = if is_nil(params["inserted_at"]) do
        cond do
          is_nil(params["email_id"]) and is_nil(params["contact_number"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          is_nil(params["contact_number"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)

          is_nil(params["email_id"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   left_join: contact in assoc(comman, :contacts),
                   where: contact.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          is_nil(params["email_id"]) and is_nil(params["contact_number"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          is_nil(params["email_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          is_nil(params["contact_number"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
          true ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name
                   })
            |> Repo.paginate(params)
        end

      else
        added_date = params["inserted_at"]
        cond do
          is_nil(params["email_id"]) and is_nil(params["contact_number"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["contact_number"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["email_id"]) and is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: comman in assoc(e, :commanall),
                   left_join: contact in assoc(comman, :contacts),
                   where: contact.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["email_id"]) and is_nil(params["contact_number"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["department_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["email_id"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: comman in assoc(e, :commanall),
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          is_nil(params["contact_number"]) ->
            (
              from e in Employee,
                   where: ^merge_params,
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
          true ->
            (
              from e in Employee,
                   where: ^merge_params,
                   left_join: comman in assoc(e, :commanall),
                   where: comman.email_id == ^params["email_id"],
                   having: e.inserted_at >= ^added_date and e.inserted_at < datetime_add(
                     ^added_date,
                     1,
                     "day"
                   ),
                   left_join: department in assoc(e, :departments),
                   where: department.id == ^params["department_id"],
                   left_join: number in assoc(comman, :contacts),
                   where: number.contact_number == ^params["contact_number"],
                   select: %{
                     id: e.id,
                     title: e.title,
                     first_name: e.first_name,
                     last_name: e.last_name,
                     status: e.status,
                     profile_picture: e.profile_picture,
                     dateofbirth: e.date_of_birth,
                     gender: e.gender,
                     department_id: department.id,
                     department_name: department.department_name,
                     inserted_at: e.inserted_at
                   })
            |> Repo.paginate(params)
        end
      end

      # check request
      request_params = params["request_key"]

      map = if request_params == "BOTH" do
        Stream.with_index(query.entries, 1)
        |> Enum.reduce(
             %{},
             fn ({v, k}, emp) ->
               id = v.id
               # get all requested card count
               count_card = Repo.one(
                 from m in Requestcard, where: m.employee_id == ^id and m.status == ^"R", select: count(m.id)
               )

               # get all requested money count
               count_money = Repo.one(
                 from c in Requestmoney, where: c.employee_id == ^id and c.status == ^"R", select: count(c.id)
               )

               card_requesed = if count_card > 0 do
                 count_card
               else
                 nil
               end
               money_requesed = if count_money > 0 do
                 count_money
               else
                 nil
               end

               response_emp = if count_card > 0 or count_money > 0  do
                 %{
                   id: v.id,
                   title: v.title,
                   first_name: v.first_name,
                   last_name: v.last_name,
                   status: v.status,
                   profile_picture: v.profile_picture,
                   dateofbirth: v.dateofbirth,
                   gender: v.gender,
                   department_id: v.department_id,
                   department_name: v.department_name,
                   card_requesed: card_requesed,
                   money_requesed: money_requesed
                 }
               end
               Map.put(emp, k, response_emp)
             end
           )
      else
        if request_params == "CARD" do
          Stream.with_index(query.entries, 1)
          |> Enum.reduce(
               %{},
               fn ({v, k}, emp) ->
                 id = v.id
                 # get all requested card count
                 count_card = Repo.one(
                   from m in Requestcard, where: m.employee_id == ^id and m.status == ^"R", select: count(m.id)
                 )

                 response_emp = if count_card > 0 do
                   %{
                     id: v.id,
                     title: v.title,
                     first_name: v.first_name,
                     last_name: v.last_name,
                     status: v.status,
                     profile_picture: v.profile_picture,
                     dateofbirth: v.dateofbirth,
                     gender: v.gender,
                     department_id: v.department_id,
                     department_name: v.department_name,
                     card_requesed: count_card,
                     money_requesed: nil
                   }
                 end
                 Map.put(emp, k, response_emp)
               end
             )
        else
          if request_params == "MONEY" do
            Stream.with_index(query.entries, 1)
            |> Enum.reduce(
                 %{},
                 fn ({v, k}, emp) ->
                   id = v.id
                   # get all requested card count
                   count_money = Repo.one(
                     from m in Requestmoney, where: m.employee_id == ^id and m.status == ^"R", select: count(m.id)
                   )

                   response_emp = if count_money > 0 do
                     %{
                       id: v.id,
                       title: v.title,
                       first_name: v.first_name,
                       last_name: v.last_name,
                       status: v.status,
                       profile_picture: v.profile_picture,
                       dateofbirth: v.dateofbirth,
                       gender: v.gender,
                       department_id: v.department_id,
                       department_name: v.department_name,
                       card_requesed: nil,
                       money_requesed: count_money
                     }
                   end
                   Map.put(emp, k, response_emp)

                 end
               )
          else
            Stream.with_index(query.entries, 1)
            |> Enum.reduce(
                 %{},
                 fn ({v, k}, emp) ->
                   response_emp = %{
                     id: v.id,
                     title: v.title,
                     first_name: v.first_name,
                     last_name: v.last_name,
                     status: v.status,
                     profile_picture: v.profile_picture,
                     dateofbirth: v.dateofbirth,
                     gender: v.gender,
                     department_id: v.department_id,
                     department_name: v.department_name,
                     card_requesed: nil,
                     money_requesed: nil
                   }
                   Map.put(emp, k, response_emp)
                 end
               )
          end
        end
      end


      data_value = map
                   |> Map.delete(:__struct__) # change the struct to a Map
                   |> Enum.filter(fn {_, v} -> v end)
                   |> Enum.into(%{})

      new_data = Map.values(data_value)

      json conn,
           %{
             status_code: "200",
             data: new_data,
             page_number: query.page_number,
             total_pages: query.total_pages
           }
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getSingleEmployeeAddress(conn, params) do
    employeeaddress = Commanall
                      |> Repo.get(params["commanallId"])
                      |> Repo.preload(:address)
    render(conn, CompanyView, "employeeaddress.json", employeeaddress: employeeaddress)
  end

  def getSingleEmployeeContacts(conn, params) do
    employeecontacts = Commanall
                       |> Repo.get(params["commanallId"])
                       |> Repo.preload(:contacts)
    render(conn, CompanyView, "employeecontacts.json", employeecontacts: employeecontacts)
  end

  def getSingleCompanyAddress(conn, params) do
    companyaddress = Commanall
                     |> Repo.get(params["commanallId"])
                     |> Repo.preload(:address)
    render(conn, CompanyView, "companyaddress.json", companyaddress: companyaddress)
  end

  def getSingleCompanyContacts(conn, params) do
    companycontacts = Commanall
                      |> Repo.get(params["commanallId"])
                      |> Repo.preload(:contacts)
    render(conn, CompanyView, "companycontacts.json", companycontacts: companycontacts)
  end

  def getDirectorsAddress(conn, params) do
    addressdirectors = Directors
                       |> Repo.get(params["directorId"])
                       |> Repo.preload(:addressdirectors)
    render(conn, CompanyView, "addressdirectors.json", addressdirectors: addressdirectors)
  end

  def getDirectorsContacts(conn, params) do
    contactsdirectors = Directors
                        |> Repo.get(params["directorId"])
                        |> Repo.preload(:contactsdirectors)
    render(conn, CompanyView, "contactsdirectors.json", contactsdirectors: contactsdirectors)
  end

  @doc "inserts comapny manager - needs re discussing"
  def insertCompanyManager(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

      manager = %{
        "company_id" => company_id,
        "departments_id" => params["departments_id"],
        "first_name" => params["first_name"],
        "last_name" => params["last_name"],
        "date_of_birth" => params["date_of_birth"],
        "gender" => params["gender"],
        "profile_picture" => params["profile_picture"],
        "is_manager" => params["is_manager"],
        "inserted_by" => commanid
      }

      employee_changeset = Employee.changeset(%Employee{}, manager)
      case Repo.insert(employee_changeset) do
        {:ok, employee} -> render(conn, EmployeeView, "show.json", employee: employee)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def assignCard(conn, params) do
    text  conn, "assignCard #{params["companyId"]}"
  end

  def updateCompanyDepartment(conn, params) do
    text  conn, "updateCompanyDepartment #{params["companyId"]} #{params["id"]}"
  end

  def updateCompanyProject(conn, params) do
    text  conn, "updateCompanyProject #{params["companyId"]} #{params["id"]}"
  end

  @doc "update company employee"
  def updateCompanyEmployee(conn, %{"id" => id, "employee" => params}) do
    unless map_size(params) == 0 do
      %{"id" => compid} = conn.assigns[:current_user]

      get_employee = Repo.get_by!(Employee, id: id, company_id: compid)
      get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^id, select: a.id
      get_address = Repo.get_by!(Address, commanall_id: get_commanall_id, is_primary: "Y")

      employee_changeset = Employee.changeset(get_employee, params)
      address_changeset = Address.changeset(get_address, params)
      checkchangeset = (employee_changeset.valid? && address_changeset.valid?)

      if checkchangeset do
        case Repo.update(employee_changeset) && Repo.update(address_changeset) do
          {:ok, _response} -> if is_nil(get_employee.departments_id)  do
                                department = if is_nil(params["departments_id"]) do
                                  nil
                                else
                                  Repo.get_by(Departments, id: params["departments_id"], company_id: compid)
                                end
                                if is_nil(department) do
                                  render(
                                    conn,
                                    ViolacorpWeb.SuccessView,
                                    "success.json",
                                    response: "Employee Details have been UPDATED"
                                  )
                                else
                                  [count_dep] = Repo.all from d in Employee,
                                                         where: d.departments_id == ^params["departments_id"] and d.company_id == ^compid,
                                                         select: count(d.id)

                                  new_number = %{"number_of_employee" => count_dep}
                                  dep_changeset = Departments.updateEmployeeNumberchangeset(department, new_number)
                                  case Repo.update(dep_changeset) do
                                    {:ok, _response} -> render(
                                                          conn,
                                                          ViolacorpWeb.SuccessView,
                                                          "success.json",
                                                          response: "Employee Details have been UPDATED"
                                                        )
                                    {:error, changeset} ->
                                      conn
                                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                                  end
                                end
                              else
                                departments_id = Integer.to_string(get_employee.departments_id)
                                if params["departments_id"] != departments_id do
                                  old_department = Repo.get_by(
                                    Departments,
                                    id: get_employee.departments_id,
                                    company_id: compid
                                  )
                                  new_department = Repo.get_by(
                                    Departments,
                                    id: params["departments_id"],
                                    company_id: compid
                                  )
                                  if is_nil(old_department) or is_nil(new_department) do
                                    render(
                                      conn,
                                      ViolacorpWeb.SuccessView,
                                      "success.json",
                                      response: "Employee Details have been UPDATED"
                                    )
                                  else

                                    [count_dep] = Repo.all from d in Employee,
                                                           where: d.departments_id == ^params["departments_id"] and d.company_id == ^compid,
                                                           select: count(d.id)

                                    decrease = if old_department.number_of_employee > 0 do
                                      old_department.number_of_employee - 1
                                    else
                                      old_department.number_of_employee
                                    end

                                    old_number = %{"number_of_employee" => decrease}
                                    new_number = %{"number_of_employee" => count_dep}
                                    dep_changeset_old = Departments.updateEmployeeNumberchangeset(
                                      old_department,
                                      old_number
                                    )
                                    dep_changeset_new = Departments.updateEmployeeNumberchangeset(
                                      new_department,
                                      new_number
                                    )

                                    case Repo.update(dep_changeset_old) && Repo.update(dep_changeset_new) do
                                      {:ok, _response} ->
                                        render(
                                          conn,
                                          ViolacorpWeb.SuccessView,
                                          "success.json",
                                          response: "Employee Details have been UPDATED!"
                                        )
                                      {:error, changeset} ->
                                        conn
                                        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                                    end
                                  end
                                else
                                  render(
                                    conn,
                                    ViolacorpWeb.SuccessView,
                                    "success.json",
                                    response: "Employee Details have been UPDATED!"
                                  )
                                end
                              end
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        error_changeset = if address_changeset.valid? == false do
          address_changeset
        else
          if employee_changeset.valid? == false do
            employee_changeset
          else
            %{}
          end
        end

        render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: error_changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "update company manager"
  def updateCompanyManager(conn, %{"id" => id, "employee" => params}) do
    employee = Repo.get!(Employee, id)
    changeset = Employee.changeset(employee, params)
    case Repo.update(changeset) do
      {:ok, employee} -> render(conn, EmployeeView, "show.json", employee: employee)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  def updateCompanyAssignCard(conn, params) do
    text  conn, "updateCompanyAssignCard #{params["companyId"]} #{params["id"]}"
  end

  def getSingleDepartment(conn, params) do
    text  conn, "getSingleDepartment #{params["companyId"]} #{params["id"]}"
  end

  def getSingleProject(conn, params) do
    text  conn, "getSingleProject #{params["companyId"]} #{params["id"]}"
  end

  def getSingleEmployee(conn, params) do
    text  conn, "getSingleEmployee #{params["companyId"]} #{params["id"]}"
  end

  def getSingleManager(conn, params) do
    text  conn, "getSingleManager #{params["companyId"]} #{params["id"]}"
  end

  def getAllDepartments(conn, params) do
    text  conn, "getAllDepartments #{params["companyId"]}"
  end

  def getAllProjects(conn, params) do
    text  conn, "getAllProjects #{params["companyId"]}"
  end

  def getAllEmployees(conn, params) do
    text  conn, "getAllProjects #{params["companyId"]}"
  end

  def getAllManagers(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    employee = Repo.all (
                          from e in Employee,
                               where: e.company_id == ^company_id and e.is_manager == "Y",
                               left_join: department in assoc(e, :departments),
                               select: %{
                                 id: e.id,
                                 title: e.title,
                                 first_name: e.first_name,
                                 last_name: e.last_name,
                                 status: e.status,
                                 profile_picture: e.profile_picture,
                                 dateofbirth: e.date_of_birth,
                                 gender: e.gender,
                                 department_id: department.id,
                                 department_name: department.department_name
                               })
    json conn, %{status_code: "200", data: employee}

  end

  def getAllAssignCards(conn, params) do
    text  conn, "getAllAssignCards #{params["companyId"]}"
  end

  def moneyRollback(conn, params) do
    text  conn, "moneyRollback #{params["companyId"]} #{params["employeeId"]} #{params["cardId"]}"
  end

  def topupCard(conn, params) do
    text  conn, "topupCard #{params["companyId"]} #{params["employeeId"]} #{params["cardId"]}"
  end

  def ownAccount(conn, params) do
    text  conn, "ownAccount #{params["companyId"]} #{params["accountId"]}"
  end

  @doc "refresh balance"
  def refreshBalance(conn, _params) do
    %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

    # get accomplish user id
    commanall = Repo.one from c in Commanall, where: c.id == ^commanid and c.company_id == ^companyid,
                                              select: %{
                                                accomplish_userid: c.accomplish_userid
                                              }

    userid = commanall.accomplish_userid
    response = if commanall.accomplish_userid != nil do
      TestController.update_account_balance(commanid, userid)
    else
      %{"response_code" => "404", "response_message" => "Record not found!"}
    end

    response_code = if response["response_code"] == "0000" do
      "200"
    else
      response["response_code"]
    end

    response_msg = if response["response_code"] == "0000" do
      "Balance Refreshed"
    else
      response["response_message"]
    end

    company = Repo.one from c in Companyaccounts, where: c.company_id == ^companyid,
                                                  select: %{
                                                    available_balance: c.available_balance
                                                  }
    available_balance = if is_nil(company) do
      "0.00"
    else
      to_string(company.available_balance)
    end
    json conn, %{status_code: response_code, message: response_msg, balance: available_balance}
  end

  @doc "Update Employee Balance"
  def refreshEmployeeBalance(conn, params) do

    employee_id = params["employeeId"]

    # call Load Pending Transaction method
    pending_load_params = %{
      "worker_type" => "pending_transactions_updater",
      "employee_id" => employee_id
    }
    success_load_params = %{
      "worker_type" => "success_transactions_updater",
      "employee_id" => employee_id
    }
    Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [pending_load_params], max_retries: 1)
    Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [success_load_params], max_retries: 1)

    # get accomplish user id
    commanall = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                              select: %{
                                                accomplish_userid: c.accomplish_userid
                                              }

    userid = commanall.accomplish_userid
    response = if commanall.accomplish_userid != nil do
      TestController.update_card_balance(userid)
    else
      %{"response_code" => "404", "response_message" => "Record not found!"}
    end

    response_code = if response["response_code"] == "0000" do
      "200"
    else
      response["response_code"]
    end

    response_msg = if response["response_code"] == "0000" do
      "Balance Refreshed"
    else
      response["response_message"]
    end

    json conn, %{status_code: response_code, message: response_msg}

  end

  #  @doc "Update Employee Balance"
  #  def refreshCardBalance(conn, params) do
  #
  #    card_id = String.to_integer(params["cardId"])
  #    employee_id = params["employeeId"]
  #
  #    # get accomplish user id
  #    commanall = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
  #                                              select: %{
  #                                                accomplish_userid: c.accomplish_userid
  #                                              }
  #
  #    userid = commanall.accomplish_userid
  #    response = if commanall.accomplish_userid != nil do
  #      TestController.update_single_card_balance(card_id, userid)
  #    else
  #      %{"response_code" => "404", "response_message" => "Record not found!"}
  #    end
  #
  #    response_code = if response["response_code"] == "0000" do
  #      "200"
  #    else
  #      response["response_code"]
  #    end
  #
  #    response_msg = if response["response_code"] == "0000" do
  #      "Balance Refreshed"
  #    else
  #      response["response_message"]
  #    end
  #
  #    json conn, %{status_code: response_code, message: response_msg}
  #
  #  end

  @doc "Update Employee Balance"
  def refreshCardBalance(conn, params) do

    card_id = String.to_integer(params["cardId"])

    # get accomplish user id
    employeecards = Repo.one from e in Employeecards, where: e.id == ^card_id,
                                                      select: %{
                                                        accomplish_card_id: e.accomplish_card_id
                                                      }

    account_id = employeecards.accomplish_card_id
    response = if employeecards.accomplish_card_id != nil do
      TestController.update_single_card_balance_new(card_id, account_id)
    else
      %{"response_code" => "404", "response_message" => "Record not found!"}
    end

    response_code = if response["response_code"] == "0000" do
      "200"
    else
      response["response_code"]
    end

    response_msg = if response["response_code"] == "0000" do
      "Balance Refreshed"
    else
      response["response_message"]
    end

    json conn, %{status_code: response_code, message: response_msg}

  end

  @doc "Get All Requested card List"
  def getAllRequestCardList(conn, _params) do
    %{"id" => companyid} = conn.assigns[:current_user]

    requested_card_list = Repo.all (
                                     from r in Requestcard,
                                          where: r.company_id == ^companyid and r.status == ^"R",
                                          left_join: e in assoc(r, :employee),
                                          order_by: [
                                            desc: r.inserted_at
                                          ],
                                          select: %{
                                            id: r.id,
                                            employee_id: r.employee_id,
                                            currency: r.currency,
                                            card_type: r.card_type,
                                            status: r.status,
                                            first_name: e.first_name,
                                            last_name: e.last_name
                                          })
    json conn, %{status_code: "200", data: requested_card_list}
  end

  @doc "Get Employee requested card list"
  def getEmployeeRequestCard(conn, params) do
    %{"id" => companyid} = conn.assigns[:current_user]
    employee_id = params["employeeId"]

    requested_card_list = (
                            from r in Requestcard,
                                 where: r.company_id == ^companyid and r.employee_id == ^employee_id and r.status == ^"R",
                                 select: %{
                                   id: r.id,
                                   employee_id: r.employee_id,
                                   currency: r.currency,
                                   card_type: r.card_type,
                                   status: r.status
                                 }
                            )
                          |> Repo.paginate(params)

    total_count = Enum.count(requested_card_list)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: requested_card_list.entries,
           page_number: requested_card_list.page_number,
           total_pages: requested_card_list.total_pages
         }
  end
  @doc "get company's all transactions"
  def companyTransactionsList(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    #    DEPRECATED
    get_transactions = (
                         from t in Transactions,
                              where: t.commanall_id != ^commanid and t.company_id == ^compid and t.transaction_type != "B2A",
                              left_join: transactionsreceipt in assoc(t, :transactionsreceipt),
                              order_by: [
                                desc: t.transaction_date
                              ],
                              select: %{
                                id: t.id,
                                amount: t.amount,
                                fee_amount: t.fee_amount,
                                final_amount: t.final_amount,
                                remark: t.remark,
                                balance: t.balance,
                                previous_balance: t.previous_balance,
                                transaction_mode: t.transaction_mode,
                                transaction_date: t.transaction_date,
                                transaction_type: t.transaction_type,
                                transaction_id: t.transaction_id,
                                category: t.category,
                                cur_code: t.cur_code,
                                projects_id: t.projects_id,
                                description: t.description,
                                status: t.status,
                                receipt_url: transactionsreceipt.receipt_url
                              }
                         )
                       |> Repo.paginate(params)
    total_count = Enum.count(get_transactions)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: get_transactions.entries,
           page_number: get_transactions.page_number,
           total_pages: get_transactions.total_pages
         }
  end

  def companyTransactionsListV1(conn, params) do
    %{"id" => compid} = conn.assigns[:current_user]

    get_transactions = Transactions
                       |> where(
                            [t],
                            t.company_id == ^compid and (
                              (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                                t.transaction_type == "C2A" and t.transaction_mode == "D") or (
                                t.transaction_type == "C2O") or (t.transaction_type == "C2I") or (
                                t.transaction_type == "C2F"))
                          )
                       |> order_by(desc: :transaction_date)
                       |> preload(:transactionsreceipt)
                       |> preload(:projects)
                       |> Repo.paginate(params)

    render(conn, EmployeeView, "manytrans_paginate_receipt_project.json", transactions: get_transactions)
  end

  @doc "company funding topup list"
  def companyTopupList(conn, _params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    get_transactions = Repo.all from t in Transactions,
                                where: t.commanall_id == ^commanid and t.company_id == ^compid and t.category == "TU"
                                and is_nil(t.server_date),
                                order_by: [
                                  desc: t.transaction_date
                                ],
                                select: %{
                                  id: t.id,
                                  amount: t.amount,
                                  fee_amount: t.fee_amount,
                                  final_amount: t.final_amount,
                                  remark: t.remark,
                                  balance: t.balance,
                                  previous_balance: t.previous_balance,
                                  transaction_mode: t.transaction_mode,
                                  transaction_date: t.transaction_date,
                                  transaction_type: t.transaction_type,
                                  transaction_id: t.transaction_id,
                                  category: t.category,
                                  cur_code: t.cur_code,
                                  projects_id: t.projects_id,
                                  description: t.description,
                                  status: t.status
                                }
    render(conn, ViolacorpWeb.SuccessView, "success.json", response: get_transactions)
  end

  @doc "get company's load money transaction list"
  def companyLoadMoneyList(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    # call manual load method
    load_params = %{
      "worker_type" => "manual_load",
      "commanall_id" => commanid,
      "company_id" => compid
    }
    Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

    get_transactions = if (params["from_date"] == "" or params["to_date"] == "") do
      (from t in Transactions,
            where: t.commanall_id == ^commanid and t.company_id == ^compid and (
              t.transaction_type == "B2A" or t.transaction_type == "A2O"),
            order_by: [
              desc: t.transaction_date
            ],
            select: %{
              id: t.id,
              amount: t.amount,
              fee_amount: t.fee_amount,
              final_amount: t.final_amount,
              remark: t.remark,
              balance: t.balance,
              previous_balance: t.previous_balance,
              transaction_mode: t.transaction_mode,
              transaction_date: t.transaction_date,
              transaction_type: t.transaction_type,
              transaction_id: t.transaction_id,
              category: t.category,
              cur_code: t.cur_code,
              projects_id: t.projects_id,
              description: t.description,
              status: t.status
            })
      |> Repo.paginate(params)

    else
      (from t in Transactions,
            where: t.commanall_id == ^commanid and t.company_id == ^compid and (
              t.transaction_type == "B2A" or t.transaction_type == "A2O"),
            having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"],
            order_by: [
              desc: t.transaction_date
            ],
            select: %{
              id: t.id,
              amount: t.amount,
              fee_amount: t.fee_amount,
              final_amount: t.final_amount,
              remark: t.remark,
              balance: t.balance,
              previous_balance: t.previous_balance,
              transaction_mode: t.transaction_mode,
              transaction_date: t.transaction_date,
              transaction_type: t.transaction_type,
              transaction_id: t.transaction_id,
              category: t.category,
              cur_code: t.cur_code,
              projects_id: t.projects_id,
              description: t.description,
              status: t.status
            })
      |> Repo.paginate(params)

    end

    total_count = Enum.count(get_transactions)

    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: get_transactions.entries,
           page_number: get_transactions.page_number,
           total_pages: get_transactions.total_pages
         }
  end

  def companyLoadMoneyListV1(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    # call manual load method
    load_params = %{
      "worker_type" => "manual_load",
      "commanall_id" => commanid,
      "company_id" => compid
    }
    #    Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

    # is_nil(params["from_date"]) and is_nil(params["to_date"])

    get_transactions =
      if (params["from_date"] == "" and params["to_date"] == "") do
        Transactions
        |> where(
             [t],
             t.commanall_id == ^commanid and t.company_id == ^compid and t.status == "S" and (
               t.transaction_type == "B2A" or t.transaction_type == "A2O" or (
                 t.transaction_type == "A2C" and t.transaction_mode == "D"))
           )
        |> order_by(desc: :transaction_date)
        |> preload(:transactionsreceipt)
        |> Repo.paginate(params)
      else
        if params["from_date"] == "" and params["to_date"] != "" do
          Transactions
          |> where(
               [t],
               t.transaction_date <= ^params["to_date"] and t.commanall_id == ^commanid and t.status == "S" and t.company_id == ^compid and (
                 t.transaction_type == "B2A" or t.transaction_type == "A2O" or (
                   t.transaction_type == "A2C" and t.transaction_mode == "D"))
             )
          |> order_by(desc: :transaction_date)
          |> preload(:transactionsreceipt)
          |> Repo.paginate(params)
        else
          if params["from_date"] != "" and params["to_date"] == "" do
            Transactions
            |> where(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.commanall_id == ^commanid and t.status == "S" and t.company_id == ^compid and (
                   t.transaction_type == "B2A" or t.transaction_type == "A2O" or (
                     t.transaction_type == "A2C" and t.transaction_mode == "D"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> Repo.paginate(params)
          else
            Transactions
            |> where(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id == ^commanid and t.status == "S" and t.company_id == ^compid and (
                   t.transaction_type == "B2A" or t.transaction_type == "A2O" or (
                     t.transaction_type == "A2C" and t.transaction_mode == "D"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> Repo.paginate(params)
          end
        end
      end

    render(conn, EmployeeView, "manytrans_paginate.json", transactions: get_transactions)
  end

  # List of account transadction
  def companyLoadMoneyTransaction(conn, params) do

    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]
    get_transactions =
      Transactions
      |> where(
           [t],
           t.commanall_id == ^commanid and t.company_id == ^compid and (t.transaction_type == "B2A")
         )
      |> order_by(desc: :transaction_date)
      |> preload(:transactionsreceipt)
      |> Repo.paginate(params)

    render(conn, EmployeeView, "manytrans_paginate.json", transactions: get_transactions)
  end

  def companyLoadMoneySingleV1(conn, params) do
    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]
    if is_nil(params["transactionId"]) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Missing/nil param, make sure you send all required params"
             }
           }
    else
      get_transactions = Transactions
                         |> where(
                              [t],
                              t.commanall_id == ^commanid and t.company_id == ^compid and t.id == ^params["transactionId"]
                            )
                         |> order_by(desc: :transaction_date)
                         |> preload(:transactionsreceipt)
                         |> Repo.one

      render(conn, EmployeeView, "singletrans_withreceipt.json", transactions: get_transactions)
    end
  end

  @doc "cardsTransactions with filter (by employee, card, amount, transaction_type, project) - note employee side transaction "
  def getCardTransactions(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanall_id, "id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      # DEPRECATED
      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.commanall_id != ^commanall_id,
                   left_join: transactionsreceipt in assoc(t, :transactionsreceipt),
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     transaction_date: t.transaction_date,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status,
                     receipt_url: transactionsreceipt.receipt_url
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id != ^commanall_id,
                   left_join: transactionsreceipt in assoc(t, :transactionsreceipt),
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status,
                     receipt_url: transactionsreceipt.receipt_url
                   })
            |> Repo.paginate(params)
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.commanall_id != ^commanall_id,
                   left_join: transactionsreceipt in assoc(t, :transactionsreceipt),
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status,
                     receipt_url: transactionsreceipt.receipt_url
                   })
            |> Repo.paginate(params)
          else
            (
              from t in Transactions,
                   where: ^merge_params,
                   having: t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.commanall_id != ^commanall_id,
                   left_join: transactionsreceipt in assoc(t, :transactionsreceipt),
                   limit: ^params["results_limit"],
                   offset: ^params["from_result"],
                   order_by: [
                     desc: t.transaction_date
                   ],
                   select: %{
                     id: t.id,
                     commanall_id: t.commanall_id,
                     amount: t.amount,
                     fee_amount: t.fee_amount,
                     final_amount: t.final_amount,
                     remark: t.remark,
                     transaction_mode: t.transaction_mode,
                     balance: t.balance,
                     previous_balance: t.previous_balance,
                     transaction_date: t.transaction_date,
                     transaction_type: t.transaction_type,
                     transaction_id: t.transaction_id,
                     category: t.category,
                     cur_code: t.cur_code,
                     projects_id: t.projects_id,
                     description: t.description,
                     status: t.status,
                     receipt_url: transactionsreceipt.receipt_url
                   })
            |> Repo.paginate(params)
          end
        end

      total_count = Enum.count(query)

      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: query.entries,
             page_number: query.page_number,
             total_pages: query.total_pages
           }

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getCardTransactionsV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employee_id employeecards_id final_amount transaction_type projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.company_id == ^company_id and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2O") or (
                     t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          else
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2O") or (
                     t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.company_id == ^company_id and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2O") or (
                     t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> limit(^params["results_limit"])
            |> offset(^params["from_result"])
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          else
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D") or (t.transaction_type == "C2O") or (
                     t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> limit(^params["results_limit"])
            |> offset(^params["from_result"])
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          end
        end

      render(conn, EmployeeView, "manytrans_paginate_receipt_project.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  # Get only pos transaction
  def getCardPOSTransactions(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      filtered_params =
        params
        |> Map.take(~w( company_id employee_id employeecards_id final_amount projects_id ))
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      from_token = [company_id: company_id]
      merge_params = Enum.concat(filtered_params, from_token)

      query =
        if is_nil(params["results_limit"]) and is_nil(params["from_result"]) do
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.company_id == ^company_id and (
                   (t.transaction_type == "C2O") or (t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          else
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                   (t.transaction_type == "C2O") or (t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          end
        else
          if is_nil(params["from_date"]) and is_nil(params["to_date"]) do
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.company_id == ^company_id and (
                   (t.transaction_type == "C2O") or (t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> limit(^params["results_limit"])
            |> offset(^params["from_result"])
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          else
            Transactions
            |> where(^merge_params)
            |> having(
                 [t],
                 t.transaction_date >= ^params["from_date"] and t.transaction_date <= ^params["to_date"] and t.company_id == ^company_id and (
                   (t.transaction_type == "C2O") or (t.transaction_type == "C2I") or (t.transaction_type == "C2F"))
               )
            |> limit(^params["results_limit"])
            |> offset(^params["from_result"])
            |> order_by(desc: :transaction_date)
            |> preload(:transactionsreceipt)
            |> preload(:projects)
            |> Repo.paginate(params)
          end
        end

      render(conn, EmployeeView, "manytrans_paginate_receipt_project.json", transactions: query)
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc   "get companys last five topup to employee"
  def getLastFiveTopup(conn, _params) do

    %{"id" => compid} = conn.assigns[:current_user]

    #    DEPRECATED
    get_transactions = Repo.all from t in Transactions,
                                where: t.company_id == ^compid and (
                                  t.transaction_type == "A2C" and t.transaction_mode == "D") and t.status == "S",
                                order_by: [
                                  desc: t.transaction_date
                                ],
                                limit: 5,
                                select: %{
                                  id: t.id,
                                  amount: t.amount,
                                  fee_amount: t.fee_amount,
                                  final_amount: t.final_amount,
                                  balance: t.balance,
                                  previous_balance: t.previous_balance,
                                  remark: t.remark,
                                  transaction_mode: t.transaction_mode,
                                  transaction_date: t.transaction_date,
                                  transaction_type: t.transaction_type,
                                  transaction_id: t.transaction_id,
                                  category: t.category,
                                  cur_code: t.cur_code,
                                  projects_id: t.projects_id,
                                  description: t.description,
                                  status: t.status
                                }
    render(conn, ViolacorpWeb.SuccessView, "success.json", response: get_transactions)
  end

  def getLastFiveTopupV1(conn, _params) do
    %{"id" => compid} = conn.assigns[:current_user]

    query = Transactions
            |> where(
                 [t],
                 t.company_id == ^compid and (
                   (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                     t.transaction_type == "C2A" and t.transaction_mode == "D")) and t.status == "S"
               )
            |> limit(5)
            |> order_by(desc: :transaction_date)
            |> Repo.all

    render(conn, EmployeeView, "manytrans_noReceipt.json", transactions: query)
  end


  @doc   "inserts Mandate info to DB"
  def insertMandate(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

      check = Repo.one from m in Mandate, where: m.commanall_id == ^commanid, select: count(m.id)
      if check > 0 do
        json conn, %{status_code: "202", response: "Mandate already exists"}
      else
        if (
             is_nil(params["terms_of_service"]) or is_nil(params["terms_and_conditions"]) or is_nil(
               params["cookies_policy"]
             ) or is_nil(params["privacy_policy"])) or (
             params["terms_of_service"] != "yes" or params["terms_and_conditions"] != "yes" or params["cookies_policy"] != "yes" or params["privacy_policy"] != "yes") do

          json conn, %{status_code: "4003", response: "Missing params/not ticked all checkboxes"}
        else
          mandate_data = %{
            terms_of_service: params["terms_of_service"],
            terms_and_conditions: params["terms_and_conditions"],
            cookies_policy: params["cookies_policy"],
            privacy_policy: params["privacy_policy"],
          }
          directors_id = Repo.one from c in Company, where: c.id == ^compid,
                                                     left_join: director in assoc(c, :directors),
                                                     where: director.sequence == 1,
                                                     select: director.id
          mandate = %{
            "commanall_id" => commanid,
            "directors_id" => directors_id,
            "response_data" => Poison.encode!(mandate_data),
            "inserted_by" => commanid
          }
          changeset = Mandate.changeset(%Mandate{}, mandate)
          case Repo.insert(changeset) do
            {:ok, _mandate} ->
              json conn, %{status_code: "200", response: "Mandate inserted successfully"}
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

  @doc "company's internal messages list"
  def companyNotification(conn, params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

    notifications = (
                      from e in Employee,
                           where: e.company_id == ^company_id,
                           left_join: c in assoc(e, :commanall),
                           where: c.employee_id == e.id,
                           left_join: n in assoc(c, :notifications),
                           where: n.commanall_id == c.id or n.commanall_id == ^commanid,
                           order_by: [
                             desc: n.inserted_at
                           ],
                           select: %{
                             id: n.id,
                             subject: n.subject,
                             message: n.message,
                             status: n.status,
                             date_time: n.inserted_at
                           })
                    |> Repo.paginate(params)

    json conn,
         %{
           status_code: "200",
           total_count: notifications.total_entries,
           data: notifications.entries,
           page_number: notifications.page_number,
           total_pages: notifications.total_pages
         }
  end

  @doc "employee's internal messages list"
  def employeeNotification(conn, params) do

    get_commanall_id = Repo.one from a in Commanall, where: a.employee_id == ^params["employeeId"],
                                                     select: %{
                                                       id: a.id
                                                     }

    notifications = (
                      from e in Notifications,
                           where: e.commanall_id == ^get_commanall_id.id,
                           order_by: [
                             desc: e.inserted_at
                           ],
                           select: %{
                             id: e.id,
                             subject: e.subject,
                             message: e.message,
                             status: e.status,
                             date_time: e.inserted_at
                           })
                    |> Repo.paginate(params)

    total_count = Enum.count(notifications)
    json conn,
         %{
           status_code: "200",
           total_count: total_count,
           data: notifications.entries,
           page_number: notifications.page_number,
           total_pages: notifications.total_pages
         }
  end

  @doc "Get company details for menus"
  def menuList(conn, _params) do
    %{"commanall_id" => commanid, "id" => compid} = conn.assigns[:current_user]

    company_info = Repo.one from c in Company, where: c.id == ^compid,
                                               select: %{
                                                 name: c.company_name,
                                                 type: c.company_type
                                               }


    contact_info = Repo.one from c in Contacts, where: c.commanall_id == ^commanid and c.is_primary == ^"Y",
                                                select: %{
                                                  number: c.contact_number
                                                }

    step_info = Repo.one from c in Commanall, where: c.id == ^commanid,
                                              select: %{
                                                step_number: c.reg_step,
                                                step: c.step,
                                              }

    directors_info = Repo.all from d in Directors, where: d.company_id == ^compid,
                                                   select: %{
                                                     id: d.id,
                                                     position: d.position,
                                                     title: d.title,
                                                     first_name: d.first_name,
                                                     last_name: d.last_name,
                                                   }

    dir_count = Repo.one from d in Directors, where: d.company_id == ^compid, select: count(d.id)


    chk_address = Repo.one from a in Address, where: a.commanall_id == ^commanid and a.is_primary == ^"N",
                                              select: count(a.id)

    treding_address = if chk_address > 0 do
      "Yes"
    else
      "No"
    end

    response = %{
      company_name: company_info.name,
      company_type: company_info.type,
      contact: contact_info.number,
      step_number: step_info.step_number,
      step: step_info.step,
      treding_address: treding_address,
      no_of_directors: dir_count,
      directors: directors_info
    }

    json conn, response
  end

  @doc "For Id Proof - company upload employee document"
  def uploadKycFirst(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      employee_id = params["employeeId"]

      commonall_info = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                     select: %{
                                                       id: c.id
                                                     }

      file_extension = params["file_extension"]
      file_location_address = if params["content"] != "" do
        image_address = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
        if file_extension == "pdf" do
          ViolacorpWeb.Main.Assetstore.upload_document(image_address)
        else
          ViolacorpWeb.Main.Assetstore.upload_image(image_address)
        end
      else
        nil
      end

      image_bucket = Application.get_env(:violacorp, :aws_bucket)
      mode = Application.get_env(:violacorp, :aws_mode)
      region = Application.get_env(:violacorp, :aws_region)
      aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

      file_name = file_location_address
                  |> String.split(aws_url, trim: true)
                  |> Enum.join()

      kyc_common_id = commonall_info.id
      existingKycFirst = Repo.all(
        from e in Kycdocuments, where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A"
      )
      if existingKycFirst do
        from(e in Kycdocuments, where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A")
        |> Repo.update_all(
             set: [
               status: "D"
             ]
           )
      end


      kycdocuments = %{
        "commanall_id" => commonall_info.id,
        "documenttype_id" => params["documenttype_id"],
        "document_number" => params["document_number"],
        "expiry_date" => params["expiry_date"],
        "issue_date" => params["issue_date"],
        "file_type" => params["file_extension"],
        "content" => String.replace_leading(params["content"], "data:image/jpeg;base64,", ""),
        "file_location" => file_location_address,
        "file_name" => file_name,
        "status" => "A",
        "type" => "I",
        "inserted_by" => commanid
      }
      kycdocuments_changeset = Kycdocuments.changeset(%Kycdocuments{}, kycdocuments)

      case Repo.insert(kycdocuments_changeset) do
        {:ok, _director} ->
          employee = Repo.get!(Employee, employee_id)
          update_status = %{"status" => "K2"}
          commanall_changeset = Employee.changesetStatus(employee, update_status)
          Repo.update(commanall_changeset)
          json conn, %{status_code: "200", message: "Id Proof Uploaded."}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For Address Proof - mobApp"
  def uploadKycSecond(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      employee_id = params["employeeId"]

      commonall_info = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                     select: %{
                                                       id: c.id
                                                     }
      common_all_id = commonall_info.id

      file_extension = params["file_extension"]
      file_location_id = if params["content"] != "" do
        image_id = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
        if file_extension == "pdf" do
          ViolacorpWeb.Main.Assetstore.upload_document(image_id)
        else
          ViolacorpWeb.Main.Assetstore.upload_image(image_id)
        end
      else
        nil
      end

      image_bucket = Application.get_env(:violacorp, :aws_bucket)
      mode = Application.get_env(:violacorp, :aws_mode)
      region = Application.get_env(:violacorp, :aws_region)
      aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

      file_name = file_location_id
                  |> String.split(aws_url, trim: true)
                  |> Enum.join()

      kycdocuments = %{
        "commanall_id" => common_all_id,
        "documenttype_id" => params["documenttype_id"],
        "file_type" => params["file_extension"],
        "content" => String.replace_leading(params["content"], "data:image/jpeg;base64,", ""),
        "file_location" => file_location_id,
        "file_name" => file_name,
        "status" => "A",
        "type" => "A",
        "inserted_by" => commanid
      }
      kycdocuments_changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, kycdocuments)

      case Repo.insert(kycdocuments_changeset) do
        {:ok, _director} ->
          accomplish_response = TestController.create_employee(common_all_id, commanid)

          employee = Repo.get!(Employee, employee_id)
          update_status = if accomplish_response == "200" do
            %{"status" => "A"}
          else
            %{"status" => "AP"}
          end
          status_code = if accomplish_response == "200" do
            "200"
          else
            "5008"
          end
          messages = if accomplish_response == "200" do
            "Address Proof Uploaded."
          else
            accomplish_response
          end
          commanall_changeset = Employee.changesetStatus(employee, update_status)
          Repo.update(commanall_changeset)

          if accomplish_response == "200" do
            employee_verify_kyc = "NO"
            if employee_verify_kyc == "YES" do
              Accomplish.register_fourstop(employee_id)
            end
            comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                            select: %{
                                                              accomplish_userid: c.accomplish_userid,
                                                              employee_id: c.employee_id
                                                            }
            kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^common_all_id,
                                                            where: d.type == "I",
                                                            select: %{
                                                              document_number: d.document_number,
                                                              documenttype_id: d.documenttype_id,
                                                              expiry_date: d.expiry_date,
                                                              issue_date: d.issue_date,
                                                              file_type: d.file_type,
                                                              file_name: d.file_name,
                                                              content: d.content,
                                                              file_location: d.file_location
                                                            }
            #            emp_info = Repo.one from e in Employee, where: e.id == ^comman_all_data.employee_id,
            #                                                    select: %{
            #                                                      first_name: e.first_name,
            #                                                      last_name: e.last_name
            #                                                    }

            documenttype_id = if kyc_document.documenttype_id == 9 do
              "2"
            else
              if kyc_document.documenttype_id == 10 do
                "0"
              else
                "1"
              end
            end

            request = %{
              user_id: comman_all_data.accomplish_userid,
              commanall_id: common_all_id,
              issue_date: kyc_document.issue_date,
              expiry_date: kyc_document.expiry_date,
              number: kyc_document.document_number,
              type: documenttype_id
            }
            _response = Accomplish.upload_identification(request)

            #            request_document = %{
            #              user_id: comman_all_data.accomplish_userid,
            #              first_name: emp_info.first_name,
            #              last_name: emp_info.last_name,
            #              file_name: kyc_document.file_name,
            #              file_extension: ".#{kyc_document.file_type}",
            #              content: kyc_document.content
            #            }
            #
            #            _response_document = Accomplish.create_document(request_document)

            json conn, %{status_code: status_code, message: messages}
          else
            json conn,
                 %{
                   status_code: status_code,
                   errors: %{
                     message: messages
                   }
                 }
          end
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For Id Proof - company upload employee document"
  def uploadEmployeeKycFirstV1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      employee_id = params["employeeId"]
      commonall_info = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                     select: %{
                                                       id: c.id
                                                     }
      if !is_nil(commonall_info) do

        kycdocuments = %{
          "commanall_id" => commonall_info.id,
          "documenttype_id" => params["documenttype_id"],
          "document_number" => params["document_number"],
          "country" => params["country"],
          "expiry_date" => params["expiry_date"],
          "issue_date" => params["issue_date"],
          "status" => "A",
          "type" => "I",
          "inserted_by" => commanid
        }
        kycdocuments_changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, kycdocuments)
        if kycdocuments_changeset.valid? do
          kyc_common_id = commonall_info.id
          existingKycFirst = Repo.all(
            from e in Kycdocuments, where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A"
          )
          if existingKycFirst do
            from(e in Kycdocuments, where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A")
            |> Repo.update_all(
                 set: [
                   status: "R"
                 ]
               )
          end

          file_location_one = if params["image_one"] != "" do
            #              image_address = String.replace_leading(params["image_one"], "data:image/jpeg;base64,", "")
            ViolacorpWeb.Main.Assetstore.upload_image(params["image_one"])
          else
            nil
          end

          file_location_two = if params["image_two"] != "" do
            #              image_address = String.replace_leading(params["image_two"], "data:image/jpeg;base64,", "")
            ViolacorpWeb.Main.Assetstore.upload_image(params["image_two"])
          else
            nil
          end

          file_name = if !is_nil(file_location_one) do
            Path.basename(file_location_one)
          else
            if !is_nil(file_location_two) do
              Path.basename(file_location_two)
            else
              nil
            end
          end
          file_map = %{
            "file_location" => file_location_one,
            "file_location_two" => file_location_two,
            "file_name" => file_name,
          }
          new_kyc_map = Map.merge(kycdocuments, file_map)
          changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, new_kyc_map)
          case Repo.insert(changeset) do
            {:ok, _director} ->
              employee = Repo.get!(Employee, employee_id)
              update_status = %{"status" => "ADINFO"}
              commanall_changeset = Employee.changesetStatus(employee, update_status)
              Repo.update(commanall_changeset)
              json conn, %{status_code: "200", message: "Id Proof Uploaded."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: kycdocuments_changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "employee does not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def uploadEmployeeKycSecondV1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      employee_id = params["employeeId"]

      commonall_info = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                     select: %{
                                                       id: c.id,
                                                     }
      if !is_nil(commonall_info) do
        employee = Repo.get!(Employee, employee_id)
        if employee.status === "ADINFO" do
          common_all_id = commonall_info.id
          kycdocuments = %{
            "commanall_id" => common_all_id,
            "documenttype_id" => params["documenttype_id"],
            "document_number" => params["document_number"],
            "type" => "A",
            "status" => "A",
            "inserted_by" => commanid
          }
          kycdocuments_changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, kycdocuments)
          if kycdocuments_changeset.valid? do
            existingKycFirst = Repo.all(
              from e in Kycdocuments, where: e.commanall_id == ^common_all_id and e.type == "A" and e.status == "A"
            )
            if existingKycFirst do
              from(e in Kycdocuments, where: e.commanall_id == ^common_all_id and e.type == "A" and e.status == "A")
              |> Repo.update_all(
                   set: [
                     status: "R"
                   ]
                 )
            end
            file_location_one = if params["image_one"] != "" do
              #              image_address = String.replace_leading(params["image_one"], "data:image/jpeg;base64,", "")
              ViolacorpWeb.Main.Assetstore.upload_image(params["image_one"])
            else
              nil
            end
            file_name = if !is_nil(file_location_one), do: Path.basename(file_location_one), else: nil

            file_map = %{
              "file_location" => file_location_one,
              "file_name" => file_name,
            }
            new_kyc_map = Map.merge(kycdocuments, file_map)
            changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, new_kyc_map)
            case Repo.insert(changeset) do
              {:ok, _director} ->

                #                check_status = Accomplish.register_fourstop(employee_id)
                check_status = TestController.employee_verify_GBG(commonall_info.id)
                if check_status["status"] == "200" do

                  accomplish_response = TestController.create_employee(commonall_info.id, commanid)

                  update_status = if accomplish_response == "200" do
                    %{"status" => "A"}
                  else
                    %{"status" => "AP"}
                  end
                  status_code = if accomplish_response == "200" do
                    "200"
                  else
                    "5008"
                  end
                  messages = if accomplish_response == "200" do
                    "Success! Kyc Uploaded"
                  else
                    accomplish_response
                  end

                  commanall_changeset = Employee.changesetStatus(employee, update_status)
                  Repo.update(commanall_changeset)

                  if accomplish_response == "200" do

                    comman_all_data = Repo.one from c in Commanall, where: c.id == ^commonall_info.id,
                                                                    select: %{
                                                                      accomplish_userid: c.accomplish_userid,
                                                                      employee_id: c.employee_id
                                                                    }
                    kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^commonall_info.id,
                                                                    where: d.type == "I" and d.status == "A",
                                                                    select: %{
                                                                      document_number: d.document_number,
                                                                      documenttype_id: d.documenttype_id,
                                                                      expiry_date: d.expiry_date,
                                                                      issue_date: d.issue_date,
                                                                      file_type: d.file_type,
                                                                      content: d.content,
                                                                      file_name: d.file_name,
                                                                      file_location: d.file_location
                                                                    }

                    documenttype_id = if kyc_document.documenttype_id == 9 do
                      "2"
                    else
                      if kyc_document.documenttype_id == 10 do
                        "0"
                      else
                        "1"
                      end
                    end

                    request = %{
                      "worker_type" => "create_identification",
                      "user_id" => comman_all_data.accomplish_userid,
                      "commanall_id" => commonall_info.id,
                      "issue_date" => kyc_document.issue_date,
                      "expiry_date" => kyc_document.expiry_date,
                      "number" => kyc_document.document_number,
                      "type" => documenttype_id,
                      "employee_id" => employee_id,
                      "request_id" => commanid
                    }

                    Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

                    json conn, %{status_code: status_code, message: messages}
                  else
                    json conn,
                         %{
                           status_code: status_code,
                           errors: %{
                             message: messages
                           }
                         }
                  end
                else
                  update_status = %{"status" => "AP"}
                  commanall_changeset = Employee.changesetStatus(employee, update_status)
                  Repo.update(commanall_changeset)
                  json conn,
                       %{
                         status_code: "5008",
                         errors: %{
                           message: check_status["message"]
                         }
                       }
                end
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: kycdocuments_changeset)
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Please complete your information step first."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "employee does not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For Id Proof - company upload employee document"
  def uploadeKycFirst(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      employee_id = params["employeeId"]

      commonall_info = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                     select: %{
                                                       id: c.id
                                                     }
      if is_nil(commonall_info) do
        json conn,
             %{
               status_code: "404",
               errors: %{
                 message: "Employee Does not exist."
               }
             }
      else
        common_all_id = commonall_info.id

        existingKycFirst = Repo.all(
          from e in Kycdocuments, where: e.commanall_id == ^common_all_id and e.type == "I" and e.status == "A"
        )
        if existingKycFirst do
          from(e in Kycdocuments, where: e.commanall_id == ^common_all_id and e.type == "I" and e.status == "A")
          |> Repo.update_all(
               set: [
                 status: "D"
               ]
             )
        end

        kycdocuments = %{
          "commanall_id" => common_all_id,
          "documenttype_id" => params["documenttype_id"],
          "document_number" => params["document_number"],
          "expiry_date" => params["expiry_date"],
          "issue_date" => params["issue_date"],
          "status" => "A",
          "type" => "I",
          "inserted_by" => commanid
        }
        kycdocuments_changeset = Kycdocuments.changeset(%Kycdocuments{}, kycdocuments)

        existing = Repo.get_by(Kycdocuments, commanall_id: commanid, status: "A", type: "I")

        if !is_nil(existing) do
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Contact your administrator"
                 }
               }
        else

          case Repo.insert(kycdocuments_changeset) do
            {:ok, _director} ->
              commanall = Repo.get_by(Commanall, id: commanid)
              ex_ip_address = conn.remote_ip
                              |> Tuple.to_list
                              |> Enum.join(".")
              ht_ip_address = get_req_header(conn, "ip_address")
                              |> List.first
              new_ip_address = %{ex_ip: ex_ip_address, ht_ip: ht_ip_address}
                               |> Poison.encode!()
              _ip_address = if new_ip_address == commanall.ip_address do
                ""
              else
                ip_map = %{
                  ip_address: new_ip_address
                }
                ip_changeset = Commanall.update_token(commanall, ip_map)
                Repo.update(ip_changeset)
              end
              check_status = Accomplish.register_fourstop(employee_id)
              employee = Repo.get!(Employee, employee_id)
              if check_status["status"] == "200" do
                accomplish_response = TestController.create_employee(common_all_id, commanid)

                employee = Repo.get!(Employee, employee_id)
                update_status = if accomplish_response == "200" do
                  %{"status" => "A"}
                else
                  %{"status" => "AP"}
                end
                status_code = if accomplish_response == "200" do
                  "200"
                else
                  "5008"
                end
                messages = if accomplish_response == "200" do
                  "Id Proof Uploaded."
                else
                  accomplish_response
                end
                commanall_changeset = Employee.changesetStatus(employee, update_status)
                Repo.update(commanall_changeset)

                if accomplish_response == "200" do
                  comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                                  select: %{
                                                                    accomplish_userid: c.accomplish_userid,
                                                                    employee_id: c.employee_id
                                                                  }
                  kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^common_all_id,
                                                                  where: d.type == "I",
                                                                  where: d.status == "A",
                                                                  select: %{
                                                                    document_number: d.document_number,
                                                                    documenttype_id: d.documenttype_id,
                                                                    expiry_date: d.expiry_date,
                                                                    issue_date: d.issue_date,
                                                                    file_type: d.file_type,
                                                                    file_name: d.file_name,
                                                                    content: d.content,
                                                                    file_location: d.file_location
                                                                  }

                  documenttype_id = if kyc_document.documenttype_id == 9 do
                    "2"
                  else
                    if kyc_document.documenttype_id == 10 do
                      "0"
                    else
                      "1"
                    end
                  end


                  request = %{
                    "worker_type" => "create_identification",
                    "user_id" => comman_all_data.accomplish_userid,
                    "commanall_id" => commonall_info.id,
                    "issue_date" => kyc_document.issue_date,
                    "expiry_date" => kyc_document.expiry_date,
                    "number" => kyc_document.document_number,
                    "employee_id" => employee_id,
                    "type" => documenttype_id,
                    "request_id" => commanid
                  }

                  Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

                  json conn, %{status_code: status_code, message: messages}

                  #                    request = %{
                  #                      user_id: comman_all_data.accomplish_userid,
                  #                      commanall_id: common_all_id,
                  #                      issue_date: kyc_document.issue_date,
                  #                      expiry_date: kyc_document.expiry_date,
                  #                      number: kyc_document.document_number
                  #                    }
                  #
                  #                    response_identify = Accomplish.create_identification(request)


                  #                    response_code = response_identify["result"]["code"]
                  #                    response_message = response_identify["result"]["friendly_message"]
                  #
                  #                    if response_code == "0000" do
                  #                      json conn, %{status_code: status_code, message: messages}
                  #                    else
                  #                      update_status =  %{"status" => "AP"}
                  #                      commanall_changeset = Employee.changesetStatus(employee, update_status)
                  #                      Repo.update(commanall_changeset)
                  #                      json conn,
                  #                           %{
                  #                             status_code: "5008",
                  #                             errors: %{
                  #                               message: response_message
                  #                             }
                  #                           }
                  #                    end
                else
                  json conn,
                       %{
                         status_code: status_code,
                         errors: %{
                           message: messages
                         }
                       }
                end
              else
                update_status = %{"status" => "AP"}
                commanall_changeset = Employee.changesetStatus(employee, update_status)
                Repo.update(commanall_changeset)
                json conn,
                     %{
                       status_code: "5007",
                       errors: %{
                         message: check_status["message"]
                       }
                     }
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

  # employee registration
  def employeeRegistration(conn, params) do

    employee_id = params["employeeId"]
    email_id = params["email_id"]
    mobile = params["mobile"]

    # check email or mobile is alrady used to not
    [count_email] = Repo.all from c in Commanall,
                             where: c.email_id == ^email_id,
                             select: count(c.id)

    [count_mobile] = Repo.all from con in Contacts,
                              where: con.contact_number == ^mobile and con.is_primary == ^"Y",
                              select: count(con.id)

    response = if count_email > 0 and count_mobile > 0 do
      %{
        status_code: "4003",
        errors: %{
          message: "Email id and Mobile number both used by another user."
        }
      }
    else
      if count_email > 0 do
        %{
          status_code: "4003",
          errors: %{
            message: "Email id used by another user."
          }
        }
      else
        if count_mobile > 0 do
          %{
            status_code: "4003",
            errors: %{
              message: "Mobile number used by another user."
            }
          }
        else
          nil
        end
      end
    end

    if response == nil do
      # Update email id and mobile number
      commanall = Repo.get_by(Commanall, employee_id: employee_id)
      common_all_id = commanall.id
      change_email = %{"email_id" => email_id}
      changeset_commanall = Commanall.changeset_updateemail(commanall, change_email)
      case Repo.update(changeset_commanall) do
        {:ok, _company} ->
          contacts = Repo.get_by(Contacts, commanall_id: common_all_id, is_primary: "Y")
          change_contact = %{"contact_number" => mobile}
          changeset_contacts = Contacts.changeset_number(contacts, change_contact)
          case Repo.update(changeset_contacts) do
            {:ok, _company} ->
              # Send to third party data
              accomplish_response = TestController.create_employee(common_all_id, common_all_id)

              employee = Repo.get!(Employee, employee_id)
              update_status = if accomplish_response == "200" do
                %{"status" => "A"}
              else
                %{"status" => "AP"}
              end
              status_code = if accomplish_response == "200" do
                "200"
              else
                "5008"
              end
              messages = if accomplish_response == "200" do
                "Registration have done."
              else
                accomplish_response
              end
              commanall_changeset = Employee.changesetStatus(employee, update_status)
              Repo.update(commanall_changeset)

              if accomplish_response == "200" do
                comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                                select: %{
                                                                  accomplish_userid: c.accomplish_userid,
                                                                  employee_id: c.employee_id
                                                                }
                kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^common_all_id,
                                                                where: d.type == "I",
                                                                where: d.status == "A",
                                                                select: %{
                                                                  document_number: d.document_number,
                                                                  documenttype_id: d.documenttype_id,
                                                                  expiry_date: d.expiry_date,
                                                                  issue_date: d.issue_date,
                                                                  file_type: d.file_type,
                                                                  content: d.content,
                                                                  file_location: d.file_location
                                                                }

                documenttype_id = if kyc_document.documenttype_id == 9 do
                  "2"
                else
                  if kyc_document.documenttype_id == 10 do
                    "0"
                  else
                    "1"
                  end
                end
                request = %{
                  user_id: comman_all_data.accomplish_userid,
                  commanall_id: common_all_id,
                  issue_date: kyc_document.issue_date,
                  expiry_date: kyc_document.expiry_date,
                  number: kyc_document.document_number,
                  type: documenttype_id
                }
                _response = Accomplish.upload_identification(request)
                json conn, %{status_code: status_code, message: messages}
              else
                json conn,
                     %{
                       status_code: status_code,
                       errors: %{
                         message: messages
                       }
                     }
              end

            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end

    else
      json conn, response
    end
  end

  @doc "Assign a project to an employee"
  def assignProject(conn, params) do
    unless map_size(params) == 0 do

      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      [count] = Repo.all from a in Assignproject,
                         where: a.employee_id == ^params["employee_id"] and a.projects_id == ^params["projects_id"],
                         select: count(a.id)
      if count == 0 do
        assignproject = %{
          "employee_id" => params["employee_id"],
          "projects_id" => params["projects_id"],
          "inserted_by" => commanid
        }
        changeset = Assignproject.changeset(%Assignproject{}, assignproject)

        case Repo.insert(changeset) do
          {:ok, _response} -> render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Project assigned.")
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end

      else
        json conn,
             %{
               status_code: "404",
               errors: %{
                 message: "Project already assigned."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Assign a project to an employee"
  def projectList(conn, params) do
    [count] = Repo.all from a in Assignproject, where: a.employee_id == ^params["employeeId"],
                                                select: count(a.id)
    requested_card_list = (from a in Assignproject,
                                where: a.employee_id == ^params["employeeId"],
                                left_join: p in assoc(a, :projects),
                                where: p.is_delete == "N",
                                order_by: [
                                  desc: a.inserted_at
                                ],
                                select: %{
                                  id: a.id,
                                  projects_id: a.projects_id,
                                  project_name: p.project_name,
                                  start_date: p.start_date
                                })
                          |> Repo.paginate(params)
    total_count = Enum.count(requested_card_list)

    if count == 0 do
      json conn,
           %{
             status_code: "404",
             errors: %{
               message: "No record found."
             }
           }
    else
      json conn,
           %{
             status_code: "200",
             total_count: total_count,
             data: requested_card_list.entries,
             page_number: requested_card_list.page_number,
             total_pages: requested_card_list.total_pages
           }
    end
  end

  @doc "For Id Proof - company upload employee document"
  def uploadDocument(conn, params) do

    file_extension = params["file_extension"]
    file_location_address = if params["content"] != "" do
      image_address = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
      if file_extension == "pdf" do
        ViolacorpWeb.Main.Assetstore.upload_document(image_address)
      else
        ViolacorpWeb.Main.Assetstore.upload_image(image_address)
      end
    else
      nil
    end

    text conn, file_location_address
  end

  @doc "change pin function"
  def employeeChangePin(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      # get employee details
      get_employee = Repo.get_by(Commanall, employee_id: params["employee_id"])

      if is_nil(get_employee) do
        json conn, %{status_code: "4003", messages: "Employee does not exist"}
      else
        pin = params["pin"]
        check_employee = Repo.get(Employee, get_employee.employee_id)
        if check_employee.company_id == company_id do
          new_pin = %{
            vpin: pin
          }
          changeset = Commanall.changeset_updatepin(get_employee, new_pin)

          case Repo.update(changeset) do
            {:ok, _otpmap} -> json conn, %{status_code: "200", messages: "Passcode Changed Successfully"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn, %{status_code: "4003", messages: "Employee does not exist for this company"}
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end

  end

  def changeEmployeePin(conn, _params) do
    %{"commanall_id" => _commanid, "id" => id} = conn.assigns[:current_user]

    getallemployee = Repo.all(from e in Employee, where: e.company_id == ^id and e.status == "A", select: e.id)

    if is_nil(getallemployee) do
      json conn,
           %{
             status_code: "404",
             errors: %{
               message: "Employee dose not found."
             }
           }
    else

      response = Enum.each(
        getallemployee,
        fn employee_id ->
          commanall = Repo.one(from c in Commanall, where: c.employee_id == ^employee_id)
          changeset = %{vpin: "1234"}
          new_changeset = Commanall.changeset_updatepin(commanall, changeset)

          case Repo.update(new_changeset) do
            {:ok, _commanall} -> true
            {:error, _changeset} -> false
          end
        end
      )

      case response do
        :ok ->
          json conn, %{status_code: "200", messages: "Pin Changed Successfully."}
        :error ->
          json conn,
               %{
                 status_code: "404",
                 errors: %{
                   message: "Something is wrong."
                 }
               }
      end
      json conn, response
    end
  end

  def dir_as_employee(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      if params["as_employee"] == "Y" or is_nil(params["directors_id"]) or params["directors_id"] == "" do

        director = Repo.one(
          from d in Directors, where: d.id == ^params["directors_id"] and d.as_employee == "N",
                               left_join: daddress in assoc(d, :addressdirectors),
                               left_join: dcontacts in assoc(d, :contactsdirectors),
                               select: %{
                                 id: d.id,
                                 company_id: d.company_id,
                                 title: d.title,
                                 first_name: d.first_name,
                                 last_name: d.last_name,
                                 date_of_birth: d.date_of_birth,
                                 gender: d.gender,
                                 email_id: d.email_id,
                                 sequence: d.sequence,
                                 address_line_one: daddress.address_line_one,
                                 address_line_two: daddress.address_line_two,
                                 address_line_three: daddress.address_line_three,
                                 post_code: daddress.post_code,
                                 county: daddress.county,
                                 town: daddress.town,
                                 contact_number: dcontacts.contact_number
                               }
        )


        if director do
          case checkDirectorKycStep(params["directors_id"]) do
            "Yes" ->
              if director.sequence == 1 do
                commanall = Repo.get(Commanall, commanid)
                if commanall do
                  unless is_nil(commanall.accomplish_userid) do
                    employee_details = %{
                      "company_id" => commanall.company_id,
                      "director_id" => director.id,
                      "employeeids" => nil,
                      "departments_id" => nil,
                      "title" => director.title,
                      "position" => nil,
                      "first_name" => director.first_name,
                      "last_name" => director.last_name,
                      "date_of_birth" => director.date_of_birth,
                      "gender" => director.gender,
                      "status" => "A",
                      "inserted_by" => commanid
                    }
                    employee_changeset = Employee.changeset(%Employee{}, employee_details)

                    case Repo.insert(employee_changeset) do
                      {:ok, employee} -> employee_id = employee.id

                                         update_commanall = %{"employee_id" => employee_id, "as_employee" => "Y"}
                                         commanall_changeset = Commanall.changeset_as_employee(
                                           commanall,
                                           update_commanall
                                         )

                                         case Repo.update(commanall_changeset) do
                                           {:ok, commanall} ->
                                             getdirectorsdetails = Repo.get!(Directors, params["directors_id"])
                                             as_employee_director = %{
                                               as_employee: "Y",
                                               employee_id: employee_id
                                             }
                                             director_changeset = Directors.update_status(
                                               getdirectorsdetails,
                                               as_employee_director
                                             )
                                             Repo.update(director_changeset)
                                             type = Application.get_env(:violacorp, :card_type)
                                             accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
                                             accomplish_longitude = Application.get_env(
                                               :violacorp,
                                               :accomplish_longitude
                                             )
                                             fulfilment_config_id = Application.get_env(
                                               :violacorp,
                                               :fulfilment_config_id_p
                                             )

                                             bin_id = Application.get_env(:violacorp, :gbp_card_bin_id)
                                             number = Application.get_env(:violacorp, :gbp_card_number)
                                             request = %{
                                               type: type,
                                               bin_id: bin_id,
                                               number: number,
                                               currency: "GBP",
                                               user_id: commanall.accomplish_userid,
                                               status: 12,
                                               fulfilment_config_id: fulfilment_config_id,
                                               fulfilment_notes: "create cards for user",
                                               fulfilment_reason: 1,
                                               fulfilment_status: 1,
                                               latitude: accomplish_latitude,
                                               longitude: accomplish_longitude,
                                               position_description: "",
                                               acceptance2: 2,
                                               acceptance: 1
                                             }

                                             response = Accomplish.create_card(request)
                                             response_code = response["result"]["code"]

                                             if response_code == "0000" do
                                               # Update commanall card_requested
                                               card_request = %{"card_requested" => "Y"}
                                               changeset_commanall = Commanall.changesetRequest(commanall, card_request)
                                               currencies_id = Repo.one from c in Currencies,
                                                                        where: c.currency_code == ^response["info"]["currency"],
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
                                                 "expiry_date" => response["info"]["security"]["expiry_date"],
                                                 "source_id" => response["info"]["original_source_id"],
                                                 "activation_code" => response["info"]["security"]["activation_code"],
                                                 "status" => response["info"]["status"],
                                                 "card_type" => "P",
                                                 "inserted_by" => commanid
                                               }
                                               changeset_comacc = Employeecards.changeset(
                                                 %Employeecards{},
                                                 employeecard
                                               )
                                               Repo.insert(changeset_comacc)
                                               Repo.update(changeset_commanall)
                                               [count_card] = Repo.all from d in Employeecards,
                                                                       where: d.employee_id == ^employee_id and (
                                                                         d.status == "1" or d.status == "4" or d.status == "12"),
                                                                       select: %{
                                                                         count: count(d.id)
                                                                       }
                                               new_number = %{"no_of_cards" => count_card.count}
                                               cards_changeset = Employee.updateEmployeeCardschangeset(
                                                 employee,
                                                 new_number
                                               )
                                               Repo.update(cards_changeset)
                                               json conn,
                                                    %{status_code: "200", message: "Success, employee account created"}
                                             else
                                               json conn,
                                                    %{
                                                      status_code: "4003",
                                                      message: "failed to request card from accomplish"
                                                    }
                                             end

                                           {:error, changeset} ->
                                             conn
                                             |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                                         end
                      {:error, changeset} ->
                        conn
                        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                    end
                  else
                    json conn,
                         %{
                           status_code: "4003",
                           errors: %{
                             message: "Not registered with accomplish yet"
                           }
                         }
                  end
                else
                  json conn,
                       %{
                         status_code: "4003",
                         errors: %{
                           message: "No common user found"
                         }
                       }
                end
              else

                # check email or mobile is alrady used to not
                [count_email] = if is_nil(director.email_id) do
                  [0]
                else
                  Repo.all from c in Commanall,
                           where: c.email_id == ^director.email_id,
                           select: count(c.id)
                end

                [count_mobile] = if is_nil(director.contact_number) do
                  [0]
                else
                  Repo.all from con in Contacts,
                           where: con.contact_number == ^director.contact_number and con.is_primary == ^"Y",
                           select: count(con.id)
                end

                response = if count_email > 0 and count_mobile > 0 do
                  %{
                    status_code: "4003",
                    errors: %{
                      message: "Email id and Mobile number both used by another user."
                    }
                  }
                else
                  if count_email > 0 do
                    %{
                      status_code: "4003",
                      errors: %{
                        message: "Email id used by another user."
                      }
                    }
                  else
                    if count_mobile > 0 do
                      %{
                        status_code: "4003",
                        errors: %{
                          message: "Mobile number used by another user."
                        }
                      }
                    else
                      nil
                    end
                  end
                end

                if response == nil do
                  country_id = Application.get_env(:violacorp, :country_id)
                  country_code = Application.get_env(:violacorp, :country_code)

                  employee = %{
                    "company_id" => director.company_id,
                    "director_id" => director.id,
                    "employeeids" => params["employee_ids"],
                    "departments_id" => params["departments_id"],
                    "title" => director.title,
                    "position" => params["position"],
                    "first_name" => director.first_name,
                    "last_name" => director.last_name,
                    "date_of_birth" => director.date_of_birth,
                    "gender" => director.gender,
                    "status" => "A",
                    "is_manager" => params["is_manager"],
                    "inserted_by" => commanid
                  }
                  employee_changeset = Employee.changeset(%Employee{}, employee)

                  address = %{
                    address: %{
                      address_line_one: director.address_line_one,
                      address_line_two: director.address_line_two,
                      address_line_three: director.address_line_three,
                      post_code: director.post_code,
                      town: director.town,
                      county: director.county,
                      countries_id: country_id,
                      is_primary: "Y",
                      inserted_by: commanid
                    }
                  }

                  contacts = %{
                    contacts: %{
                      contact_number: director.contact_number,
                      code: country_code,
                      is_primary: "Y",
                      inserted_by: commanid
                    }
                  }

                  viola_id = Commontools.random_string(6)
                  password = Commontools.random_string(6)
                  contact_params = %{
                    viola_id: viola_id,
                    email_id: director.email_id,
                    vpin: params["vpin"],
                    password: password,
                    as_employee: "N",
                    status: "A",
                    address: address,
                    contacts: contacts
                  }

                  commanall_changeset = Commanall.changeset_contact(%Commanall{}, contact_params)

                  bothinsert = Ecto.Changeset.put_assoc(employee_changeset, :commanall, [commanall_changeset])

                  case Repo.insert(bothinsert) do
                    {:ok, _response} ->

                      getemployee = Repo.one(
                        from cmn in Commanall, where: cmn.email_id == ^director.email_id,
                                               left_join: c in assoc(cmn, :contacts),
                                               on: c.is_primary == "Y",
                                               left_join: dd in assoc(cmn, :devicedetails),
                                               on: dd.is_delete == "N" and (dd.type == "A" or dd.type == "I"),
                                               preload: [
                                                 contacts: c,
                                                 devicedetails: dd
                                               ]
                      )


                      employee_id = getemployee.employee_id
                      dirKyc = Repo.get_by(Kycdirectors, directors_id: director.id, type: "I", status: "A")

                      if is_nil(dirKyc) do
                        employee = Repo.get!(Employee, employee_id)
                        update_status = %{"status" => "K1"}
                        commanall_changeset = Employee.changesetStatus(employee, update_status)
                        Repo.update(commanall_changeset)
                        json conn,
                             %{
                               status_code: "4003",
                               errors: %{
                                 message: "Kyc Not uploaded."
                               }
                             }
                      else

                        kyc_common_id = getemployee.id
                        existingKycFirst = Repo.all(
                          from e in Kycdocuments,
                          where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A"
                        )
                        if existingKycFirst do
                          from(
                            e in Kycdocuments,
                            where: e.commanall_id == ^kyc_common_id and e.type == "I" and e.status == "A"
                          )
                          |> Repo.update_all(
                               set: [
                                 status: "R"
                               ]
                             )
                        end

                        kycdocuments = %{
                          commanall_id: getemployee.id,
                          documenttype_id: dirKyc.documenttype_id,
                          document_number: dirKyc.document_number,
                          file_name: dirKyc.file_name,
                          file_location: dirKyc.file_location,
                          file_location_two: dirKyc.file_location_two,
                          expiry_date: dirKyc.expiry_date,
                          issue_date: dirKyc.issue_date,
                          status: "A",
                          type: "I",
                          inserted_by: getemployee.id
                        }
                        kycdocuments_changeset = Kycdocuments.changeset(%Kycdocuments{}, kycdocuments)
                        Repo.insert(kycdocuments_changeset)

                        # check if director have address proof so store address proof
                        dirAddKyc = Repo.one(
                          from ad in Kycdirectors,
                          where: ad.directors_id == ^director.id and ad.type == ^"A" and ad.status == ^"A",
                          limit: 1,
                          select: ad
                        )
                        if !is_nil(dirAddKyc) do
                          kycAdd_documents = %{
                            commanall_id: getemployee.id,
                            documenttype_id: dirAddKyc.documenttype_id,
                            document_number: dirAddKyc.document_number,
                            file_name: dirAddKyc.file_name,
                            file_location: dirAddKyc.file_location,
                            file_location_two: dirAddKyc.file_location_two,
                            expiry_date: dirAddKyc.expiry_date,
                            issue_date: dirAddKyc.issue_date,
                            status: "A",
                            type: "A",
                            inserted_by: getemployee.id
                          }
                          kycAdd_documents_changeset = Kycdocuments.changesetAddressProof(
                            %Kycdocuments{},
                            kycAdd_documents
                          )
                          Repo.insert(kycAdd_documents_changeset)
                        end

                        # update directors as employee have or not
                        getdirectorsdetails = Repo.get!(Directors, params["directors_id"])
                        as_employee_director = %{
                          as_employee: "Y",
                          employee_id: employee_id
                        }
                        director_changeset = Directors.update_status(getdirectorsdetails, as_employee_director)
                        Repo.update(director_changeset)

                        # check 4Stop Call
                        check_override = Repo.one from k in Kycdirectors,
                                                  where: k.directors_id == ^director.id and not is_nil(
                                                    k.refered_id
                                                  ) and not is_nil(k.fourstop_response) and k.status == "A",
                                                  limit: 1,
                                                  select: k
                        chk_override_value = if !is_nil(check_override), do: "Yes", else: "No"
                        #                    check_4s = Repo.one from f in Fourstop, where: f.director_id == ^director.id and f.rec == ^"Approve", select: f
                        #                    chk_4s_value = if !is_nil(check_4s), do: "Yes", else: chk_override_value
                        check_status = if chk_override_value == "No" do
                          #                                      Accomplish.register_fourstop(employee_id)
                          TestController.employee_verify_GBG(getemployee.id)
                        else
                          %{"status" => "200", "message" => "Success"}
                        end
                        if check_status["status"] == "200" do
                          commanall_id_employee = getemployee.id
                          accomplish_response = TestController.create_employee(commanall_id_employee, commanid)
                          if accomplish_response == "200" do
                            getcompany = Repo.get!(Company, director.company_id)

                            accomplish_userid = Repo.one(
                              from cmn in Commanall, where: cmn.id == ^commanall_id_employee,
                                                     select: cmn.accomplish_userid
                            )

                            documenttype_id = if dirKyc.documenttype_id == 9 do
                              "2"
                            else
                              if dirKyc.documenttype_id == 10 do
                                "0"
                              else
                                "1"
                              end
                            end

                            request = %{
                              "worker_type" => "create_identification",
                              "user_id" => accomplish_userid,
                              "commanall_id" => commanall_id_employee,
                              "issue_date" => dirKyc.issue_date,
                              "expiry_date" => dirKyc.expiry_date,
                              "number" => dirKyc.document_number,
                              "employee_id" => employee_id,
                              "type" => documenttype_id,
                              "request_id" => commanid
                            }

                            Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

                            #                        #ALERTS  DEPRECATED
                            #                        data = %{
                            #                          :section => "addemployee",
                            #                          :commanall_id => getemployee.id,
                            #                          :employee_name => "#{params["first_name"]} #{params["last_name"]}",
                            #                          :company_name => getcompany.company_name,
                            #                          :pswd => password
                            #                        }
                            #                        AlertsController.sendEmail(data)
                            #                        AlertsController.sendNotification(data)
                            #                        AlertsController.sendSms(data)
                            #                        AlertsController.storeNotification(data)

                            data = [
                              %{
                                section: "addemployee",
                                type: "E",
                                email_id: getemployee.email_id,
                                data: %{
                                  :email => getemployee.email_id,
                                  :employee_name => "#{params["first_name"]} #{params["last_name"]}",
                                  :company_name => getcompany.company_name,
                                  :pswd => password
                                }
                                # Content
                              },
                              %{
                                section: "addemployee",
                                type: "S",
                                contact_code: if is_nil(Enum.at(getemployee.contacts, 0)) do
                                  nil
                                else
                                  Enum.at(getemployee.contacts, 0).code
                                end,
                                contact_number: if is_nil(Enum.at(getemployee.contacts, 0)) do
                                  nil
                                else
                                  Enum.at(getemployee.contacts, 0).contact_number
                                end,
                                data: %{
                                  :company_name => getcompany.company_name
                                }
                                # Content
                              },
                              %{
                                section: "addemployee",
                                type: "N",
                                token: if is_nil(getemployee.devicedetails) do
                                  nil
                                else
                                  getemployee.devicedetails.token
                                end,
                                push_type: if is_nil(getemployee.devicedetails) do
                                  nil
                                else
                                  getemployee.devicedetails.type
                                end, # "I" or "A"
                                login: getemployee.as_login, # "Y" or "N"
                                data: %{}
                                # Content
                              }
                            ]
                            V2AlertsController.main(data)

                            message = "Request to join ViolaCorporate sent to #{params["first_name"]} #{
                              params["last_name"]
                            }"
                            notification_details = %{
                              "commanall_id" => commanid,
                              "subject" => "addemployee",
                              "message" => message,
                              "inserted_by" => commanid
                            }
                            insert = Notifications.changeset(%Notifications{}, notification_details)
                            Repo.insert(insert)
                            json conn, %{status_code: "200", message: "Success, employee account created"}
                          else
                            json conn,
                                 %{
                                   status_code: "4003",
                                   errors: %{
                                     message: "failed to register account to accomplish"
                                   }
                                 }
                          end
                        else

                          employee = Repo.get!(Employee, employee_id)
                          update_status = %{"status" => "AP"}
                          commanall_changeset = Employee.changesetStatus(employee, update_status)
                          Repo.update(commanall_changeset)
                          json conn,
                               %{
                                 status_code: "5008",
                                 errors: %{
                                   message: check_status["message"]
                                 }
                               }
                        end
                      end
                    {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
                else
                  json conn, response
                end
              end

            "No" ->
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "Director KYC not completed"
                     }
                   }
          end

        else
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   message: "You are already an employee"
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 message: "missing/wrong param value"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  defp checkDirectorKycStep(director_id) do
    check_kyc = Repo.get_by(Kyclogin, directors_id: director_id)
    case check_kyc do
      nil ->
        chk_kyc_idproof = Repo.one(
          from kycid in Kycdirectors,
          where: kycid.directors_id == ^director_id and kycid.type == "I" and kycid.status == "A",
          select: count(kycid.id)
        )
        if chk_kyc_idproof > 0 do
          "Yes"
        else
          "No"
        end
      data ->
        case data.steps do
          "DONE" ->
            kyc_idproof = Repo.one(
              from kycid in Kycdirectors,
              where: kycid.directors_id == ^director_id and kycid.type == "I" and kycid.status == "A",
              select: count(kycid.id)
            )
            kyc_address = Repo.one(
              from kycadd in Kycdirectors,
              where: kycadd.directors_id == ^director_id and kycadd.type == "A" and kycadd.status == "A",
              select: count(kycadd.id)
            )
            if kyc_idproof > 0 and kyc_address > 0 do
              "Yes"
            else
              "No"
            end
          _ -> "No"
        end
    end
  end

  # View single transaction details
  def getCompanyTransaction(conn, params) do
    get_transactions = Transactions
                       |> where([t], t.id == ^params["transactionId"])
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> preload(:transactionsreceipt)
                       |> Repo.one

    render(conn, EmployeeView, "singletrans_project.json", transactions: get_transactions)
  end


  # Check card status for pending activation & check KYC status
  def checkCardStatus(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    commanall = Repo.get_by(Commanall, id: commanid)

    user_id = commanall.company_id
    cid = nil

    payload = %{
      "email" => commanall.email_id,
      "commanall_id" => commanall.id,
      "id" => user_id,
      "violaid" => commanall.viola_id,
      "cid" => cid
    }

    keyfortoken = Application.get_env(:violacorp, :tokenKey)
    new_token = ViolacorpWeb.Main.MainController.create_token(keyfortoken, payload)

    get_version = Repo.one(
      from v in Versions, order_by: [
        desc: :id
      ],
                          select: %{
                            android: v.android,
                            ios: v.iphone,
                            ekyc: v.ekyc
                          }
    )
    version = %{android: get_version.android, ios: get_version.ios}

    json conn,
         %{
           status_code: "200",
           token: new_token,
           kyc_status: nil,
           card_request: nil,
           ekyc: get_version.ekyc,
           version: Poison.encode!(version),
           appversion: getLatestAppVersion(),
           check_version: commanall.check_version
         }

  end


  defp getLatestAppVersion() do
    get_appversions = Repo.all(
                        from a in Appversions, where: a.is_active == ^"Y",
                                               select: %{
                                                 version: a.version,
                                                 type: a.type
                                               }
                      )
                      |> Enum.reduce(%{}, fn (inner_map, acc) -> Map.put(acc, inner_map.type, inner_map.version) end)
    Poison.encode!(get_appversions)
  end

  @doc """
  change phone number for Step 1
  """
  def changeMobileStepOne(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    contact_number = params["contact_number"]
    contact = Repo.one(
      from cont in Contacts, where: cont.commanall_id == ^commanid and cont.is_primary == ^"Y", select: cont
    )
    mobile_changeset = %{contact_number: contact_number}
    changeset = Contacts.changeset_number(contact, mobile_changeset)
    if changeset.valid? do

      check_mobile = Repo.one(
        from c in Contacts, where: c.contact_number == ^params["contact_number"], select: count(c.id)
      )
      if check_mobile == 0 do
        #        checknumber = Repo.one from commanall in Commanall, where: commanall.id == ^commanid,
        #                                                            left_join: contacts in assoc(commanall, :contacts),
        #                                                            where: contacts.is_primary == "Y",
        #                                                            select: %{
        #                                                              commanall_id: commanall.id,
        #                                                              contact_number: contacts.contact_number,
        #                                                              code: contacts.code
        #                                                            }
        checknumber = Repo.one(
          from cmn in Commanall, where: cmn.id == ^commanid,
                                 left_join: cc in assoc(cmn, :contacts),
                                 on: cc.is_primary == "Y",
                                 left_join: d in assoc(cmn, :devicedetails),
                                 on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                 preload: [
                                   contacts: cc,
                                   devicedetails: d
                                 ]
        )


        if !is_nil(checknumber) do
          generate_otp = Commontools.randnumber(6)
          otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
          otp_code = Poison.encode!(otp_code_map)

          otpmap = %{
            "commanall_id" => checknumber.id,
            "otp_code" => otp_code,
            "otp_source" => "Contact",
            "inserted_by" => checknumber.id
          }
          changeset = Otp.changeset(%Otp{}, otpmap)

          checkrecord = Repo.one from o in Otp,
                                 where: o.commanall_id == ^checknumber.id and o.otp_source == "Contact",
                                 select: count(o.commanall_id)
          if checkrecord == 0 do
            case Repo.insert(changeset) do
              {:ok, otpmap} -> # ALERTS
                #                # ALERTS DEPRECATED
                #                data = %{
                #                  :section => "change_mobile",
                #                  :contact_number => params["contact_number"],
                #                  :otp_source => "Contact",
                #                  :commanall_id => checknumber.commanall_id,
                #                  :generate_otp => generate_otp
                #                }
                #                AlertsController.sendNotification(data)
                #                AlertsController.sendSms(data)

                data = [
                  %{
                    section: "change_mobile",
                    type: "E",
                    email_id: checknumber.email_id,
                    data: %{
                      :generate_otp => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_mobile",
                    type: "S",
                    contact_code: if is_nil(Enum.at(checknumber.contacts, 0)) do
                      nil
                    else
                      Enum.at(checknumber.contacts, 0).code
                    end,
                    contact_number: if is_nil(Enum.at(checknumber.contacts, 0)) do
                      nil
                    else
                      Enum.at(checknumber.contacts, 0).contact_number
                    end,
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_mobile",
                    type: "N",
                    token: if is_nil(checknumber.devicedetails) do
                      nil
                    else
                      checknumber.devicedetails.token
                    end,
                    push_type: if is_nil(checknumber.devicedetails) do
                      nil
                    else
                      checknumber.devicedetails.type
                    end, # "I" or "A"
                    login: checknumber.as_login, # "Y" or "N"
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)


                json conn,
                     %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otpmap.id}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            otp = Repo.get_by(Otp, commanall_id: checknumber.id, otp_source: "Contact")
            changeset = Otp.changeset(otp, otpmap)
            case Repo.update(changeset) do
              {:ok, _otpmap} ->
                #                # ALERTS DEPRECATED
                #                data = %{
                #                  :section => "change_mobile",
                #                  :contact_number => params["contact_number"],
                #                  :commanall_id => checknumber.commanall_id,
                #                  :otp_source => "Contact",
                #                  :generate_otp => generate_otp
                #                }
                #                AlertsController.sendNotification(data)
                #                AlertsController.sendSms(data)

                data = [
                  %{
                    section: "change_mobile",
                    type: "E",
                    email_id: checknumber.email_id,
                    data: %{
                      :generate_otp => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_mobile",
                    type: "S",
                    contact_code: Enum.at(checknumber.contacts, 0).code,
                    contact_number: Enum.at(checknumber.contacts, 0).contact_number,
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_mobile",
                    type: "N",
                    token: checknumber.devicedetails.token,
                    push_type: checknumber.devicedetails.type, # "I" or "A"
                    login: checknumber.as_login, # "Y" or "N"
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)

                json conn,
                     %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otp.id}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          end
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "contact number used by someone."
               }
             }
      end
    else
      conn
      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc """
  change phone number Step two
  """
  def changeMobileStepTwo(conn, params) do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get_by(Commanall, id: commanid, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^commanid and o.otp_source == "Contact",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        contact_number = params["contact_number"]
        contact = Repo.one(
          from cont in Contacts, where: cont.commanall_id == ^commanid and cont.is_primary == ^"Y", select: cont
        )
        mobile_changeset = %{contact_number: contact_number}
        changeset = Contacts.changeset_number(contact, mobile_changeset)
        history = %{
          company_id: company_id,
          field_name: "Mobile",
          old_value: contact.contact_number,
          new_value: contact_number,
          inserted_by: company_id
        }
        if changeset.valid? do
          if !is_nil(commanall.accomplish_userid) do

            get_details = Accomplish.get_user(commanall.accomplish_userid)
            result_code = get_details["result"]["code"]
            result_message = get_details["result"]["friendly_message"]
            if result_code == "0000" do
              mobile_id = get_in(get_details["phone"], [Access.at(0), "id"])
              number = "+#{contact.code}#{contact_number}"
              is_primary = Application.get_env(:violacorp, :accomplish_is_primary)
              country_code = Application.get_env(:violacorp, :accomplish_country_code)

              request_map = %{
                common_id: commanid,
                urlid: commanall.accomplish_userid,
                country_code: country_code,
                is_primary: is_primary,
                number: number,
              }
              response = Accomplish.create_phone(request_map)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              if response_code == "0000" do
                request_delete_map = %{
                  id: mobile_id,
                  common_id: commanid,
                  urlid: commanall.accomplish_userid
                }
                response_data = Accomplish.delete_phone(request_delete_map)
                response_code = response_data["result"]["code"]
                if response_code == "0000" do
                  HistoryManagement.updateHistory(history)
                  Repo.update(changeset)
                  json conn, %{status_code: "200", message: "Success, contact number changed."}
                else
                  json conn, %{status_code: "5001", errors: response_message}
                end
              else
                json conn, %{status_code: "5001", errors: response_message}
              end
            else
              json conn, %{status_code: "5001", errors: result_message}
            end
          else
            HistoryManagement.updateHistory(history)
            Repo.update(changeset)
            json conn, %{status_code: "200", message: "Success, contact number changed."}
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 otp_code: "Incorrect OTP please re-enter correct OTP"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  @doc """
  change Email for Step 1
  """
  def changeEmailStepOne(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    check_email = Repo.one(from c in Commanall, where: c.email_id == ^params["email"], select: count(c.id))
    if check_email == 0 do
      generate_otp = Commontools.randnumber(6)
      otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
      otp_code = Poison.encode!(otp_code_map)

      otpmap = %{
        "commanall_id" => commanid,
        "otp_code" => otp_code,
        "otp_source" => "Email",
        "inserted_by" => commanid
      }
      changeset = Otp.changeset(%Otp{}, otpmap)

      checkrecord = Repo.one from o in Otp,
                             where: o.commanall_id == ^commanid and o.otp_source == "Email",
                             select: count(o.commanall_id)
      if checkrecord == 0 do
        case Repo.insert(changeset) do
          {:ok, otpmap} ->
            #               ALERTS DEPRECATED
            #              data = %{
            #                :section => "change_email",
            #                :email => params["email"],
            #                :commanall_id => commanid,
            #                :generate_otp => generate_otp
            #              }
            #              AlertsController.sendEmail(data)


            commanall = Repo.one(
              from cmn in Commanall, where: cmn.email_id == ^params["email"],
                                     left_join: cc in assoc(cmn, :contacts),
                                     on: cc.is_primary == "Y",
                                     left_join: d in assoc(cmn, :devicedetails),
                                     on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                     preload: [
                                       contacts: cc,
                                       devicedetails: d
                                     ]
            )


            if !is_nil(commanall) do
              data = [
                %{
                  section: "change_email",
                  type: "E",
                  email_id: params["email"],
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
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
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
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
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)
            end

            json conn,
                 %{status_code: "200", messages: "Email ID changing process has been initiated.  ", otp_id: otpmap.id}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        otp = Repo.get_by(Otp, commanall_id: commanid, otp_source: "Email")
        changeset = Otp.changeset(otp, otpmap)
        case Repo.update(changeset) do
          {:ok, _otpmap} ->
            #              # ALERTS DEPRECATED
            #              data = %{
            #                :section => "change_email",
            #                :email => params["email"],
            #                :commanall_id => commanid,
            #                :generate_otp => generate_otp
            #              }
            #              AlertsController.sendEmail(data)

            commanall = Repo.one(
              from cmn in Commanall, where: cmn.company_id == ^params["email"],
                                     left_join: cc in assoc(cmn, :contacts),
                                     on: cc.is_primary == "Y",
                                     left_join: d in assoc(cmn, :devicedetails),
                                     on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                     preload: [
                                       contacts: cc,
                                       devicedetails: d
                                     ]
            )
            data = [
              %{
                section: "change_email",
                type: "E",
                email_id: params["email"],
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              },
              %{
                section: "change_email",
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
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              },
              %{
                section: "change_email",
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
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              }
            ]
            V2AlertsController.main(data)


            json conn, %{status_code: "200", messages: "Email ID changing process has been initiated.", otp_id: otp.id}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Email used by someone."
             }
           }
    end
  end

  @doc """
  change email for company and employee
  """
  def changeEmailStepTwo(conn, params) do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get_by(Commanall, id: commanid, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp, where: o.commanall_id == ^commanid and o.otp_source == "Email",
                                       select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        email_changeset = %{email_id: params["email_id"]}
        changeset = Commanall.changesetEmail(commanall, email_changeset)
        history = %{
          company_id: company_id,
          field_name: "Email",
          old_value: commanall.email_id,
          new_value: params["email_id"],
          inserted_by: company_id
        }
        if changeset.valid? do
          if !is_nil(commanall.accomplish_userid) do

            get_details = Accomplish.get_user(commanall.accomplish_userid)
            result_code = get_details["result"]["code"]
            result_message = get_details["result"]["friendly_message"]
            if result_code == "0000" do
              email_id = get_in(get_details["email"], [Access.at(0), "id"])
              is_primary = Application.get_env(:violacorp, :accomplish_is_primary)

              request_map = %{
                common_id: commanid,
                urlid: commanall.accomplish_userid,
                address: params["email_id"],
                is_primary: is_primary,
              }
              response = Accomplish.create_email(request_map)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              if response_code == "0000" do
                request_delete_map = %{
                  id: email_id,
                  common_id: commanid,
                  urlid: commanall.accomplish_userid
                }
                response_data = Accomplish.delete_email(request_delete_map)
                res_code = response_data["result"]["code"]
                res_message = response["result"]["friendly_message"]
                if res_code == "0000" do
                  HistoryManagement.updateHistory(history)
                  Repo.update(changeset)
                  json conn, %{status_code: "200", message: "Success, email changed."}
                else
                  json conn, %{status_code: "5001", errors: res_message}
                end
              else
                json conn, %{status_code: "5001", errors: response_message}
              end
            else
              json conn, %{status_code: "5001", errors: result_message}
            end
          else
            HistoryManagement.updateHistory(history)
            Repo.update(changeset)
            json conn, %{status_code: "200", message: "Success, email changed."}
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 otp_code: "Incorrect OTP please re-enter correct OTP"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  @doc """
  change address for company and employee
  """
  def changeAddress(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    address = Repo.get_by(Address, commanall_id: commanid)

    if !is_nil(address) do
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
      address_changeset = %{
        address_line_one: address_line_one,
        address_line_two: address_line_two,
        town: params["town"],
        post_code: params["post_code"],
        county: params["county"],
      }
      changeset = Address.changeset(address, address_changeset)
      if changeset.valid? do
        commanall = Repo.one(
          from c in Commanall, where: c.id == ^commanid,
                               select: %{
                                 accomplish_userid: c.accomplish_userid
                               }
        )
        if !is_nil(commanall) do

          country_code = Application.get_env(:violacorp, :accomplish_country_code)

          request_map = %{
            common_id: commanid,
            urlid: commanall.accomplish_userid,
            country_code: country_code,
            address_line1: address_line_one,
            address_line2: address_line_two,
            city_town: params["town"],
            postal_zip_code: params["post_code"],
            state_region: params["county"],
          }
          response = Accomplish.change_address(request_map)
          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]
          if response_code == "0000" do
            Repo.update(changeset)
            json conn, %{status_code: "200", message: "Success, address changed."}
          else
            json conn, %{status_code: "5001", errors: response_message}
          end
        else
          Repo.update(changeset)
          json conn, %{status_code: "200", message: "Success, address changed."}
        end
      else
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "address information not found."
             }
           }
    end
  end

  @doc """
  company change mobile step one
  """
  def changeEmployeeMobileStepOne(conn, params) do
    %{"id" => _company_id} = conn.assigns[:current_user]

    check_mobile = Repo.one(
      from c in Contacts, where: c.contact_number == ^params["contact_number"], select: count(c.id)
    )
    _employee_contact_id = params["employee_contact_id"]

    if check_mobile == 0 do
      checknumber = Repo.one from cmn in Commanall, where: cmn.employee_id == ^params["employee_id"],
                                                    left_join: m in assoc(cmn, :contacts),
                                                    on: m.is_primary == "Y",
                                                    left_join: d in assoc(cmn, :devicedetails),
                                                    on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                    select: %{
                                                      commanall_id: cmn.id,
                                                      email_id: cmn.email_id,
                                                      as_login: cmn.as_login,
                                                      code: m.code,
                                                      contact_number: m.contact_number,
                                                      token: d.token,
                                                      token_type: d.type,
                                                    }

      if !is_nil(checknumber) do
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)

        otpmap = %{
          "commanall_id" => checknumber.commanall_id,
          "otp_code" => otp_code,
          "otp_source" => "Contact",
          "inserted_by" => checknumber.commanall_id
        }
        changeset = Otp.changeset(%Otp{}, otpmap)

        checkrecord = Repo.one from o in Otp,
                               where: o.commanall_id == ^checknumber.commanall_id and o.otp_source == "Contact",
                               select: count(o.commanall_id)
        if checkrecord == 0 do
          case Repo.insert(changeset) do
            {:ok, otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_mobile",
              #                :contact_number => params["contact_number"],
              #                :otp_source => "Contact",
              #                :commanall_id => checknumber.commanall_id,
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendNotification(data)
              #              AlertsController.sendSms(data)



              data = [
                %{
                  section: "change_mobile",
                  type: "E",
                  email_id: checknumber.email_id,
                  data: %{
                    :generate_otp => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "S",
                  contact_code: checknumber.code,
                  contact_number: checknumber.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "N",
                  token: checknumber.token,
                  push_type: checknumber.token_type, # "I" or "A"
                  login: checknumber.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)


              json conn,
                   %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otpmap.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: checknumber.commanall_id, otp_source: "Contact")

          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_mobile",
              #                :contact_number => params["contact_number"],
              #                :commanall_id => checknumber.commanall_id,
              #                :otp_source => "Contact",
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendNotification(data)
              #              AlertsController.sendSms(data)

              data = [
                %{
                  section: "change_mobile",
                  type: "E",
                  email_id: checknumber.email_id,
                  data: %{
                    :generate_otp => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "S",
                  contact_code: checknumber.code,
                  contact_number: checknumber.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "N",
                  token: checknumber.token,
                  push_type: checknumber.token_type, # "I" or "A"
                  login: checknumber.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)

              json conn,
                   %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otp.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "Employee does`t found for this company."
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "contact number used by someone."
             }
           }
    end
  end

  @doc """
  company change mobile step two
  """
  def changeEmployeeMobileStepTwo(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    director_contact_id = params["director_contact_id"]
    employee_contact_id = params["employee_contact_id"]

    commanall_data = Repo.get_by(Commanall, company_id: company_id, vpin: params["pin"])

    if !is_nil(commanall_data) do
      commanall = Repo.get_by(Commanall, employee_id: params["employee_id"])
      if !is_nil(commanall) do
        getotp = Repo.one from o in Otp,
                          where: o.commanall_id == ^commanall.id and o.otp_source == "Contact",
                          select: o.otp_code
        otpdecode = Poison.decode!(getotp)
        if otpdecode["otp_code"] == params["otp_code"] do
          contact_number = params["contact_number"]
          contact = Repo.one(
            from cont in Contacts, where: cont.commanall_id == ^commanall.id and cont.id == ^employee_contact_id,
                                   select: cont
          )
          mobile_changeset = %{contact_number: contact_number}
          changeset = Contacts.changeset_number(contact, mobile_changeset)

          if changeset.valid? do
            if !is_nil(commanall.accomplish_userid) do

              get_details = Accomplish.get_user(commanall.accomplish_userid)
              result_code = get_details["result"]["code"]
              result_message = get_details["result"]["friendly_message"]
              if result_code == "0000" do
                mobile_id = get_in(get_details["phone"], [Access.at(0), "id"])
                number = "+#{contact.code}#{contact_number}"
                is_primary = Application.get_env(:violacorp, :accomplish_is_primary)
                country_code = Application.get_env(:violacorp, :accomplish_country_code)

                request_map = %{
                  common_id: commanall.id,
                  urlid: commanall.accomplish_userid,
                  country_code: country_code,
                  is_primary: is_primary,
                  number: number,
                }
                response = Accomplish.create_phone(request_map)
                response_code = response["result"]["code"]
                response_message = response["result"]["friendly_message"]
                if response_code == "0000" do
                  request_delete_map = %{
                    id: mobile_id,
                    common_id: commanall.id,
                    urlid: commanall.accomplish_userid

                  }
                  response_data = Accomplish.delete_phone(request_delete_map)
                  response_code = response_data["result"]["code"]
                  if response_code == "0000" do
                    if !is_nil(director_contact_id) do
                      director_data = Repo.get_by(Contactsdirectors, id: director_contact_id)
                      director_changeset = Contactsdirectors.changeset(director_data, mobile_changeset)
                      history = %{
                        directors_id: director_data.directors_id,
                        field_name: "Mobile",
                        old_value: director_data.contact_number,
                        new_value: contact_number,
                        inserted_by: company_id
                      }
                      HistoryManagement.updateHistory(history)
                      Repo.update(director_changeset)
                    end
                    history = %{
                      employee_id: params["employee_id"],
                      field_name: "Mobile",
                      old_value: contact.contact_number,
                      new_value: contact_number,
                      inserted_by: company_id
                    }
                    HistoryManagement.updateHistory(history)
                    Repo.update(changeset)
                    json conn, %{status_code: "200", message: "Success, contact number changed."}
                  else
                    json conn, %{status_code: "5001", errors: response_message}
                  end
                else
                  json conn, %{status_code: "5001", errors: response_message}
                end
              else
                json conn, %{status_code: "5001", errors: result_message}
              end
            else
              history = %{
                employee_id: params["employee_id"],
                field_name: "Mobile",
                old_value: contact.contact_number,
                new_value: contact_number,
                inserted_by: company_id
              }
              HistoryManagement.updateHistory(history)
              Repo.update(changeset)
              json conn, %{status_code: "200", message: "Success, contact number changed."}
            end
          else
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   otp_code: "Incorrect OTP please re-enter correct OTP"
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "Invalid ID"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  @doc"""
    Company  Change Employee Email Step One
  """
  def changeEmployeeEmailStepOne(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    check_email = Repo.one(
      from commanall in Commanall, where: commanall.email_id == ^params["email_id"], select: count(commanall.id)
    )

    if check_email == 0 do
      case checkCompanyEmployee(company_id, params) do
        {:ok, commanall} ->
          generate_otp = Commontools.randnumber(6)
          otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
          otp_code = Poison.encode!(otp_code_map)

          otpmap = %{
            "commanall_id" => commanall.id,
            "otp_code" => otp_code,
            "otp_source" => "Email",
            "inserted_by" => commanall.id
          }
          changeset = Otp.changeset(%Otp{}, otpmap)

          checkrecord = Repo.one from o in Otp,
                                 where: o.commanall_id == ^commanall.id and o.otp_source == "Email",
                                 select: count(o.commanall_id)
          getemployee = Repo.one from cmn in Commanall, where: cmn.id == ^commanall.id,
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

          if checkrecord == 0 do
            case Repo.insert(changeset) do
              {:ok, otpmap} ->
                #                # ALERTS
                #                data = %{
                #                  :section => "change_email",
                #                  :email => params["email_id"],
                #                  :otp_source => "Email",
                #                  :commanall_id => commanall.id,
                #                  :generate_otp => generate_otp
                #                }
                #                AlertsController.sendEmail(data)

                data = [
                  %{
                    section: "change_email",
                    type: "E",
                    email_id: params["email_id"],
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_email",
                    type: "S",
                    contact_code: getemployee.code,
                    contact_number: getemployee.contact_number,
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_email",
                    type: "N",
                    token: getemployee.token,
                    push_type: getemployee.token_type, # "I" or "A"
                    login: getemployee.as_login, # "Y" or "N"
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)


                json conn,
                     %{status_code: "200", messages: "Email ID changing process has been initiated.", otp_id: otpmap.id}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            otp = Repo.get_by(Otp, commanall_id: commanall.id, otp_source: "Email")
            changeset = Otp.changeset(otp, otpmap)
            case Repo.update(changeset) do
              {:ok, _otpmap} ->
                # ALERTS
                #                data = %{
                #                  :section => "change_email",
                #                  :email => params["email_id"],
                #                  :commanall_id => commanall.id,
                #                  :otp_source => "Email",
                #                  :generate_otp => generate_otp
                #                }
                #                AlertsController.sendEmail(data)

                data = [
                  %{
                    section: "change_email",
                    type: "E",
                    email_id: params["email_id"],
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_email",
                    type: "S",
                    contact_code: getemployee.code,
                    contact_number: getemployee.contact_number,
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  },
                  %{
                    section: "change_email",
                    type: "N",
                    token: getemployee.token,
                    push_type: getemployee.token_type, # "I" or "A"
                    login: getemployee.as_login, # "Y" or "N"
                    data: %{
                      :otp_code => generate_otp
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)
                json conn,
                     %{status_code: "200", messages: "Email ID changing process has been initiated.  ", otp_id: otp.id}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          end
        {:error, message} ->
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   employee_id: message
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "email used by someone."
             }
           }
    end
  end

  @doc"""
      Change Employee Email Step Two
  """
  def changeEmployeeEmailStepTwo(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    commanall_data = Repo.get_by(Commanall, company_id: company_id, vpin: params["pin"])
    commanall = Repo.get_by(Commanall, employee_id: params["employee_id"])

    if !is_nil(commanall) and (commanall_data) do
      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^commanall.id and o.otp_source == "Email",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        email_id = params["email_id"]
        email_changeset = %{email_id: email_id}
        changeset = Commanall.changeset_updateemail(commanall, email_changeset)
        if changeset.valid? do
          if !is_nil(commanall.accomplish_userid) do

            get_details = Accomplish.get_user(commanall.accomplish_userid)
            result_code = get_details["result"]["code"]
            result_message = get_details["result"]["friendly_message"]
            if result_code == "0000" do
              email_id = get_in(get_details["email"], [Access.at(0), "id"])
              is_primary = Application.get_env(:violacorp, :accomplish_is_primary)

              request_map = %{
                common_id: commanall.id,
                urlid: commanall.accomplish_userid,
                address: params["email_id"],
                is_primary: is_primary,
              }
              response = Accomplish.create_email(request_map)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              if response_code == "0000" do
                request_delete_map = %{
                  id: email_id,
                  common_id: commanall.id,
                  urlid: commanall.accomplish_userid
                }
                response_data = Accomplish.delete_email(request_delete_map)
                res_code = response_data["result"]["code"]
                res_message = response["result"]["friendly_message"]
                if res_code == "0000" do
                  if !is_nil(params["directors_id"]) and params["directors_id"] != "" do
                    director_data = Repo.get_by(Directors, id: params["directors_id"])
                    n_changeset = Directors.update_email(director_data, email_changeset)
                    history = %{
                      directors_id: params["directors_id"],
                      field_name: "Email",
                      old_value: director_data.email_id,
                      new_value: params["email_id"],
                      inserted_by: company_id
                    }
                    HistoryManagement.updateHistory(history)
                    Repo.update(n_changeset)
                  else
                    # get director_id from employee table
                    employee = Repo.get_by(Employee, id: params["employee_id"])
                    if !is_nil(employee.director_id) do
                      director_data = Repo.get_by(Directors, id: employee.director_id)
                      if !is_nil(director_data) do
                        n_changeset = Directors.update_email(director_data, email_changeset)
                        history = %{
                          directors_id: director_data.id,
                          field_name: "Email",
                          old_value: director_data.email_id,
                          new_value: params["email_id"],
                          inserted_by: company_id
                        }
                        HistoryManagement.updateHistory(history)
                        Repo.update(n_changeset)
                      end
                    end
                  end
                  history = %{
                    employee_id: params["employee_id"],
                    field_name: "Email",
                    old_value: commanall.email_id,
                    new_value: params["email_id"],
                    inserted_by: company_id
                  }
                  HistoryManagement.updateHistory(history)
                  Repo.update(changeset)
                  json conn, %{status_code: "200", message: "Success, email changed."}
                else
                  json conn, %{status_code: "5001", errors: res_message}
                end
              else
                json conn, %{status_code: "5001", errors: response_message}
              end
            else
              json conn, %{status_code: "5001", errors: result_message}
            end
          else
            history = %{
              employee_id: params["employee_id"],
              field_name: "Email",
              old_value: commanall.email_id,
              new_value: params["email_id"],
              inserted_by: company_id
            }
            HistoryManagement.updateHistory(history)
            Repo.update(changeset)
            json conn, %{status_code: "200", message: "Success, email changed."}
          end
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 otp_code: "Incorrect OTP please re-enter correct OTP"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  def checkCompanyEmployee(company_id, params) do
    commanall = Repo.one from commanall in Commanall, where: commanall.employee_id == ^params["employee_id"],
                                                      left_join: emp in assoc(commanall, :employee),
                                                      where: emp.company_id == ^company_id,
                                                      select: %{
                                                        id: commanall.id,
                                                      }
    case commanall do
      nil -> {:error, "Employee does`t found for this company."}
      data -> {:ok, data}
    end
  end

  @doc """
      Change Director's Mobile Step One
  """
  def changeDirectorMobileStepOne(conn, params) do
    %{"id" => _company_id, "commanall_id" => commanid} = conn.assigns[:current_user]

    check_mobile = Repo.one(
      from c in Contactsdirectors, where: c.contact_number == ^params["contact_number"], select: count(c.id)
    )
    if check_mobile == 0  do

      checknumber = Repo.one(
        from cont in Contactsdirectors, where: cont.directors_id == ^params["directors_id"], limit: 1, select: cont
      )
      if !is_nil(checknumber) do
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)

        otpmap = %{
          "commanall_id" => commanid,
          "otp_code" => otp_code,
          "otp_source" => "Contact",
          "inserted_by" => commanid
        }
        changeset = Otp.changeset(%Otp{}, otpmap)

        checkrecord = Repo.one from o in Otp,
                               where: o.commanall_id == ^commanid and o.otp_source == "Contact",
                               select: count(o.commanall_id)
        if checkrecord == 0 do
          case Repo.insert(changeset) do
            {:ok, otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_mobile",
              #                :contact_number => params["contact_number"],
              #                :otp_source => "Contact",
              #                :commanall_id => commanid,
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendNotification(data)
              #              AlertsController.sendSms(data)

              getemployee = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
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
                                                              token_type: d.type
                                                            }

              data = [
                %{
                  section: "change_mobile",
                  type: "E",
                  email_id: getemployee.email_id,
                  data: %{
                    :generate_otp => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "S",
                  contact_code: getemployee.code,
                  contact_number: getemployee.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "N",
                  token: getemployee.token,
                  push_type: getemployee.token_type, # "I" or "A"
                  login: getemployee.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)


              json conn,
                   %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otpmap.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: commanid, otp_source: "Contact")
          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_mobile",
              #                :contact_number => params["contact_number"],
              #                :commanall_id => commanid,
              #                :otp_source => "Contact",
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendNotification(data)
              #              AlertsController.sendSms(data)

              getemployee = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
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
              data = [
                %{
                  section: "change_mobile",
                  type: "E",
                  email_id: params["email_id"],
                  data: %{
                    :generate_otp => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "S",
                  contact_code: getemployee.code,
                  contact_number: getemployee.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_mobile",
                  type: "N",
                  token: getemployee.token,
                  push_type: getemployee.token_type, # "I" or "A"
                  login: getemployee.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)

              json conn,
                   %{status_code: "200", messages: "Phone no changing process has been initiated.", otp_id: otp.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "Director does`t found for this company."
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "contact number used by someone."
             }
           }
    end
  end

  @doc"""
      Change Director Mobile Step Two
  """
  def changeDirectorMobileStepTwo(conn, params) do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]

    commanall = Repo.get_by(Commanall, company_id: company_id, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^commanid and o.otp_source == "Contact",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        contact_number = params["contact_number"]
        contact = Repo.one(
          from cont in Contactsdirectors, where: cont.directors_id == ^params["directors_id"], limit: 1, select: cont
        )
        mobile_changeset = %{contact_number: contact_number}
        changeset = Contactsdirectors.changeset(contact, mobile_changeset)
        if changeset.valid? do
          history = %{
            directors_id: params["directors_id"],
            field_name: "Mobile",
            old_value: contact.contact_number,
            new_value: contact_number,
            inserted_by: company_id
          }
          HistoryManagement.updateHistory(history)
          Repo.update(changeset)
          json conn, %{status_code: "200", message: "Success, contact number changed."}
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 otp_code: "Incorrect OTP please re-enter correct OTP"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  @doc"""
      Change Director's Email Step One
  """
  def changeDirectorEmailStepOne(conn, params) do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]

    check_email = Repo.one(from d in Directors, where: d.email_id == ^params["email_id"], select: count(d.id))
    if check_email == 0 do

      checknumber = Repo.get_by(Directors, company_id: company_id, id: params["directors_id"])
      if !is_nil(checknumber) do
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)

        otpmap = %{
          "commanall_id" => commanid,
          "otp_code" => otp_code,
          "otp_source" => "Email",
          "inserted_by" => commanid
        }
        changeset = Otp.changeset(%Otp{}, otpmap)

        checkrecord = Repo.one from o in Otp,
                               where: o.commanall_id == ^commanid and o.otp_source == "Email",
                               select: count(o.commanall_id)
        if checkrecord == 0 do
          case Repo.insert(changeset) do
            {:ok, otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_email",
              #                :email_id => params["email_id"],
              #                :otp_source => "Email",
              #                :commanall_id => commanid,
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendEmail(data)

              getemployee = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
                                                            left_join: m in assoc(cmn, :contacts),
                                                            on: m.is_primary == "Y",
                                                            left_join: dd in assoc(cmn, :devicedetails),
                                                            on: dd.is_delete == "N" and (
                                                              dd.type == "A" or dd.type == "I"),
                                                            select: %{
                                                              id: cmn.id,
                                                              email_id: cmn.email_id,
                                                              as_login: cmn.as_login,
                                                              code: m.code,
                                                              contact_number: m.contact_number,
                                                              token: dd.token,
                                                              token_type: dd.type
                                                            }

              data = [
                %{
                  section: "change_email",
                  type: "E",
                  email_id: params["email_id"],
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
                  type: "S",
                  contact_code: getemployee.code,
                  contact_number: getemployee.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
                  type: "N",
                  token: getemployee.token,
                  push_type: getemployee.token_type, # "I" or "A"
                  login: getemployee.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)

              json conn,
                   %{status_code: "200", messages: "Email ID changing process has been initiated.  ", otp_id: otpmap.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: commanid, otp_source: "Email")
          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _otpmap} ->
              #              # ALERTS
              #              data = %{
              #                :section => "change_email",
              #                :email_id => params["email_id"],
              #                :commanall_id => commanid,
              #                :otp_source => "Email",
              #                :generate_otp => generate_otp
              #              }
              #              AlertsController.sendEmail(data)

              getemployee = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
                                                            left_join: m in assoc(cmn, :contacts),
                                                            on: m.is_primary == "Y",
                                                            left_join: dd in assoc(cmn, :devicedetails),
                                                            on: dd.is_delete == "N" and (
                                                              dd.type == "A" or dd.type == "I"),
                                                            select: %{
                                                              id: cmn.id,
                                                              email_id: cmn.email_id,
                                                              as_login: cmn.as_login,
                                                              code: m.code,
                                                              contact_number: m.contact_number,
                                                              token: dd.token,
                                                              token_type: dd.type
                                                            }

              data = [
                %{
                  section: "change_email",
                  type: "E",
                  email_id: params["email_id"],
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
                  type: "S",
                  contact_code: getemployee.code,
                  contact_number: getemployee.contact_number,
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                },
                %{
                  section: "change_email",
                  type: "N",
                  token: getemployee.token,
                  push_type: getemployee.token_type, # "I" or "A"
                  login: getemployee.as_login, # "Y" or "N"
                  data: %{
                    :otp_code => generate_otp
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)

              json conn,
                   %{status_code: "200", messages: "Email ID changing process has been initiated.  ", otp_id: otp.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "Director does`t found for this company."
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Email used by someone."
             }
           }
    end
  end

  @doc"""
      Change Director's Email Step Two
  """
  def changeDirectorEmailStepTwo(conn, params) do
    %{"id" => company_id, "commanall_id" => commanid} = conn.assigns[:current_user]

    commanall = Repo.get_by(Commanall, company_id: company_id, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^commanid and o.otp_source == "Email",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        email = params["email_id"]
        data_email = Repo.get_by(Directors, id: params["directors_id"])
        email_changeset = %{email_id: email}
        changeset = Directors.update_email(data_email, email_changeset)
        if changeset.valid? do
          history = %{
            directors_id: params["directors_id"],
            field_name: "Email",
            old_value: data_email.email_id,
            new_value: email,
            inserted_by: company_id
          }
          HistoryManagement.updateHistory(history)
          Repo.update(changeset)
          json conn, %{status_code: "200", message: "Success, email changed."}
        else
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 otp_code: "Incorrect OTP please re-enter correct OTP"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4003",
             errors: %{
               pin: "Passcode does not match, try again"
             }
           }
    end
  end

  def getAllListOFDirectors(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    directors = Repo.all from d in Directors, where: d.company_id == ^company_id and d.as_employee == "N",
      #                                              left_join: kyc in assoc(d, :kyclogin),
      #                                              where: kyc.steps == "DONE",
                                              select: %{
                                                id: d.id,
                                                position: d.position,
                                                title: d.title,
                                                first_name: d.first_name,
                                                last_name: d.last_name,
                                                as_employee: d.as_employee,
                                              }
    json conn, %{status_code: "200", data: directors}
  end
end