defmodule ViolacorpWeb.Main.MainController do
  use ViolacorpWeb, :controller
  import Ecto.Query
  require Logger
  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Mandate
  alias Violacorp.Schemas.Fourstopcallback
  alias Violacorp.Schemas.Duefees
  alias Violacorp.Schemas.Companydocumentinfo
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Versions
  alias Violacorp.Schemas.Appversions
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Blockusers
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Loginhistory
#  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  alias Violacorp.Schemas.Contacts

  @doc   "Login Function"
  def login(conn, params) do
    unless map_size(params) == 0 do
      changeset = Commanall.login_changeset(%Commanall{}, params)
      if changeset.valid? do
        commanall = Repo.get_by(Commanall, email_id: params["email_id"], password: params["password"])

        #    check if record is empty
       if commanall == nil do
          Loginhistory.addLoginHistory(params["email_id"], nil, nil, nil, nil)
          conn
          |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
          |> halt
        else
        case commanall.internal_status do
            "C"   ->
                      Loginhistory.addLoginHistory(commanall, nil, nil, nil, nil)
                     conn
                     |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, "4002.json", message: "You do not have permission to login. Please contact customer service.")
                     |> halt
            "S"   ->
                    Loginhistory.addLoginHistory(commanall, nil, nil, nil, nil)
                     conn
                     |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, "4002.json", message: "You do not have permission to login. Please contact customer service.")
                     |> halt
            "UR" ->
                    Loginhistory.addLoginHistory(commanall, nil, nil, nil, nil)
                     conn
                    |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, "4002.json", message: "You do not have permission to login. Please contact customer service.")
                    |> halt
            _    ->
                  # check company or employee block or not
                  if commanall.status in ["D", "B", "U", "R"] do
                    Loginhistory.addLoginHistory(commanall, nil, nil, nil, nil)
                    conn
                    |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, "4002.json", message: "You do not have permission to login. Please contact customer service.")
                    |> halt
                  else
                      #          device_type = if commanall.employee_id != nil and commanall.as_employee != "Y" do
                      #            "M"
                      #          else
                      #            if is_nil(commanall.employee_id) and commanall.company_id != nil do
                      #              if params["type"] == "FCM" or params["type"] == "APNS" do
                      #                "M"
                      #              else
                      #                "W"
                      #              end
                      #            else
                      #              "W"
                      #            end
                      #          end

                      check_date = Repo.get_by(Blockusers, commanall_id: commanall.id, type: "B", status: "A")

                      check_block_date =  if check_date != nil do
                        today_date = DateTime.utc_now
                        compare =  DateTime.compare(today_date, check_date.block_date)
                        if compare == :gt or compare == :eq do
                          mapStatusUpdate = Commanall.updateStatus(commanall, %{status: "B"})
                          Repo.update(mapStatusUpdate)
                          "Yes"
                        else
                          "No"
                        end
                      else
                        "No"
                      end

                      if check_block_date === "No" do
                        device_type =  if params["type"] == "FCM" or params["type"] == "APNS" do
                          "M"
                        else
                          "W"
                        end

                        ex_ip_address = conn.remote_ip |> Tuple.to_list |> Enum.join(".")

                        ht_ip_address = get_req_header(conn, "ip_address")|> List.first

                        new_ip_address = %{ex_ip: ex_ip_address, ht_ip: ht_ip_address} |> Poison.encode!()

                        _ip_address = if new_ip_address == commanall.ip_address do
                          ""
                        else
                          ip_map = %{
                            ip_address: new_ip_address
                          }
                          ip_changeset = Commanall.update_token(commanall, ip_map)
                          Repo.update(ip_changeset)
                        end

                        new_commanall = Map.merge(commanall, %{device_type: device_type})
                        abc = conn
                              |> check_password(commanall.password, commanall.password)
                              |> assign_token(new_commanall, params)
                        case abc do
                          "fail" ->
                            Loginhistory.addLoginHistory(commanall, nil, nil, abc, "No")
                            conn
                            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
                            |> halt
                          _ ->

                            get_version = Repo.one(from v in Versions, order_by: [desc: :id], select: %{android: v.android, ios: v.iphone, ekyc: v.ekyc})
                            version = %{android: get_version.android, ios: get_version.ios}

                            if commanall.employee_id != nil and commanall.as_employee != "Y" do
                              # get employee status
                              #            employee_status = Repo.get!(Employee, commanall.employee_id)
                              employee_status = Repo.one from e in Employee, where: e.id == ^commanall.employee_id,
                                                                             select: %{
                                                                               id: e.id,
                                                                               status: e.status,
                                                                               first_name: e.first_name,
                                                                               last_name: e.last_name
                                                                             }
                              full_name = "#{employee_status.first_name} #{employee_status.last_name}"

                              type = if params["type"] == "FCM" do
                                "A"
                              else
                                if params["type"] == "APNS" do
                                  "I"
                                else
                                  "W"
                                end
                              end

                              get_device = Repo.one(from dd in Devicedetails, where: dd.commanall_id == ^commanall.id and dd.is_delete == ^"N", limit: 1, select: dd)
                              if is_nil(get_device) do
                                first_device =
                                  %{
                                    "commanall_id" => commanall.id,
                                    "unique_id" => params["unique_id"],
                                    "token" => params["token"],
                                    "type" => type,
                                    "details" =>
                                      "{manufacturer: #{params["manufacturer"]}, model_name: #{params["model_name"]}, platform: #{
                                        params["platform"]
                                      }, serial: #{params["serial"]}}",
                                    "inserted_by" => commanall.id
                                  }

                                changeset = Devicedetails.changeset(%Devicedetails{}, first_device)
                                Repo.insert(changeset)
                              else
                                if get_device.token != params["token"] or get_device.type != type do
                                  delete_existing = %{"is_delete" => "Y"}
                                  update_existing = Devicedetails.deleteStatusChangeset(get_device, delete_existing)
                                  Repo.update(update_existing)
                                  new_device = %{
                                    "commanall_id" => commanall.id,
                                    "unique_id" => params["unique_id"],
                                    "token" => params["token"],
                                    "type" => type,
                                    "details" =>
                                      "{manufacturer: #{params["manufacturer"]}, model_name: #{params["model_name"]}, platform: #{
                                        params["platform"]
                                      }, serial: #{params["serial"]} }",
                                    "inserted_by" => commanall.id
                                  }
                                  changeset = Devicedetails.changeset(%Devicedetails{}, new_device)
                                  Repo.insert(changeset)
                                end
                              end

                              is_manager = Repo.one(
                                from comman in Commanall, where: comman.id == ^commanall.id,
                                                          left_join: emp in assoc(comman, :employee),
                                                          where: emp.id == comman.employee_id,
                                                          select: emp.is_manager
                              )

                              vpin = if is_nil(commanall.vpin) do
                                "N"
                              else
                                "Y"
                              end

                              as_employee = if commanall.company_id != nil and commanall.as_employee == "Y" do
                                "Y"
                              else
                                "N"
                              end
                              document = getDocumentId(employee_status, commanall)
                              ## Login status to Y
                              Repo.update(Commanall.update_login(commanall, %{"as_login" => "Y"}))

                              details = %{
                                code: "1010",
                                status: "success",
                                status_code: "200",
                                token: abc,
                                email: params["email_id"],
                                name: full_name,
                                type: "EMPLOYEE",
                                employee_id: commanall.employee_id,
                                emp_status: employee_status.status,
                                is_manager: is_manager,
                                card_requested: commanall.card_requested,
                                vpin: vpin,
                                locationId: "53",
                                ekyc: get_version.ekyc,
                                version: Poison.encode!(version),
                                appversion: getLatestAppVersion(),
                                as_employee: as_employee,
                                document_id: if !is_nil(document) do document.document_id else nil end,
                                documenttype_id: if !is_nil(document) do document.documenttype_id else nil end,
                                check_version: commanall.check_version,
                                accomplish_balance: ""
                              }
                              Loginhistory.addLoginHistory(commanall, details, type, abc, "No")
                              json  conn, details

                            else
                              if commanall.company_id != nil do
                                company_status = Repo.one from c in Company, where: c.id == ^commanall.company_id,
                                                                             select: %{
                                                                               cname: c.company_name
                                                                             }
                                get_device = Repo.one(from dd in Devicedetails, where: dd.commanall_id == ^commanall.id and dd.is_delete == ^"N", limit: 1, select: dd)
                                dir_type = Repo.one from d in Directors,
                                                    where: d.company_id == ^commanall.company_id and d.sequence == 1,
                                                    select: d.position

                                type = if is_nil(dir_type) do
                                  "nil"
                                else
                                  String.upcase(dir_type)
                                end


                                #                        if is_nil(get_device) do
                                #                          first_device =
                                #                            %{
                                #                              "commanall_id" => commanall.id,
                                #                              "type" => "W",
                                #                              "details" =>
                                #                                "{user-agent: #{params["useragent"]}, ip: #{params["ip"]}}",
                                #                              "inserted_by" => commanall.id
                                #                            }
                                #
                                #                          changeset = Devicedetails.changeset(%Devicedetails{}, first_device)
                                #                          Repo.insert(changeset)
                                #                        else
                                #                          if get_device.details != "{user-agent: #{params["useragent"]}, ip: #{params["ip"]}}" do
                                #                            delete_existing = %{"is_delete" => "Y"}
                                #                            update_existing = Devicedetails.deleteStatusChangeset(get_device, delete_existing)
                                #                            Repo.update(update_existing)
                                #
                                #                            new_device = %{
                                #                              "commanall_id" => commanall.id,
                                #                              "type" => "W",
                                #                              "details" =>
                                #                                "{user-agent: #{params["useragent"]}, ip: #{params["ip"]}}",
                                #                              "inserted_by" => commanall.id
                                #                            }
                                #                            changeset = Devicedetails.changeset(%Devicedetails{}, new_device)
                                #                            Repo.insert(changeset)
                                #                          end
                                #                        end
                                #
                                #
                                #

                                dev_type = if params["type"] == "FCM" do
                                  "A"
                                else
                                  if params["type"] == "APNS" do
                                    "I"
                                  else
                                    "W"
                                  end
                                end

                                if is_nil(get_device) do
                                  first_device =
                                    %{
                                      "commanall_id" => commanall.id,
                                      "unique_id" => params["unique_id"],
                                      "token" => params["token"],
                                      "type" => dev_type,
                                      "details" =>
                                        "{manufacturer: #{params["manufacturer"]}, model_name: #{params["model_name"]}, platform: #{
                                          params["platform"]
                                        }, serial: #{params["serial"]}}",
                                      "inserted_by" => commanall.id
                                    }

                                  changeset = Devicedetails.changeset(%Devicedetails{}, first_device)
                                  Repo.insert(changeset)
                                else
                                  if get_device.token != params["token"] or get_device.type != dev_type do
                                    delete_existing = %{"is_delete" => "Y"}
                                    update_existing = Devicedetails.deleteStatusChangeset(get_device, delete_existing)
                                    Repo.update(update_existing)
                                    new_device = %{
                                      "commanall_id" => commanall.id,
                                      "unique_id" => params["unique_id"],
                                      "token" => params["token"],
                                      "type" => dev_type,
                                      "details" =>
                                        "{manufacturer: #{params["manufacturer"]}, model_name: #{params["model_name"]}, platform: #{
                                          params["platform"]
                                        }, serial: #{params["serial"]} }",
                                      "inserted_by" => commanall.id
                                    }
                                    changeset = Devicedetails.changeset(%Devicedetails{}, new_device)
                                    Repo.insert(changeset)
                                  end
                                end
                                # Check if Mandate is available for the company
                                [check_mandate] = Repo.all from m in Mandate, where: m.commanall_id == ^commanall.id,
                                                                              select: count(m.id)
                                mandate = if check_mandate > 0 do
                                  "yes"
                                else
                                  "no"
                                end

                                #Count company's employees in different statuses
                                [total_employees] = Repo.all from temp in Employee,
                                                             where: temp.company_id == ^commanall.company_id and (
                                                               temp.status == "A" or temp.status == "K1" or temp.status == "K2" or temp.status == "AP"),
                                                             select: count(temp.id)
                                [kyc1_employees] = Repo.all from k1emp in Employee,
                                                            where: k1emp.company_id == ^commanall.company_id and k1emp.status == "K1",
                                                            select: count(k1emp.id)
                                [kyc2_employees] = Repo.all from k2emp in Employee,
                                                            where: k2emp.company_id == ^commanall.company_id and k2emp.status == "K2",
                                                            select: count(k2emp.id)
                                [ap_employees] = Repo.all from apemp in Employee,
                                                          where: apemp.company_id == ^commanall.company_id and apemp.status == "AP",
                                                          select: count(apemp.id)
                                ac_employees = total_employees - (kyc1_employees + kyc2_employees + ap_employees)

                                # Check due fees
                                last_duefees = Repo.one(
                                  from d in Duefees, where: d.commanall_id == ^commanall.id and d.type == "M",
                                                     order_by: [
                                                       desc: d.id
                                                     ],
                                                     limit: 1,
                                                     select: %{
                                                       pay_date: d.pay_date,
                                                       next_date: d.next_date,
                                                       id: d.id
                                                     }
                                )

                                today = NaiveDateTime.utc_now()
                                to_date = [today.year, today.month, today.day]
                                          |> Enum.map(&to_string/1)
                                          |> Enum.map(&String.pad_leading(&1, 2, "0"))
                                          |> Enum.join("-")

                                last_date = if !is_nil(last_duefees) do
                                  last_duefees.next_date
                                else
                                  NaiveDateTime.add(commanall.inserted_at, 86400 * 31)
                                end

                                pre_date = [last_date.year, last_date.month, last_date.day]
                                           |> Enum.map(&to_string/1)
                                           |> Enum.map(&String.pad_leading(&1, 2, "0"))
                                           |> Enum.join("-")

                                end_timex = Timex.parse!("#{to_date} 00:00:00", "%Y-%m-%d %H:%M:%S", :strftime)
                                start_timex = Timex.parse!("#{pre_date} 00:00:00", "%Y-%m-%d %H:%M:%S", :strftime)
                                diff_in_days = Timex.diff(start_timex, end_timex, :days)

                                pending_days = if diff_in_days < 6 and diff_in_days > 0 do
                                  diff_in_days
                                else
                                  nil
                                end

                                # check company documents
                                company_document_info = if commanall.status == "P" do
                                  com_doc_contant = Repo.one(
                                    from c in Companydocumentinfo, where: c.company_id == ^commanall.company_id and c.status == "A",
                                                                   order_by: [
                                                                     desc: c.id
                                                                   ],
                                                                   limit: 1,
                                                                   select: %{
                                                                     contant: c.contant
                                                                   }
                                  )
                                  if !is_nil(com_doc_contant) do
                                    com_doc_contant.contant
                                  else
                                    nil
                                  end
                                else
                                  nil
                                end

                                vpin = if is_nil(commanall.vpin) do
                                  "N"
                                else
                                  "Y"
                                end

                                as_employee = if commanall.employee_id != nil and commanall.as_employee == "Y" do
                                  "Y"
                                else
                                  "N"
                                end

                                if !is_nil(commanall.accomplish_userid) do
                                  # call manual load method
                                  load_params = %{
                                    "worker_type" => "manual_load",
                                    "commanall_id" => commanall.id,
                                    "company_id" => commanall.company_id
                                  }
                                  Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)
                                end

                                # check bank account exist or not
                                check_bank_account = Repo.one(from cb in Companybankaccount, where: cb.company_id == ^commanall.company_id and cb.status == "A", limit: 1, select: count(cb.id))
                                cb_status = if check_bank_account != 0 do "Yes" else "No" end

                                ## get Company balance
                                company_data = Repo.get_by(Companyaccounts, company_id: commanall.company_id)
                                document = getDirectorDocument(commanall)
                                ## Login status to Y
                                Repo.update(Commanall.update_login(commanall, %{"as_login" => "Y"}))

                                contact = Repo.one(from ct in Contacts, where: ct.commanall_id == ^commanall.id, limit: 1)
                                contact_number = if !is_nil(contact), do: contact.contact_number, else: ""
                                d_id =  case Repo.get_by(Directors, company_id: commanall.company_id, is_primary: "Y") do
                                  nil -> %{id: nil, company_id: commanall.company_id}
                                  d -> d
                                  end
                                details_login = %{
                                  code: "1010",
                                  status: "success",
                                  status_code: "200",
                                  token: abc,
                                  type: type,
                                  email: commanall.email_id,
                                  name: company_status.cname,
                                  company_id: commanall.company_id,
                                  com_status: commanall.status,
                                  emp_status: commanall.status,
                                  commanall_id: commanall.id,
                                  step: commanall.reg_step,
                                  mandate: mandate,
                                  total_employees: total_employees,
                                  k1_employees: kyc1_employees,
                                  k2_employees: kyc2_employees,
                                  ap_employees: ap_employees,
                                  ac_employees: ac_employees,
                                  pending_days: pending_days,
                                  document_contant: company_document_info,
                                  locationId: "53",
                                  as_employee: as_employee,
                                  vpin: vpin,
                                  ekyc: get_version.ekyc,
                                  version: Poison.encode!(version),
                                  appversion: getLatestAppVersion(),
                                  cb_account: cb_status,
                                  directors_id: if !is_nil(document) do document.directors_id else nil end,
                                  document_id: if !is_nil(document) do document.document_id else nil end,
                                  documenttype_id: if !is_nil(document) do document.documenttype_id else nil end,
                                  accomplish_balance: if company_data != nil do company_data.available_balance else "" end,
                                  currency: if company_data != nil do company_data.currency_code else "" end,
                                  check_version: commanall.check_version,
                                  contact_number: contact_number,
                                  primary_director_id: d_id.id
                                }
                                Loginhistory.addLoginHistory(commanall, details_login, dev_type, abc, "No")

                                json  conn, details_login

                              end
                            end
                        end
                      else
                        Loginhistory.addLoginHistory(commanall, nil, nil, nil, "Yes")
                        conn
                        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, "4002.json", message: "Your account has been blocked, Please contact to administrator.")
                        |> halt
                      end
                  end
        end
       end
      else
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  def switch_to_employee(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get(Commanall, commanid)
    if commanall do
      if commanall.employee_id != nil and commanall.as_employee == "Y" do
        employee_status = Repo.one from e in Employee, where: e.id == ^commanall.employee_id,
                                                       select: %{
                                                         company_id: e.company_id,
                                                         status: e.status,
                                                         is_manager: e.is_manager,
                                                         first_name: e.first_name,
                                                         last_name: e.last_name
                                                       }
        full_name = "#{employee_status.first_name} #{employee_status.last_name}"

        vpin = if is_nil(commanall.vpin) do
          "N"
        else
          "Y"
        end
        get_version = Repo.one(from v in Versions, order_by: [desc: :id], select: %{android: v.android, ios: v.iphone, ekyc: v.ekyc})
        version = %{android: get_version.android, ios: get_version.ios}

        keyfortoken = Application.get_env(:violacorp, :tokenKey)
        user_id = commanall.employee_id
        cid = employee_status.company_id
        payload = %{
          "email" => commanall.email_id,
          "commanall_id" => commanall.id,
          "id" => user_id,
          "violaid" => commanall.viola_id,
          "cid" => cid
        }
        token = create_token(keyfortoken, payload)

        json conn, %{
          code: "1010",
          status: "success",
          status_code: "200",
          token: token,
          email: commanall.email_id,
          name: full_name,
          type: "EMPLOYEE",
          employee_id: commanall.employee_id,
          emp_status: employee_status.status,
          is_manager: employee_status.is_manager,
          card_requested: commanall.card_requested,
          vpin: vpin,
          locationId: "53",
          ekyc: get_version.ekyc,
          version: Poison.encode!(version),
          appversion: getLatestAppVersion(),
          as_employee: "N",
          check_version: commanall.check_version,
        }

      else
        json conn, %{status_code: "4003", message: "Not a registered as employee"}
      end
    else
      json conn, %{status_code: "4003", message: "No user found"}
    end
  end


  def switch_to_company(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get(Commanall, commanid)
    if commanall do
      if commanall.company_id != nil and commanall.as_employee == "Y" do
        company_status = Repo.one from e in Company, where: e.id == ^commanall.company_id,
                                                       select: %{
                                                         company_name: e.company_name,
                                                       }

        vpin = if is_nil(commanall.vpin) do
          "N"
        else
          "Y"
        end
        get_version = Repo.one(from v in Versions, order_by: [desc: :id], select: %{android: v.android, ios: v.iphone, ekyc: v.ekyc})
        version = %{android: get_version.android, ios: get_version.ios}

        keyfortoken = System.get_env("VC_TOKEN_KEY")
        user_id = commanall.employee_id
        cid = commanall.company_id
        payload = %{
          "email" => commanall.email_id,
          "commanall_id" => commanall.id,
          "id" => user_id,
          "violaid" => commanall.viola_id,
          "cid" => cid
        }
        token = create_token(keyfortoken, payload)

        # check bank account exist or not
        check_bank_account = Repo.one(from cb in Companybankaccount, where: cb.company_id == ^commanall.company_id and cb.status == "A", limit: 1, select: count(cb.id))
        cb_status = if check_bank_account != 0 do "Yes" else "No" end

        dir_type = Repo.one from d in Directors,
                            where: d.company_id == ^commanall.company_id and d.sequence == 1,
                            select: d.position

        type = if is_nil(dir_type) do
          "nil"
        else
          String.upcase(dir_type)
        end

        ## get Company balance
        company_data = Repo.get_by(Companyaccounts, company_id: commanall.company_id)

        json  conn,
              %{
                code: "1010",
                status: "success",
                status_code: "200",
                token: token,
                type: type,
                email: commanall.email_id,
                name: company_status.company_name,
                company_id: commanall.company_id,
                com_status: commanall.status,
                commanall_id: commanall.id,
                cb_status: cb_status,
                ekyc: get_version.ekyc,
                version: Poison.encode!(version),
                appversion: getLatestAppVersion(),
                vpin: vpin,
                accomplish_balance: if company_data != nil do company_data.available_balance else "" end,
                currency: if company_data != nil do company_data.currency_code else "" end,
              }
      else
        json conn, %{status_code: "4003", message: "Not a registered as employee"}
      end
    else
      json conn, %{status_code: "4003", message: "No user found"}
    end

  end

  @doc "logout function "
  def logout(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    case Repo.get(Commanall, commanid) do
      nil -> %{status_code: "4003", message: "No user found"}
      comman ->
               ## Login status to N
               case Repo.update(Commanall.update_login(comman, %{"as_login" => "N"})) do
                 {:ok, _newpins} ->

                   current = Repo.get_by(Devicedetails, commanall_id: commanid, is_delete: "N")
                   if !is_nil(current) do
                     delete_existing = %{"is_delete" => "Y"}
                     update_existing = Devicedetails.deleteStatusChangeset(current, delete_existing)
                     Repo.update(update_existing)
                   end
                   json conn, %{status_code: "200", messages: "Logout Successful"}
                 {:error, changeset} ->
                   conn
                   |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
               end
    end
  end

  @doc "forget pin function - one"
  def createPin(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    current = Repo.get(Commanall, commanid)
    if is_nil(current.vpin) do
      new_pin = %{"vpin" => params["vpin"]}
      addPin_changeset = Commanall.changeset_updatepin(current, new_pin)
      case Repo.update(addPin_changeset) do
        {:ok, _newpins} ->
          json conn, %{status_code: "200", messages: "Added Passcode Successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4003", messages: "Passcode already exists"}
    end
  end

  @doc "forget pin function - one"
  def logoutDevice(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    current = Repo.get_by(Devicedetails, commanall_id: commanid, is_delete: "N")
    if current do
      delete_existing = %{"is_delete" => "Y"}
      update_existing = Devicedetails.deleteStatusChangeset(current, delete_existing)
      Repo.update(update_existing)
      json conn, %{status_code: "200", messages: "Logged out from Device"}
    end
    json conn, %{status_code: "4003", messages: "No Active device found for this user"}
  end

  @doc "forget pin function - one"
  def forgotPinOne(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      checknumber = Repo.one from cmn in Commanall, where: cmn.id == ^commanid, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y" and m.contact_number == ^params["contact_number"], left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                    select: %{
                                                      commanall_id: cmn.id,
                                                      email_id: cmn.email_id,
                                                      as_login: cmn.as_login,
                                                      code: m.code,
                                                      contact_number: m.contact_number,
                                                      token: d.token,
                                                      token_type: d.type
                                                    }
      if !is_nil(checknumber) do

        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)

        otpmap = %{
          "commanall_id" => checknumber.commanall_id,
          "otp_code" => otp_code,
          "otp_source" => "Pin",
          "inserted_by" => checknumber.commanall_id
        }
        changeset = Otp.changeset(%Otp{}, otpmap)

        checkrecord = Repo.one from o in Otp,
                               where: o.commanall_id == ^checknumber.commanall_id and o.otp_source == "Pin",
                               select: count(o.commanall_id)

        if checkrecord == 0 do
          case Repo.insert(changeset) do
            {:ok, _otpmap} ->

              data = [
                %{
                  section: "forgot_pin",
                  type: "S",
                  contact_code: checknumber.code,
                  contact_number: checknumber.contact_number,
                  data: %{:otp_code => generate_otp} # Content
                }]
              V2AlertsController.main(data)


              json conn, %{status_code: "200", messages: "Inserted New Passcode OTP."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: checknumber.commanall_id, otp_source: "Pin")
          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _otpmap} ->

              data = [
                %{
                  section: "forgot_pin",
                  type: "S",
                  contact_code: checknumber.code,
                  contact_number: checknumber.contact_number,
                  data: %{:otp_code => generate_otp} # Content
                }]
              V2AlertsController.main(data)

              json conn, %{status_code: "200", messages: "Updated Existing Passcode OTP"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        json conn, %{status_code: "4004", messages: "Incorrect Number"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "forget pin function - two"
  def forgotPinTwo(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      # commanall_id, otp, new_password
      commanall = Repo.get!(Commanall, commanid)
      changeset = %{vpin: params["new_pin"]}
      new_changeset = Commanall.changeset_updatepin(commanall, changeset)

      getotp = Repo.one from o in Otp, where: o.commanall_id == ^commanid and o.otp_source == "Pin",
                                       select: o.otp_code
      otpdecode = Poison.decode!(getotp)

      if otpdecode["otp_code"] == params["otp_code"] do
        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Success, Passcode updated"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4004", messages: "Incorrect OTP code"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc  "forget Password function - one"
  def forgotPasswordOne(conn, params) do
    unless map_size(params) == 0 do
      checknumber = Repo.one from cmn in Commanall, where: cmn.email_id == ^params["email"], left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                    select: %{
                                                      count: count(cmn.email_id),
                                                      commanall_id: cmn.id,
                                                      email_id: cmn.email_id,
                                                      as_login: cmn.as_login,
                                                      code: m.code,
                                                      contact_number: m.contact_number,
                                                      token: d.token,
                                                      token_type: d.type,
                                                    }



      if !is_nil(checknumber) and checknumber.count == 1 do

        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)

        otpmap = %{
          "commanall_id" => checknumber.commanall_id,
          "otp_code" => otp_code,
          "otp_source" => "Password",
          "inserted_by" => checknumber.commanall_id
        }
        changeset = Otp.changeset(%Otp{}, otpmap)

        checkrecord = Repo.one from o in Otp,
                               where: o.commanall_id == ^checknumber.commanall_id and o.otp_source == "Password",
                               select: count(o.commanall_id)

        if checkrecord == 0 do
          case Repo.insert(changeset) do
            {:ok, _otpmap} ->
              data = [%{
                section: "forgot_password",
                type: "E",
                email_id: checknumber.email_id,
                data: %{:otp_code => generate_otp}   # Content
              }]
              V2AlertsController.main(data)

              json conn,
                   %{
                     status_code: "200",
                     commanall_id: "#{checknumber.commanall_id}",
                     messages: "Inserted New Password OTP"
                   }
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: checknumber.commanall_id, otp_source: "Password")
          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _json} ->

              data = [%{
                section: "forgot_password",
                type: "E",
                email_id: checknumber.email_id,
                data: %{:otp_code => generate_otp}   # Content
              }]
              V2AlertsController.main(data)
              json conn,
                   %{
                     status_code: "200",
                     commanall_id: "#{checknumber.commanall_id}",
                     messages: "Updated Existing Password OTP"
                   }
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        json conn, %{status_code: "4004", messages: "Incorrect Email"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc  "forget Password function - two"
  def forgotPasswordTwo(conn, params) do
    unless map_size(params) == 0 do
      # commanall_id, otp, new_password
      commanall = Repo.get!(Commanall, params["commanall_id"])
      changeset = %{password: params["new_password"]}
      new_changeset = Commanall.changeset_updatepassword(commanall, changeset)

      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^params["commanall_id"] and o.otp_source == "Password",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)

      if otpdecode["otp_code"] == params["otp_code"] do
        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Success, password updated"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4004", messages: "Incorrect OTP please re-enter correct OTP"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "resend otp function"
  def resend_otp(conn, params) do
    unless map_size(params) == 0 do
      getinfo = Repo.one from o in Otp, where: o.id == ^params["id"],
                                        select: %{
                                          commanall_id: o.commanall_id,
                                          otp_code: o.otp_code,
                                          otp_source: o.otp_source,
                                          updated_at: o.updated_at
                                        }
      otp_code_attempt = Poison.decode!(getinfo.otp_code)

      notification_section = case getinfo.otp_source do
        "Registration_mobile" -> "company_registration_otp_mobile"
        "Pin" -> "forgot_pin"
        "Password" -> "forgot_password"
        "Registration" -> "company_registration_otp"
        _ -> "forgot_password"

      end
      if otp_code_attempt["otp_attempt"] == 0 do
        current_datetime = NaiveDateTime.utc_now()
        diff = NaiveDateTime.diff(current_datetime, getinfo.updated_at)

        if diff >= 1800 do
          generate_otp = Commontools.randnumber(6)

          otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 2}
          new_otp = Poison.encode!(otp_code_map)

          oldotp = Repo.get_by!(Otp, commanall_id: params["commanall_id"], otp_source: getinfo.otp_source)
          otpmap = %{
            "commanall_id" => getinfo.commanall_id,
            "otp_code" => new_otp,
            "otp_source" => getinfo.otp_source
          }
          changeset = Otp.attempt_changeset(oldotp, otpmap)

          case Repo.update(changeset) do
            {:ok, _otpmap} ->

              commondata = Repo.one from cmn in Commanall, where: cmn.id == ^getinfo.commanall_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                           select: %{
                                                             id: cmn.id,
                                                             email_id: cmn.email_id,
                                                             as_login: cmn.as_login,
                                                             code: m.code,
                                                             contact_number: m.contact_number,
                                                             token: d.token,
                                                             token_type: d.type
                                                           }

              data = if getinfo.otp_source == "Pin" or getinfo.otp_source == "Registration_mobile"  do
                [
                  %{
                    section: notification_section,
                    type: "S",
                    contact_code: commondata.code,
                    contact_number: commondata.contact_number,
                    data: %{
                      :otp_code => generate_otp
                    } # Content
                  }
                ]
              else
                [
                  %{
                    section: notification_section,
                    type: "E",
                    email_id: commondata.email_id,
                    data: %{
                      :otp_code => generate_otp,
                      :otp_source => getinfo.otp_source
                    } # Content
                  }
                ]
              end
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

          oldotp = Repo.get!(Otp, params["id"])
          otpmap = %{
            "commanall_id" => getinfo.commanall_id,
            "otp_code" => "#{new_otp}",
            "otp_source" => getinfo.otp_source
          }
          changeset = Otp.attempt_changeset(oldotp, otpmap)

          case Repo.update(changeset) do
            {:ok, _otpmap} ->
              commondata = Repo.one from cmn in Commanall, where: cmn.id == ^getinfo.commanall_id, left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                           select: %{
                                                             id: cmn.id,
                                                             email_id: cmn.email_id,
                                                             as_login: cmn.as_login,
                                                             code: m.code,
                                                             contact_number: m.contact_number,
                                                             token: d.token,
                                                             token_type: d.type
                                                           }

              data = if getinfo.otp_source == "Pin" or getinfo.otp_source == "Registration_mobile"  do
                [
                  %{
                    section: notification_section,
                    type: "S",
                    contact_code: commondata.code,
                    contact_number: commondata.contact_number,
                    data: %{
                      :otp_code => generate_otp
                    }# Content
                  }
                ]
              else
                [
                  %{
                    section: notification_section,
                    type: "E",
                    email_id: commondata.email_id,
                    data: %{
                      :otp_code => generate_otp,
                      :otp_source => getinfo.otp_source
                    }# Content
                  }
                ]
              end

              V2AlertsController.main(data)

              json conn, %{status_code: "200", messages: "Inserted New OTP and reduced attempt"}
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

  @doc "reset employee password -admin side"
  def resetEmployeePassword(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]
      get_employee = Repo.get_by(Commanall, employee_id: params["employee_id"])

      password = params["new_password"]

      check_employee = Repo.get(Employee, get_employee.employee_id)
      if check_employee.company_id == company_id do
        new_pass = %{
          password: password
        }
        changeset = Commanall.changeset_updatepassword(get_employee, new_pass)

        case Repo.update(changeset) do
          {:ok, _otpmap} -> json conn, %{status_code: "200", messages: "Password Changed Successfully"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4004", messages: "Employee does not exist for this company"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "change password function "
  def change_password(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      match_current = Repo.one from psw in Commanall,
                               where: psw.id == ^commanid and psw.password == ^params["password"],
                               select: count(psw.id)

      if match_current == 1 do
        commanall = Repo.get!(Commanall, commanid)
        changeset = %{password: params["new_password"]}
        new_changeset = Commanall.changeset_updatepassword(commanall, changeset)

        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Success, password changed"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end

      else
        json conn, %{status_code: "4004", messages: "Password does not match, try again"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "change pin function"
  def change_pin(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      match_current = Repo.one from psw in Commanall, where: psw.id == ^commanid and psw.vpin == ^params["pin"],
                                                      select: count(psw.id)

      if match_current == 1 do
        commanall = Repo.get!(Commanall, commanid)
        changeset = %{vpin: params["new_pin"]}
        new_changeset = Commanall.changeset_updatepin(commanall, changeset)

        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Passcode changed successfully."}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end

      else
        json conn, %{status_code: "4004", messages: "Passcode does not match, try again"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end

  end

  @doc "Verify pin function"
  def verify_pin(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      match_current = Repo.one from psw in Commanall, where: psw.id == ^commanid and psw.vpin == ^params["pin"],
                                                      select: count(psw.id)

      commanall = Repo.get_by(Commanall, id: commanid)
      check_version = commanall.check_version

      get_version = Repo.one(from v in Versions, order_by: [desc: :id], select: %{android: v.android, ios: v.iphone, ekyc: v.ekyc})
      version = %{android: get_version.android, ios: get_version.ios}

      if match_current == 1 do
        json conn, %{status_code: "200", messages: "Success, Passcode verified", version: Poison.encode!(version), appversion: getLatestAppVersion(), check_version: check_version}
      else
        if match_current == 0 or match_current > 1 do
          json conn, %{status_code: "4004", errors: %{message: "Passcode does not match, try again"}}
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "create vpin function"
  def create_pin(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      commanall = Repo.get!(Commanall, commanid)

      if is_nil(commanall.vpin) do
        changeset = %{vpin: params["pin"]}
        new_changeset = Commanall.changeset_updatepin(commanall, changeset)

        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Passcode created successfully."}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end

      else
        json conn, %{status_code: "4004", messages: "Passcode Already Set"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "reset token function"
  def resetToken(conn, params) do
    unless map_size(params) == 0 do
      commanall = Repo.get_by(Commanall, id: params["id"])

      #    check if record is empty
      if commanall == nil do
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :"no user found")
        |> halt
      else
        abc = conn
              |> check_password(commanall.password, commanall.password)
              |> assign_token(commanall, commanall)

        case abc do
          "fail" ->
            conn
            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
            |> halt
          _ ->
            if commanall.company_id == nil do
              # get employee status
              #            employee_status = Repo.get!(Employee, commanall.employee_id)
              employee_status = Repo.one from e in Employee, where: e.id == ^commanall.employee_id,
                                                             select: %{
                                                               status: e.status,
                                                               first_name: e.first_name,
                                                               last_name: e.last_name
                                                             }
              full_name = "#{employee_status.first_name} #{employee_status.last_name}"

              json  conn,
                    %{
                      code: "1010",
                      status: "success",
                      status_code: "200",
                      token: abc,
                      email: commanall.email_id,
                      name: full_name,
                      employee_id: commanall.employee_id,
                      emp_status: employee_status.status
                    }
            else
              company_status = Repo.one from c in Company, where: c.id == ^commanall.company_id,
                                                           select: %{
                                                             cname: c.company_name
                                                           }
              json  conn,
                    %{
                      code: "1010",
                      status: "success",
                      status_code: "200",
                      token: abc,
                      email: commanall.email_id,
                      name: company_status.cname,
                      company_id: commanall.company_id,
                      com_status: commanall.status,
                      step: commanall.reg_step
                    }
            end

        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Check admin password"
  def checkPassword(conn, params) do
    unless map_size(params) == 0 do
      changeset = Administratorusers.login_changeset(%Administratorusers{}, params)
      if changeset.valid? do
        commanall = Repo.get_by(Administratorusers, email_id: params["email_id"], password: params["password"])

        #    check if record is empty
        if commanall == nil do
          conn
          |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
          |> halt
        else
          abc = conn
                |> check_password(commanall.password, commanall.password)
                |> assign_token_admin(commanall, params)

          case abc do
            "fail" ->
              conn
              |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
              |> halt
            _ ->
              type = if params["email_id"] == "admin@viola.group" do
                "Y"
              else
                "N"
              end
              json  conn,
                    %{
                      status_code: "1010",
                      status: "success",
                      token: abc,
                      type: type
                    }
          end
        end
      else
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc  "for testing purposes - automate otp "
  def automate_otp(conn, params) do
    unless map_size(params) == 0 do
      username = "admin"
      password = "viola123"

      if params["username"] == username and params["password"] == password do

        commanall_id = Repo.one from c in Commanall, where: c.email_id == ^params["email"], select: c.id
        if commanall_id == nil do
          text conn, "no such user exists"
        else
          getotp = Repo.one from o in Otp, where: o.commanall_id == ^commanall_id and o.otp_source == "Password",
                                           select: o.otp_code

          otpdecode = Poison.decode!(getotp)

          text conn, "#{otpdecode["otp_code"]}"
        end
      else
        text conn, "Incorrect username/password"

      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  @doc  "for testing purposes - check if notifications working "
  def check_notification(conn, params) do
    unless map_size(params) == 0 do
      username = "admin"
      password = "viola123"

      if params["username"] == username and params["password"] == password do
        get_id = Repo.get_by(Commanall, email_id: params["email"])

        get_platform = Repo.get_by(Devicedetails, commanall_id: get_id.id, status: "A", is_delete: "N")

        _send = if is_nil(get_platform) do
          text conn, "no device found for this user"
        else
          messagebody = %{
            "worker_type" => "send_android",
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Test Notification"
            }
          }
          cond do
            get_platform.type == "A" -> Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [messagebody], max_retries: 1)
                                        text conn, "sent android"
            get_platform.type == "I" -> Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [messagebody], max_retries: 1)
                                        text conn, "sent ios"
            true -> text conn, "no platform match for notification"
          end
        end
      else
        text conn, "Incorrect username/password"

      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end
  @doc "checks if two given password match"
  def check_password(_conn, password1, password2) do
    case password1 == password2 do
      :true -> "pass"
      :false -> "fail"
    end
  end

  @doc  "if password match assigns token"
  def assign_token(status, commanall, _params) do
    #    Phoenix.Token.sign(ViolacorpWeb.Endpoint, key_for_token, payload)

    #    employee_status = Repo.one from e in Employee, where: e.id == ^commanall.employee_id, select: %{status: e.status}
    keyfortoken = Application.get_env(:violacorp, :tokenKey)

    user_id = if commanall.company_id == nil do
      commanall.employee_id
    else
      commanall.company_id
    end
    cid = if commanall.company_id == nil and commanall.employee_id != nil do
      employee = Repo.get_by(Employee, id: user_id)
      employee.company_id
    else
      nil
    end

    case status do
      "pass" -> new_party = Repo.get(Commanall, commanall.id)
                ip_address = if is_nil(new_party.ip_address) do
                               nil
                             else
                               if is_nil(Poison.decode!(new_party.ip_address) |> Map.get( :ht_ip)) do
                                  Poison.decode!(new_party.ip_address) |> Map.get( :ex_ip)
                               else
                                  Poison.decode!(new_party.ip_address) |> Map.get( :ht_ip)
                               end
                              end
                payload = %{
                  "email" => commanall.email_id,
                  "commanall_id" => commanall.id,
                  "id" => user_id,
                  "violaid" => commanall.viola_id,
                  "cid" => cid,
                  "ip_address" => ip_address,
                  "device_type" => commanall.device_type
                }

                token = create_token(keyfortoken, payload)
                if is_map(new_party) do
                  token_map = if commanall.device_type == "M" do
                    %{
                      m_api_token: token
                    }
                  else
                    %{
                      api_token: token
                    }
                  end
                  token_changeset = Commanall.update_token(new_party, token_map)

                  case Repo.update(token_changeset) do
                    {:ok, _party} -> token
                    {:error, _changeset} ->
                      Logger.warn("Token update failed in assign token for #{commanall.id}")
                  end
                else
                  Logger.warn("Query on in assign token has failed for #{commanall.id}")
                end

      "fail" -> "fail"
    end
  end

  @doc  "if password match assign token"
  def assign_token_admin(status, commanall, _params) do

    keyfortoken = Application.get_env(:violacorp, :tokenKey)

    payload = %{
      "email" => commanall.email_id,
      "commanall_id" => commanall.id
    }
    case status do
      "pass" -> create_token(keyfortoken, payload)
      "fail" -> "fail"
    end
  end

  @doc "Create Token"
  def create_token(key_for_token, payload) do
    Phoenix.Token.sign(ViolacorpWeb.Endpoint, key_for_token, payload)
  end


  @doc "4 stop call back methods"
  # Post Method
  def callbackPost(conn, params) do
    unless map_size(params) == 0 do
      callbackdata = %{"response" => Poison.encode!(params)}
      changeset_callback = Fourstopcallback.changeset(%Fourstopcallback{}, callbackdata)
      Repo.insert(changeset_callback)
      text conn, "Done"
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end
  # Get Method
  def callbackGet(conn, _params) do
    #    callbackdata = %{"response" => Poison.encode!(_params)}
    #    changeset_callback = Fourstopcallback.changeset(%Fourstopcallback{}, callbackdata)
    #    Repo.insert(changeset_callback)
    text conn, "Done"
  end

  @doc "Back Method"
  def backUrl(conn, params) do
    unless map_size(params) == 0 do
      id = params["id"]
      commanid = params["commanid"]

      step_info = Repo.one from c in Commanall, where: c.id == ^commanid,
                                                select: %{
                                                  step_number: c.reg_step,
                                                  step: c.step,
                                                  reg_data: c.reg_data
                                                }

      response = Poison.decode!(step_info.reg_data)

      json conn, %{status_code: "200", data: response[id]}
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Refresh Token"
  def refreshToken(conn, params) do

    email_id = params["email_id"]
    token = params["token"]
    ip_address = get_req_header(conn, "ip_address")|> List.first

    keyfortoken = Application.get_env(:violacorp, :tokenKey)

    case Phoenix.Token.verify(ViolacorpWeb.Endpoint, keyfortoken, token, max_age: 86400) do
      {:ok, _data} ->
        json conn, %{status_code: "200", token: token}
      {:error, :expired} ->
        commanall = Repo.get_by(Commanall, email_id: email_id)

        if is_map(commanall) do
        user_id = if commanall.company_id == nil do
          commanall.employee_id
        else
          commanall.company_id
        end
        cid = if commanall.company_id == nil do
          employee = Repo.get_by(Employee, id: user_id)
          employee.company_id
        else
          nil
        end
        device_type = if params["type"] == "FCM" or params["type"] == "APNS" do
              "M"
            else
              "W"
            end

        payload = %{
          "email" => commanall.email_id,
          "commanall_id" => commanall.id,
          "id" => user_id,
          "violaid" => commanall.viola_id,
          "cid" => cid,
          "device_type" => device_type,
          "ip_address" => ip_address
        }
        new_token = create_token(keyfortoken, payload)

        token_map = if device_type == "M" do
          %{
            m_api_token: new_token
          }
        else
          %{
            api_token: new_token
          }
        end
        token_changeset = Commanall.update_token(commanall, token_map)

        case Repo.update(token_changeset) do
          {:ok, _party} -> json conn, %{status_code: "200", token: new_token}
          {:error, _changeset} ->
            Logger.warn("Token update failed in assign token for #{commanall.id}")
        end

        else
          Logger.warn("Query on refresh token has failed for #{commanall.id}")
        end
      {:error, _} ->
        json conn, %{status_code: "4003", token: "Token not valid"}
    end
  end

  @doc "accept legal terms"
  def acceptlegal(conn, _params) do
    %{"id" => employee_id} = conn.assigns[:current_user]

    employee = Repo.get_by(Employee, id: employee_id)
    if employee != nil do
      accepted_at = DateTime.utc_now
      updateTerms = %{terms_accepted: "Yes", status: "IDINFO", terms_accepted_at: accepted_at}
      changeset = Employee.updateTerms(employee, updateTerms)
      case Repo.update(changeset) do
        {:ok, _changeset} ->json conn, %{status_code: "200", message: "Accepted legal condition"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4004", message: "Party Not found!"}
    end

  end

  defp getLatestAppVersion() do
    get_appversions = Repo.all(from a in Appversions, where: a.is_active == ^"Y", select: %{version: a.version, type: a.type})
                      |> Enum.reduce(%{}, fn(inner_map, acc) -> Map.put(acc, inner_map.type, inner_map.version) end)
    Poison.encode!(get_appversions)
  end

  defp getDocumentId(employee, common) do
    employee_id = common.id
    cond do
      employee.status == "IDDOC1" ->
        Repo.one(from k in Kycdocuments, where: k.commanall_id == ^employee_id and k.type == "I" and k.status == "A", select: %{document_id: k.id, documenttype_id: k.documenttype_id})
      employee.status == "IDDOC2" ->
        Repo.one(from k in Kycdocuments, where: k.commanall_id == ^employee_id and k.type == "I" and k.status == "A", select: %{document_id: k.id, documenttype_id: k.documenttype_id})
      employee.status == "ADDOC1" ->
        Repo.one(from k in Kycdocuments, where: k.commanall_id == ^employee_id and k.type == "A" and k.status == "A", select: %{document_id: k.id, documenttype_id: k.documenttype_id})
      true -> nil
    end
  end

  defp getDirectorDocument(common) do
    company_id = common.company_id
    director_id = Repo.one(from d in Directors, where: d.company_id == ^company_id, limit: 1, order_by: [desc: d.inserted_at], select: d.id)
    if !is_nil(director_id) do
      cond do
        common.reg_step == "IDDOC1" ->
          Repo.one(from k in Kycdirectors, where: k.directors_id == ^director_id and k.type == "I" and k.status == "A", select: %{document_id: k.id, directors_id: k.directors_id, documenttype_id: k.documenttype_id})
        common.reg_step == "IDDOC2" ->
          Repo.one(from k in Kycdirectors, where: k.directors_id == ^director_id and k.type == "I" and k.status == "A", select: %{document_id: k.id, directors_id: k.directors_id, documenttype_id: k.documenttype_id})
        common.reg_step == "ADDOC1" ->
          Repo.one(from k in Kycdirectors, where: k.directors_id == ^director_id and k.type == "A" and k.status == "A", select: %{document_id: k.id, directors_id: k.directors_id, documenttype_id: k.documenttype_id})
        true -> nil
      end
    else
      nil
    end
  end
end