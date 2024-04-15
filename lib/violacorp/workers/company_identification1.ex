defmodule Violacorp.Workers.CompanyIdentification1 do
  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Versions

  alias Violacorp.Workers.SendEmail
  alias Violacorp.Mailer
  alias Violacorp.Workers.Documentupload
  #  alias ViolacorpWeb.Thirdparty.FamilyController

  alias Violacorp.Mailer

  def perform(params) do

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

end
