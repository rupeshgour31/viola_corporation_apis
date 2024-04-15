defmodule Violacorp.Workers.CompanyIdentification do
  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Versions
  alias Violacorp.Schemas.Thirdpartylogs

  alias Violacorp.Workers.SendEmail
  alias Violacorp.Workers.CompanyIdProof

  alias Violacorp.Mailer

  def perform(params) do

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
              }
              #            Exq.enqueue_in(Exq, "documentupload", 15, Documentupload, [request])
              Exq.enqueue_in(Exq, "company_id_proof", 10, CompanyIdProof, [request])
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
                     |> SendEmail.sendemail()
                     |> Mailer.deliver_later()
      end
    end
  end

end
