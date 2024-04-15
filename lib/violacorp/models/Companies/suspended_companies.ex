defmodule Violacorp.Models.Companies.SuspendedCompanies do
  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Employee

  @moduledoc false

  @doc" Model Of List of Suspended Companies"
  def suspended_companies(params) do
    filtered = params
               |> Map.take(~w(  email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]
    (from a in Commanall,
          having: ^filtered,
          where: a.internal_status == "S" and  not is_nil(a.accomplish_userid),
          join: b in assoc(a, :company),
          where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%") ,
          select: %{
            id: a.id,
            company_id: b.id,
            email_id: a.email_id,
            company_name: b.company_name,
            company_type: b.company_type,
            date_added: a.inserted_at,
            status: a.internal_status
          } )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  @doc """
    this function for get all suspended company
  """
  def suspendedCompaniesV1(params) do
    filtered = params
               |> Map.take(~w(username email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]
    (from a in Commanall,
          having: ^filtered,
          where: a.status == "D" and  not is_nil(a.accomplish_userid),
          join: b in assoc(a, :company),
          where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%") ,
          select: %{
            id: a.id,
            username: a.username,
            company_id: b.id,
            email_id: a.email_id,
            company_name: b.company_name,
            company_type: b.company_type,
            date_added: a.inserted_at,
            last_tag: fragment("(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name", a.id),
            status: a.status
          } )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  def online_account(params) do
    Repo.one(
      from a in Companybankaccount, where: a.company_id == ^params["company_id"],
                                    left_join: b in assoc(a, :company),
                                    left_join: com in assoc(b, :commanall), where: com.internal_status == "S" and not is_nil(com.accomplish_userid),
                                    select: %{
                                      account_number: a.account_number,
                                      clear_bank_account_number: a.account_number,
                                      sort_code: a.sort_code,
                                      currency: a.currency,
                                      balance: a.balance,
                                      status: a.status
                                    }
    )
  end

  def card_management_account(params) do
    Repo.one(
      from a in Companyaccounts,
      where: a.company_id == ^params["company_id"],left_join: com in  Commanall,where: a.company_id == com.company_id and com.internal_status == "S",
      select: %{
        account_number: a.account_number,
        accomplish_account_number: a.accomplish_account_number,
        available_balance: a.available_balance,
        current_balance: a.current_balance,
        currency: a.currency_code,
        status: a.status
      }
    )
  end

  def employee_details(params) do
    (
      from a in Employee,
           where: a.company_id == ^params["company_id"],left_join: com in  Commanall,where: a.id == com.employee_id and com.internal_status == "S",
           select: %{
             id: a.id,
             first_name: a.first_name,
             middle_name: a.middle_name,
             last_name: a.last_name,
             position: a.position,
             date_of_birth: a.date_of_birth,
             kyc_status: a.status
           })
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end


  @doc" Model Of Director Details"
  def director_details(params) do
    count = (from a in Directors, order_by: [asc: a.first_name],
                                  where: a.company_id == ^params["id"],
                                  left_join: b in assoc(a, :addressdirectors),
                                  left_join: c in assoc(a, :contactsdirectors),
                                  select: %{email_id: a.email_id,id: a.id, first_name: a.first_name, last_name: a.last_name,date_of_birth: a.date_of_birth, status: a.status, address_line_one: b.address_line_one,address_line_two: b.address_line_two,address_line_three: b.address_line_three,city: b.city, post_code: b.post_code, contact_number: c.contact_number})
            |> Repo.all

    _address = Enum.map(count, fn (x) -> x[:id]


                                        data = Repo.one(from kyc in Kycdirectors, where: kyc.directors_id == ^x[:id] and kyc.type == "A",
                                                                                  left_join: dt in assoc(kyc, :documenttype),
                                                                                  left_join: dc in assoc(dt, :documentcategory),
                                                                                  select: %{ type: kyc.type,document_number: kyc.document_number, title: dc.title,document_type: dt.title, expiry_date: kyc.expiry_date, inserted_at: kyc.inserted_at, kyc_status: kyc.status})

                                        id_info = Repo.one(from kc in Kycdirectors, where: kc.directors_id == ^x[:id] and kc.type == "I",
                                                                                    left_join: dtt in assoc(kc, :documenttype),
                                                                                    left_join: dcc in assoc(dtt, :documentcategory),
                                                                                    select: %{type: kc.type, document_number: kc.document_number, title: dcc.title,document_type: dtt.title,  expiry_date: kc.expiry_date, inserted_at: kc.inserted_at, kyc_status: kc.status})



                                        %{
                                          first_name: x[:first_name],
                                          last_name: x[:last_name],
                                          position: x[:position],
                                          date_of_birth: x[:date_of_birth],
                                          status: x[:status],
                                          city: x[:city],
                                          address_line_one: x[:address_line_one],
                                          address_line_two: x[:address_line_two],
                                          address_line_three: x[:address_line_three],
                                          post_code: x[:post_code],
                                          contact_number: x[:contact_number],
                                          kyc:  %{address: data ,id: id_info}
                                        }
    end)

  end



  @doc" Model Of Company Address Contact Details"
  def company_address_contacts(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],where: a.internal_status == "S",
                           join: b in assoc(a, :address),
                           join: c in assoc(a, :contacts),
                           select: %{
                             address_line_one: b.address_line_one,
                             address_line_two: b.address_line_two,
                             address_line_three: b.address_line_three,
                             city: b.city,
                             contact_number: c.contact_number,
                             post_code: b.post_code,
                             email_id: a.email_id,
                             status: a.status

                           })
  end


  def company_description(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],where: a.internal_status == "S",
                           join: b in assoc(a, :kycopinion),
                           on: b.commanall_id == a.id,
                           right_join: c in Administratorusers,
                           on: b.inserted_by == c.id,
                           select: %{
                             fullname: c.fullname,
                             description: b.description,
                             signature: b.signature,
                             status: b.status,
                             inserted_at: b.inserted_at

                           })
  end


  def employee_card(params) do

    Repo.all(
      from a in Company, where: a.id == ^params["company_id"],left_join: com in assoc(a, :commanall),where: com.internal_status == "S",
                         join: b in assoc(a, :employee),
                         join: c in Employeecards,
                         on: c.employee_id == b.id,
                         select: %{
                           first_name: b.first_name,
                           middle_name: b.middle_name,
                           last_name: b.last_name,
                           name_on_card: c.name_on_card,
                           card_type: c.card_type,
                           last_digit: c.last_digit,
                           available_balance: c.available_balance,
                           available_balance: c.available_balance,
                           current_balance: c.current_balance,
                           expiry_date: c.expiry_date,
                           currency_code: c.currency_code,
                           status: c.status

                         })
  end




  @doc" Model Of company Kyb Description"
  def company_kyb(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],where:  a.internal_status == "S",
                           join: b in assoc(a, :kycdocuments),
                           on: b.commanall_id == a.id,
                           join: c in Documenttype,
                           on: c.id == b.documenttype_id,
                           select: %{
                             title: c.title,
                             inserted_at: a.inserted_at,
                             status: b.status


                           })
  end



  @doc" Model Of company  Description"
  def company_info(params) do
    _data = Repo.one(
      from a in Company, where: a.id == ^params["company_id"],
                         left_join: b in Commanall,  where: b.internal_status == "S" and not is_nil(b.accomplish_userid),
                         left_join: m in assoc(b,:mandate),
                         left_join: d in assoc(m,:directors), where: d.id == m.directors_id,
                         left_join: c in Countries,
                         join: ad in Administratorusers,
                         on: ad.id == b.inserted_by,
                         where: c.id == a.countries_id and b.company_id == a.id ,
                         select: %{
                           mandate_date: m.inserted_at,
                           title: d.title,
                           first_name: d.first_name,
                           last_name: d.last_name,
                           registration_number: a.registration_number,
                           company_logo: a.company_logo,
                           company_name: a.company_name,
                           email_id: b.email_id,
                           viola_id: b.viola_id,
                           status: b.status,
                           company_type: a.company_type,
                           registration_date: a.inserted_at,
                           accomplish_userid: b.accomplish_userid,
                           country_name: c.country_name,
                           approve_by: ad.fullname,
                         })


  end



end
