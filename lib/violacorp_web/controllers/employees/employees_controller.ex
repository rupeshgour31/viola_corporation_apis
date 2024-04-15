defmodule ViolacorpWeb.Employees.EmployeesController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Validatecard
  alias Violacorp.Libraries.Commontools
  alias ViolacorpWeb.Comman.TestController
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Transactionsreceipt
  alias Violacorp.Schemas.Assignproject
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Projects
  alias Violacorp.Schemas.Versions
  alias Violacorp.Schemas.Appversions
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Devicedetails

  alias ViolacorpWeb.Employees.EmployeeView
  alias ViolacorpWeb.Main.DashboardView

  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController
  alias Violacorp.Libraries.HistoryManagement

  def updateEmployee(conn, params) do
    text  conn, "updateEmployee #{params["id"]}"
  end


  @doc "gets all employees of a company from Employee table"
  def getAllEmployees(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    employee = Repo.all (
                          from e in Employee,
                               where: e.company_id == ^company_id,
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

  @doc "gets single employee of a company from Employee table"
  def getSingleEmployee(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    employee = Repo.one(from e in Employee, where: e.id == ^params["id"] and e.company_id == ^company_id)
    render(conn, EmployeeView, "show.json", employee: employee)
  end

  @doc "EMPLOYEE INFO (ADDRESS, CONTACTS)"
  def getSingleEmployeeInfo(conn, params) do
    commanall = Repo.get!(Commanall, params["id"])
    employee = Employee
               |> Repo.get(commanall.employee_id)
               |> Repo.preload(:commanall)
               |> Repo.preload(commanall: :address)
               |> Repo.preload(commanall: :contacts)
    render(conn, EmployeeView, "renderwithaddress.json", employee: employee)
  end

  def requestMoney(conn, params) do
    text  conn, "requestMoney #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def transactionsList(conn, params) do
    %{"id" => empid} = conn.assigns[:current_user]

    transactions = Repo.all(
                     from t in Transactions,
                     where: t.employee_id == ^empid and t.employeecards_id == ^params["cardId"] and (
                       t.transaction_type != "B2A" or t.transaction_type != "A20") and (
                              (t.transaction_type == "A2C" and t.transaction_mode == "C") or (
                                t.transaction_type == "C2A" and t.transaction_mode == "D") or (
                                t.transaction_type == "C2I") or (t.transaction_type == "C2O")),
                     order_by: [
                       desc: t.transaction_date
                     ]
                   )
                   |> Repo.preload(:transactionsreceipt)
    render(conn, EmployeeView, "manytrans.json", transactions: transactions)

    #    get_transactions =  Transactions
    #                        |> where([t], t.employeecards_id == ^params["cardId"] and ((t.transaction_type == "A2C" and t.transaction_mode == "C") or (t.transaction_type == "C2A" and t.transaction_mode == "D") or  (t.transaction_type == "C2I") or (t.transaction_type == "C2O") or (t.transaction_type == "C2F")))
    #                        |> order_by(desc: :transaction_date)
    #                        |> preload(:transactionsreceipt)
    #                        |> Repo.paginate(params)
    #
    #    render(conn, EmployeeView, "manytrans.json", transactions: get_transactions)

  end

  def getEmployeeTransaction(conn, params) do
    %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]

    get_transaction = Repo.one from t in Transactions,
                               where: t.commanall_id == ^commanid and t.employee_id == ^empid and t.id == ^params["transactionId"],
                               select: %{
                                 id: t.id,
                                 amount: t.amount,
                                 fee_amount: t.fee_amount,
                                 final_amount: t.final_amount,
                                 remark: t.remark,
                                 balance: t.balance,
                                 previous_balance: t.previous_balance,
                                 transaction_mode: t.transaction_mode,
                                 transaction_type: t.transaction_type,
                                 transaction_id: t.transaction_id,
                                 category: t.category,
                                 status: t.status,
                                 transaction_date: t.transaction_date,
                                 cur_code: t.cur_code,
                                 projects_id: t.projects_id,
                                 project_name: nil,
                                 notes: t.notes,
                                 description: t.description,
                                 entertain_id: t.entertain_id,
                                 category_id: t.category_id
                               }
    if is_nil(get_transaction) do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Transaction Record Not Found!"
             }
           }
    else

      project_id = get_transaction.projects_id
      project_name = if project_id != nil do
        Repo.one from p in Projects, where: p.id == ^project_id,
                                     select: %{
                                       project_name: p.project_name
                                     }
      else
        nil
      end

      get_transaction_receipts = Repo.all from transactionsreceipt in Transactionsreceipt,
                                          where: transactionsreceipt.transactions_id == ^params["transactionId"],
                                          select: %{
                                            trans_receipt_id: transactionsreceipt.id,
                                            content: transactionsreceipt.content,
                                            receipt_url: transactionsreceipt.receipt_url
                                          }

      merge_transaction = if project_name == nil do
        get_transaction
      else
        Map.merge(get_transaction, project_name)
      end
      new = Map.new([transaction: merge_transaction, receipts: get_transaction_receipts])

      json  conn, %{status_code: "200", data: new}
    end
  end

  def getEmployeeTransactionV1(conn, params) do
    #      %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]
    get_transactions = Transactions
                       |> where([t], t.id == ^params["transactionId"])
                       |> order_by(desc: :transaction_date)
                       |> preload(:projects)
                       |> preload(:transactionsreceipt)
                       |> Repo.one

    render(conn, EmployeeView, "singletrans_project.json", transactions: get_transactions)
  end

  def balance(conn, params) do
    text  conn, "balance #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def documents(conn, params) do
    text  conn, "documents #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def address(conn, params) do
    text  conn, "address #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def contacts(conn, params) do
    text  conn, "contacts #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def notifications(conn, params) do
    text  conn, "notifications #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  def updateCardStatus(conn, params) do
    unless map_size(params) == 0 do
      get_card = Repo.get!(Employeecards, params["cardid"])
      changeset = %{status: params["new_status"], reason: params["reason"], change_status: "E"}
      new_changeset = Employeecards.changesetStatus(get_card, changeset)

      if get_card.change_status == "A" or get_card.change_status == "C" and get_card.status == "4" or get_card.status == "5" do
        json conn, %{status_code: "4003", messages: "Cannot change status of this card, contact Company!"}
      else

        # Call to accomplish
        request = %{urlid: get_card.accomplish_card_id, status: params["new_status"]}
        response = Accomplish.activate_deactive_card(request)

        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" or response_code == "3055" do
          case Repo.update(new_changeset) do
            {:ok, _commanall} -> if params["new_status"] == "1" do
                                   json conn, %{status_code: "200", messages: "Success, Card Activated!"}
                                 else
                                   json conn, %{status_code: "200", messages: "Success, Card Deactivated!"}
                                 end
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn,
               %{
                 status_code: response_code,
                 errors: %{
                   messages: response_message
                 }
               }
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "gets all cards(activated&locked only) of an employee from Employee table"
  def getEmployeeCards(conn, _params) do
    %{"id" => id} = conn.assigns[:current_user]

    employeecards = Repo.all(
      from e in Employeecards, where: e.employee_id == ^id and e.status != "5" and e.status != "12"
    )
    render(conn, DashboardView, "employeecards.json", employeecards: employeecards)
  end

  def profileImage(conn, params) do
    text  conn, "profileImage #{params["companyId"]} #{params["id"]} #{params["cardId"]}"
  end

  @doc "Request for a new card"
  def requestCard(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "cid" => company_id, "id" => employee_id} = conn.assigns[:current_user]

      # fetch company id
      employee = Repo.get!(Employee, employee_id)

      carddata = Repo.one from r in Requestcard,
                          where: r.employee_id == ^employee_id and r.card_type == ^params["card_type"] and r.currencies_id == ^params["currency"] and r.status == "R",
                          select: %{
                            id: r.id
                          }
      currency = Repo.one from c in Companyaccounts,
                          where: c.company_id == ^company_id and c.currencies_id == ^params["currency"],
                          select: %{
                            currency_code: c.currency_code,
                            count: count(c.id)
                          }

      if currency.count == 0 do
        json conn,
             %{
               status_code: "4005",
               errors: %{
                 message: "selected currency unavailable."
               }
             }
      else
        if is_nil(carddata) do

          cardrequest = %{
            "company_id" => company_id,
            "employee_id" => employee_id,
            "currencies_id" => params["currency"],
            "currency" => currency.currency_code,
            "card_type" => params["card_type"],
            "reason" => params["reason"],
            "inserted_by" => commanid
          }
          requestcard_changeset = Requestcard.changeset(%Requestcard{}, cardrequest)

          case Repo.insert(requestcard_changeset) do
            {:ok, _response} ->

              company_info = Repo.one from cmn in Commanall, where: cmn.company_id == ^company_id,
                                                             select: %{
                                                               id: cmn.id,
                                                               email_id: cmn.email_id,
                                                               as_login: cmn.as_login
                                                             }

              mobile_info = Repo.one from mm in Contacts,
                                     where: mm.commanall_id == ^company_info.id and mm.is_primary == "Y",
                                     select: %{
                                       code: mm.code,
                                       contact_number: mm.contact_number,
                                     }
              device_info = Repo.one from dd in Devicedetails,
                                     where: dd.commanall_id == ^company_info.id and dd.is_delete == "N" and (
                                       dd.type == "A" or dd.type == "I"),
                                     select: %{
                                       token: dd.token,
                                       token_type: dd.type
                                     }

              company_name = Repo.one(
                from company in Company, where: company.id == ^company_id, select: company.company_name
              )
              card_type = if params["card_type"] == "V" do
                "virtual"
              else
                "physical"
              end
              #              #ALERTS DEPRECATED
              #              data = %{
              #                :section => "request_card",
              #                :commanall_id => company_info,
              #                :card_type => card_type,
              #                :employee_name => "#{employee.first_name} #{employee.last_name}",
              #                :currency => currency.currency_code,
              #                :company_name => company_name
              #              }
              #              AlertsController.sendEmail(data)
              #              AlertsController.sendNotification(data)
              #              AlertsController.sendSms(data)
              #              AlertsController.storeNotification(data)


              data = [
                %{
                  section: "request_card",
                  type: "E",
                  email_id: company_info.email_id,
                  data: %{
                    :card_type => card_type,
                    :employee_name => "#{employee.first_name} #{employee.last_name}",
                    :currency => currency.currency_code,
                    :company_name => company_name
                  }
                  # Content
                },
                %{
                  section: "request_card",
                  type: "S",
                  contact_code: if !is_nil(mobile_info) do
                    mobile_info.code
                  else
                    nil
                  end,
                  contact_number: if !is_nil(mobile_info) do
                    mobile_info.contact_number
                  else
                    nil
                  end,
                  data: %{
                    :card_type => card_type,
                    :employee_name => "#{employee.first_name} #{employee.last_name}",
                    :currency => currency.currency_code,
                    :company_name => company_name
                  }
                  # Content# Content
                },
                %{
                  section: "request_card",
                  type: "N",
                  token: if !is_nil(device_info) do
                    device_info.token
                  else
                    nil
                  end,
                  push_type: if !is_nil(device_info) do
                    device_info.token_type
                  else
                    nil
                  end, # "I" or "A"
                  login: company_info.as_login, # "Y" or "N"
                  data: %{
                    :card_type => card_type,
                    :employee_name => "#{employee.first_name} #{employee.last_name}",
                    :currency => currency.currency_code,
                    :company_name => company_name
                  }
                  # Content
                }
              ]
              V2AlertsController.main(data)

              render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Card Requested")
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn,
               %{
                 status_code: "4005",
                 errors: %{
                   message: "card already requested."
                 }
               }
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For Id Proof - mobApp"
  def uploadKycFirst(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => employee_id} = conn.assigns[:current_user]

      existingKycFirst = Repo.all(
        from e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == "I" and e.status == "A"
      )
      if existingKycFirst do
        from(e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == "I" and e.status == "A")
        |> Repo.update_all(
             set: [
               status: "D"
             ]
           )
      end

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

      kycdocuments = %{
        "commanall_id" => commanid,
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
      %{"commanall_id" => commanid, "id" => employee_id} = conn.assigns[:current_user]

      existingKycSecond = Repo.get_by(Kycdocuments, commanall_id: commanid, type: "A", status: "A")

      if existingKycSecond do
        update_it = %{"status" => "D"}
        existingKycSecondUPDATE = Kycdocuments.update_status(existingKycSecond, update_it)
        Repo.update(existingKycSecondUPDATE)
      end

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

      firstKycType = Repo.one from k in Kycdocuments,
                              where: k.commanall_id == ^commanid and k.type == "I" and k.status == "A",
                              select: k.documenttype_id

      if firstKycType do
        if firstKycType == 19 and String.to_integer(params["documenttype_id"]) == 21 do
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   documenttype_id: "Driving Licence already selected for ID Proof."
                 }
               }
        else
          image_bucket = Application.get_env(:violacorp, :aws_bucket)
          mode = Application.get_env(:violacorp, :aws_mode)
          region = Application.get_env(:violacorp, :aws_region)
          aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

          file_name = file_location_id
                      |> String.split(aws_url, trim: true)
                      |> Enum.join()

          kycdocuments = %{
            "commanall_id" => commanid,
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
              accomplish_response = TestController.create_employee(commanid, commanid)

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
                comman_all_data = Repo.one from c in Commanall, where: c.id == ^commanid,
                                                                select: %{
                                                                  accomplish_userid: c.accomplish_userid,
                                                                  employee_id: c.employee_id
                                                                }
                kyc_document = Repo.one from d in Kycdocuments,
                                        where: d.commanall_id == ^commanid and d.type == "I" and d.status == "A",
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
                #                emp_info = Repo.one from e in Employee, where: e.id == ^comman_all_data.employee_id,
                #                                                        select: %{
                #                                                          first_name: e.first_name,
                #                                                          last_name: e.last_name
                #                                                        }

                documenttype_id = if kyc_document.documenttype_id == "9" do
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
                  commanall_id: commanid,
                  issue_date: kyc_document.issue_date,
                  expiry_date: kyc_document.expiry_date,
                  type: documenttype_id,
                  number: kyc_document.document_number
                }
                _response = Accomplish.upload_identification(request)

                #                request_document = %{
                #                  user_id: comman_all_data.accomplish_userid,
                #                  commanall_id: commanid,
                #                  first_name: emp_info.first_name,
                #                  last_name: emp_info.last_name,
                #                  file_name: kyc_document.file_name,
                #                  file_extension: ".#{kyc_document.file_type}",
                #                  content: kyc_document.content
                #                }
                #
                #                _response_document = Accomplish.create_document(request_document)

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
        end
      else
        json conn, %{status_code: "4003", message: "KYC1 not found"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  @doc "For Id Proof - mobApp"
  def uploadeKycFirst(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => employee_id} = conn.assigns[:current_user]

      existingKycFirst = Repo.all(
        from e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == "I" and e.status == "A"
      )
      if existingKycFirst do
        from(e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == "I" and e.status == "A")
        |> Repo.update_all(
             set: [
               status: "D"
             ]
           )
      end

      kycdocuments = %{
        "commanall_id" => commanid,
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

            commanall = Repo.get!(Commanall, commanid)
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

              accomplish_response = TestController.create_employee(commanid, commanid)


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

                comman_all_data = Repo.one from c in Commanall, where: c.id == ^commanid,
                                                                select: %{
                                                                  accomplish_userid: c.accomplish_userid,
                                                                  employee_id: c.employee_id
                                                                }
                kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^commanid,
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
                  "commanall_id" => commanid,
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
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For Id Proof - mobApp"
  def uploadKycFirstV1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => employee_id} = conn.assigns[:current_user]

      employee = Repo.get!(Employee, employee_id)
      if ((employee.status == "IDINFO" or employee.status == "K1") and params["type"] == "I") or (
        employee.status == "ADINFO" and params["type"] == "A") do
        existingKycFirst = Repo.all(
          from e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == ^params["type"] and e.status == "A"
        )
        if existingKycFirst do
          from(e in Kycdocuments, where: e.commanall_id == ^commanid and e.type == ^params["type"] and e.status == "A")
          |> Repo.update_all(
               set: [
                 status: "R"
               ]
             )
        end

        existing = Repo.get_by(Kycdocuments, commanall_id: commanid, status: "A", type: params["type"])

        if !is_nil(existing) do

          user_step = cond do
            (employee.status == "IDINFO" or employee.status == "K1") and params["type"] == "I" -> "IDDOC1"
            employee.status == "ADINFO" and params["type"] == "A" -> "ADDOC1"
          end
          update_status = %{"status" => user_step}
          commanall_changeset = Employee.changesetStatus(employee, update_status)
          Repo.update(commanall_changeset)

          json conn,
               %{
                 status_code: "200",
                 data: "Success! Kyc Upload.",
                 document_id: existing.id
               }
        else

          kycdocuments = %{
            "commanall_id" => commanid,
            "documenttype_id" => params["documenttype_id"],
            "document_number" => params["document_number"],
            "expiry_date" => params["expiry_date"],
            "issue_date" => params["issue_date"],
            "country" => params["country"],
            "status" => "A",
            "type" => params["type"], # [I,A]
            "inserted_by" => commanid
          }
          changeset = case params["type"] do
            "A" -> Kycdocuments.changesetAddressProof(%Kycdocuments{}, kycdocuments)
            "I" -> Kycdocuments.changesetIDProof(%Kycdocuments{}, kycdocuments)
          end
          case Repo.insert(changeset) do
            {:ok, kyc} ->

              user_step = cond do
                (employee.status == "IDINFO" or employee.status == "K1") and params["type"] == "I" -> "IDDOC1"
                employee.status == "ADINFO" and params["type"] == "A" -> "ADDOC1"
              end
              update_status = %{"status" => user_step}
              commanall_changeset = Employee.changesetStatus(employee, update_status)
              Repo.update(commanall_changeset)

              json conn,
                   %{
                     status_code: "200",
                     data: "Success! Kyc Upload.",
                     document_id: kyc.id
                   }
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
                 message: "Please complete your information step first."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "For doc upload - mobApp"
  def uploadKycSecondV1(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => employee_id} = conn.assigns[:current_user]

      employee = Repo.get!(Employee, employee_id)
      if employee.status == "IDDOC1" or employee.status == "IDDOC2" or employee.status == "ADDOC1" do
        document_id = params["document_id"]
        check_data = Repo.one from k in Kycdocuments,
                              where: k.commanall_id == ^commanid and k.id == ^document_id and k.status == "A", select: k

        if !is_nil(check_data) do
          file_location_id = if params["content"] != "" do
            image_id = String.replace_leading(params["content"], "data:image/jpeg;base64,", "")
            ViolacorpWeb.Main.Assetstore.upload_image(image_id)
          else
            nil
          end
          file_name = if !is_nil(file_location_id) do
            Path.basename(file_location_id)
          else
            ""
          end
          kycdocuments = cond do
            is_nil(check_data.file_location) ->
              %{
                "file_location" => file_location_id,
                "file_name" => file_name,
                "status" => "A",
              }
            is_nil(check_data.file_location_two) -> %{
                                                      "file_location_two" => file_location_id
                                                    }
            true -> %{
                      "file_location" => file_location_id,
                      "file_name" => file_name,
                      "status" => "A",
                    }
          end
          kycdocuments_changeset = case check_data.type do
            "A" -> Kycdocuments.changesetAddressProof(check_data, kycdocuments)
            "I" -> Kycdocuments.changesetIDProof(check_data, kycdocuments)
          end

          case Repo.update(kycdocuments_changeset) do
            {:ok, _director} ->

              if employee.status == "ADDOC1" and check_data.type == "A" do
                check_status = TestController.employee_verify_GBG(commanid)
                #                  check_status = Accomplish.register_fourstop(employee_id)
                if check_status["status"] == "200" do

                  accomplish_response = TestController.create_employee(commanid, commanid)

#                  update_status = if accomplish_response == "200" do
#                    %{"status" => "A"}
#                  else
#                    %{"status" => "AP"}
#                  end
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

#                  commanall_changeset = Employee.changesetStatus(employee, update_status)
#                  Repo.update(commanall_changeset)

                  if accomplish_response == "200" do

                    comman_all_data = Repo.one from c in Commanall, where: c.id == ^commanid,
                                                                    select: %{
                                                                      accomplish_userid: c.accomplish_userid,
                                                                      employee_id: c.employee_id
                                                                    }
                    kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^commanid,
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
                      "commanall_id" => commanid,
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
              else
                user_step = cond do
                  employee.status == "IDDOC1" and check_data.type == "I" -> "IDDOC2"
                  employee.status == "IDDOC2" and check_data.type == "I" -> "ADINFO"
                end
                changeset_step = %{"status" => user_step}
                changeset = Employee.changesetStatus(employee, changeset_step)
                Repo.update(changeset)
              end

              json conn,
                   %{
                     status_code: "200",
                     data: "Success! Kyc Upload."
                   }
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn, %{status_code: "4003", message: "KYC not found"}
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
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "gets all details of an employee (personal info + cards"
  def getEmployeeProfile(conn, _params) do
    %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]

    employee_comman_data = Repo.one from commanall in Commanall, where: commanall.id == ^commanid,
                                                                 left_join: address in assoc(commanall, :address),
                                                                 where: address.is_primary == "Y",
                                                                 left_join: contacts in assoc(commanall, :contacts),
                                                                 where: contacts.is_primary == "Y",
                                                                 left_join: employee in assoc(commanall, :employee),
                                                                 select: %{
                                                                   email_id: commanall.email_id,
                                                                   address_line_one: address.address_line_one,
                                                                   address_line_two: address.address_line_two,
                                                                   city: address.city,
                                                                   town: address.town,
                                                                   post_code: address.post_code,
                                                                   county: address.county,
                                                                   contact_number: contacts.contact_number,
                                                                   code: contacts.code,
                                                                   first_name: employee.first_name,
                                                                   last_name: employee.last_name,
                                                                   date_of_birth: employee.date_of_birth,
                                                                   gender: employee.gender,
                                                                   title: employee.title,
                                                                   employee_id: employee.id
                                                                 }
    employee_cards = Repo.all from e in Employeecards, where: e.employee_id == ^empid and e.status != "5",
                                                       select: %{
                                                         id: e.id,
                                                         currency_code: e.currency_code,
                                                         card_number: e.card_number,
                                                         expiry_date: e.expiry_date,
                                                         name_on_card: e.name_on_card,
                                                         available_balance: e.available_balance,
                                                         current_balance: e.available_balance,
                                                         card_type: e.card_type,
                                                         status: e.status
                                                       }

    json conn, %{status_code: "200", employee_data: employee_comman_data, employee_cards: employee_cards}
  end


  def refreshBalance(conn, _params) do
    %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]

    # get accomplish user id
    commanall = Repo.one from c in Commanall, where: c.id == ^commanid and c.employee_id == ^empid,
                                              select: %{
                                                accomplish_userid: c.accomplish_userid
                                              }
    if !is_nil(commanall) do
        # call Load Pending Transaction method
        pending_load_params = %{
          "worker_type" => "pending_transactions_updater",
          "employee_id" => empid
        }
        success_load_params = %{
          "worker_type" => "success_transactions_updater",
          "employee_id" => empid
        }
        Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [pending_load_params], max_retries: 1)
        Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [success_load_params], max_retries: 1)

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
    else
        json conn, %{status_code: "404", message: "Record not found!"}
    end
  end

  def skipStep(conn, params) do
    %{"id" => employee_id} = conn.assigns[:current_user]
    employee = Repo.get!(Employee, employee_id)

    user_step = params["step"]
    changeset_step = %{"status" => user_step}
    changeset = Employee.changesetStatus(employee, changeset_step)
    case Repo.update(changeset) do
      {:ok, _party} -> json conn, %{status_code: "200", message: "Success! Skipped Step."}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "Assign a project to an employee"
  def assignProject(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]

      assignproject = %{
        "employee_id" => empid,
        "projects_id" => params["projects_id"],
        "inserted_by" => commanid
      }
      changeset = Assignproject.changeset(%Assignproject{}, assignproject)

      case Repo.insert(changeset) do
        {:ok, _response} -> render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Project Assigned.")
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "gets full card number details of a card"
  def get_cvv(conn, params) do
    %{"id" => empid} = conn.assigns[:current_user]

    employeecard = Repo.one from e in Employeecards, where: e.employee_id == ^empid and e.id == ^params["cardId"],
                                                     select: %{
                                                       accomplish_card_id: e.accomplish_card_id
                                                     }

    response = Accomplish.get_cvv(employeecard.accomplish_card_id)

    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      json conn,
           %{
             status_code: "200",
             data: %{
               card_number: response["info"]["number"],
               security_code: response["info"]["security"]["security_code"]
             }
           }
    else
      json conn,
           %{
             status_code: response_code,
             errors: %{
               message: response_message
             }
           }
    end
  end

  @doc "gets pin of a card"
  def get_pin(conn, params) do
    %{"id" => empid} = conn.assigns[:current_user]

    employeecard = Repo.one from e in Employeecards, where: e.employee_id == ^empid and e.id == ^params["cardId"],
                                                     select: %{
                                                       accomplish_card_id: e.accomplish_card_id
                                                     }

    response = Accomplish.get_cvv(employeecard.accomplish_card_id)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      status = response["info"]["status"]
      if status == "1" do
        json conn,
             %{
               status_code: "200",
               data: %{
                 card_number: response["info"]["number"],
                 pin: response["info"]["security"]["pin_code"]
               }
             }
      else
        json conn,
             %{
               status_code: response_code,
               errors: %{
                 message: response_message
               }
             }
      end
    else
      json conn,
           %{
             status_code: response_code,
             errors: %{
               message: response_message
             }
           }
    end
  end

  @doc "Requests an activation code for card activation"
  def requestCodeV1(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => empid} = conn.assigns[:current_user]

      last_digit = params["last_digit"]
      case Validatecard.valid?(last_digit) do
        true ->
          number = Commontools.lastfour(last_digit)
          employeecard = Repo.one from e in Employeecards, where: e.employee_id == ^empid and e.last_digit == ^number,
                                                           select: %{
                                                             last_digit: e.last_digit,
                                                             employee_id: e.employee_id,
                                                             activation_code: e.activation_code,
                                                             activation_key: e.accomplish_card_id,
                                                             status: e.status
                                                           }

          if employeecard == nil do
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Invalid Card Number"
                   }
                 }
          else

            # Check card status on accomplish
            account_id = employeecard.activation_key
            response = Accomplish.get_account(account_id)

            response_code = response["result"]["code"]
            response_message = response["result"]["friendly_message"]

            if response_code == "0000" do
              acc_status = response["info"]["status"]

              # Update Card Status
              get_card = Repo.get_by(Employeecards, accomplish_card_id: account_id)
              if get_card.status != acc_status do
                changeset = %{status: acc_status}
                new_changeset = Employeecards.changesetStatus(get_card, changeset)
                Repo.update(new_changeset)
              end

              if acc_status == "12" do
                employee = Repo.one from c in Employee, where: c.id == ^employeecard.employee_id,
                                                        left_join: commanall in assoc(c, :commanall),
                                                        select: %{
                                                          id: commanall.id,
                                                          first_name: c.first_name,
                                                          last_name: c.last_name
                                                        }

                act_code = String.split(employeecard.activation_code, "", trim: true)
                first_four = act_code
                             |> Enum.take(4)
                             |> Enum.join()
                last_four = act_code
                            |> Enum.take(-4)
                            |> Enum.join()
                newactcode = "#{first_four} #{last_four}"

                #                             DEPRECATED
                #                             data = %{
                #                               :section => "card_activate",
                #                               :commanall_id => employee.id,
                #                               :employee_name => "#{employee.first_name} #{employee.last_name}",
                #                               :activation_code => newactcode,
                #                               :card => employeecard.last_digit
                #                             }
                #                             AlertsController.sendEmail(data)
                #                             AlertsController.sendNotification(data)
                #                             AlertsController.sendSms(data)
                #                             AlertsController.storeNotification(data)

                commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employeecard.employee_id,
                                                             left_join: m in assoc(cmn, :contacts),
                                                             on: m.is_primary == "Y",
                                                             left_join: d in assoc(cmn, :devicedetails),
                                                             on: d.is_delete == "N" and (
                                                               d.type == "A" or d.type == "I"),
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
                    section: "card_activate",
                    type: "E",
                    email_id: commandata.email_id,
                    data: %{
                      :employee_name => "#{employee.first_name} #{employee.last_name}",
                      :activation_code => newactcode,
                      :card => employeecard.last_digit
                    }
                    # Content
                  },
                  %{
                    section: "card_activate",
                    type: "S",
                    contact_code: commandata.code,
                    contact_number: commandata.contact_number,
                    data: %{
                      :employee_name => "#{employee.first_name} #{employee.last_name}",
                      :activation_code => newactcode,
                      :card => employeecard.last_digit
                    }
                    # Content# Content
                  },
                  %{
                    section: "card_activate",
                    type: "N",
                    token: commandata.token,
                    push_type: commandata.token_type, # "I" or "A"
                    login: commandata.as_login, # "Y" or "N"
                    data: %{
                      :employee_name => "#{employee.first_name} #{employee.last_name}",
                      :activation_code => newactcode,
                      :card => employeecard.last_digit
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)

                json conn,
                     %{
                       status_code: "200",
                       data: %{
                         activation_key: "#{employeecard.activation_key}"
                       }
                     }
              else
                json conn, %{status_code: "201", message: "Card Activated."}
              end
            else
              json conn,
                   %{
                     status_code: "5004",
                     errors: %{
                       message: response_message
                     }
                   }
            end
          end
        false ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Invalid Card Number"
                 }
               }
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  def requestCode(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => empid} = conn.assigns[:current_user]

      last_digit = params["last_digit"]

      employeecard = Repo.one from e in Employeecards, where: e.employee_id == ^empid and e.last_digit == ^last_digit,
                                                       select: %{
                                                         last_digit: e.last_digit,
                                                         employee_id: e.employee_id,
                                                         activation_code: e.activation_code,
                                                         activation_key: e.accomplish_card_id,
                                                         status: e.status
                                                       }

      if employeecard == nil do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Invalid Card Number"
               }
             }
      else

        # Check card status on accomplish
        account_id = employeecard.activation_key
        response = Accomplish.get_account(account_id)

        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do
          acc_status = response["info"]["status"]

          # Update Card Status
          get_card = Repo.get_by(Employeecards, accomplish_card_id: account_id)
          if get_card.status != acc_status do
            changeset = %{status: acc_status}
            new_changeset = Employeecards.changesetStatus(get_card, changeset)
            Repo.update(new_changeset)
          end

          if acc_status == "12" do
            employee = Repo.one from c in Employee, where: c.id == ^employeecard.employee_id,
                                                    left_join: commanall in assoc(c, :commanall),
                                                    select: %{
                                                      id: commanall.id,
                                                      first_name: c.first_name,
                                                      last_name: c.last_name
                                                    }

            act_code = String.split(employeecard.activation_code, "", trim: true)
            first_four = act_code
                         |> Enum.take(4)
                         |> Enum.join()
            last_four = act_code
                        |> Enum.take(-4)
                        |> Enum.join()
            newactcode = "#{first_four} #{last_four}"

            commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^employeecard.employee_id,
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

            #                DEPRECATED
            #                data = %{
            #                  :section => "card_activate",
            #                  :commanall_id => employee.id,
            #                  :employee_name => "#{employee.first_name} #{employee.last_name}",
            #                  :activation_code => newactcode,
            #                  :card => employeecard.last_digit
            #                }
            #                AlertsController.sendEmail(data)
            #                AlertsController.sendNotification(data)
            #                AlertsController.sendSms(data)
            #                AlertsController.storeNotification(data)

            data = [
              %{
                section: "card_activate",
                type: "E",
                email_id: commandata.email_id,
                data: %{
                  :employee_name => "#{employee.first_name} #{employee.last_name}",
                  :activation_code => newactcode,
                  :card => employeecard.last_digit
                }
                # Content
              },
              %{
                section: "card_activate",
                type: "S",
                contact_code: commandata.code,
                contact_number: commandata.contact_number,
                data: %{
                  :employee_name => "#{employee.first_name} #{employee.last_name}",
                  :activation_code => newactcode,
                  :card => employeecard.last_digit
                }
                # Content# Content
              },
              %{
                section: "card_activate",
                type: "N",
                token: commandata.token,
                push_type: commandata.token_type, # "I" or "A"
                login: commandata.as_login, # "Y" or "N"
                data: %{
                  :employee_name => "#{employee.first_name} #{employee.last_name}",
                  :activation_code => newactcode,
                  :card => employeecard.last_digit
                }
                # Content
              }
            ]
            V2AlertsController.main(data)

            json conn,
                 %{
                   status_code: "200",
                   data: %{
                     activation_key: "#{employeecard.activation_key}"
                   }
                 }
          else
            json conn, %{status_code: "201", message: "Card Activated."}
          end
        else
          json conn,
               %{
                 status_code: "5004",
                 errors: %{
                   message: response_message
                 }
               }
        end
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Activates a card if activation key matches"
  def createCard(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid, "id" => empid} = conn.assigns[:current_user]

      activation_code = params["activation_code"]
      activation_key = params["activation_key"]
      employeecard = Repo.one from e in Employeecards,
                              where: e.employee_id == ^empid and e.accomplish_card_id == ^activation_key and e.activation_code == ^activation_code,
                              select: %{
                                status: e.status,
                                id: e.id
                              }

      if employeecard == nil do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Invalid Activation Code or Key"
               }
             }
      else
        if employeecard.status == "12" do
          # send to accomplish for change status
          request = %{urlid: activation_key, status: "1"}
          response = Accomplish.activate_deactive_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]
          if response_code == "0000" do
            get_card = Repo.get!(Employeecards, employeecard.id)
            changeset = %{status: "1"}
            new_changeset = Employeecards.changesetStatus(get_card, changeset)
            Repo.update(new_changeset)
            # Update commanall card_requested
            commanall_data = Repo.get!(Commanall, commanid)

            employeecards = Repo.all from a in Employeecards, where: a.employee_id == ^empid and a.status == "12",
                                                              select: count(a.id)
            _card_request = if employeecards == [0] do
              card_request = %{"card_requested" => "N"}
              changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
              Repo.update(changeset_commanall)
            end

            employee = Repo.get!(Employee, empid)
            [count_card] = Repo.all from d in Employeecards,
                                    where: d.employee_id == ^empid and (
                                      d.status == "1" or d.status == "4" or d.status == "12"),
                                    select: %{
                                      count: count(d.id)
                                    }
            new_number = %{"no_of_cards" => count_card.count}
            cards_changeset = Employee.updateEmployeeCardschangeset(employee, new_number)
            Repo.update(cards_changeset)

            json conn,
                 %{
                   status_code: "200",
                   data: %{
                     message: "Card Activated."
                   }
                 }
          else
            json conn,
                 %{
                   status_code: "5005",
                   errors: %{
                     message: response_message
                   }
                 }
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Card Already Approved."
                 }
               }
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "gets all company accounts of a company from Companyaccounts table"
  def companyAccounts(conn, _params) do
    %{"cid" => cid} = conn.assigns[:current_user]

    currencies = Repo.all (
                            from e in Companyaccounts,
                                 where: e.company_id == ^cid,
                                 select: %{
                                   id: e.currencies_id,
                                   currency_code: e.currency_code
                                 })

    json conn, %{status_code: "200", data: currencies}
  end

  @doc "gets all notifications for logged in user"
  def employeeNotification(conn, _params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    notifications = Repo.all from e in Notifications, where: e.commanall_id == ^commanid,
                                                      select: %{
                                                        id: e.id,
                                                        subject: e.subject,
                                                        message: e.message,
                                                        status: e.status,
                                                        date_time: e.inserted_at
                                                      }

    render(conn, ViolacorpWeb.SuccessView, "success.json", response: notifications)

  end

  @doc "gets all notifications for logged in user"
  def updateNotification(conn, _params) do

    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    from(e in Notifications, where: e.commanall_id == ^commanid)
    |> Repo.update_all(
         set: [
           status: "R"
         ]
       )

    render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Update all un-read notifications.")

  end

  @doc "gets all cards that are on pending activaton status"
  def employeePendingCards(conn, _params) do
    %{"id" => employee_id} = conn.assigns[:current_user]
    employeecards = Repo.all from a in Employeecards, where: a.employee_id == ^employee_id and a.status == "12",
                                                      select: count(a.id)
    results = if employeecards == [0] do
      "N"
    else
      "Y"
    end
    json conn, %{status_code: "200", data: results}
  end


  # employee registration
  def employeeDirectRegistration(conn, params) do
    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do
        employee_id = params["employeeId"]
        request_id = params["request_id"]

        # check emloyee id
        [check_id] = Repo.all from c in Commanall,
                              where: c.employee_id == ^employee_id and is_nil(c.accomplish_userid) and c.status == ^"A",
                              select: count(c.id)

        response = if check_id == 0 do
          %{
            status_code: "404",
            errors: %{
              message: "Employee already registered."
            }
          }
        else
          nil
        end

        if response == nil do
          # Update email id and mobile number
          commanall = Repo.get_by(Commanall, employee_id: employee_id)
          common_all_id = commanall.id

          # Send to third party data
          accomplish_response = TestController.create_employee(common_all_id, request_id)

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

          if accomplish_response == "200" do
            comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                            select: %{
                                                              accomplish_userid: c.accomplish_userid,
                                                              employee_id: c.employee_id
                                                            }
            kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^common_all_id,
                                                            where: d.type == "I" and d.status == "A",
                                                            limit: 1,
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
            #            request = %{
            #              user_id: comman_all_data.accomplish_userid,
            #              commanall_id: common_all_id,
            #              issue_date: kyc_document.issue_date,
            #              expiry_date: kyc_document.expiry_date,
            #              type: documenttype_id,
            #              number: kyc_document.document_number
            #            }
            #            _response = Accomplish.upload_identification(request)

            request = %{
              "worker_type" => "create_identification",
              "user_id" => comman_all_data.accomplish_userid,
              "commanall_id" => common_all_id,
              "issue_date" => kyc_document.issue_date,
              "expiry_date" => kyc_document.expiry_date,
              "number" => kyc_document.document_number,
              "type" => documenttype_id,
              "employee_id" => employee_id,
              "request_id" => request_id
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
          json conn, response
        end
      else
        json conn,
             %{
               status_code: "4002",
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

  @doc "Assign a project to an employee"
  def projectList(conn, _params) do

    %{"id" => employee_id} = conn.assigns[:current_user]

    [count] = Repo.all from a in Assignproject, where: a.employee_id == ^employee_id,
                                                select: count(a.id)

    project_list = Repo.all (
                              from a in Assignproject,
                                   where: a.employee_id == ^employee_id,
                                   left_join: p in assoc(a, :projects),
                                   order_by: [
                                     desc: a.inserted_at
                                   ],
                                   select: %{
                                     id: a.id,
                                     projects_id: a.projects_id,
                                     project_name: p.project_name,
                                     start_date: p.start_date
                                   })
    if count == 0 do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "No record found."
             }
           }
    else
      json conn, %{status_code: "200", data: project_list}
    end
  end


  @doc "forget pin function - two"
  def forgotPinTwo(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    unless map_size(params) == 0 do
      # otp, new_pin
      commanall = Repo.get!(Commanall, commanid)
      changeset = %{vpin: params["new_pin"]}
      new_changeset = Commanall.changeset_updatepin(commanall, changeset)

      getotp = Repo.one from o in Otp, where: o.commanall_id == ^commanid and o.otp_source == "Pin",
                                       select: o.otp_code
      otpdecode = Poison.decode!(getotp)

      if otpdecode["otp_code"] == params["otp_code"] do
        case Repo.update(new_changeset) do
          {:ok, _commanall} -> json conn, %{status_code: "200", messages: "Success, Pin updated"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4003", messages: "Incorrect OTP code"}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  #  get Single Requested Card
  def getSingleRequestedCard(conn, params) do

    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      cardId = params["cardId"]

      requestedcard = Repo.one(
        from rc in Requestcard, where: rc.id == ^cardId and rc.company_id == ^company_id and rc.status == "R",
                                left_join: employee in assoc(rc, :employee),
                                select: %{
                                  employee_id: employee.id,
                                  first_name: employee.first_name,
                                  last_name: employee.last_name,
                                  currency: rc.currency,
                                  card_type: rc.card_type,
                                  reason: rc.reason,
                                  inserted_by: rc.inserted_by,
                                  inserted_at: rc.inserted_at
                                }
      )
      if is_nil(requestedcard) do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "No record found."
               }
             }
      else
        json conn, %{status_code: "200", data: requestedcard}
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  #  get Single Requested Money
  def getSingleRequestedMoney(conn, params) do

    unless map_size(params) == 0 do
      %{"id" => company_id} = conn.assigns[:current_user]

      cardId = params["cardId"]

      requestedmoney = Repo.one(
        from rm in Requestmoney, where: rm.id == ^cardId and rm.company_id == ^company_id and rm.status == "R",
                                 left_join: employee in assoc(rm, :employee),
                                 left_join: employeecard in assoc(rm, :employeecards),
                                 select: %{
                                   employee_id: employee.id,
                                   first_name: employee.first_name,
                                   last_name: employee.last_name,
                                   currency: rm.cur_code,
                                   amount: rm.amount,
                                   reason: rm.reason,
                                   inserted_at: rm.inserted_at,
                                   card_number: employeecard.last_digit,
                                 }
      )
      if is_nil(requestedmoney) do
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "No record found."
               }
             }
      else
        json conn, %{status_code: "200", data: requestedmoney}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  # Check card status for pending activation & check KYC status
  def checkCardStatus(conn, _params) do

    %{"id" => employee_id} = conn.assigns[:current_user]

    commanall = Repo.get_by(Commanall, employee_id: employee_id)
    if !is_nil(commanall) do
      userid = commanall.accomplish_userid

      keyfortoken = Application.get_env(:violacorp, :tokenKey)
      user_id = commanall.employee_id

      cid = if commanall.company_id == nil do
        employee = Repo.get_by(Employee, id: user_id)
        employee.company_id
      else
        commanall.company_id
      end

      payload = %{
        "email" => commanall.email_id,
        "commanall_id" => commanall.id,
        "id" => user_id,
        "violaid" => commanall.viola_id,
        "cid" => cid
      }
      new_token = ViolacorpWeb.Main.MainController.create_token(keyfortoken, payload)

      # check kyc status
      employee = Repo.get!(Employee, employee_id)
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
      card_requested = if userid == nil do
        "Y"
      else
        # Update card requested
        check_activation = Repo.one from e in Employeecards,
                                    where: e.employee_id == ^employee_id and e.status == "12",
                                    select: count(e.id)
        if check_activation > 0 do
          commanall_data = Repo.get!(Commanall, commanall.id)
          card_request = %{"card_requested" => "Y"}
          changeset = Commanall.changesetRequest(commanall_data, card_request)
          Repo.update(changeset)
          "Y"
        else
          "N"
        end
      end

      check_version = commanall.check_version
      json conn,
           %{
             status_code: "200",
             token: new_token,
             kyc_status: employee.status,
             card_request: card_requested,
             ekyc: get_version.ekyc,
             version: Poison.encode!(version),
             appversion: getLatestAppVersion(),
             check_version: check_version
           }
    else
      json conn, %{ status_code: "4001", errors: %{ message: "InValid User" } }
    end
  end


  @doc "checks if the logged-in employee has any cards pending activation"
  def getPendingStatus(conn, _params) do

    %{"commanall_id" => commanid} = conn.assigns[:current_user]

    card_requested = Repo.one from c in Commanall, where: c.id == ^commanid, select: c.card_requested

    if card_requested do


      if card_requested == "Y" do
        json conn, %{status_code: "200", messages: "Card/s awaiting activation", card_requested: "Y"}
      else
        json conn, %{status_code: "4003", messages: "No card activation pending", card_requested: "N"}
      end

    else

      json conn, %{status_code: "4003", messages: "no user found"}
    end
  end


  # employee card manual transaction load
  def manualTransactions(conn, params) do
    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

        # call success and pending worker
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

        json conn,
             %{
               status_code: "200",
               message: "Manualy capture success & pending transactions."
             }

      else
        json conn,
             %{
               status_code: "4002",
               message: "You have not permission to any update, Please contact to administrator."
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             message: "No Parameter Found."
           }
    end
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

    check_mobile = Repo.get_by(Contacts, contact_number: params["contact_number"])
    if is_nil(check_mobile) do
      checknumber = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
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
            {:ok, otpmap} -> # ALERTS
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
                  contact_number: params["contact_number"],
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


              json conn, %{status_code: "200", messages: "Inserted New Contact OTP.", otp_id: otpmap.id}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          otp = Repo.get_by(Otp, commanall_id: checknumber.commanall_id, otp_source: "Contact")
          changeset = Otp.changeset(otp, otpmap)
          case Repo.update(changeset) do
            {:ok, _otpmap} -> # ALERTS
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
                  contact_number: params["contact_number"],
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

              json conn, %{status_code: "200", messages: "Updated Existing Contact OTP", otp_id: otp.id}
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
               message: "contact number used someone."
             }
           }
    end
  end

  @doc """
  change phone number Step two
  """
  def changeMobileStepTwo(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get_by(Commanall, id: commanid, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp,
                        where: o.commanall_id == ^commanid and o.otp_source == "Contact",
                        select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        contact_number = params["contact_number"]
        contact = Repo.get_by(Contacts, commanall_id: commanid, is_primary: "Y")
        mobile_changeset = %{contact_number: contact_number}
        changeset = Contacts.changeset_number(contact, mobile_changeset)
        if changeset.valid? do
          history = %{
            employee_id: commanall.employee_id,
            field_name: "Mobile",
            old_value: contact.contact_number,
            new_value: contact_number,
            inserted_by: commanall.employee_id
          }
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

                  employee_id = commanall.employee_id
                  employee_info = Repo.get_by(Employee, id: employee_id)
                  if !is_nil(employee_info.director_id) do
                    #                      director_data = Repo.get_by(Contactsdirectors, directors_id: employee_info.director_id, is_primary: "Y")
                    director_data = Repo.one(
                      from cd in Contactsdirectors, where: cd.directors_id == ^employee_info.director_id,
                                                    limit: 1,
                                                    select: cd
                    )
                    n_changeset = Contactsdirectors.changeset(director_data, mobile_changeset)
                    history = %{
                      directors_id: employee_info.director_id,
                      field_name: "Mobile",
                      old_value: director_data.contact_number,
                      new_value: contact_number,
                      inserted_by: commanall.employee_id
                    }
                    HistoryManagement.updateHistory(history)
                    Repo.update(n_changeset)
                  end
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

    check_email = Repo.one(
      from cmn in Commanall, where: cmn.email_id == ^params["email_id"],
                             left_join: c in assoc(cmn, :contacts),
                             on: c.is_primary == "Y",
                             left_join: d in assoc(cmn, :devicedetails),
                             on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                             preload: [
                               contacts: c,
                               devicedetails: d
                             ]
    )

    if is_nil(check_email) do
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
            #            # ALERTS DEPRECATED
            #            data = %{
            #              :section => "change_email",
            #              :email => params["email"],
            #              :commanall_id => commanid,
            #              :generate_otp => generate_otp
            #            }
            #            AlertsController.sendEmail(data)

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
                contact_code: if is_nil(Enum.at(check_email.contacts, 0)) do
                  nil
                else
                  Enum.at(check_email.contacts, 0).code
                end,
                contact_number: if is_nil(Enum.at(check_email.contacts, 0)) do
                  nil
                else
                  Enum.at(check_email.contacts, 0).contact_number
                end,
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              },
              %{
                section: "change_email",
                type: "N",
                token: if is_nil(check_email.devicedetails) do
                  nil
                else
                  check_email.devicedetails.token
                end,
                push_type: if is_nil(check_email.devicedetails) do
                  nil
                else
                  check_email.devicedetails.type
                end, # "I" or "A"
                login: check_email.as_login, # "Y" or "N"
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              }
            ]
            V2AlertsController.main(data)
            json conn, %{status_code: "200", messages: "Inserted New email OTP.", otp_id: otpmap.id}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        otp = Repo.get_by(Otp, commanall_id: commanid, otp_source: "Email")
        changeset = Otp.changeset(otp, otpmap)
        case Repo.update(changeset) do
          {:ok, _otpmap} ->
            #            # ALERTS DEPRECATED
            #            data = %{
            #              :section => "change_email",
            #              :email => params["email"],
            #              :commanall_id => commanid,
            #              :generate_otp => generate_otp
            #            }
            #            AlertsController.sendEmail(data)

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
                contact_code: if is_nil(Enum.at(check_email.contacts, 0)) do
                  nil
                else
                  Enum.at(check_email.contacts, 0).code
                end,
                contact_number: if is_nil(Enum.at(check_email.contacts, 0)) do
                  nil
                else
                  Enum.at(check_email.contacts, 0).contact_number
                end,
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              },
              %{
                section: "change_email",
                type: "N",
                token: if is_nil(check_email.devicedetails) do
                  nil
                else
                  check_email.devicedetails.token
                end,
                push_type: if is_nil(check_email.devicedetails) do
                  nil
                else
                  check_email.devicedetails.type
                end, # "I" or "A"
                login: check_email.as_login, # "Y" or "N"
                data: %{
                  :otp_code => generate_otp
                }
                # Content
              }
            ]
            V2AlertsController.main(data)


            json conn, %{status_code: "200", messages: "Updated Existing email OTP", otp_id: otp.id}
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
               message: "Email used someone."
             }
           }
    end
  end

  @doc """
  change email for company and employee
  """
  def changeEmailStepTwo(conn, params) do
    %{"commanall_id" => commanid} = conn.assigns[:current_user]
    commanall = Repo.get_by(Commanall, id: commanid, vpin: params["pin"])
    if !is_nil(commanall) do
      getotp = Repo.one from o in Otp, where: o.commanall_id == ^commanid and o.otp_source == "Email",
                                       select: o.otp_code
      otpdecode = Poison.decode!(getotp)
      if otpdecode["otp_code"] == params["otp_code"] do
        email_changeset = %{email_id: params["email_id"]}
        changeset = Commanall.changesetEmail(commanall, email_changeset)
        if changeset.valid? do
          history = %{
            employee_id: commanall.employee_id,
            field_name: "Email",
            old_value: commanall.email_id,
            new_value: params["email_id"],
            inserted_by: commanall.employee_id
          }
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

                  employee_id = commanall.employee_id
                  employee = Repo.get_by(Employee, id: employee_id)
                  if !is_nil(employee.director_id) do
                    director_data = Repo.get_by(Directors, id: employee.director_id)
                    n_changeset = Directors.update_email(director_data, email_changeset)
                    history = %{
                      directors_id: director_data.id,
                      field_name: "Email",
                      old_value: director_data.email_id,
                      new_value: params["email_id"],
                      inserted_by: employee_id
                    }
                    HistoryManagement.updateHistory(history)
                    Repo.update(n_changeset)
                  end
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
end