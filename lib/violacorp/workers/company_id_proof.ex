defmodule Violacorp.Workers.CompanyIdProof do

  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Thirdpartylogs

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Workers.CompanyAddressProof

  def perform(params) do
    commanall_id = params["commanall_id"]
    check_idproof = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Id Proof%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_idproof) do
      request = %{
        user_id: params["user_id"],
        commanall_id: params["commanall_id"],
        first_name: params["first_name"],
        last_name: params["last_name"],
        type: params["type"],
        subject: params["subject"],
        entity: params["entity"],
        file_name: params["file_name"],
        file_extension: params["file_extension"],
        content: params["content"],
        document_id: params["document_id"],
        request_id: params["request_id"],
      }
      response = Accomplish.create_document(request)
      response_code = response["result"]["code"]
      if response_code == "0000" do

        commonall_id = params["commanall_id"]
        company_detail = Repo.get_by(Commanall, id: commonall_id)
        company = Repo.get(Company, company_detail.company_id)
        company_id = company.id

        get_director = Repo.one(
          from d in Directors, where: d.company_id == ^company_id and d.is_primary == "Y",
                               select: %{
                                 id: d.id,
                                 first_name: d.first_name,
                                 last_name: d.last_name
                               }
        )
        director_id = get_director.id
        address_document = Repo.one(
          from ak in Kycdirectors, where: ak.directors_id == ^director_id and ak.status == "A" and ak.type == "A",
                                   select: %{
                                     id: ak.id,
                                     address_file_location: ak.file_location,
                                     address_documenttype_id: ak.documenttype_id
                                   }
        )

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
              document_id: address_document.id,
              request_id: params["request_id"],
            }
            Exq.enqueue_in(Exq, "company_address_proof", 10, CompanyAddressProof, [request])
          end
        end
      end
    end
  end
end
