defmodule Violacorp.Workers.V1.Identification do

  import Ecto.Query
  alias Violacorp.Repo
  require Logger
  alias Violacorp.Mailer
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Versions
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Workers.SendEmail



  def perform(params) do
    case params["worker_type"] do
      "company_identification" ->
        Map.delete(params, "worker_type")
        |> company_identification()
      "company_identification1" ->
        Map.delete(params, "worker_type")
        |> company_identification1()
      "employee_identification" ->
        Map.delete(params, "worker_type")
        |> employee_identification()
      "update_trustlevel" ->
        Map.delete(params, "worker_type")
        |> update_trustlevel()
      "create_identification" ->
        Map.delete(params, "worker_type")
        |> create_identification()
      "company_block" ->
        Map.delete(params, "worker_type")
        |> company_block()
      "company_disable" ->
        Map.delete(params, "worker_type")
        |> company_disable()
      "company_enable" ->
        Map.delete(params, "worker_type")
        |> company_enable()
      _ ->
        Logger.warn("Worker: #{params["worker_type"]} not found in Identification")
        :ok
    end
  end

  @doc """
     company identification on accomplish
  """
  def company_identification(params) do
    check_identification = Repo.one(
      from log in Thirdpartylogs, where: log.commanall_id == ^params["commanall_id"]
                                         and like(log.section, "%Create Identification%") and
                                         log.status == ^"S",
                                  limit: 1,
                                  select: log
    )
    if is_nil(check_identification) do

      request = %{
        user_id: params["user_id"],
        commanall_id: params["commanall_id"],
        issue_date: params["issue_date"],
        expiry_date: params["expiry_date"],
        number: params["number"],
        type: params["type"],
        verification_status: params["verification_status"],
        request_id: params["request_id"],
      }

      response_identify = Accomplish.upload_identification(request)
      response_code = response_identify["result"]["code"]
      response_message = response_identify["result"]["friendly_message"]
      commonall_id = params["commanall_id"]
      company_detail = Repo.get_by(Commanall, id: commonall_id)
      company = Repo.get(Company, company_detail.company_id)

      if response_code == "0000" do

        _emaildata = %{
                       :from => "no-reply@violacorporate.com",
                       :to => company_detail.email_id,
                       :subject => "Your ViolaCorporate account is ready",
                       :company_name => company.company_name,
                       :templatefile => "new_global_template.html",
                       :layoutfile => "company_registration_welcome.html"
                     }
                     |> Violacorp.Workers.SendEmail.sendemail()
                     |> Mailer.deliver_later()

        company_id = company.id
        get_director = Repo.one(
          from d in Directors, where: d.company_id == ^company_id and d.is_primary == "Y",
                               select: %{
                                 id: d.id,
                                 first_name: d.first_name,
                                 last_name: d.last_name
                               }
        )
        if !is_nil(get_director) do
          director_id = get_director.id
          #        check_override = Repo.one(from ky in Kycdirectors, where: ky.directors_id == ^director_id and ky.status == "A" and not is_nil(ky.refered_id), select: count(ky.id))
          #        if check_override > 0 do
          id_document = Repo.one from k in Kycdirectors,
                                 where: k.directors_id == ^director_id and k.status == "A" and k.type == "I",
                                 select: %{
                                   id: k.id,
                                   documenttype_id: k.documenttype_id,
                                   document_number: k.document_number,
                                   expiry_date: k.expiry_date,
                                   file_location: k.file_location,
                                   issue_date: k.issue_date,
                                 }

          # call worker for Id proof
          if !is_nil(id_document) do
            file_data = id_document.file_location
            if !is_nil(file_data) do
              %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
              content = Base.encode64(body)
              file_extension = Path.extname(file_data)

              type = case id_document.documenttype_id do
                19 -> "4"
                10 -> "2"
                9 -> "3"
                _ -> "3"
              end

              file_name = case id_document.documenttype_id do
                19 -> "Driving Licence"
                10 -> "Passport"
                9 -> "National ID"
                _ -> "National ID"
              end

              request = %{
                user_id: params["user_id"],
                commanall_id: commonall_id,
                first_name: get_director.first_name,
                last_name: get_director.last_name,
                type: type,
                subject: "#{file_name}",
                entity: 25,
                file_name: file_name,
                file_extension: file_extension,
                content: content,
                document_id: id_document.id,
                request_id: params["request_id"],
                worker_type: "company_id_proof",
              }
              #            Exq.enqueue_in(Exq, "documentupload", 15, Documentupload, [request])
              Exq.enqueue_in(Exq, "upload_document", 10, Violacorp.Workers.V1.UploadDocument, [request])
            end
          end
        end
      else
        version = Repo.get(Versions, "1")
        email = version.dev_email

        status_map = %{"status" => "P"}
        updateStatus = Commanall.updateStatus(company_detail, status_map)
        Repo.update(updateStatus)

        company = Repo.get(Company, company_detail.company_id)
        data = %{
          status_code: response_code,
          message: response_message,
          commmanall_id: commonall_id,
          company_name: company.company_name
        }

        _emaildata = %{
                       :from => "no-reply@violacorporate.com",
                       :to => "#{email}",
                       :subject => "VCorp Company Create Identification Error.",
                       :data => data,
                       :templatefile => "company_error_notification.html",
                       :layoutfile => "company_error_notification.html"
                     }
                     |> Violacorp.Workers.SendEmail.sendemail()
                     |> Mailer.deliver_later()
      end
    end
  end

  @doc """
     employee identification on accomplish
  """
  def employee_identification(params) do
    # check Identification uploaded or not
    commanall_id = params["commanall_id"]
    check_identification = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Create Identification%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_identification) do
      request = %{
        user_id: params["user_id"],
        commanall_id: params["commanall_id"],
        issue_date: params["issue_date"],
        expiry_date: params["expiry_date"],
        type: params["type"],
        verification_status: params["verification_status"],
        number: params["number"],
        request_id: params["request_id"],
      }

      employee_id = params["employee_id"]

      employee = Repo.get(Employee, employee_id)
      _emp_company_id = employee.company_id

      response_identify = Accomplish.upload_identification(request)
      response_code = response_identify["result"]["code"]
      response_message = response_identify["result"]["friendly_message"]

      if response_code == "0000" do

        id_document = Repo.one from k in Kycdocuments,
                               where: k.commanall_id == ^params["commanall_id"] and k.status == "A" and k.type == "I",
                               limit: 1,
                               select: %{
                                 id: k.id,
                                 documenttype_id: k.documenttype_id,
                                 document_number: k.document_number,
                                 expiry_date: k.expiry_date,
                                 file_location: k.file_location,
                                 issue_date: k.issue_date,
                               }

        # call worker for Id proof
        if !is_nil(id_document) do
          file_data = id_document.file_location
          if !is_nil(file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
            content = Base.encode64(body)
            file_extension = Path.extname(file_data)

            type = case id_document.documenttype_id do
              19 -> "4"
              10 -> "2"
              9 -> "3"
              _ -> "3"
            end

            file_name = case id_document.documenttype_id do
              19 -> "Driving Licence"
              10 -> "Passport"
              9 -> "National ID"
              _ -> "National ID"
            end

            request = %{
              user_id: params["user_id"],
              employee_id: params["employee_id"],
              commanall_id: params["commanall_id"],
              first_name: employee.first_name,
              last_name: employee.last_name,
              type: type,
              subject: "#{file_name}",
              entity: 25,
              file_name: file_name,
              file_extension: file_extension,
              content: content,
              document_id: id_document.id,
              request_id: params["request_id"],
              worker_type: "employee_id_proof"
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
          end
        end

        _response = response_message
      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)

        version = Repo.get(Versions, "1")
        #          email_type = Application.get_env(:violacorp, :error_notification)

        email = version.dev_email
        #          employee_id = employee.id
        #          employee_name = "#{employee.first_name} #{employee.last_name}"

        data = %{
          status_code: response_code,
          message: response_message,
          employee_id: employee.id,
          employee_name: "#{employee.first_name} #{employee.last_name}"
        }

        _emaildata = %{
                       :from => "no-reply@violacorporate.com",
                       :to => "#{email}",
                       :subject => "VCorp Create Identification Error.",
                       :data => data,
                       :templatefile => "error_notification.html",
                       :layoutfile => "error_notification.html"
                     }
                     |> Violacorp.Workers.SendEmail.sendemail()
                     |> Mailer.deliver_later()

        _response = response_message
      end
    end
  end

  @doc """
     company identification on accomplish
  """
  def company_identification1(params) do

    request = %{
      user_id: params["user_id"],
      commanall_id: params["commanall_id"],
      issue_date: params["issue_date"],
      expiry_date: params["expiry_date"],
      number: params["number"],
      type: params["type"],
      verification_status: params["verification_status"]
    }

    response_identify = Accomplish.upload_identification(request)
    response_code = response_identify["result"]["code"]
    response_message = response_identify["result"]["friendly_message"]

    commonall_id = params["commanall_id"]
    company_detail = Repo.get_by(Commanall, id: commonall_id)
    company = Repo.get(Company, company_detail.company_id)

    if response_code == "0000" do

      #      # Create Family Group
      #      _output = FamilyController.createFamily(commonall_id)

      status_map = %{"status" => "A"}
      updateStatus = Commanall.updateStatus(company_detail, status_map)
      Repo.update(updateStatus)

      _response = response_message
      _emaildata = %{
                     :from => "no-reply@violacorporate.com",
                     :to => company_detail.email_id,
                     :subject => "Your ViolaCorporate account is ready",
                     :company_name => company.company_name,
                     :templatefile => "new_global_template.html",
                     :layoutfile => "company_registration_welcome.html"
                   }
                   |> SendEmail.sendemail()
                   |> Mailer.deliver_later()

      company_id = company.id
      get_director = Repo.one(
        from d in Directors, where: d.company_id == ^company_id and d.is_primary == "Y",
                             select: %{
                               id: d.id,
                               first_name: d.first_name,
                               last_name: d.last_name
                             }
      )
      if !is_nil(get_director) do
        director_id = get_director.id
        #        check_override = Repo.one(from ky in Kycdirectors, where: ky.directors_id == ^director_id and ky.status == "A" and not is_nil(ky.refered_id), select: count(ky.id))
        #        if check_override > 0 do
        id_document = Repo.one from k in Kycdirectors,
                               where: k.directors_id == ^director_id and k.status == "A" and k.type == "I",
                               select: %{
                                 id: k.id,
                                 documenttype_id: k.documenttype_id,
                                 document_number: k.document_number,
                                 expiry_date: k.expiry_date,
                                 file_location: k.file_location,
                                 issue_date: k.issue_date,
                               }
        address_document = Repo.one from ak in Kycdirectors,
                                    where: ak.directors_id == ^director_id and ak.status == "A" and ak.type == "A",
                                    select: %{
                                      id: ak.id,
                                      address_file_location: ak.file_location,
                                      address_documenttype_id: ak.documenttype_id
                                    }
        # call worker for Id proof
        if !is_nil(id_document) do
          file_data = id_document.file_location
          if !is_nil(file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
            content = Base.encode64(body)
            file_extension = Path.extname(file_data)

            type = case id_document.documenttype_id do
              19 -> "4"
              10 -> "2"
              9 -> "3"
              _ -> "3"
            end

            file_name = case id_document.documenttype_id do
              19 -> "Driving Licence"
              10 -> "Passport"
              9 -> "National ID"
              _ -> "National ID"
            end

            request = %{
              user_id: params["user_id"],
              commanall_id: commonall_id,
              first_name: get_director.first_name,
              last_name: get_director.last_name,
              type: type,
              subject: "#{file_name}",
              entity: 25,
              file_name: file_name,
              file_extension: file_extension,
              content: content,
              document_id: id_document.id
            }
            Exq.enqueue_in(Exq, "documentupload", 15, Documentupload, [request])
          end
        end

        # call worker for address proof
        if !is_nil(address_document) do
          address_file_data = address_document.address_file_location
          if !is_nil(address_file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(address_file_data)
            address_content = Base.encode64(body)
            address_file_extension = Path.extname(address_file_data)

            address_type = case address_document.address_documenttype_id do
              1 -> "5"
              2 -> "10"
              21 -> "4"
              4 -> "7"
              _ -> "5"
            end

            document_name = case address_document.address_documenttype_id do
              1 -> "Utility Bill"
              2 -> "Council Tax"
              21 -> "Driving Licence"
              4 -> "Bank Statement"
              _ -> "Utility Bill"
            end

            request = %{
              user_id: params["user_id"],
              commanall_id: commonall_id,
              first_name: get_director.first_name,
              last_name: get_director.last_name,
              type: address_type,
              subject: "#{document_name}",
              entity: 15,
              file_name: document_name,
              file_extension: address_file_extension,
              content: address_content,
              document_id: address_document.id
            }
            Exq.enqueue_in(Exq, "documentupload", 25, Documentupload, [request])
          end
        end

        #        end

      end
    else
      version = Repo.get(Versions, "1")
      email = version.dev_email

      status_map = %{"status" => "P"}
      updateStatus = Commanall.updateStatus(company_detail, status_map)
      Repo.update(updateStatus)

      company = Repo.get(Company, company_detail.company_id)
      data = %{
        status_code: response_code,
        message: response_message,
        commmanall_id: commonall_id,
        company_name: company.company_name
      }

      _emaildata = %{
                     :from => "no-reply@violacorporate.com",
                     :to => "#{email}",
                     :subject => "VCorp Company Create Identification Error.",
                     :data => data,
                     :templatefile => "company_error_notification.html",
                     :layoutfile => "company_error_notification.html"
                   }
                   |> SendEmail.sendemail()
                   |> Mailer.deliver_later()
    end
  end

  @doc """
     update trust level
  """
  def update_trustlevel(params) do

    commanall_id = params["commanall_id"]
    user_id = params["user_id"]

    # get information
    comman_data = Repo.get!(Commanall, commanall_id)

    response = Accomplish.get_user(user_id)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do

      trust_level = %{trust_level: response["security"]["trust_level"]}
      changeset_commanall = Commanall.updateTrustLevel(comman_data, trust_level)
      case Repo.update(changeset_commanall) do
        {:ok, _data} -> Logger.warn "Update Trust level call: Response Trust Level Updated."
        {:error, changeset} -> Logger.warn "Update Trust level call: validation issue #{~s(#{changeset})}"
      end
    else
      Logger.warn "Update Trust level call: Failed Response #{response_message}"
    end
  end

  @doc """
     create identification
  """
  def create_identification(params) do

    # check Identification uploaded or not
    commanall_id = params["commanall_id"]
    check_identification = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Create Identification%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_identification) do
      request = %{
        user_id: params["user_id"],
        commanall_id: params["commanall_id"],
        issue_date: params["issue_date"],
        expiry_date: params["expiry_date"],
        type: params["type"],
        verification_status: params["verification_status"],
        number: params["number"],
        request_id: params["request_id"],
      }

      employee_id = params["employee_id"]

      employee = Repo.get(Employee, employee_id)
      _emp_company_id = employee.company_id

      response_identify = Accomplish.upload_identification(request)
      response_code = response_identify["result"]["code"]
      response_message = response_identify["result"]["friendly_message"]

      if response_code == "0000" do

        id_document = Repo.one from k in Kycdocuments,
                               where: k.commanall_id == ^params["commanall_id"] and k.status == "A" and k.type == "I",
                               limit: 1,
                               select: %{
                                 id: k.id,
                                 documenttype_id: k.documenttype_id,
                                 document_number: k.document_number,
                                 expiry_date: k.expiry_date,
                                 file_location: k.file_location,
                                 issue_date: k.issue_date,
                               }

        # call worker for Id proof
        if !is_nil(id_document) do
          file_data = id_document.file_location
          if !is_nil(file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
            content = Base.encode64(body)
            file_extension = Path.extname(file_data)

            type = case id_document.documenttype_id do
              19 -> "4"
              10 -> "2"
              9 -> "3"
              _ -> "3"
            end

            file_name = case id_document.documenttype_id do
              19 -> "Driving Licence "
              10 -> "Passport"
              9 -> "National ID"
              _ -> "National ID"
            end

            request = %{
              worker_type: "employee_id_proof",
              user_id: params["user_id"],
              employee_id: params["employee_id"],
              commanall_id: params["commanall_id"],
              first_name: employee.first_name,
              last_name: employee.last_name,
              type: type,
              subject: "#{file_name}",
              entity: 25,
              file_name: file_name,
              file_extension: file_extension,
              content: content,
              document_id: id_document.id,
              request_id: params["request_id"]
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
          end
        end

        _response = response_message
      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)

        version = Repo.get(Versions, "1")
        #          email_type = Application.get_env(:violacorp, :error_notification)

        email = version.dev_email
        #          employee_id = employee.id
        #          employee_name = "#{employee.first_name} #{employee.last_name}"

        data = %{
          status_code: response_code,
          message: response_message,
          employee_id: employee.id,
          employee_name: "#{employee.first_name} #{employee.last_name}"
        }

        _emaildata = %{
                       :from => "no-reply@violacorporate.com",
                       :to => "#{email}",
                       :subject => "VCorp Create Identification Error.",
                       :data => data,
                       :templatefile => "error_notification.html",
                       :layoutfile => "error_notification.html"
                     }
                     |> SendEmail.sendemail()
                     |> Mailer.deliver_later()

        _response = response_message
      end
    end
  end

  @doc """
     Block Company Worker
  """
  def company_block(params) do
    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    admin_id = params["admin_id"]

    # check Company Bank Account
    get_bank_account = Repo.one(
      from cb in Companybankaccount,
      where: cb.company_id == ^company_id and cb.currency == ^"GBP" and not is_nil(cb.account_id) and cb.status != ^"B"
    )
    if !is_nil(get_bank_account) do
      # Call Clear Bank
      body_string = %{
                      "status" => "Closed",
                      "statusReason" => "Other"
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})
      request = %{
        commanall_id: commanall_id,
        requested_by: admin_id,
        account_id: get_bank_account.account_id,
        body: string
      }
      res = Clearbank.account_status(request)
      if res["status_code"] == "204" or res["status_code"] == "409" do

        # Update Account Status
        changeset = %{status: "B"}
        new_acc_changeset = Companybankaccount.changesetStatus(get_bank_account, changeset)
        Repo.update(new_acc_changeset)

        company_info = %{
          "worker_type" => "company_block",
          "admin_id" => admin_id,
          "commanall_id" => commanall_id,
          "company_id" => company_id
        }
        Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
      end
    else

      # check company card management account
      get_account = Repo.one(
        from a in Companyaccounts,
        where: a.company_id == ^company_id and not is_nil(a.accomplish_account_id) and a.status != ^"5",
        limit: 1,
        select: a
      )
      if !is_nil(get_account) do
        request = %{urlid: get_account.accomplish_account_id, status: "6"}
        response = Accomplish.activate_deactive_card(request)
        response_code = response["result"]["code"]
        if response_code == "0000" or response_code == "3055" or response_code == "3030" do
          # Update Account Status
          changeset_account = %{status: "5"}
          new_acc_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_acc_changeset)

          company_info = %{
            "worker_type" => "company_block",
            "admin_id" => admin_id,
            "commanall_id" => commanall_id,
            "company_id" => company_id
          }
          Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
        else
          changeset_account = %{reason: response["result"]["friendly_message"]}
          new_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_changeset)
        end
      else
        # check company employee
        status_var = ["B", "K1", "K2", "K1", "AP", "IDINFO", "K2", "ADINFO", "IDDOC1", "IDDOC2", "ADDOC1"]
        get_employee = Repo.one(
          from emp in Employee, where: emp.company_id == ^company_id and emp.status not in ^status_var,
                                limit: 1,
                                select: emp
        )
        if !is_nil(get_employee) do

          # check employee card
          get_emp_card = Repo.one(
            from card in Employeecards,
            where: card.employee_id == ^get_employee.id and (card.status != ^"12" and card.status != ^"5"),
            limit: 1,
            select: card
          )
          if !is_nil(get_emp_card) do
            request = %{urlid: get_emp_card.accomplish_card_id, status: "6"}
            response = Accomplish.activate_deactive_card(request)
            response_code = response["result"]["code"]
            if response_code == "0000" or response_code == "3055" or response_code == "3030" do
              # Update Account Status
              changeset_card = %{status: "5", change_status: "A"}
              new_acc_changeset = Employeecards.changesetCardStatus(get_emp_card, changeset_card)
              Repo.update(new_acc_changeset)

              company_info = %{
                "worker_type" => "company_block",
                "admin_id" => admin_id,
                "commanall_id" => commanall_id,
                "company_id" => company_id
              }
              Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
            else
              changeset_card = %{reason: response["result"]["friendly_message"]}
              new_changeset = Employeecards.changesetStatus(get_emp_card, changeset_card)
              Repo.update(new_changeset)
            end
          else
            changeset_employee = %{status: "B"}
            new_changeset = Employee.changesetStatus(get_employee, changeset_employee)
            Repo.update(new_changeset)

            commanall_info = Repo.one(
              from empc in Commanall, where: empc.employee_id == ^get_employee.id and empc.status != ^"B",
                                      limit: 1,
                                      select: empc
            )
            if !is_nil(commanall_info) do
              changeset_emp = %{status: "B", api_token: nil, m_api_token: nil}
              new_changeset = Commanall.updateStatus(commanall_info, changeset_emp)
              Repo.update(new_changeset)
            end

            company_info = %{
              "worker_type" => "company_block",
              "admin_id" => admin_id,
              "commanall_id" => commanall_id,
              "company_id" => company_id
            }
            Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
          end
        else
          # update company status
          commanall_company = Repo.one(
            from com in Commanall, where: com.id == ^commanall_id and com.status != ^"B", limit: 1, select: com
          )
          if !is_nil(commanall_company) do
            changeset_company = %{status: "B", api_token: nil, m_api_token: nil}
            new_changeset = Commanall.updateStatus(commanall_company, changeset_company)
            Repo.update(new_changeset)
          end
        end
      end
    end
  end

  @doc """
     Disable Company Worker
  """
  def company_disable(params) do
    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    admin_id = params["admin_id"]

    # check Company Bank Account
    get_bank_account = Repo.one(
      from cb in Companybankaccount,
      where: cb.company_id == ^company_id and cb.currency == ^"GBP" and not is_nil(cb.account_id) and cb.status != ^"D"
    )
    if !is_nil(get_bank_account) do
      # Call Clear Bank
      body_string = %{
                      "status" => "Suspended",
                      "statusReason" => "Other"
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})
      request = %{
        commanall_id: commanall_id,
        requested_by: admin_id,
        account_id: get_bank_account.account_id,
        body: string
      }
      res = Clearbank.account_status(request)
      if res["status_code"] == "204" or res["status_code"] == "409" do

        # Update Account Status
        changeset = %{status: "D"}
        new_acc_changeset = Companybankaccount.changesetStatus(get_bank_account, changeset)
        Repo.update(new_acc_changeset)

        company_info = %{
          "worker_type" => "company_disable",
          "admin_id" => admin_id,
          "commanall_id" => commanall_id,
          "company_id" => company_id
        }
        Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
      end
    else

      # check company card management account
      get_account = Repo.one(
        from a in Companyaccounts,
        where: a.company_id == ^company_id and not is_nil(a.accomplish_account_id) and a.status != ^"4",
        limit: 1,
        select: a
      )
      if !is_nil(get_account) do
        request = %{urlid: get_account.accomplish_account_id, status: "4"}
        response = Accomplish.activate_deactive_card(request)
        response_code = response["result"]["code"]
        if response_code == "0000" or response_code == "3055" or response_code == "3030" do
          # Update Account Status
          changeset_account = %{status: "4"}
          new_acc_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_acc_changeset)

          company_info = %{
            "worker_type" => "company_disable",
            "admin_id" => admin_id,
            "commanall_id" => commanall_id,
            "company_id" => company_id
          }
          Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
        else
          changeset_account = %{reason: response["result"]["friendly_message"]}
          new_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_changeset)
        end
      else
        # check company employee
        status_var = ["D", "K1", "K2", "K1", "AP", "IDINFO", "K2", "ADINFO", "IDDOC1", "IDDOC2", "ADDOC1"]
        get_employee = Repo.one(
          from emp in Employee, where: emp.company_id == ^company_id and emp.status not in ^status_var,
                                limit: 1,
                                select: emp
        )
        if !is_nil(get_employee) do

          # check employee card
          get_emp_card = Repo.one(
            from card in Employeecards,
            where: card.employee_id == ^get_employee.id and (card.status != ^"12" and card.status != ^"4"),
            limit: 1,
            select: card
          )
          if !is_nil(get_emp_card) do
            request = %{urlid: get_emp_card.accomplish_card_id, status: "4"}
            response = Accomplish.activate_deactive_card(request)
            response_code = response["result"]["code"]
            if response_code == "0000" or response_code == "3055" or response_code == "3030" do
              # Update Account Status
              changeset_card = %{status: "4", change_status: "A"}
              new_acc_changeset = Employeecards.changesetCardStatus(get_emp_card, changeset_card)
              Repo.update(new_acc_changeset)

              company_info = %{
                "worker_type" => "company_disable",
                "admin_id" => admin_id,
                "commanall_id" => commanall_id,
                "company_id" => company_id
              }
              Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
            else
              changeset_card = %{reason: response["result"]["friendly_message"]}
              new_changeset = Employeecards.changesetStatus(get_emp_card, changeset_card)
              Repo.update(new_changeset)
            end
          else
            changeset_employee = %{status: "D"}
            new_changeset = Employee.changesetStatus(get_employee, changeset_employee)
            Repo.update(new_changeset)

            commanall_info = Repo.one(
              from empc in Commanall, where: empc.employee_id == ^get_employee.id and empc.status != ^"D",
                                      limit: 1,
                                      select: empc
            )
            if !is_nil(commanall_info) do
              changeset_emp = %{status: "D", api_token: nil, m_api_token: nil}
              new_changeset = Commanall.updateStatus(commanall_info, changeset_emp)
              Repo.update(new_changeset)
            end

            company_info = %{
              "worker_type" => "company_disable",
              "admin_id" => admin_id,
              "commanall_id" => commanall_id,
              "company_id" => company_id
            }
            Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
          end
        else
          # update company status
          commanall_company = Repo.one(
            from com in Commanall, where: com.id == ^commanall_id and com.status != ^"D", limit: 1, select: com
          )
          if !is_nil(commanall_company) do
            changeset_company = %{status: "D", api_token: nil, m_api_token: nil}
            new_changeset = Commanall.updateStatus(commanall_company, changeset_company)
            Repo.update(new_changeset)
          end
        end
      end
    end
  end

  @doc """
     Enable Company Worker company_enable
  """
  def company_enable(params) do
    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    admin_id = params["admin_id"]

    # check Company Bank Account
    get_bank_account = Repo.one(
      from cb in Companybankaccount,
      where: cb.company_id == ^company_id and cb.currency == ^"GBP" and not is_nil(cb.account_id) and cb.status != ^"A"
    )
    if !is_nil(get_bank_account) do
      # Call Clear Bank
      body_string = %{
                      "status" => "Enabled",
                      "statusReason" => "NotProvided"
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})
      request = %{
        commanall_id: commanall_id,
        requested_by: admin_id,
        account_id: get_bank_account.account_id,
        body: string
      }
      res = Clearbank.account_status(request)
      if res["status_code"] == "204" or res["status_code"] == "409" do

        # Update Account Status
        changeset = %{status: "A"}
        new_acc_changeset = Companybankaccount.changesetStatus(get_bank_account, changeset)
        Repo.update(new_acc_changeset)

        company_info = %{
          "worker_type" => "company_enable",
          "admin_id" => admin_id,
          "commanall_id" => commanall_id,
          "company_id" => company_id
        }
        Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
      end
    else

      # check company card management account
      get_account = Repo.one(
        from a in Companyaccounts,
        where: a.company_id == ^company_id and not is_nil(a.accomplish_account_id) and a.status != ^"1",
        limit: 1,
        select: a
      )
      if !is_nil(get_account) do
        request = %{urlid: get_account.accomplish_account_id, status: "1"}
        response = Accomplish.activate_deactive_card(request)
        response_code = response["result"]["code"]
        if response_code == "0000" or response_code == "3055" or response_code == "3030" do
          # Update Account Status
          changeset_account = %{status: "1"}
          new_acc_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_acc_changeset)

          company_info = %{
            "worker_type" => "company_enable",
            "admin_id" => admin_id,
            "commanall_id" => commanall_id,
            "company_id" => company_id
          }
          Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
        else
          changeset_account = %{reason: response["result"]["friendly_message"]}
          new_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_changeset)
        end
      else
        # check company employee
        status_var = ["A", "K1", "K2", "K1", "AP", "IDINFO", "K2", "ADINFO", "IDDOC1", "IDDOC2", "ADDOC1"]
        get_employee = Repo.one(
          from emp in Employee, where: emp.company_id == ^company_id and emp.status not in ^status_var,
                                limit: 1,
                                select: emp
        )
        if !is_nil(get_employee) do

          # check employee card
          get_emp_card = Repo.one(
            from card in Employeecards,
            where: card.employee_id == ^get_employee.id and (card.status != ^"12" and card.status != ^"1"),
            limit: 1,
            select: card
          )
          if !is_nil(get_emp_card) do
            request = %{urlid: get_emp_card.accomplish_card_id, status: "1"}
            response = Accomplish.activate_deactive_card(request)
            response_code = response["result"]["code"]
            if response_code == "0000" or response_code == "3055" or response_code == "3030" do
              # Update Account Status
              changeset_card = %{status: "1"}
              new_acc_changeset = Employeecards.changesetCardStatus(get_emp_card, changeset_card)
              Repo.update(new_acc_changeset)

              company_info = %{
                "worker_type" => "company_enable",
                "admin_id" => admin_id,
                "commanall_id" => commanall_id,
                "company_id" => company_id
              }
              Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
            else
              changeset_card = %{reason: response["result"]["friendly_message"]}
              new_changeset = Employeecards.changesetStatus(get_emp_card, changeset_card)
              Repo.update(new_changeset)
            end
          else
            changeset_employee = %{status: "A"}
            new_changeset = Employee.changesetStatus(get_employee, changeset_employee)
            Repo.update(new_changeset)

            commanall_info = Repo.one(
              from empc in Commanall, where: empc.employee_id == ^get_employee.id and empc.status != ^"A",
                                      limit: 1,
                                      select: empc
            )
            if !is_nil(commanall_info) do
              changeset_emp = %{status: "A", api_token: nil, m_api_token: nil}
              new_changeset = Commanall.updateStatus(commanall_info, changeset_emp)
              Repo.update(new_changeset)
            end

            company_info = %{
              "worker_type" => "company_enable",
              "admin_id" => admin_id,
              "commanall_id" => commanall_id,
              "company_id" => company_id
            }
            Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [company_info], max_retries: 1)
          end
        else
          # update company status
          commanall_company = Repo.one(
            from com in Commanall, where: com.id == ^commanall_id and com.status != ^"A", limit: 1, select: com
          )
          if !is_nil(commanall_company) do
            changeset_company = %{status: "A", api_token: nil, m_api_token: nil}
            new_changeset = Commanall.updateStatus(commanall_company, changeset_company)
            Repo.update(new_changeset)
          end
        end
      end
    end
  end

end
