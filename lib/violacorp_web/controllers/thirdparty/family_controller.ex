defmodule ViolacorpWeb.Thirdparty.FamilyController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Employee

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools

  @doc "Create Family Account"
  def createFamily(commanid) do

    # Fetch company data
    country_code = Application.get_env(:violacorp, :accomplish_country_code)
    userdata = Repo.one from commanall in Commanall, where: commanall.id == ^commanid,
                                                     left_join: address in assoc(commanall, :address),
                                                     where: address.is_primary == "Y",
                                                     left_join: contacts in assoc(commanall, :contacts),
                                                     where: contacts.is_primary == "Y",
                                                     left_join: company in assoc(commanall, :company),
                                                     left_join: directors in assoc(company, :directors),
                                                     where: directors.is_primary == "Y",
                                                     select: %{
                                                       company_id: company.id,
                                                       company_name: company.company_name,
                                                       email_id: commanall.email_id,
                                                       accomplish_userid: commanall.accomplish_userid,
                                                       address_line_one: address.address_line_one,
                                                       address_line_two: address.address_line_two,
                                                       city: address.city,
                                                       post_code: address.post_code,
                                                       county: address.county,
                                                       town: address.town,
                                                       contact_number: contacts.contact_number,
                                                       code: contacts.code,
                                                       title: directors.title,
                                                       first_name: directors.first_name,
                                                       last_name: directors.last_name,
                                                       position: directors.position,
                                                       dob: directors.date_of_birth,
                                                       gender: directors.gender
                                                     }

    cc_name = String.slice(userdata.company_name, 0..1)
    random_num = Commontools.randnumberlimit(4)
    user_id = userdata.accomplish_userid
    type = 1
    status = "1"
    code = "#{String.upcase(cc_name)}#{random_num}"
    name = userdata.company_name

    address_type = 1
    is_billing = "1"
    address_line1 = userdata.address_line_one
    address_line2 = userdata.address_line_two
    postal_zip_code = userdata.post_code
    city_town = userdata.town
    country_code = country_code

    phone_type = 1
    number = userdata.contact_number
    number_code = userdata.code
    verification_status = "1"

    email_type = 1
    address = userdata.email_id
    is_primary = "1"

    request = %{
            commanid: commanid,
            user_id: user_id,
            type: type,
            status: status,
            code: code,
            name: name,
            address_type: address_type,
            is_billing: is_billing,
            address_line1: address_line1,
            address_line2: address_line2,
            postal_zip_code: postal_zip_code,
            city_town: city_town,
            country_code: country_code,
            phone_type: phone_type,
            number: "+#{number_code}#{number}",
            verification_status: verification_status,
            email_type: email_type,
            address: address,
            is_primary: is_primary
    }

    response = Accomplish.create_group(request)

    response_code = response["result"]["code"]
    if response_code == "0000" do
      company = Repo.get(Company, userdata.company_id)
      update_group = %{"group_id" => response["info"]["id"]}
      changeset = Company.changesetGroup(company, update_group)
      Repo.update(changeset)
    end
    _response_message = response["result"]["friendly_message"]

  end

  @doc "Create Family Members"
  def createFamilyMembers(commanid) do

    # Fetch employee data
    employeeData = Repo.one from commanall in Commanall, where: commanall.id == ^commanid,
                                                     left_join: employee in assoc(commanall, :employee),
                                                     select: %{
                                                       company_id: employee.company_id,
                                                       accomplish_userid: commanall.accomplish_userid,
                                                       employee_id: employee.id
                                                     }

    # Fetch employee data
    companyData = Repo.one from commanall in Commanall, where: commanall.company_id == ^employeeData.company_id,
                                                    left_join: company in assoc(commanall, :company),
                                                     select: %{
                                                       id: commanall.id,
                                                       accomplish_userid: commanall.accomplish_userid,
                                                       group_id: company.group_id
                                                     }

    user_id = employeeData.accomplish_userid
    role = 3
    membership_status = 1

    group_id = companyData.group_id

    _response = if is_nil(group_id) do
                  "Group not found"
                else
                  request = %{
                    commanid: commanid,
                    user_id: user_id,
                    role: role,
                    membership_status: membership_status,
                    group_id: group_id
                  }
                  response = Accomplish.create_group_member(request)

                  response_code = response["result"]["code"]
                  if response_code == "0000" do
                        group_member_id = get_in(response["group_user"], [Access.at(0)])
                        employee = Repo.get(Employee, employeeData.employee_id)
                        update_group = %{"group_id" => group_id, "group_member_id" => group_member_id["id"]}
                        changeset = Employee.changesetGroup(employee, update_group)
                        Repo.update(changeset)
                  end
                  _response_message = response["result"]["friendly_message"]
                end

  end

end