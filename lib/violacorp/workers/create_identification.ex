defmodule Violacorp.Workers.CreateIdentification do
  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Libraries.Accomplish

  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Versions
  #  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Thirdpartylogs

  alias Violacorp.Workers.SendEmail
  alias Violacorp.Mailer
  #  alias Violacorp.Workers.PhysicalCard
  #  alias Violacorp.Workers.Documentupload
  alias Violacorp.Workers.EmployeeIdProof

  alias Violacorp.Mailer

  def perform(params) do

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
              request_id: params["request_id"]
            }
            Exq.enqueue_in(Exq, "employee_id_proof", 15, EmployeeIdProof, [request])
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

end
