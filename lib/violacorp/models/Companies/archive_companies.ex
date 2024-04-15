defmodule Violacorp.Models.Companies.ArchiveCompanies do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Libraries.Commontools
  @moduledoc false

  @doc" Model Of List of Archived Companies"
  def archived_companies(params) do
    filtered = params
               |> Map.take(~w( email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]


    _active_companies = (from a in Commanall,having: ^filtered,
                              where: a.status == "D" and a.internal_status == "A" ,
                                              left_join: b in assoc(a, :company),
                                              where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%") ,
                                              select: %{
                                              company_id: b.id,
                                                id: a.id,
                                                email_id: a.email_id,
                                                company_name: b.company_name,
                                                company_type: b.company_type,
                                                date_added: a.inserted_at,
                                                status: a.status,
                                                internal_status: a.internal_status
                                              } )
                        |> order_by(desc: :id)
                        |> Repo.paginate(params)
  end

  @doc """
    this function for list of all archive company
  """
  def archivedCompaniesV1(params) do
    filtered = params
               |> Map.take(~w(username email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]

    (from a in Commanall,having: ^filtered,
                         where: a.status == "R",
                         left_join: b in assoc(a, :company),
                         where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%") ,
                         select: %{
                           company_id: b.id,
                           id: a.id,
                           username: a.username,
                           email_id: a.email_id,
                           company_name: b.company_name,
                           company_type: b.company_type,
                           date_added: a.inserted_at,
                           last_tag: fragment("(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name", a.id),
                           status: a.status,
                           internal_status: a.internal_status
                         } )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  @doc""

  def archivedCompanyProfile(params) do

    Repo.one(
      from c in Company, where: c.id == ^params["company_id"],
                         left_join: com in assoc(c, :commanall),
                         where: com.status == "D" and not is_nil(com.accomplish_userid),
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
                           registration_number: c.registration_number,
                           email_id: com.email_id,
                           accomplish_user_id: com.accomplish_userid,
                           monthly_transfer: c.monthly_transfer,
                           viola_id: com.viola_id,
                           status: com.status,
                           loading_fee: c.loading_fee,
                           mandate_date: m.inserted_at,
                           signed_by_title: d.title,
                           website: c.company_website,
                           signed_by_first_name: d.first_name,
                           signed_by_last_name: d.last_name
                         }
    )

  end


@doc""

  def archivedCompanyOnlineAccount(params) do
    Repo.all(
      from a in Companybankaccount, where: a.company_id == ^params["company_id"],
                                    left_join: b in assoc(a, :company),
                                    left_join: com in assoc(b, :commanall),
                                    where: com.status == "D" and not is_nil(com.accomplish_userid),
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
  @doc""
  def archivedCompanyCardManagementAccount(params) do

    Repo.all(
      from a in Companyaccounts,
      where: a.company_id == ^params["company_id"],
      left_join: c in assoc(a,:company),
      left_join: com  in assoc(c, :commanall), where: com.status == "D" and not is_nil(com.accomplish_userid),
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
  @doc""

  def archivedCompanyEmployeeList(params) do
    (
      from a in Employee,
           where: a.company_id == ^params["company_id"],
           left_join: c in assoc(a,:company),
           left_join: com  in assoc(c, :commanall), where: com.status == "D" and not is_nil(com.accomplish_userid),
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
  @doc""
  def archivedCompanyEmployeeCards(params) do

    Repo.all(
      from e in Employeecards,
                               left_join: emp in assoc(e, :employee),
                               left_join: c in assoc(emp, :company),
                               left_join: com in assoc(c, :commanall),
                               where: emp.company_id == ^params["company_id"],
                               where: com.status == "D" and not is_nil(com.accomplish_userid),
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
  @doc""
  def archivedCompanyDirectorList(params) do

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
  @doc""
  def archivedCompanyDescription(params) do

    Repo.all(from c in Commanall, where: c.company_id == ^params["company_id"] and not is_nil(c.accomplish_userid) and c.status == "D",
                                      left_join: k in assoc(c, :kycopinion),
                                      left_join: a in Administratorusers, on: k.inserted_by == a.id,
                                      select: %{
                                        fullname: a.fullname,
                                        description: k.description,
                                        signature: k.signature,
                                        status: k.status,
                                        inserted_at: k.inserted_at
                                      }
                                      )
  end

  @doc""
  def archivedCompanyContactAddress(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"] and a.status == "D" and not is_nil(a.accomplish_userid),
                           left_join: b in assoc(a, :address),
                           left_join: c in assoc(a, :contacts),
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
  @doc""
  def archivedCompanyKyb(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           left_join: b in assoc(a, :kycdocuments),
                           left_join: c in assoc(b, :documenttype),
                           where: a.status == "D" and not is_nil(a.accomplish_userid),
                           select: %{
                             title: c.title,
                             inserted_at: b.inserted_at,
                             status: b.status
                           })
  end

  @doc"Delete Company"
  def deleteCompany(params) do

    data = Repo.get_by(Commanall, company_id: params["company_id"], status: "D")

    if !is_nil(data) do

      status = %{status: "B"}
      changeset = Commanall.updateStatus(data, status)
      Repo.update(changeset)
      {:ok, "Company Deleted"}
    else
      {:not_found, "Record not found!"}
    end
  end

  @doc """
      get all companies account with cards
  """
  def getallCompaniesAccountCards(params) do
     company_id = params["company_id"]
     get_bank_account =  Repo.all(from b in Companybankaccount, where: b.company_id == ^params["company_id"] and not is_nil(b.account_id), select: %{bank_id: b.id, account_number: b.account_number, balance: b.balance})
     get_card_account =  Repo.all(from a in Companyaccounts, where: a.company_id == ^params["company_id"], select: %{account_id: a.id, account_number: a.account_number, balance: a.available_balance})
     employee_ids = Repo.one(from e in Employee, where: e.company_id == ^params["company_id"], limit: 1, select: fragment("GROUP_CONCAT(?)", e.id))
     employee_cards = if !is_nil(employee_ids) do
                         emp_ids = String.split(employee_ids,",")
                         Repo.all(from c in Employeecards, where: c.employee_id in ^emp_ids,  select: %{card_id: c.id, employee_id: c.employee_id, balance: c.available_balance, last_digit: c.last_digit})
                      else
                         []
                      end
     card_account = Enum.map(get_card_account, fn acc ->
       Map.merge(acc, %{account_number: Commontools.account_number(acc.account_number)})
     end)
     details = checkCompaniesBalance(company_id)
     %{online_bank_account: get_bank_account, card_management_account: card_account, employee_cards: employee_cards, total_balance: details.total_balance, is_permission: details.is_permission}
  end

  # calculate balance and give permission
  defp checkCompaniesBalance(company_id) do

    bank_account =  Repo.one(from b in Companybankaccount, where: b.company_id == ^company_id, select: sum(b.balance))
    get_bank_account = if is_nil(bank_account), do: "0.00", else: bank_account
    card_account =  Repo.one(from a in Companyaccounts, where: a.company_id == ^company_id, select: sum(a.available_balance))
    get_card_account = if is_nil(card_account), do: "0.00", else: card_account
    employee_ids = Repo.one(from e in Employee, where: e.company_id == ^company_id, limit: 1, select: fragment("GROUP_CONCAT(?)", e.id))
    employee_cards = if !is_nil(employee_ids) do
      emp_ids = String.split(employee_ids,",")
     card_account = Repo.one(from c in Employeecards, where: c.employee_id in ^emp_ids,  select: sum(c.available_balance))
     if !is_nil(card_account), do: card_account, else: "0.00"
    else
      "0.00"
    end
    total_balance = Decimal.add(Decimal.add(get_bank_account, get_card_account), employee_cards)
    is_permission = if Decimal.cmp(total_balance, "0.00") == :eq, do: "YES", else: "NO"
    %{total_balance: total_balance, is_permission: is_permission}
  end
end
