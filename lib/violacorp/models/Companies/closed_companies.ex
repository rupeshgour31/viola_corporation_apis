defmodule Violacorp.Companies.ClosedCompanies do
  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Kycdirectors
#  alias Violacorp.Schemas.Documenttype
#  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Company
#  alias Violacorp.Schemas.Tags
#  alias Violacorp.Schemas.Transactions

  @moduledoc false


  def closedCompanyProfile(params) do

    Repo.one(
      from c in Company, where: c.id == ^params["company_id"],
                         left_join: com in assoc(c, :commanall),
                         where: com.internal_status == "C" and not is_nil(com.accomplish_userid),
                         left_join: w in assoc(c, :countries),
                         left_join: m in assoc(com, :mandate),
                         left_join: d in assoc(m, :directors),
                         left_join: ad in Administratorusers,
                         on: com.inserted_by == ad.id,
                         select: %{
                           company_name: c.company_name,
                           approve_by: ad.fullname,
                           company_type: c.company_type,
                           sector: "#NO SECTOR#",
                           sector_details: c.sector_details,
                           country: w.country_name,
                           registration_date: c.date_of_registration,
                           email_id: com.email_id,
                           accomplish_user_id: com.accomplish_userid,
                           monthly_transfer: c.monthly_transfer,
                           viola_id: com.viola_id,
                           status: com.status,
                           loading_fee: c.loading_fee,
                           mandate_date: m.inserted_at,
                           signed_by_title: d.title,
                           signed_by_first_name: d.first_name,
                           signed_by_last_name: d.last_name,
                           internal_status: com.internal_status
                         }

    )

  end
  @doc" Model Of List of Closed Companies"
  def closed_companies(params) do
    filtered = params
               |> Map.take(~w(email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      company_name = params["company_name"]
     contact_number = params["contact_number"]
    company_type = params["company_type"]

    _active_companies = (from a in Commanall,having: ^filtered,
                                              left_join: b in assoc(a, :company),
                                              left_join: c in assoc(a, :contacts),
                                              on: a.internal_status == "C" and  c.is_primary == "Y",
                                              where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%") and like(c.contact_number, ^"%#{contact_number}%"),
                                              select: %{
                                                company_id: b.id,
                                                id: a.id,
                                                email_id: a.email_id,
                                                company_name: b.company_name,
                                                contact_number: c.contact_number,
                                                company_type: b.company_type,
                                                date_added: a.inserted_at,
                                                internal_status: a.internal_status,
                                                status: a.status
                                              } )
                        |> order_by(desc: :id)
                        |> Repo.paginate(params)

  end

  @doc """
    this function for list of closed company
  """
  def closedCompaniesV1(params) do
    filtered = params
               |> Map.take(~w(username email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]

    (from a in Commanall,
       having: ^filtered,
       left_join: b in assoc(a, :company),
       where: a.status == "B" and like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%"),
       select: %{
         company_id: b.id,
         id: a.id,
         username: a.username,
         email_id: a.email_id,
         company_name: b.company_name,
         company_type: b.company_type,
         date_added: a.inserted_at,
         internal_status: a.internal_status,
         last_tag: fragment("(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name", a.id),
         status: a.status
       } )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

#  defp get_last_tag(commanall_id) do
#    Repo.one(from t in Tags, where: t.commanall_id == ^commanall_id, order_by: [desc: t.id], limit: 1, select: t.description)
#  end

  def online_bank_account(params)do
    Repo.all(
      from a in Companybankaccount, where: a.company_id == ^params["company_id"],
                                    left_join: c in assoc(a,:company),
                                    left_join: com  in assoc(c, :commanall),where: com.internal_status == "C",
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
    Repo.all(
      from a in Companyaccounts,
      where: a.company_id == ^params["company_id"],
      left_join: c in assoc(a,:company),
      left_join: com  in assoc(c, :commanall),where: com.internal_status == "C",
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
           where: a.company_id == ^params["company_id"],
           left_join: c in assoc(a,:company),
           left_join: com  in assoc(c, :commanall),where: com.internal_status == "C",
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

  def employee_card(params) do

    Repo.all(
      from e in Employeecards, where: e.employee_id == ^params["employee_id"],
                               left_join: emp in assoc(e, :employee),
                               left_join: c in assoc(emp, :company),
                               left_join: com in assoc(c, :commanall),
                               where: com.internal_status == "C",
                               select: %{
                                 first_name: emp.first_name,
                                 middle_name: emp.middle_name,
                                 last_name: emp.last_name,
                                 name_on_card: e.name_on_card,
                                 card_type: e.card_type,
                                 last_digit: e.last_digit,
                                 available_balance: e.available_balance,
                                 available_balance: e.available_balance,
                                 current_balance: e.current_balance,
                                 expiry_date: e.expiry_date,
                                 currency_code: e.currency_code,
                                 status: e.status
                               }
    )
  end

  def director_details(params) do

    count = (from a in Directors, order_by: [asc: a.first_name],
                                  where: a.company_id == ^params["company_id"],
                                  left_join: b in assoc(a, :addressdirectors),
                                  left_join: c in assoc(a, :contactsdirectors),
                                  select: %{
                                    email_id: a.email_id,id: a.id,
                                    first_name: a.first_name,
                                    last_name: a.last_name,
                                    date_of_birth: a.date_of_birth,
                                    status: a.status,
                                    address_line_one: b.address_line_one,
                                    address_line_two: b.address_line_two,
                                    address_line_three: b.address_line_three,
                                    city: b.city,
                                    post_code: b.post_code,
                                    contact_number: c.contact_number
                                  })
            |> Repo.all

    _address = Enum.map(count, fn (x) -> x[:id]

                              data = Repo.all(from kyc in Kycdirectors, where: kyc.directors_id == ^x[:id] and kyc.type == "A",
                                                                        left_join: dt in assoc(kyc, :documenttype),
                                                                        left_join: dc in assoc(dt, :documentcategory),
                                                                        select: %{
                                                                          type: kyc.type,
                                                                          issue_date: kyc.issue_date,
                                                                          document_number: kyc.document_number,
                                                                          title: dc.title,
                                                                          document_type: dt.title,
                                                                          expiry_date: kyc.expiry_date,
                                                                          inserted_at: kyc.inserted_at,
                                                                          kyc_status: kyc.status
                                                                        })

                              id_info = Repo.all(from kc in Kycdirectors, where: kc.directors_id == ^x[:id] and kc.type == "I",
                                                                          left_join: dtt in assoc(kc, :documenttype),
                                                                          left_join: dcc in assoc(dtt, :documentcategory),
                                                                          select: %{
                                                                            type: kc.type,
                                                                            issue_date: kc.issue_date,
                                                                            document_number: kc.document_number,
                                                                            title: dcc.title,
                                                                            document_type: dtt.title,
                                                                            expiry_date: kc.expiry_date,
                                                                            inserted_at: kc.inserted_at,
                                                                            kyc_status: kc.status
                                                                          })

                              %{
                                director_info: %{
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
                                  contact_number: x[:contact_number]},
                                kyc:  %{address: data ,id: id_info}
                              }
    end)
  end

  def company_description(params) do

    Repo.all(
      from c in Company, where: c.id == ^params["company_id"],
                         left_join: com in assoc(c, :commanall),
                         left_join: k in assoc(com, :kycopinion),
                         right_join: ad in Administratorusers,
                         on: k.inserted_by == ad.id,

                         where: com.internal_status == "C",
                         select: %{
                           fullname: ad.fullname,
                           description: k.description,
                           signature: k.signature,
                           status: k.status,
                           inserted_at: k.inserted_at
                         }
    )
  end


  def company_address_contacts(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"] and a.internal_status == "C",
                           left_join: b in assoc(a, :address),
                           left_join: c in assoc(a, :contacts),
                           where: a.internal_status == "C",
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

  def company_kyb(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           left_join: b in assoc(a, :kycdocuments),
                           left_join: c in assoc(b, :documenttype),
                           where: a.internal_status == "C",
                           select: %{
                             title: c.title,
                             inserted_at: b.inserted_at,
                             status: b.status
                           })
  end







end
