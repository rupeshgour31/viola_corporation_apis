defmodule Violacorp.Models.Companies.ActiveCompanies do
  @moduledoc false
  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Documenttype
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Kycdirectors
  #  alias Violacorp.Schemas.Documentcategory
  alias Violacorp.Schemas.Kyccomments
  alias Violacorp.Schemas.Blockusers
  alias Violacorp.Schemas.Commankyccomments
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Duefees
  alias Violacorp.Schemas.Kycopinion
  alias Violacorp.Schemas.Tags
  alias Violacorp.Schemas.Documentcategory
  #  alias Violacorp.Schemas.Fourstop

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish

  @doc""

  def activeCompanyLoadingFee(params, admin_id) do

    case checkLoadingFeeValidation(params) do
      {:ok, _message} ->
        type = params["type"]
        plan = params["plan"]
        id = params["company_id"]
        case type do
          "N" ->
            company = Repo.get_by(Company, id: id)
            if !is_nil(company)do
              dates = %{"date_to" => nil, "date_from" => nil, "loading_fee" => "N", inserted_by: admin_id}
              changeset = Company.changeset(company, dates)
              case Repo.update(changeset)do
                {:ok, _changeset} -> {:ok, "Record Updated"}
                {:error, changeset} -> {:error, changeset}
              end
            else
              {:not_found, "Record not found!"}
            end
          "W" ->
            days = case plan do
              "1" -> 2629746
              "3" -> 7890000
              "6" -> 15780000
              "12" -> 31560000
              "Never" -> 0
              _ -> nil
            end
            if !is_nil(days) do
              date_from = DateTime.utc_now()
              date_to = DateTime.add(date_from, days, :second)
              company = Repo.one(from com in Company, where: com.id == ^id, limit: 1, select: com)
              comman = Repo.one(from c in Commanall, where: c.company_id == ^id, limit: 1, select: c)
              due_fee = Repo.one(
                from d in Duefees, where: d.commanall_id == ^comman.id and d.type == ^"M" and d.status == ^"P", limit: 1
              )
              dates = %{"date_to" => date_to, "date_from" => date_from, "loading_fee" => "W", }
              if !is_nil(company)do
                if is_nil(due_fee) do
                  changeset = Company.changeset(company, dates)
                  case Repo.update(changeset)do
                    {:ok, _changeset} -> {:ok, "Record Updated"}
                    {:error, changeset} -> {:error, changeset}
                  end
                else
                  changeset = Company.changeset(company, dates)
                  case Repo.update(changeset)do
                    {:ok, _changeset} -> {:ok, "Record Updated"}
                    {:error, changeset} -> {:error, changeset}
                  end
                  change = %{pay_date: date_from, next_date: date_to}
                  duefees = Duefees.changeset(due_fee, change)
                  case Repo.update(duefees)do
                    {:ok, _changeset} -> {:ok, "Record Updated"}
                    {:error, duefees} -> {:error, duefees}
                  end
                end
              else
                {:not_found, "Record not found!"}
              end
            else
              {:error_message, "Feeplan not found!"}
            end
          _ -> {:not_found, "Fee not found!"}
        end
      {:error, message} -> {:validation_error, message}
    end

  end

  def checkLoadingFeeValidation(params) do
    cond do
      is_nil(params["type"]) ->
        {
          :error,
          %{
            status_code: "4003",
            errors: %{
              type: "can't be blank."
            }
          }
        }
      is_nil(params["plan"]) ->
        {
          :error,
          %{
            status_code: "4003",
            errors: %{
              plan: "can't be blank."
            }
          }
        }
      is_nil(params["company_id"]) ->
        {
          :error,
          %{
            status_code: "4003",
            errors: %{
              company_id: "can't be blank."
            }
          }
        }
      true ->
        {:ok, "done"}
    end
  end

  @doc" Model Of List of Active Companies"
  def active_companies(params) do
    filtered = params
               |> Map.take(~w(username email_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    contact_number = params["contact_number"]
    company_type = params["company_type"]



    data = (
             from a in Commanall,
                  where: a.internal_status == "A" and a.status == "A",
                  having: ^filtered,
                  left_join: b in assoc(a, :company),
                  order_by: [
                    asc: b.company_name
                  ],
                  where: like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%"),
                  left_join: c in assoc(a, :contacts),
                  on: c.commanall_id == a.id and c.is_primary == "Y",
                  where: like(c.contact_number, ^"%#{contact_number}%"),
                  left_join: d in assoc(b, :companyaccounts),
                  select: %{
                    loading_fee: b.loading_fee,
                    accomplish_userid: a.accomplish_userid,
                    inserted_by: a.inserted_by,
                    status: a.status,
                    email_id: a.email_id,
                    commanall_id: a.id,
                    username: a.username,
                    contact_number: c.contact_number,
                    company_id: b.id,
                    company_name: b.company_name,
                    company_type: b.company_type,
                    trust_level: a.trust_level,
                    reg_at: a.inserted_at,
                    inserted_at: d.inserted_at,
                    available_balance: d.available_balance,
                  })
           |> Repo.paginate(params)
    company = Enum.map data, fn x -> company_id = x.company_id
                                     _approved_on = x.inserted_at
                                     reg_at = x.reg_at

                                     all = Repo.one(
                                       from a in Company, where: a.id == ^company_id,
                                                          join: b in assoc(a, :employee),
                                                          join: c in Employeecards,
                                                          on: c.employee_id == b.id,
                                                          select: %{
                                                            total: sum(c.available_balance)
                                                          }
                                     )
                                     get_balance = Repo.one(
                                       from a in Companybankaccount,
                                       where: a.company_id == ^company_id and a.status == "A",
                                       select: sum(a.balance)
                                     )
                                     tags_info = get_last_tag(x.commanall_id)
                                     if get_balance != nil do
                                       _map = %{
                                         card_bal: all.total,
                                         last_tag: tags_info.last_tag,
                                         balance: get_balance,
                                         commanall_id: x.commanall_id,
                                         username: x.username,
                                         company_id: x.company_id,
                                         trust_level: x.trust_level,
                                         email_id: x.email_id,
                                         status: x.status,
                                         company_name: x.company_name,
                                         available_balance: x.available_balance,
                                         approved_on: x.inserted_at,
                                         registration_on: reg_at,
                                         company_type: x.company_type,
                                         loading_fee: x.loading_fee
                                       }
                                     else
                                       _map = %{
                                         card_bal: all.total,
                                         last_tag: tags_info.last_tag,
                                         balance: 0.00,
                                         commanall_id: x.commanall_id,
                                         username: x.username,
                                         company_id: x.company_id,
                                         trust_level: x.trust_level,
                                         email_id: x.email_id,
                                         status: x.status,
                                         company_name: x.company_name,
                                         available_balance: x.available_balance,
                                         approved_on: x.inserted_at,
                                         registration_on: reg_at,
                                         company_type: x.company_type,
                                         loading_fee: x.loading_fee
                                       }
                                     end
      #            map = %{card_bal: all.total,   company_id:  x.company_id ,trust_level: x.trust_level, email_id: x.email_id,status: x.status, company_name: x.company_name,available_balance: x.available_balance, approved_on: x.inserted_at, registration_on: reg_at, company_type: x.company_type, }

    end
    %{
      entries: company,
      page_number: data.page_number,
      page_size: data.page_size,
      total_entries: data.total_entries,
      total_pages: data.total_pages
    }
  end

  #-------------------------Active--Companies---Profile-----------------------------------------------

  @doc" Model Of Get Online Account"

  def online_account(params) do
    Repo.all(
      from a in Companybankaccount, where: a.company_id == ^params["company_id"],
                                    select: %{
                                      company_id: a.company_id,
                                      id: a.id,
                                      account_number: a.account_number,
                                      clear_bank_account_number: a.account_number,
                                      sort_code: a.sort_code,
                                      currency: a.currency,
                                      balance: a.balance,
                                      status: a.status,
                                      iban_number: a.iban_number
                                    }
    )
  end

  @doc" Model Of Get Card Management Account"
  def card_management_account(params) do
    account = Repo.all(
      from a in Companyaccounts,
      where: a.company_id == ^params["company_id"],
      left_join: b in assoc(a, :company),
      select: %{
        company_id: b.id,
        id: a.id,
        account_number: a.account_number,
        accomplish_account_id: a.accomplish_account_id,
        accomplish_account_number: a.accomplish_account_number,
        available_balance: a.available_balance,
        current_balance: a.current_balance,
        currency: a.currency_code,
        status: a.status
      }
    )
    Enum.map(
      account,
      fn acc ->
        Map.merge(acc, %{account_number: Commontools.account_number(acc.account_number)})
      end
    )
  end

  @doc" Model Of Employee Details"
  def employee_details(params) do
    card = (
             from a in Employee,
                  where: a.company_id == ^params["company_id"],
                  select: %{
                    id: a.id,
                    first_name: a.first_name,
                    middle_name: a.middle_name,
                    last_name: a.last_name,
                    position: a.position,
                    date_of_birth: a.date_of_birth,
                    kyc_status: a.status,
                    director_id: a.director_id
                  })
           |> order_by(desc: :id)
           |> Repo.paginate(params)
    response = Enum.map card, fn x ->

      data = if !is_nil(x.director_id), do: "Y", else: "N"

      %{
        id: x.id,
        first_name: x.first_name,
        middle_name: x.middle_name,
        last_name: x.last_name,
        position: x.position,
        date_of_birth: x.date_of_birth,
        kyc_status: x.kyc_status,
        as_director: data
      }
    end

    %{
      entries: response,
      page_number: card.page_number,
      total_entries: card.total_entries,
      page_size: card.page_size,
      total_pages: card.total_pages
    }
  end


  @doc" Model Of Director Details"
  def director_details(params) do
    count = (
              from a in Directors,
                   order_by: [
                     asc: a.first_name
                   ],
                   where: a.company_id == ^params["id"],
                   left_join: b in assoc(a, :addressdirectors),
                   left_join: c in assoc(a, :contactsdirectors),
                   select: %{
                     director_id: a.id,
                     email_id: a.email_id,
                     id: a.id,
                     position: a.position,
                     first_name: a.first_name,
                     last_name: a.last_name,
                     date_of_birth: a.date_of_birth,
                     verify_kyc: a.verify_kyc,
                     status: a.status,
                     as_employee: a.as_employee,
                     address_line_one: b.address_line_one,
                     address_line_two: b.address_line_two,
                     address_line_three: b.address_line_three,
                     city: b.town,
                     post_code: b.post_code,
                     contact_number: c.contact_number
                   })
            |> Repo.all

    _address = Enum.map(
      count,
      fn (x) -> x[:id]

                employee = Repo.all(from e in Employee, where: e.director_id == ^x.director_id, select: e)
                as_employee = if employee != [], do: "Y", else: "N"

                data = Repo.all(
                  from kyc in Kycdirectors, where: kyc.directors_id == ^x[:id] and kyc.type == "A",
                                            left_join: dt in Documenttype,
                                            on: dt.id == kyc.documenttype_id,
                                            left_join: dc in assoc(dt, :documentcategory),
                                            order_by: [
                                              desc: kyc.id
                                            ],
                                            select: %{
                                              kyc_directors_id: kyc.id,
                                              reason: kyc.reason,
                                              type: kyc.type,
                                              issue_date: kyc.issue_date,
                                              document_number: kyc.document_number,
                                              title: dc.title,
                                              document_type: dt.title,
                                              expiry_date: kyc.expiry_date,
                                              inserted_at: kyc.inserted_at,
                                              kyc_status: kyc.status,
                                              file_location: kyc.file_location,
                                              file_location_two: kyc.file_location_two
                                            }
                )

                response = Enum.map(
                  data,
                  fn y ->
                    data = if !is_nil(y.file_location) or !is_nil(y.file_location_two) do
                      file_one = y.file_location

                      image_one = if !is_nil(file_one), do: file_one, else: ""
                      image_second = if !is_nil(y.file_location_two), do: (y.file_location_two), else: ""
                      %{image_one: image_one, image_second: image_second}

                    else
                      %{image_one: "", image_second: ""}
                    end
                    %{
                      kyc_directors_id: y.kyc_directors_id,
                      type: y.type,
                      reason: y.reason,
                      issue_date: y.issue_date,
                      document_number: y.document_number,
                      title: y.title,
                      document_type: y.document_type,
                      expiry_date: y.expiry_date,
                      inserted_at: y.inserted_at,
                      kyc_status: y.kyc_status,
                      file_location: y.file_location,
                      file_location_two: y.file_location_two,
                      image_one: data.image_one,
                      image_second: data.image_second
                    }
                  end
                )

                id_info = Repo.all(
                  from kc in Kycdirectors, where: kc.directors_id == ^x[:id] and kc.type == "I",
                                           left_join: dtt in Documenttype,
                                           on: dtt.id == kc.documenttype_id,
                                           left_join: dcc in assoc(dtt, :documentcategory),
                                           left_join: adm2 in Administratorusers,
                                           on: adm2.id == kc.refered_id,
                                           order_by: [
                                             desc: kc.id
                                           ],
                                           select: %{
                                             kyc_directors_id: kc.id,
                                             type: kc.type,
                                             issue_date: kc.issue_date,
                                             document_number: kc.document_number,
                                             title: dcc.title,
                                             document_type: dtt.title,
                                             expiry_date: kc.expiry_date,
                                             inserted_at: kc.inserted_at,
                                             kyc_status: kc.status,
                                             file_location: kc.file_location,
                                             file_location_two: kc.file_location_two,
                                             fourstop_response: kc.fourstop_response,
                                             reason: kc.reason,
                                             refered_id: kc.refered_id,
                                             refered_by: adm2.fullname,
                                           }
                )

                _response_id = Enum.map(
                  id_info,
                  fn y ->
                    data = if !is_nil(y.file_location) or !is_nil(y.file_location_two) do
                      file_one = y.file_location

                      image_one = if !is_nil(file_one), do: file_one, else: ""
                      image_second = if !is_nil(y.file_location_two), do: (y.file_location_two), else: ""
                      %{image_one: image_one, image_second: image_second}

                    else
                      %{image_one: "", image_second: ""}
                    end
                    %{
                      kyc_directors_id: y.kyc_directors_id,
                      type: y.type,
                      issue_date: y.issue_date,
                      document_number: y.document_number,
                      title: y.title,
                      reason: y.reason,
                      document_type: y.title,
                      expiry_date: y.expiry_date,
                      inserted_at: y.inserted_at,
                      kyc_status: y.kyc_status,
                      file_location: y.file_location,
                      file_location_two: y.file_location_two,
                      image_one: data.image_one,
                      image_second: data.image_second,
                      fourstop_response: y.fourstop_response,
                      refered_id: y.refered_id,
                      refered_by: y.refered_by,
                    }
                  end
                )
                key = Enum.map(
                  id_info,
                  fn (q) ->
                    #                            gbg_status = if x[:verify_kyc] == "gbg", do: getGBGStatus(q.fourstop_response), else: get_fourstop_info(x[:director_id])
                    gbg_status = checkThirdpartyResponse(q.fourstop_response)
                    new_key = if !is_nil(x[:date_of_birth]) and !is_nil(x[:contact_number]) and !is_nil(
                      x[:address_line_one]
                    ) and !is_nil(q.issue_date) do
                      %{call_gbg: "YES", gbg_status: gbg_status}
                    else
                      %{call_gbg: "NO", gbg_status: gbg_status}
                    end
                    _get = Map.merge(q, new_key)
                  end
                )

                %{
                  director_info: %{
                    as_employee: as_employee,
                    first_name: x[:first_name],
                    director_id: x[:director_id],
                    email_id: x[:email_id],
                    last_name: x[:last_name],
                    position: x[:position],
                    date_of_birth: x[:date_of_birth],
                    status: x[:status],
                    city: x[:city],
                    address_line_one: x[:address_line_one],
                    address_line_two: x[:address_line_two],
                    address_line_three: x[:address_line_three],
                    post_code: x[:post_code],
                    contact_number: x[:contact_number]
                  },
                  kyc: %{
                    address: response,
                    id: key
                  }
                }
      end
    )


    #
    #
    #    director_info  = Repo.one(from a in Directors,
    #                                 left_join: b in assoc(a, :addressdirectors),
    #                                 left_join: c in assoc(a, :contactsdirectors),
    #                                   where: a.id == ^params["id"],
    #                                 select: %{
    #                                   id: a.id,
    #                                   first_name: a.first_name,
    #                                   middle_name: a.middle_name,
    #                                   last_name: a.last_name,
    #                                   position: a.position,
    #                                   date_of_birth: a.date_of_birth,
    #                                   address_line_one: b.address_line_one,
    #                                   address_line_two: b.address_line_two,
    #                                   address_line_three: b.address_line_three,
    #                                   city: b.city,
    #                                   contact_number: c.contact_number,
    #                                   post_code: b.post_code,
    #                                   email_id: a.email_id,
    #                                   status: a.status,
    #                                 })
    #
    #          address_info = Repo.one(from kyc in Kycdirectors,
    #                                  where: kyc.directors_id == ^director_info.id and kyc.type == "A",
    #                                  left_join: dt in assoc(kyc, :documenttype),
    #                                  left_join: dc in assoc(dt, :documentcategory),
    #              select: %{document_number: kyc.document_number, title: dc.title,document_type: dt.title,  expiry_date: kyc.expiry_date, inserted_at: kyc.inserted_at, kyc_status: kyc.status})
    #
    #    id_info = Repo.one(from kc in Kycdirectors,
    #                            where: kc.directors_id == ^director_info.id and kc.type == "I",
    #                            left_join: dtt in assoc(kc, :documenttype),
    #                            left_join: dcc in assoc(dtt, :documentcategory),
    #                            select: %{document_number: kc.document_number, title: dcc.title,document_type: dtt.title,  expiry_date: kc.expiry_date, inserted_at: kc.inserted_at, kyc_status: kc.status})
    #
    #     merge = %{address_info: address_info, id_info: id_info}
    #     map = %{director_info: director_info, kyc_detail: merge}
  end
  def director_list(params) do
    Repo.all(
      from a in Directors, order_by: [
        asc: a.first_name
      ],
                           where: a.company_id == ^params["company_id"],
                           select: %{
                             id: a.id,
                             first_name: a.first_name,
                             last_name: a.last_name,
                           }
    )
  end
  @doc" Model Of Company Address Contact Details"
  def company_address_contacts(params) do

    address_info = Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           join: b in assoc(a, :address),
                           select: %{
                             address_line_one: b.address_line_one,
                             address_line_two: b.address_line_two,
                             address_line_three: b.address_line_three,
                             is_primary: b.is_primary,
                             city: b.city,
                             post_code: b.post_code,
                             email_id: a.email_id,
                             status: a.status
                           }
    )

    contact_info = Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           join: c in assoc(a, :contacts),
                           select: %{
                             contact_number: c.contact_number,
                             is_primary: c.is_primary,
                             code: c.code,
                             email_id: a.email_id
                           }
    )
    _merge = %{address_info: address_info, contact_info: contact_info}
  end


  @doc" Model Of Company Description"
  def company_description(params) do
    Repo.all(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           join: b in Kycopinion,
                           on: b.commanall_id == a.id,
                           right_join: c in Administratorusers,
                           on: b.inserted_by == c.id,
                           order_by: [
                             desc: b.id
                           ],
                           select: %{
                             fullname: c.fullname,
                             description: b.description,
                             signature: b.signature,
                             status: b.status,
                             inserted_at: b.inserted_at

                           }
    )
  end

  @doc" Model Of employee Card Description"
  def employee_card(params) do

    Repo.all(
      from a in Company, where: a.id == ^params["company_id"],
                         join: b in assoc(a, :employee),
                         join: c in Employeecards,
                         on: c.employee_id == b.id,
                         order_by: [
                           desc: b.id
                         ],
                         select: %{
                           first_name: b.first_name,
                           middle_name: b.middle_name,
                           last_name: b.last_name,
                           name_on_card: c.name_on_card,
                           card_type: c.card_type,
                           last_digit: c.last_digit,
                           available_balance: c.available_balance,
                           account_id: c.accomplish_card_id,
                           current_balance: c.current_balance,
                           expiry_date: c.expiry_date,
                           currency_code: c.currency_code,
                           status: c.status,
                           card_id: c.id

                         }
    )
  end

  def employee_card_transaction(params) do
    filtered = params
               |> Map.take(~w(transaction_id amount status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    name = params["first_name"]
    last_name = params["last_name"]
    _pos_tx = (
                from t in Transactions,
                     having: ^filtered,
                     where: t.category == "POS" and t.employeecards_id == ^params["card_id"],
                     left_join: e in Employee,
                     on: t.employee_id == e.id,
                     where: like(e.first_name, ^"%#{name}%") and like(e.last_name, ^"%#{last_name}%"),
                     left_join: c in Commanall,
                     on: c.id == t.commanall_id,
                     where: not is_nil(c.accomplish_userid),
                     left_join: com in Company,
                     on: t.company_id == com.id,
                     where: like(com.company_name, ^"%#{company_name}%"),
                     select: %{
                       id: t.id,
                       company_name: com.company_name,
                       first_name: e.first_name,
                       last_name: e.last_name,
                       transaction_id: t.transaction_id,
                       cur_code: t.cur_code,
                       transaction_type: t.transaction_type,
                       transaction_mode: t.transaction_mode,
                       category: t.category,
                       amount: t.amount,
                       status: t.status,
                       updated_at: t.updated_at,
                       server_date: t.server_date,
                       remark: t.remark
                     })
              |> Repo.paginate(params)


  end
  @doc" Model Of company Kyb Description"
  def company_kyb(params) do
    Repo.all(
      from a in Commanall, where: a.id == ^params["commanall_id"],
                           join: b in assoc(a, :kycdocuments),
                           on: b.commanall_id == a.id,
                           join: c in Documenttype,
                           on: c.id == b.documenttype_id,
                           select: %{
                             id: b.id,
                             title: c.title,
                             inserted_at: b.inserted_at,
                             status: b.status,
                             file_location: b.file_location,


                           }
    )
  end


  @doc" Model Of company  Description"
  def company_info(params) do
    info = Repo.one(
      from a in Company, where: a.id == ^params["company_id"],
                         left_join: b in Commanall,
                         on: a.id == b.company_id,
                         left_join: m in assoc(b, :mandate),
                         left_join: con in assoc(b, :contacts),
                         where: con.is_primary == "Y",
                         left_join: d in assoc(m, :directors),
                         on: d.id == m.directors_id,
                         left_join: c in Countries,
                         on: c.id == a.countries_id and b.company_id == a.id,
                         left_join: ad in Administratorusers,
                         on: ad.id == b.inserted_by,
                         select: %{
                           username: b.username,
                           email_verified: b.email_verified,
                           mobile_verified: b.mobile_verified,
                           commanall_id: b.id,
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
                           internal_status: b.internal_status,
                           company_type: a.company_type,
                           landline_number: a.landline_number,
                           registration_date: a.inserted_at,
                           accomplish_userid: b.accomplish_userid,
                           country_name: c.country_name,
                           approve_by: ad.fullname,
                           loading_fee: a.loading_fee,
                           sector_id: a.sector_id,
                           sector_details: a.sector_details,
                           monthly_transfer: a.monthly_transfer,
                           contact_number: con.contact_number,
                         }
    )

    if !is_nil(info) do
      tag_info = get_last_tag(info.commanall_id)
      Map.merge(info, %{last_tag: tag_info.last_tag, change_by: tag_info.change_by, datetime: tag_info.datetime})
    else
      info
    end
  end

  defp get_last_tag(commanall_id) do
    get_data = Repo.one(
      from t in Tags, right_join: ad in Administratorusers,
                      on: ad.id == t.administratorusers_id,
                      where: t.commanall_id == ^commanall_id,
                      order_by: [
                        desc: t.id
                      ],
                      limit: 1,
                      select: %{
                        last_tag: t.description,
                        change_by: ad.fullname,
                        datetime: t.inserted_at
                      }
    )
    tag = if !is_nil(get_data), do: get_data.last_tag, else: ""
    change_by = if !is_nil(get_data), do: get_data.change_by, else: ""
    datetime = if !is_nil(get_data), do: get_data.datetime, else: ""
    %{last_tag: tag, change_by: change_by, datetime: datetime}
  end

  @doc "company topup info"
  def companyTopup(params) do

    amount = params["amount"]
    status = params["status"]
    transaction_id = params["transaction_id"]
    last_name = params["last_name"]
    first_name = params["first_name"]
    company_name = params["company_name"]

    filtered = params
               |> Map.take(~w(transaction_id status amount  cur_code))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    name = cond  do
      !is_nil(params["last_name"]) and !is_nil(params["first_name"]) -> "#{first_name} #{last_name}"
      !is_nil(params["last_name"]) and is_nil(params["first_name"]) -> "#{last_name}"
      is_nil(params["last_name"]) and !is_nil(params["first_name"]) -> "#{first_name}"
      true -> ""
    end
    (
      from a in Transactions,
           having: ^filtered,
           where: a.company_id == ^params["company_id"] and (
             #             a.transaction_type == "B2A" or a.transaction_type == "A2A")
             is_nil(a.account_id) and a.transaction_mode == "C" and a.category == "AA")
           and like(a.remark, ^"%#{name}%"),
           select: %{
             id: a.id,
             remark: a.remark,
             transaction_id: a.transaction_id,
             category: a.category,
             amount: a.amount,
             transaction_mode: a.transaction_mode,
             transaction_date: a.transaction_date,
             status: a.status,
             server_date: a.server_date
           })
    |> order_by(desc: :id)
    |> Repo.paginate(params)

  end
  @doc"card management top up history"

  def cardManagement_topupHistory(params) do
    filtered = params
               |> Map.take(~w(transaction_id status amount))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    (
      from a in Transactions,
           having: ^filtered,
           where: a.company_id == ^params["company_id"] and (
             a.transaction_type == "B2A" and a.transaction_mode == "C")
      )
    |> Repo.paginate(params)
  end

  @doc"card management company transaction"

  def cardManagement_companyTransactions(params) do
    (from a in Transactions,
          where:
            a.company_id == ^params["company_id"] and
            ((a.transaction_type == "B2A" and a.transaction_mode == "C")
             or (a.transaction_type == "A2C" and a.transaction_mode == "D")
             or (a.transaction_type == "C2A" and a.transaction_mode == "C")
             or (a.transaction_type == "A2O" and a.transaction_mode == "D"))
      )
    |> Repo.paginate(params)
  end

  @doc"card managment user transaction"

  def cardManagement_userTransactions(params) do
    (from a in Transactions,
          where:
            a.company_id == ^params["company_id"] and
            ((a.transaction_type == "A2C" and a.transaction_mode == "C")
             or (a.transaction_type == "C2A" and a.transaction_mode == "D")
             or (a.transaction_type == "C2O" and a.transaction_mode == "D")
             or (a.transaction_type == "C2O" and a.transaction_mode == "D")
             or (a.transaction_type == "C2F" and a.transaction_mode == "D"))
      )
    |> Repo.paginate(params)
  end

  @doc"get all fee transaction of company"

  def feeTransactions_company(params) do

    _online_fee_tx = (
                       from c in Commanall,
                            where: not is_nil(c.accomplish_userid),
                            join: com in Company,
                            on: c.company_id == com.id,
                            join: t in Transactions,
                            on: t.company_id == ^params["company_id"],
                            join: b in Companybankaccount,
                            on: b.id == t.bank_id,
                            where: is_nil(t.account_id) and t.category == "FEE",

                            select: %{
                              commanall_id: c.id,
                              accom_id: c.accomplish_userid,
                              company_name: com.company_name,
                              transaction_id: t.id,
                              final_amount: t.final_amount,
                              #                      curr_code: t.cur_code,
                              status: t.status,
                              transaction_date: t.transaction_date,
                              mode: t.transaction_mode,
                              type: t.transaction_type,
                              remark: t.remark
                            }
                       )
                     |> Repo.paginate(params)
  end

  @doc"get all credit and debit transaction"

  def credit_debit_transactions_company(params) do

    (
      from a in Transactions,
           where: a.company_id == ^params["company_id"] and
                  (
                    (a.category != "FEE" and a.category != "TU" and a.category != "CT")
                    ),
           select: %{
             remark: a.remark,
             transaction_mode: a.transaction_mode,
             transaction_type: a.transaction_type,
             transaction_id: a.transaction_id,
             category: a.category,
             amount: a.amount,
             transaction_mode: a.transaction_mode,
             transaction_date: a.transaction_date,
             status: a.status,
             server_date: a.server_date
           })
    |> Repo.paginate
  end
  @doc"get all company transfer"
  def company_transfers(params) do
    (from a in Transactions,
          where: a.company_id == ^params["company_id"] and
                 (
                   (a.category == "MV" or a.category == "AA" and a.transaction_mode == "D")
                   ),
          select: %{
            remark: a.remark,
            transaction_mode: a.transaction_mode,
            transaction_type: a.transaction_type,
            transaction_id: a.transaction_id,
            category: a.category,
            amount: a.amount,
            transaction_mode: a.transaction_mode,
            transaction_date: a.transaction_date,
            status: a.status,
            server_date: a.server_date
          })
    |> Repo.paginate
  end


  @doc"get all POs Transaction "

  def cardManagement_POS_transactions(params) do
    amount = params["amount"]
    status = params["status"]
    transaction_id = params["transaction_id"]
    (
      from a in Transactions,
           where: a.company_id == ^params["company_id"] and (a.category == "POS") and like(
             a.transaction_id,
             ^"%#{transaction_id}%"
                  )
                  and like(a.amount, ^"%#{amount}%") and like(a.status, ^"%#{status}%"),
           left_join: e in Employee,
           on: a.employee_id == e.id,
           select: %{
             remark: a.remark,
             transaction_mode: a.transaction_mode,
             transaction_type: a.transaction_type,
             transaction_id: a.transaction_id,
             description: a.description,
             category: a.category,
             amount: a.amount,
             transaction_mode: a.transaction_mode,
             transaction_date: a.transaction_date,
             status: a.status,
             server_date: a.server_date,
             first_name: e.first_name,
             last_name: e.last_name,
           }
      )
    |> Repo.paginate
  end

  @doc"get all card menagment Fee Transction"

  def cardManagement_FEE_transactions(params) do
    (
      from a in Transactions,
           where: a.company_id == ^params["company_id"] and
                  (a.category == "FEE")
      )
    |> Repo.paginate
  end

  def internalStatusUpdate(params) do
    _company_id = params["company_id"]
    commanall = Repo.one(
      from a in Commanall, where: a.company_id == ^params["company_id"]
      and not is_nil(a.accomplish_userid),
                           limit: 1,
                           select: a
    )
    if is_nil(commanall) do
      {:not_found, "Record not found!"}
    else
      interstatus = %{
        "internal_status" => params["internal_status"],
      }
      changeset = Commanall.changesetInternalStatus(commanall, interstatus)
      case Repo.update(changeset)do
        {:ok, _changeset} -> {:ok, "Success, Internal Status Updated."}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  def blockCompany(params, admin_id) do
    _company_id = params["company_id"]
    checkdata = Repo.one(
      from a in Commanall, where: a.company_id == ^params["company_id"] and a.status == "A" or a.status == "P"
      and not is_nil(a.accomplish_userid),
                           limit: 1,
                           select: a
    )
    if is_nil(checkdata) do
      {:not_found, "Record not found!"}
    else
      start_date = DateTime.utc_now
      block_date = DateTime.add(start_date, 2629746, :second)
      insert_data = %{
        commanall_id: checkdata.id,
        status_date: start_date,
        block_date: block_date,
        type: "B",
        status: "A",
        reason: params["reason"],
        inserted_by: admin_id
      }
      changeset = Blockusers.changeset(%Blockusers{}, insert_data)
      case Repo.insert(changeset)  do
        {:ok, _data} -> {:ok, "Success, Block user data Inserted"}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end


  def companyComment(params, admin_id) do
    kycdocuments_id = params["kycdocuments_id"]
    status = params["status"]
    comments = params["comments"]
    insert_map = %{
      "comments" => comments,
      "kycdocuments_id" => kycdocuments_id,
      "inserted_by" => admin_id
    }
    changeset = Commankyccomments.changeset(%Commankyccomments{}, insert_map)
    case Repo.insert(changeset)  do
      {:ok, _data} ->
        case status do
          "A" ->
            get = Repo.one(from k in Kycdocuments, where: k.id == ^kycdocuments_id, limit: 1, select: k)
            map = %{"status" => "A"}
            changeset_kyc_doc = Kycdocuments.update_status(get, map)
            Repo.update(changeset_kyc_doc)
          "R" ->
            check = Repo.one(from k in Kycdocuments, where: k.id == ^kycdocuments_id, limit: 1, select: k)
            map = %{"status" => "R"}
            changeset_kyc = Kycdocuments.update_status(check, map)
            Repo.update(changeset_kyc)
        end
        {:ok, "Comment Added"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def updateCardStatus(params)do
    id = params["card_id"]
    get = Repo.one from card in Employeecards, where: card.id == ^id, limit: 1, select: card
    if !is_nil(get) do
      card = %{
        "status" => params["status"],
        "reason" => params["reason"],
        "change_status" => "A",
        "inserted_by" => params["inserted_by"],
      }
      changeset = Employeecards.changesetStatus(get, card)
      if changeset.valid? do
        # Call to accomplish
        request = %{urlid: get.accomplish_card_id, status: params["status"]}
        response = Accomplish.activate_deactive_card(request)
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]
        if response_code == "0000" or response_code == "3055"do
          Repo.update(changeset)
          {:ok, "Success, Status Updated"}
        else
          {:error_message, "#{response_code} #{response_message}"}
        end
      else
        {:error, changeset}
      end
    else
      {:error_message, "Record Not Found.!"}
    end
  end

  def manualTransactions(params) do
    pending_load_params = %{
      "worker_type" => "manual_pending",
      "id" => params["id"],
      "from_date" => params["from_date"],
      "to_date" => params["to_date"],
    }
    success_load_params = %{
      "worker_type" => "manual_success",
      "id" => params["id"],
      "from_date" => params["from_date"],
      "to_date" => params["to_date"],
    }
    Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [pending_load_params], max_retries: 1)
    Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [success_load_params], max_retries: 1)

  end

  def  director_kyc_comments(params, admin_id)do
    kycdirectors_id = params["kycdirectors_id"]
    director_id = params["director_id"]
    status = params["status"]
    comments = params["comments"]
    insert_map = %{
      "comment" => comments,
      "kycdirectors_id" => kycdirectors_id,
      "inserted_by" => admin_id
    }
    changeset = Kyccomments.changeset(%Kyccomments{}, insert_map)
    case Repo.insert(changeset)do
      {:ok, _data} ->
        case status do
          "A" ->
            x = Repo.one(from k in Kycdirectors, where: k.id == ^kycdirectors_id, select: k)
            if x.type == "A" do
              map = %{"status" => "A"}
              changeset_address = Kycdirectors.changeset_addess(x, map)
              Repo.update(changeset_address)
            end
            if x.type == "I" do
              map = %{"status" => "AC"}
              changeset_kyc_doc = Kycdirectors.kycStatusChangeset(x, map)
              Repo.update(changeset_kyc_doc)
            end
          "R" ->
            get = Repo.one(from k in Kycdirectors, where: k.id == ^kycdirectors_id)
            map = %{"status" => "R", "director_id" => director_id}
            changeset_kyc_doc = Kycdirectors.kycStatusChangeset(get, map)
            Repo.update(changeset_kyc_doc)
          _ -> ""
        end
        {:ok, "Success, Comment Added"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def director_comments_list(params) do
    _profile = Repo.all(
      from c in Kyccomments, where: c.kycdirectors_id == ^params["kycdirectors_id"],
                             order_by: [
                               desc: c.id
                             ],
                             join: kycd in Kycdirectors,
                             on: kycd.id == c.kycdirectors_id,
                             join: a in Administratorusers,
                             on: c.inserted_by == a.id,
                             select: %{
                               status: kycd.status,
                               comment: c.comment,
                               unique_id: a.unique_id,
                               role: a.role,
                               inserted_at: c.inserted_at,
                               fullname: a.fullname
                             }
    )
  end

  @doc """
    change company status
  """
  def changeCompanyStatus(params, admin_id) do

    company_commanall_id = params["commanall_id"]
    reason = params["reason"]
    status = params["status"]

    getCompany = Repo.one(from t in Commanall, where: t.id == ^company_commanall_id and not is_nil(t.accomplish_userid))
    if !is_nil(getCompany) do
      company_status = case params["status"] do
        "A" -> "Active"
        "D" -> "Suspend"
        "B" -> "Close"
        "U" -> "Under Review"
      end
      if getCompany.status == status do
        {:already_status, "Company already have #{company_status}"}
      else

        # Store Reason
        tag_map = %{
          commanall_id: company_commanall_id,
          administratorusers_id: admin_id,
          description: reason,
          status: "Company #{company_status}",
          inserted_by: "99999#{admin_id}"
        }
        tags_changeset = Tags.changeset(%Tags{}, tag_map)
        case Repo.insert(tags_changeset) do
          {:ok, _data} ->
            case params["status"] do
              "A" ->
                company_info = %{
                  "admin_id" => admin_id,
                  "commanall_id" => company_commanall_id,
                  "company_id" => getCompany.company_id,
                  "worker_type" => "company_enable"
                }
                Exq.enqueue(
                  Exq,
                  "enable_disable_block",
                  Violacorp.Workers.EnableDisableBlock,
                  [company_info],
                  max_retries: 1
                )
                {:ok, "We are processing to active this company successfully"}
              "D" ->
                company_info = %{
                  "admin_id" => admin_id,
                  "commanall_id" => company_commanall_id,
                  "company_id" => getCompany.company_id,
                  "worker_type" => "company_disable"
                }
                Exq.enqueue(
                  Exq,
                  "enable_disable_block",
                  Violacorp.Workers.EnableDisableBlock,
                  [company_info],
                  max_retries: 1
                )
                {:ok, "We are processing to suspend this company successfully"}
              "B" ->
                company_info = %{
                  "admin_id" => admin_id,
                  "commanall_id" => company_commanall_id,
                  "company_id" => getCompany.company_id,
                  "worker_type" => "company_block"
                }
                Exq.enqueue(
                  Exq,
                  "enable_disable_block",
                  Violacorp.Workers.EnableDisableBlock,
                  [company_info],
                  max_retries: 1
                )
                {:ok, "We are processing to close this company successfully"}
              "U" ->
                changeset = Commanall.updateStatus(getCompany, %{"status" => "U"})
                case Repo.update(changeset) do
                  {:ok, _company} -> {:ok, "Successfully under review this company"}
                  {:error, changeset} -> {:error, changeset}
                end
            end
          {:error, changeset} -> {:error, changeset}
        end
      end
    else
      {:not_found, "company is not active"}
    end
  end

  def activeCompanyCheckList(params) do

    data = (
             from a in Commanall,
                  where: a.company_id == ^params["company_id"],
                  select: %{
                    commanall_id: a.id,
                    company_id: a.company_id
                  })
           |> Repo.one
    case data do
      [] -> {:error, "No Record Found"}
      #%{status_code: "4004", message: "No Record Found"}
      nil -> {:error, "No Record Found"}
      #%{status_code: "4004", message: "No Record Found"}
      data ->

        type1 = Repo.one(from c in Company, where: c.id == ^data.company_id, select: c.company_type)
        type = if type1 == "STR" do
          "SOL"
        else
          "LTD"
        end

        #gets list of document required
        category_id = Repo.one(from category in Documentcategory, where: category.code == ^type, select: category.id)
        documents = Repo.all(
          from docs in Documenttype, where: docs.documentcategory_id == ^category_id,
                                     select: %{
                                       id: docs.id,
                                       title: docs.title
                                     }
        )
        {:ok, documents}
    end
  end


  defp checkThirdpartyResponse(response) do
    if !is_nil(response) do
      check = if String.contains?(response, "http://schemas.xmlsoap.org/soap/envelope"), do: "GBG", else: "FS"
      case check do
        "GBG" -> getGBGStatus(response)
        "FS" -> get_fourstop_info(response)
      end
    else
      ""
    end
  end

  defp getGBGStatus(kyc_response) do
    if !is_nil(kyc_response) do
      gbg_data = Poison.decode!(kyc_response)
      _output = if !is_nil(gbg_data["response"]) do
        response = gbg_data["response"]
        string = response["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
        if !is_nil(string) do
          case string["AuthenticateSPResult"]["BandText"] do
            "Pass" -> "GBG Pass"
            "Refer" -> "GBG Refer"
            "Alert" -> "GBG Alert"
            _ -> "GBG #{string["AuthenticateSPResult"]["BandText"]}"
          end
        else
          "GBG Failed"
        end
      else
        ""
      end
    else
      ""
    end
  end
  def is_map?(map) when is_map(map), do: true
  def is_map?(map) when is_list(map), do: false

  def get_fourstop_info(response) do
    if !is_nil(response) do
      decode_response = Poison.decode!(response)
      case Map.has_key?(decode_response, "response") do
        true ->

          fourstop_data = Poison.decode!(decode_response["response"])
          if is_map?(fourstop_data) === true do
            case Map.has_key?(fourstop_data, "rec") do
              true -> case fourstop_data["rec"] do
                        "Approve" ->
                          "4s Success"
                        "Refer" ->
                          "4s refer"
                        _ ->
                          "4s failed"
                      end
              false ->
                if Map.has_key?(fourstop_data, "reference_id") === true do
                  if fourstop_data["reference_id"] != "0", do: "4s Success", else: "4s failed"
                else
                  "4s failed"
                end
            end
          else
            [fs_data] = fourstop_data
            case Map.has_key?(fs_data, "rec") do
              true -> case fs_data["rec"] do
                        "Approve" ->
                          "4s Success"
                        "Refer" ->
                          "4s refer"
                        _ ->
                          "4s failed"
                      end
              false ->
                if Map.has_key?(fs_data, "reference_id") === true do
                  if fs_data["reference_id"] != "0", do: "4s Success", else: "4s failed"
                else
                  "4s failed"
                end
            end
          end
        false ->
          case decode_response["rec"] do
            "Approve" ->
              "4s Success"
            "Refer" ->
              "4s refer"
            _ ->
              "4s failed"
          end
      end
    else
      ""
    end
  end
end