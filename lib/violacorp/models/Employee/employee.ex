defmodule Violacorp.Models.Employee do
  @moduledoc false
  import Ecto.Query

  alias Violacorp.Repo
  #  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Commankyccomments
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Documenttype
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Employeenotes
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Tags
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Schemas.Countries
  #  alias Violacorp.Schemas.Kyccommnent
  #  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Kycdocument
  #  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish


  defp checkValidation(params) do
    cond do
      (params["status"] == "" and params["comments"] == "") ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              status: ["can't be blank"],
              comments: ["can't be blank"]
            }
          }
        }
      #      (params["director_id"]) == ""-> {:error_message, %{status_code: "4003", errors: %{director_id: ["can't be blank"]}}}
      (params["status"]) == "" ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              status: ["can't be blank"]
            }
          }
        }
      (params["comments"]) == "" ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              comments: ["can't be blank"]
            }
          }
        }
      true ->
        {:ok, "done"}
    end
  end


  @doc""

  def permanantlyDeletePendingUser(params)do

    employee_id = params["employee_id"]
    commanall = Repo.get_by(Commanall, employee_id: employee_id)
    if !is_nil(commanall)do
      employee = Repo.get_by(Employee, id: employee_id)
      kycdocs = Repo.all(from a in Kycdocuments, where: a.commanall_id == ^commanall.id)
      address = Repo.get_by(Address, commanall_id: commanall.id)
      contact = Repo.get_by(Contacts, commanall_id: commanall.id)
      notifications = Repo.all(from c in Notifications, where: c.commanall_id == ^commanall.id)

      if employee.status !== "A" and is_nil(commanall.accomplish_userid) do

        if !is_nil(contact)do
          Repo.delete(contact)
        end

        if notifications !== [] do
          Enum.each notifications, fn x ->
            Repo.delete(x)
          end
        end

        if !is_nil(address)do
          Repo.delete(address)
        end

        if kycdocs !== [] do

          Enum.each kycdocs, fn x ->
            Repo.delete(x)
          end
        end

        if !is_nil(commanall)do
          Repo.delete(commanall)
        end

        if !is_nil(employee)do
          Repo.delete(employee)
        end

        {:ok, "Employee Permanently Deleted"}
      else
        {:error, "Active employee cannot be permanently deleted"}
      end
    else
      {:error, "Employee not found"}
    end
  end

  @doc " get_user_4stop_view from kyc document table"
  def get_user_4stop_view(params)do
    id = params["id"]
    (
      from a in Kycdocuments,
           where: a.id == ^id,
           select: %{
             inserted_date: a.inserted_at,
             reference_id: a.reference_id,
             status: a.status,
             response: a.fourstop_response
           })
    |> Repo.one
  end
  @doc " Get All Active User Of Company From  employee table"
  def getAllActiveEmployee(params)do

    filter = params
             |> Map.take(~w(username email_id))
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    status = params
             |> Map.take(~w(status))
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    first_name = params["first_name"]
    last_name = params["last_name"]
    _contact_number = params["contact_number"]
    gender = params["gender"]
    _active_user = (
                     from c in Commanall,
                          where: not is_nil(c.accomplish_userid) and c.status == "A" and c.internal_status == "A",
                          having: ^filter,
                          left_join: e in assoc(c, :employee),
                          on: (^status),
                          where: e.status == "A" and like(e.first_name, ^"%#{first_name}%") and like(
                            e.last_name,
                            ^"%#{last_name}%"
                                 ) and like(e.gender, ^"%#{gender}%"),
                          right_join: com in Company,
                          on: com.id == e.company_id,
                          order_by: [
                            asc: e.first_name
                          ],
                          select: %{
                            commanall_id: c.id,
                            username: c.username,
                            employee_id: e.id,
                            title: e.title,
                            first_name: e.first_name,
                            last_name: e.last_name,
                            position: e.position,
                            trust_level: c.trust_level,
                            date_of_birth: e.date_of_birth,
                            status: e.status,
                            company_id: e.company_id,
                            company_name: com.company_name,
                            last_tag: fragment(
                              "(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name",
                              c.id
                            ),
                            email_id: c.email_id,
                            gender: e.gender
                          })
                   |> Repo.paginate(params)
  end

  def getAllPendingEmployee(params)do

    filter = params
             |> Map.take(~w(username email_id))
             |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    status = params["status"]
    first_name = params["first_name"]
    last_name = params["last_name"]
    _contact_number = params["contact_number"]
    gender = params["gender"]
    (
      from c in Commanall,
           where: not is_nil(c.employee_id),
           having: ^filter,
           right_join: e in assoc(c, :employee),
           on: e.id == c.employee_id,
           where: e.status not in ["A", "D", "B"] and like(e.status, ^"%#{status}%") and like(
             e.first_name,
             ^"%#{first_name}%"
                  ) and like(e.last_name, ^"%#{last_name}%") and like(e.gender, ^"%#{gender}%"),
           right_join: com in Company,
           on: com.id == e.company_id,
           order_by: [
             desc: c.id
           ],
           select: %{
             commanall_id: c.id,
             username: c.username,
             employee_id: e.id,
             title: e.title,
             first_name: e.first_name,
             last_name: e.last_name,
             position: e.position,
             trust_level: c.trust_level,
             date_of_birth: e.date_of_birth,
             status: e.status,
             company_id: e.company_id,
             company_name: com.company_name,
             email_id: c.email_id,
             gender: e.gender
           })
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  @doc "Get All Archived User From employee table"
  def archived_employee(params)do
    filtered = params
               |> Map.take(~w(username email_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    first_name = params["first_name"]
    last_name = params["last_name"]
    gender = params["gender"]
    (from c in Commanall,
          having: ^filtered,
          where: c.status == "D",
          join: e in assoc(c, :employee),
          where: like(e.first_name, ^"%#{first_name}%") and like(e.last_name, ^"%#{last_name}%") and like(
            e.gender,
            ^"%#{gender}%"
                 ),
          right_join: com in Company,
          on: com.id == e.company_id,
          order_by: [
            asc: e.first_name
          ],
          select: %{
            commanall_id: c.id,
            username: c.username,
            title: e.title,
            first_name: e.first_name,
            last_name: e.last_name,
            email_id: c.email_id,
            position: e.position,
            trust_level: c.trust_level,
            date_of_birth: e.date_of_birth,
            company_id: e.company_id,
            status: e.status,
            gender: e.gender,
            comapny_name: com.company_name,
            last_tag:
              fragment("(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name", c.id),
            employee_id: e.id
          })
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  @doc "Get ALl Deleted User From employee Table"
  def deleted_User(params)do
    filtered = params
               |> Map.take(~w(username email_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    first_name = params["first_name"]
    last_name = params["last_name"]
    gender = params["gender"]
    status = params["status"]
    (from c in Commanall,
          where: c.status == "B",
          having: ^filtered,
          join: e in assoc(c, :employee),
          where: like(e.first_name, ^"%#{first_name}%") and like(e.last_name, ^"%#{last_name}%") and like(
            e.gender,
            ^"%#{gender}%"
                 ) and like(e.status, ^"%#{status}%"),
          right_join: com in Company,
          on: com.id == e.company_id,
          order_by: [
            asc: e.first_name
          ],
          select: %{
            commanall_id: c.id,
            username: c.username,
            employee_id: e.id,
            company_id: e.company_id,
            title: e.title,
            first_name: e.first_name,
            last_name: e.last_name,
            email_id: c.email_id,
            date_of_birth: e.date_of_birth,
            position: e.position,
            trust_level: c.trust_level,
            last_tag:
              fragment("(SELECT description FROM tags WHERE commanall_id = ? ORDER BY id DESC LIMIT 1) AS name", c.id),
            comapny_name: com.company_name,
            status: e.status
          })
    |> Repo.paginate(params)
  end


  @doc "Get All Administrator  from employee table"
  def get_administrator(params)do

    filtered = params
               |> Map.take(~w(unique_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    _administrator = (from a in Administratorusers,
                           where: ^filtered,
                           select: %{
                             id: a.id,
                             fullname: a.fullname,
                             email_id: a.email_id,
                             contact_number: a.contact_number,
                             is_primary: a.is_primary,
                             unique_id: a.unique_id,
                             role: a.role,
                             status: a.status,
                             inserted_at: a.inserted_at
                           })

                     |> Repo.paginate(params)
  end

  @doc "active user profile info by employee_id "
  def active_user_view(params) do
    profile = Repo.one(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      left_join: contact in assoc(c, :contacts),
      where: contact.is_primary == "Y",
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: com in Company,
      on: com.id == e.company_id,
      select: %{
        id: e.id,
        company_id: e.company_id,
        commanall_id: c.id,
        username: c.username,
        email_verified: c.email_verified,
        mobile_verified: c.mobile_verified,
        first_name: e.first_name,
        contact_number: contact.contact_number,
        last_name: e.last_name,
        date_of_birth: e.date_of_birth,
        email_id: c.email_id,
        viola_id: c.viola_id,
        status: e.status,
        internal_status: c.internal_status,
        gender: e.gender,
        accomplish_userid: c.accomplish_userid,
        inserted_at: c.inserted_at
      }
    )
    if !is_nil(profile) do
      tags_info = get_last_tag(profile.commanall_id)
      steps = %{
        thirdpartysteps: thirdpartylogs(profile.commanall_id),
        datetime: tags_info.datetime,
        change_by: tags_info.change_by,
        last_tag: tags_info.last_tag,
        is_authorized: checkEmployeeApprovalAuthorize(profile.commanall_id)
      }
      Map.merge(steps, profile)
    else
      profile
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

  def pending_user_profile(params) do
    profile = Repo.one(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      left_join: contact in assoc(c, :contacts),
      where: contact.is_primary == "Y",
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: com in Company,
      on: com.id == e.company_id,
      select: %{
        id: e.id,
        company_id: e.company_id,
        commanall_id: c.id,
        username: c.username,
        first_name: e.first_name,
        contact_number: contact.contact_number,
        last_name: e.last_name,
        date_of_birth: e.date_of_birth,
        email_id: c.email_id,
        viola_id: c.viola_id,
        status: e.status,
        internal_status: c.internal_status,
        gender: e.gender,
        inserted_at: c.inserted_at
      }
    )
    if !is_nil(profile) do
      steps = %{
        thirdpartysteps: thirdpartylogs(profile.commanall_id),
        is_authorized: checkEmployeeApprovalAuthorize(profile.commanall_id)
      }
      Map.merge(steps, profile)
    else
      profile
    end
  end


  @doc "Active user  card Detail "
  def active_user_card(params) do
    get_card = Repo.all(
      from e in Employeecards, order_by: [
        asc: e.id
      ],
                               where: e.employee_id == ^params["employee_id"],
        #             join: emp in assoc(e, :employee),
        #             left_join: department in assoc(emp, :departments),
        #             left_join: commanall in assoc(emp, :commanall),
                               select: %{
                                 card_id: e.id,
                                 #                       user_status: emp.status,
                                 accomplish_card_id: e.accomplish_card_id,
                                 employee_id: e.employee_id,
                                 #                       first_name: emp.first_name,
                                 #                       last_name: emp.last_name,
                                 current_balance: e.current_balance,
                                 currency_code: e.currency_code,
                                 card_number: e.last_digit,
                                 card_type: e.card_type,
                                 expiry_date: e.expiry_date,
                                 available_balance: e.available_balance,
                                 activation_code: e.activation_code,
                                 #                       department_name: department.department_name,
                                 status: e.status,
                                 #                       date_of_birth: emp.date_of_birth,
                                 #                       email_id: commanall.email_id,
                                 #                       gender: emp.gender,
                                 #                       viola_id: commanall.viola_id,
                                 #                       registration_date: commanall.inserted_at

                               }
    )
    %{card: get_card}

  end

  @doc "active user  kyc "
  def active_user_kyc(params)do

    active_address = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: k in Kycdocuments,
      on: k.commanall_id == c.id,
      where: k.type == "A",
      right_join: d in Documenttype,
      on: d.id == k.documenttype_id,
      order_by: [
        desc: k.inserted_at
      ],
      select: %{
        id: k.id,
        document_number: k.document_number,
        file_location: k.file_location,
        issue_date: k.issue_date,
        expiry_date: k.expiry_date,
        inserted_at: k.inserted_at,
        file_type: k.file_type,
        status: k.status,
        type: k.type,
        title: d.title
      }
    )

    active_idproof = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      left_join: con in assoc(c, :contacts),
      left_join: ad in assoc(c, :address),
      left_join: co in Countries,
      on: co.id == ad.countries_id,
      right_join: k in Kycdocuments,
      on: k.commanall_id == c.id,
      where: k.type == "I",
      right_join: d in Documenttype,
      on: d.id == k.documenttype_id,
      order_by: [
        desc: k.inserted_at
      ],
      select: %{
        id: k.id,
        commanall_id: c.id,
        date_of_birth: e.date_of_birth,
        contact_number: con.contact_number,
        address_line_one: ad.address_line_one,
        document_number: k.document_number,
        issue_date: k.issue_date,
        expiry_date: k.expiry_date,
        inserted_at: k.inserted_at,
        file_type: k.file_type,
        file_location: k.file_location,
        file_location_two: k.file_location_two,
        status: k.status,
        type: k.type,
        fourstop_response: k.fourstop_response,
        reference_id: k.reference_id,
        reason: k.reason,
        refered_id: k.refered_id,
        verify_kyc: e.verify_kyc,
        country_name: co.country_name,
        title: d.title
      }
    )

    key = Enum.map(
      active_idproof,
      fn (q) ->

        refered_by = if !is_nil(q.refered_id) do
          reference_id = q.refered_id
          (from a in Administratorusers, where: a.id == ^reference_id, select: a.fullname)
          |> Repo.one
        else
          nil
        end
        #                          gbg_status = if q.verify_kyc == "gbg", do: getGBGStatus(q.fourstop_response), else: get_fourstop_info(q.commanall_id)
        gbg_status = checkThirdpartyResponse(q.fourstop_response)
        new_key = if !is_nil(q.date_of_birth) and !is_nil(q.contact_number) and !is_nil(q.document_number) and !is_nil(
          q.address_line_one
        ) and !is_nil(q.issue_date) and !is_nil(q.expiry_date) do
          %{call_gbg: "YES", refered_by: refered_by, gbg_status: gbg_status}
        else
          %{call_gbg: "NO", refered_by: refered_by, gbg_status: gbg_status}
        end
        Map.merge(q, new_key)
      end
    )
    %{address_proof: active_address, id_proof: key}
  end

  @doc "get active user address"
  def active_user_address(params)do

    _active_user_add = Repo.all(
      from c in Commanall, where: c.employee_id == ^params["employee_id"],
                           right_join: add in Address,
                           on: add.commanall_id == c.id,
                           left_join: co in Countries,
                           on: co.id == add.countries_id,
                           select: %{
                             address_line_one: add.address_line_one,
                             address_line_two: add.address_line_two,
                             city: add.city,
                             town: add.town,
                             county: add.county,
                             country_name: co.country_name,
                             post_code: add.post_code,
                             is_primary: add.is_primary
                           }
    )
  end


  @doc "get active user contact"
  def  active_user_contact(params)do

    _contact = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: con in Contacts,
      on: con.commanall_id == c.id,

      select: %{
        first_name: e.first_name,
        last_name: e.last_name,
        contact_number: con.contact_number
      }
    )
  end

  @doc "get active user notes/comments"
  def  active_user_notes(params)do

    _notes = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: n in Employeenotes,
      on: n.commanall_id == c.id,
      right_join: d in Directors,
      on: d.id == e.director_id,

      select: %{
        notes: n.notes,
        inserted_at: n.inserted_at,
        first_name: d.first_name,
        last_name: d.last_name

      }
    )
  end

  @doc "get active user notes/comments 2"
  def  get_active_user_previous_notes(params)do

    _notes = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"],
      join: n in Employeenotes,
      on: n.commanall_id == c.id,
      left_join: a in Administratorusers,
      on: n.inserted_by == a.id,
      order_by: [
        desc: n.id
      ],
      select: %{
        id: n.id,
        notes: n.notes,
        inserted_at: n.inserted_at,
        submitted_by: a.fullname
      }
    )
  end

  #  def insertUserKycCommnents(params, admin_id)do
  #    kycdocuments_id = params["kycdocuments_id"]
  #    director_id = params["director_id"]
  #    status = params["status"]
  #    comments = params["comments"]
  #
  #    insert_map = %{
  #      "comments" => comments,
  #      "kycdocuments_id" => kycdocuments_id,
  #      "inserted_by" => admin_id
  #    }
  #    changeset = Kyc(%Kyccommnent{}, insert_map)
  #    case Repo.insert(changeset)do
  #      {:ok, _data} ->
  #        if status == "A"  do
  #          get = Repo.one(from k in Kycdocuments, where: k.id == ^kycdocuments_id)
  #          map = %{"status" => "A", "director_id" => director_id}
  #          changeset_kyc_doc = Kycdocuments.changeset(get, map)
  #          Repo.update(changeset_kyc_doc)
  #        else
  #          get = Repo.one(from k in Kycdocuments, where: k.id == ^kycdocuments_id)
  #          map = %{"status" => "R", "director_id" => director_id}
  #          changeset_kyc_doc = Kycdocuments.changeset(get, map)
  #          Repo.update(changeset_kyc_doc)
  #        end
  #        {:ok, "Success, Comment Added"}
  #      {:error, changeset} -> {:error, changeset}
  #    end
  #
  #  end
  @doc "insert_active_user_kyc_proof_comment"
  def  insert_active_user_kyc_proof_comment(params, admin_id) do

    case checkValidation(params) do
      {:ok, _add} ->

        kycdocuments_id = params["kycdocuments_id"]
        _director_id = params["director_id"]
        status = params["status"]
        comments = params["comments"]
        insert_map = %{
          "comments" => comments,
          "kycdocuments_id" => kycdocuments_id,
          "inserted_by" => admin_id
        }
        kyc = Repo.get_by(Kycdocuments, id: kycdocuments_id)
        if !is_nil(kyc) do
          changeset = Commankyccomments.changeset(%Commankyccomments{}, insert_map)
          case Repo.insert(changeset)do
            {:ok, _data} ->
              map = case status do
                "A" ->
                  status = case kyc.type do
                    "I" -> "AC"
                    "A" -> "A"
                  end
                  #                                    %{"status" => status, "director_id" => director_id}
                  %{"status" => status}
                "R" ->
                  #                                      %{"status" => "R", "director_id" => director_id}
                  %{"status" => "R"}
                _ -> :error
              end
              case map do
                :error -> {:status_error, "Invalid Status, Value Must be 'A' or 'R'"}
                _ -> changeset_kyc_doc = Kycdocuments.update_status(kyc, map)
                     Repo.update(changeset_kyc_doc)
                     {:ok, "Success, Comment Added"}
              end
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:document_error, "Kyc Document does not exist"}
        end
      {:error_message, message} -> {:validation_error, message}
    end
  end

  @doc "insert_active_user_new_notes"
  def  insert_active_user_new_notes(params, admin_id)do
    notes = params["notes"]
    commanall_id = params["commanall_id"]
    insert = %{
      commanall_id: commanall_id,
      notes: notes,
      inserted_by: admin_id
    }
    changeset = Employeenotes.changeset(%Employeenotes{}, insert)
    case Repo.insert(changeset) do
      {:ok, _changeset} -> {:ok, "Record Inserted"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "archive user  profile  "
  def archive_user_profile(params)do
    _profile = Repo.all(
      from c in Commanall, where: c.status == "D",
                           join: e in assoc(c, :employee),
                           where: c.employee_id == ^params["employee_id"],
                           join: con in assoc(c, :contacts),
                           right_join: k in Kycdocuments,
                           on: k.commanall_id == c.id,
                           where: k.type == "A" or k.type == "I",
                           right_join: d in Documenttype,
                           on: d.id == k.documenttype_id,
                           right_join: add in Address,
                           on: add.commanall_id == c.id,

                           select: %{
                             contact_number: con.contact_number,
                             email_id: c.email_id,
                             date_of_birth: e.date_of_birth,
                             viola_id: c.viola_id,
                             registration_date: c.inserted_at,
                             gender: e.gender,
                             type: k.type,
                             title: d.title,
                             issue_date: k.issue_date,
                             expiry_date: k.expiry_date,
                             inserted_at: k.inserted_at,
                             e_status: e.status,
                             comm_status: c.status,
                             kyc_status: k.status,
                             address_line_one: add.address_line_one,
                             address_line_two: add.address_line_two,
                             county: add.county,


                           }
    )
  end

  @doc "archive user  profile view  "
  def archive_user_profile_view(params)do

    _profile = Repo.one(
      from c in Commanall, where: c.status == "D",
                           left_join: e in assoc(c, :employee),
                           left_join: con in assoc(c, :contacts),
                           where: con.is_primary == "Y",
                           where: c.employee_id == ^params["employee_id"],
                           select: %{
                             title: e.title,
                             first_name: e.first_name,
                             last_name: e.last_name,
                             gender: e.gender,
                             email_id: c.email_id,
                             viola_id: c.viola_id,
                             status: e.status,
                             commanall_status: c.status,
                             date_of_birth: e.date_of_birth,
                             inserted_at: c.inserted_at,
                             accomplish_userid: c.accomplish_userid,
                             contact_number: con.contact_number
                           }
    )
  end

  @doc "deleted user profile view"
  def deleted__user_profile(params)do
    _user = Repo.one(
      from c in Commanall, where: c.status == "B",
                           join: e in assoc(c, :employee),
                           on: c.employee_id == ^params["employee_id"],
                           join: con in assoc(c, :contacts),
                           right_join: com in Company,
                           on: com.id == e.company_id,
                           select: %{
                             first_name: e.first_name,
                             last_name: e.last_name,
                             contact_number: con.contact_number,
                             email_id: c.email_id,
                             date_of_birth: e.date_of_birth,
                             viola_id: c.viola_id,
                             status: e.status,
                             gender: e.gender,
                             inserted_at: c.inserted_at,
                             accomplish_userid: c.accomplish_userid,
                           }
    )
    #        _map = %{employee_name: "#{user.first_name} #{user.last_name}", viola_id: user.viola_id,contact_number: user.contact_number, email_id: user.email_id,date_of_birth: user.date_of_birth, inserted_at: user.inserted_at , status: user.status, gender: user.gender  }

  end

  @doc "deleted user cards"
  def deleted_user_cards(params)do

    _get_card = Repo.all(
      from e in Employeecards,
      where: e.employee_id == ^params["employee_id"],
      join: emp in assoc(e, :employee),
      left_join: department in assoc(emp, :departments),
      left_join: commanall in assoc(emp, :commanall),
      on: commanall.status == "B",
      select: %{
        first_name: emp.first_name,
        last_name: emp.last_name,
        current_balance: e.current_balance,
        currency_code: e.currency_code,
        card_number: e.last_digit,
        card_type: e.card_type,
        expiry_date: e.expiry_date,
        available_balance: e.available_balance,
        activation_code: e.activation_code,
        department_name: department.department_name,
        status: e.status,
        date_of_birth: emp.date_of_birth,
        email_id: commanall.email_id,
        gender: emp.gender,
        viola_id: commanall.viola_id,
        registration_date: commanall.inserted_at
      }
    )
  end

  @doc "deleted user kyc"
  def deleted_user_kyc(params)do
    _deleted_user_kyc = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"] and c.status == "B",
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: k in Kycdocuments,
      on: k.commanall_id == c.id,
      where: k.type == "A" or k.type == "I",
      right_join: d in Documenttype,
      on: d.id == k.documenttype_id,
      select: %{
        first_name: e.first_name,
        last_name: e.last_name,
        date_of_birth: e.date_of_birth,
        email_id: c.email_id,
        document_number: k.document_number,
        issue_date: k.issue_date,
        expiry_date: k.expiry_date,
        inserted_at: k.inserted_at,
        file_type: k.file_type,
        status: k.status,
        type: k.type,
        title: d.title
      }
    )
  end

  @doc "deleted user address"
  def deleted_user_address(params)do
    _active_user_add = Repo.one(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"] and c.status == "B",
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: add in Address,
      on: add.commanall_id == c.id,
      select: %{
        first_name: e.first_name,
        last_name: e.last_name,
        address_line_one: add.address_line_one,
        address_line_two: add.address_line_two,
        city: add.city,
        town: add.town,
        county: add.county,
        post_code: add.post_code
      }
    )
  end

  @doc "deleted user contact detail"
  def deleted_user_contacts(params)do
    _contact = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"] and c.status == "B",
      join: e in assoc(c, :employee),
      on: e.id == c.employee_id,
      right_join: con in Contacts,
      on: con.commanall_id == c.id,

      select: %{
        first_name: e.first_name,
        last_name: e.last_name,
        contact_number: con.contact_number
      }
    )
  end

  @doc "get active user notes/comments"
  def  deleted_user_notes(params)do

    _notes = Repo.all(
      from c in Commanall,
      where: c.employee_id == ^params["employee_id"] and c.status == "B",
      join: e in assoc(c, :employee),
      right_join: n in Employeenotes,
      on: n.commanall_id == c.id,
      right_join: d in Directors,
      on: d.id == e.director_id,
      select: %{
        notes: n.notes,
        inserted_at: n.inserted_at,
        person_submmited: e.first_name
      }
    )
  end

  def pullCards(params, admin_id) do
    employee_id = params["employee_id"]

    # create array data for send to accomplish
    employee_info = Repo.one from com in Commanall,
                             where: com.employee_id == ^employee_id and com.status == "A" and not is_nil(
                               com.accomplish_userid
                             ),
                             left_join: emp in assoc(com, :employee),
                             select: %{
                               accomplish_userid: com.accomplish_userid,
                               first_name: emp.first_name,
                               last_name: emp.last_name,
                             }
    case employee_info do
      nil -> {:not_found, "User is incorrect."}
      response_data ->
        response = Accomplish.get_user(response_data.accomplish_userid)
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]
        if response_code == "0000" do
          if !is_nil(response["account"]) do
            Enum.each response["account"], fn responseCard ->
              accomplish_card_id = responseCard["info"]["id"]
              account_type = responseCard["info"]["type"]
              if account_type == "0" do
                cards = Repo.one(
                  from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id, select: e
                )
                employee = Repo.one(from em in Employee, where: em.id == ^employee_id, select: em)

                status = responseCard["info"]["status"]
                if is_nil(cards) do

                  card_type = if status == "12", do: "P", else: "V"

                  check_card = Repo.one(
                    from ca in Employeecards, where: ca.employee_id == ^employee_id, select: count(ca.id)
                  )
                  _is_primary = if check_card > 0, do: "N", else: "Y"
                  _fullname = "#{employee_info.first_name} #{employee_info.last_name}"
                  currencies_id = Repo.one from c in Currencies,
                                           where: c.currency_code == ^responseCard["info"]["currency"], select: c.id

                  card_number = responseCard["info"]["number"]
                  last_digit = Commontools.lastfour(card_number)
                  employeecard = %{
                    "employee_id" => employee_id,
                    "currencies_id" => currencies_id,
                    "currency_code" => responseCard["info"]["currency"],
                    "last_digit" => "#{last_digit}",
                    "available_balance" => responseCard["info"]["available_balance"],
                    "current_balance" => responseCard["info"]["balance"],
                    "accomplish_card_id" => responseCard["info"]["id"],
                    "bin_id" => responseCard["info"]["bin_id"],
                    "expiry_date" => responseCard["info"]["security"]["expiry_date"],
                    "source_id" => responseCard["info"]["original_source_id"],
                    "activation_code" => responseCard["info"]["security"]["activation_code"],
                    "status" => responseCard["info"]["status"],
                    "card_type" => card_type,
                    "inserted_by" => "99999#{admin_id}"
                  }
                  changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
                  Repo.insert(changeset_comacc)

                  count_card = Repo.one from d in Employeecards,
                                        where: d.employee_id == ^employee_id and (
                                          d.status == "1" or d.status == "4" or d.status == "12"),
                                        select: count(d.id)
                  new_number = %{"no_of_cards" => count_card}
                  cards_changeset = Employee.updateEmployeeCardschangeset(employee, new_number)
                  Repo.update(cards_changeset)
                else
                  if cards.status != status do
                    new_status = case status do
                      "1" -> "1"
                      "4" -> "4"
                      "6" -> "5"
                      "12" -> "12"
                      _ -> status
                    end
                    card_status = %{"status" => new_status}
                    changeset_party = Employeecards.changesetCardStatus(cards, card_status)
                    Repo.update(changeset_party)
                  end
                end
              end
            end
          end
          {:ok, response_message}
        else
          {:thirdparty_errors, response_message}
        end
    end
  end

  @doc"view employee kyc document"
  def employeeKycDocument(params) do

    getKyc = Repo.all(
      from c in Commanall, where: c.employee_id == ^params["employee_id"],
                           join: k in Kycdocuments,
                           on: c.id == k.commanall_id,
                           left_join: adm in Administratorusers,
                           on: adm.id == k.refered_id,
                           left_join: d in Documenttype,
                           on: d.id == k.documenttype_id,
                           join: e in Employee,
                           on: e.id == ^params["employee_id"],
                           order_by: [
                             desc: k.id
                           ],
                           select: %{
                             documenttype: d.title,
                             employee_id: c.employee_id,
                             id: k.id,
                             document_number: k.document_number,
                             expiry_date: k.expiry_date,
                             issue_date: k.issue_date,
                             document_category: k.type,
                             file_location: k.file_location,
                             file_location_two: k.file_location_two,
                             status: k.status,
                             refered_by: adm.fullname,
                             reason: k.reason,
                             verify_kyc: e.verify_kyc,
                             inserted_at: k.inserted_at,
                           }
    )
    if getKyc != nil do
      _response = Enum.map(
        getKyc,
        fn x ->
          data = if !is_nil(x.file_location) or !is_nil(x.file_location_two) do
            file_one = x.file_location

            image_one = if !is_nil(file_one), do: file_one, else: ""
            image_second = if !is_nil(x.file_location_two), do: (x.file_location_two), else: ""
            %{image_one: image_one, image_second: image_second}

          else
            %{image_one: "", image_second: ""}
          end
          %{
            documenttype: x.documenttype,
            id: x.id,
            document_number: x.document_number,
            expiry_date: x.expiry_date,
            issue_date: x.issue_date,
            employee_id: x.employee_id,
            document_category: x.document_category,
            status: x.status,
            inserted_at: x.inserted_at,
            image_one: data.image_one,
            image_second: data.image_second,
            file_location: x.file_location,
            verify_kyc: x.verify_kyc,
            reason: x.reason,
            refered_by: x.refered_by
          }
        end
      )
    end
  end

  @doc"update employee address"
  def employeeUpdateAddress(params) do

    get_address = Repo.one(from c in Commanall, where: c.employee_id == ^params["employee_id"], select: c.id)

    data = Repo.get_by(Address, commanall_id: get_address)

    address = %{
      "address_line_one" => params["address_line_one"],
      "address_line_two" => params["address_line_two"],
      "address_line_three" => params["address_line_three"],
      "countries_id" => params["locationId"],
      "post_code" => params["post_code"],
      "town" => params["town"],
      "county" => params["county"]
    }
    changeset_address = Address.changeset(data, address)
    case Repo.update(changeset_address) do
      {:ok, _add} -> {:ok, "Address Updated"}
      {:error, changeset} -> {:error, changeset}
    end

  end
  def checkDocumentUpload(params) do
    document_id = params["document_id"]

    get_document = Repo.get_by(Kycdocument, id: document_id, status: "A")
    if !is_nil(get_document) do
      user_info = Repo.one(
        from com in Commanall, where: com.id == ^get_document.commanall_id and not is_nil(com.accomplish_userid)
      )
      if !is_nil(user_info) do
        user_id = user_info.accomplish_userid

        response = Accomplish.get_document(user_id)
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]
        if response_code === "0000" do
          document_data = documentInfo(get_document)
          check = Enum.filter(
            response["documents"],
            fn x ->
              x["info"]["entity"] == document_data["entity"] and x["info"]["type"] == document_data["type"] and x["info"]["subject"] == document_data["file_name"]
            end
          )
          count_val = Enum.count(check)
          message = if count_val > 0,
                       do: "This document exist on accomplish.", else: "This document does not have on accomplish."
          check_doc = if count_val > 0, do: "Y", else: "N"
          {:ok, message, check_doc}
        else
          {:not_found, response_message}
        end
      else
        {:not_found, "user not valid."}
      end
    else
      {:not_found, "document not found."}
    end
  end
  defp documentInfo(document) do
    db_entity = case document.document_type do
      "IP" -> 25
      "AP" -> 15
    end

    db_type = case document.documenttype_id do
      1 -> 5
      2 -> 10
      21 -> 4
      19 -> 4
      10 -> 2
      9 -> 3
      4 -> 7
      _ -> if (document.document_type == "IP"), do: 3, else: 5
    end
    db_file_name = case document.documenttype_id do
      1 -> "Utility Bill"
      2 -> "Council Tax"
      21 -> "Driving Licence"
      19 -> "Driving Licence"
      10 -> "Passport"
      9 -> "National ID"
      4 -> "Bank Statement"
      _ -> if (document.document_type == "IP"), do: "National ID", else: "Utility Bill"
    end
    %{"entity" => db_entity, "type" => db_type, "file_name" => db_file_name}
  end

  @doc"Delete user"
  def deleteuser(params) do

    data = Repo.get_by(Commanall, employee_id: params["employee_id"], status: "D")

    if !is_nil(data) do

      status = %{status: "B"}
      changeset = Commanall.updateStatus(data, status)
      Repo.update(changeset)
      {:ok, "User Deleted"}
    else
      {:not_found, "Record not found!"}
    end
  end

  def comment_director_list(params)do
    _notes = Repo.all(
      from d in Directors, where: d.company_id == ^params["company_id"],
                           select: %{
                             title: d.title,
                             id: d.id,
                             first_name: d.first_name,
                             last_name: d.last_name
                           }
    )
  end


  def user_comments_list(params) do
    _profile = Repo.all(
      from c in Commankyccomments, order_by: [
        desc: c.id
      ],
                                   where: c.kycdocuments_id == ^params["kycdocuments_id"],
                                   left_join: k in assoc(c, :kycdocuments),
                                   join: a in Administratorusers,
                                   on: c.inserted_by == a.id,
                                   select: %{
                                     comment: c.comments,
                                     status: k.status,
                                     inserted_at: c.inserted_at,
                                     fullname: a.fullname,
                                     role: a.role,
                                     unique_id: a.unique_id,
                                   }
    )
  end

  @doc """
     update for employee status
  """
  def changeEmployeeStatus(params, admin_id) do

    case checkEmployeeStatusValidation(params) do
      {:ok, _message} ->
        employee_commanall_id = params["commanall_id"]
        reason = params["reason"]
        status = params["status"]

        getEmployee = Repo.one(
          from t in Commanall,
          where: t.id == ^employee_commanall_id and is_nil(t.company_id) and not is_nil(t.accomplish_userid)
        )
        if !is_nil(getEmployee) do
          employee_status = case params["status"] do
            "A" -> "Active"
            "D" -> "Suspend"
            "B" -> "Close"
          end
          if getEmployee.status == status do
            {:already_status, "Employee already have #{employee_status}"}
          else

            # Store Reason
            tag_map = %{
              commanall_id: employee_commanall_id,
              administratorusers_id: admin_id,
              description: reason,
              status: "Employee #{employee_status}",
              inserted_by: "99999#{admin_id}"
            }
            tags_changeset = Tags.changeset(%Tags{}, tag_map)
            case Repo.insert(tags_changeset) do
              {:ok, _data} ->
                case params["status"] do
                  "A" ->
                    employee_info = %{
                      "admin_id" => admin_id,
                      "commanall_id" => employee_commanall_id,
                      "employee_id" => getEmployee.employee_id,
                      "worker_type" => "employee_enable"
                    }
                    Exq.enqueue(
                      Exq,
                      "enable_disable_block",
                      Violacorp.Workers.EnableDisableBlock,
                      [employee_info],
                      max_retries: 1
                    )
                  "D" ->
                    employee_info = %{
                      "admin_id" => admin_id,
                      "commanall_id" => employee_commanall_id,
                      "employee_id" => getEmployee.employee_id,
                      "worker_type" => "employee_disable"
                    }
                    Exq.enqueue(
                      Exq,
                      "enable_disable_block",
                      Violacorp.Workers.EnableDisableBlock,
                      [employee_info],
                      max_retries: 1
                    )
                  "B" ->
                    employee_info = %{
                      "admin_id" => admin_id,
                      "commanall_id" => employee_commanall_id,
                      "employee_id" => getEmployee.employee_id,
                      "worker_type" => "employee_block"
                    }
                    Exq.enqueue(
                      Exq,
                      "enable_disable_block",
                      Violacorp.Workers.EnableDisableBlock,
                      [employee_info],
                      max_retries: 1
                    )
                end
                {:ok, "We are processing Employee #{employee_status} Successfully"}
              {:error, changeset} -> {:error, changeset}
            end
          end
        else
          {:not_found, "employee is not active"}
        end
      {:error, message} -> {:validation_error, message}
    end

  end

  defp checkEmployeeStatusValidation(params) do
    cond do
      is_nil(params["commanall_id"]) || params["commanall_id"] == "" ->
        {:error, %{commanall_id: "can't be blank."}}
      is_nil(params["reason"]) || params["reason"] == "" ->
        {:error, %{reason: "can't be blank."}}
      is_nil(params["status"]) || params["status"] == "" ->
        {:error, %{status: "can't be blank."}}
      params["status"] != "A" and params["status"] != "B" and params["status"] != "D" ->
        {:error, %{status: "accept only A, B, D."}}
      true ->
        {:ok, "done"}
    end
  end
  defp thirdpartylogs(commanall_id) do
    check_registration = Repo.one(
      from rlog in Thirdpartylogs,
      where: rlog.commanall_id == ^commanall_id and like(rlog.section, "%Registration%") and rlog.status == ^"S",
      limit: 1,
      select: count(rlog.id)
    )
    registration = if check_registration > 0, do: "Y", else: "N"
    case registration do
      "N" ->
        result = Repo.one(
          from reglog in Thirdpartylogs,
          where: reglog.commanall_id == ^commanall_id and like(
            reglog.section,
            "%Registration%"
                 ) and reglog.status == ^"F",
          order_by: [
            desc: reglog.id
          ],
          limit: 1,
          select: reglog.response
        )
        reason = if !is_nil(result) do
          decode_dat = Poison.decode!(result)
          decode_dat["result"]["message"]
        end
        registration_status = if !is_nil(result), do: "F", else: registration
        %{registration: registration_status, reason: reason}
      "Y" ->
        check_identification = Repo.one(
          from log in Thirdpartylogs,
          where: log.commanall_id == ^commanall_id and like(
            log.section,
            "%Create Identification%"
                 ) and log.status == ^"S",
          limit: 1,
          select: count(log.id)
        )
        identification = if check_identification > 0, do: "Y", else: "N"
        case identification do
          "N" ->
            result = Repo.one(
              from reglog in Thirdpartylogs,
              where: reglog.commanall_id == ^commanall_id and like(
                reglog.section,
                "%Create Identification%"
                     ) and reglog.status == ^"F",
              order_by: [
                desc: reglog.id
              ],
              limit: 1,
              select: reglog.response
            )
            reason = if !is_nil(result) do
              decode_dat = Poison.decode!(result)
              decode_dat["result"]["message"]
            end
            identification_status = if !is_nil(result), do: "F", else: identification
            %{registration: registration, identification: identification_status, reason: reason}
          "Y" ->
            check_id_proof = Repo.one(
              from idlog in Thirdpartylogs,
              where: idlog.commanall_id == ^commanall_id and like(idlog.section, "%Id Proof%") and idlog.status == ^"S",
              limit: 1,
              select: count(idlog.id)
            )
            proof_of_identity = if check_id_proof > 0, do: "Y", else: "N"
            case proof_of_identity do
              "N" ->
                result = Repo.one(
                  from reglog in Thirdpartylogs,
                  where: reglog.commanall_id == ^commanall_id and like(
                    reglog.section,
                    "%Id Proof%"
                         ) and reglog.status == ^"F",
                  order_by: [
                    desc: reglog.id
                  ],
                  limit: 1,
                  select: reglog.response
                )
                reason = if !is_nil(result) do
                  decode_dat = Poison.decode!(result)
                  decode_dat["result"]["message"]
                end
                identity_status = if !is_nil(result), do: "F", else: proof_of_identity
                %{
                  registration: registration,
                  identification: identification,
                  proof_of_identity: identity_status,
                  reason: reason
                }
              "Y" ->
                check_add_proof = Repo.one(
                  from addlog in Thirdpartylogs,
                  where: addlog.commanall_id == ^commanall_id and like(
                    addlog.section,
                    "%Address Proof%"
                         ) and addlog.status == ^"S",
                  limit: 1,
                  select: count(addlog.id)
                )
                proof_of_address = if check_add_proof > 0, do: "Y", else: "N"
                case proof_of_address do
                  "N" ->
                    result = Repo.one(
                      from reglog in Thirdpartylogs,
                      where: reglog.commanall_id == ^commanall_id and like(
                        reglog.section,
                        "%Address Proof%"
                             ) and reglog.status == ^"F",
                      order_by: [
                        desc: reglog.id
                      ],
                      limit: 1,
                      select: reglog.response
                    )
                    reason = if !is_nil(result) do
                      decode_dat = Poison.decode!(result)
                      decode_dat["result"]["message"]
                    end
                    address_status = if !is_nil(result), do: "F", else: proof_of_address
                    %{
                      registration: registration,
                      identification: identification,
                      proof_of_identity: proof_of_identity,
                      proof_of_address: address_status,
                      reason: reason
                    }
                  "Y" ->
                    check_card = Repo.one(
                      from card in Thirdpartylogs,
                      where: card.commanall_id == ^commanall_id and like(
                        card.section,
                        "%Create Card%"
                             ) and card.status == ^"S",
                      limit: 1,
                      select: count(card.id)
                    )
                    create_card = if check_card > 0, do: "Y", else: "N"
                    case create_card do
                      "N" ->
                        result = Repo.one(
                          from clog in Thirdpartylogs,
                          where: clog.commanall_id == ^commanall_id and like(
                            clog.section,
                            "%Create Card%"
                                 ) and clog.status == ^"F",
                          order_by: [
                            desc: clog.id
                          ],
                          limit: 1,
                          select: clog.response
                        )
                        reason = if !is_nil(result) do
                          decode_dat = Poison.decode!(result)
                          decode_dat["result"]["message"]
                        end
                        card_status = if !is_nil(result), do: "F", else: create_card
                        %{
                          registration: registration,
                          identification: identification,
                          proof_of_identity: proof_of_identity,
                          proof_of_address: proof_of_address,
                          create_card: card_status,
                          reason: reason
                        }
                      "Y" ->
                        %{
                          registration: registration,
                          identification: identification,
                          proof_of_identity: proof_of_identity,
                          proof_of_address: proof_of_address,
                          create_card: create_card,
                          reason: nil
                        }
                    end
                end
            end
        end
    end
  end

  @doc "check employee Approval for Authorized "
  def checkEmployeeApprovalAuthorize(commanall_id) do
    employee_IdKyc = Repo.one(
      from kyid in Kycdocuments,
      where: kyid.commanall_id == ^commanall_id and kyid.type == ^"I" and kyid.status == ^"A", select: count(kyid.id)
    )
    employee_AddKyc = Repo.one(
      from kyad in Kycdocuments,
      where: kyad.commanall_id == ^commanall_id and kyad.type == ^"A" and kyad.status == ^"A", select: count(kyad.id)
    )
    _result = if employee_IdKyc > 0 && employee_AddKyc > 0, do: "Y", else: "N"
  end

  @doc """
    employee kyc override by admin
  """
  def employeeKycOverride(params, admin_id) do
    data = Repo.get_by(Kycdocuments, id: params["kycdocument_id"], commanall_id: params["commanall_id"])
    if !is_nil(data) do
      type = data.type
      check = Repo.one(
        from k in Kycdocuments,
        where: k.commanall_id == ^params["commanall_id"] and k.type == ^type and k.status == "A", limit: 1, select: k.id
      )
      case check do
        nil ->
          new_changeset = %{
            status: "A",
            reason: params["reason"],
            refered_id: admin_id
          }
          changeset = Kycdocuments.changesetKycOverride(data, new_changeset)
          case Repo.update(changeset) do
            {:ok, _add} -> {:ok, "Kyc override done"}
            {:error, changeset} -> {:error, changeset}
          end
        _data -> {:already_exist, "document already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc """
      get all employee cards list with balance
  """
  def employeeCardDetails(params) do

    get_card = Repo.all(
      from e in Employeecards,
      where: e.employee_id == ^params["employee_id"],
      select: %{
        card_id: e.id,
        employee_id: e.employee_id,
        card_number: e.last_digit,
        available_balance: e.available_balance,
      }
    )
    get_info = checkEmployeeBalance(params["employee_id"])
    %{cards: get_card, is_permission: get_info.is_permission, total_balance: get_info.total_balance}
  end

  # calculate balance and give permission
  defp checkEmployeeBalance(employee_id) do
    card_account = Repo.one(
      from a in Employeecards, where: a.employee_id == ^employee_id, select: sum(a.available_balance)
    )
    is_permission = if Decimal.cmp(card_account, "0.00") == :eq, do: "YES", else: "NO"
    %{is_permission: is_permission, total_balance: card_account}
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