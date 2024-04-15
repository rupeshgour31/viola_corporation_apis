defmodule Violacorp.Models.Companies.Directors do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
#  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Documenttype
  alias Violacorp.Libraries.Commontools
  @moduledoc false

  @doc """
    this function for upload director kyc on accomplish
  """
  def uploadDirectorKyc(params, admin_id) do
    director_id = params["director_id"]
    with {:ok, _info} <- Commontools.checkOwnPassword(params["password"], admin_id),
         {:ok, director_info} <- validateDirector(director_id),
         {:ok, company_info} <- getCompanyInfo(director_info.company_id, "director") do
        proof_of_identity = Repo.one(from ki in Kycdirectors, where: ki.directors_id == ^director_id and ki.type == ^"I" and ki.status == ^"A",
                                                              limit: 1,
                                                              select: %{
                                                                id: ki.id,
                                                                documenttype_id: ki.documenttype_id,
                                                                document_number: ki.document_number,
                                                                expiry_date: ki.expiry_date,
                                                                file_location: ki.file_location,
                                                                issue_date: ki.issue_date,
                                                              })

        if !is_nil(proof_of_identity) do
          file_data = proof_of_identity.file_location
          if !is_nil(file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
            content = Base.encode64(body)
            file_extension = Path.extname(file_data)

            ## get third party document id and document type
            {document_type, document_name} = getDocumentTypeAndId(proof_of_identity.documenttype_id)

            request = %{
              user_id: company_info.accomplish_userid,
              director_id: director_id,
              first_name: director_info.first_name,
              last_name: director_info.last_name,
              type: document_type,
              subject: "#{document_name}",
              entity: 25,
              file_name: document_name,
              file_extension: file_extension,
              content: content,
              document_id: proof_of_identity.id,
              worker_type: "director_id_proof"
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
            {:ok, "Document Uploaded Successfully."}
          else
            {:not_found, "Director ID Proof document not found"}
          end
        else
          {:not_found, "Director ID Proof information not found"}
        end
    end
  end

  @doc """
    this function for upload company kyb on accomplish
  """
  def uploadCompanyKyb(params, admin_id) do

    with {:ok, _info} <- Commontools.checkOwnPassword(params["password"], admin_id),
         {:ok, document_info, document_type} <- validateCompanyKyb(params["kyb_id"]),
         {:ok, company_info} <- getCompanyInfo(document_info.commanall_id, "company") do

#            get_company_name = Repo.one(from c in Company, where: c.id == ^company_info.company_id, select: c.company_name)
            get_director_name = Repo.one(from d in Directors, where: d.company_id == ^company_info.company_id and d.is_primary == "Y", limit: 1, select: %{first_name: d.first_name, last_name: d.last_name})
            file_data = document_info.file_location
            if !is_nil(file_data) do
              %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
              content = Base.encode64(body)
              file_extension = Path.extname(file_data)

              request = %{
                user_id: company_info.accomplish_userid,
                first_name: get_director_name.first_name,
                last_name: get_director_name.last_name,
                type: "12",
                subject: "#{document_type}",
                entity: 26,
                file_name: "#{document_type}",
                file_extension: file_extension,
                content: content,
                document_id: document_info.id,
                worker_type: "company_kyb_upload"
              }
              Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
              {:ok, "Document Uploaded Successfully."}
            else
              {:not_found, "Director ID Proof document not found"}
            end
    end
  end

  defp validateCompanyKyb(document_id) do
    case document_id do
      nil -> {:field_error, %{kyb_id: "can't be blank"}}
      "" -> {:field_error, %{kyb_id: "can't be blank"}}
      document_id ->
        document_info = Repo.one(from kyb in Kycdocuments, left_join: d in Documenttype, on: d.id == kyb.documenttype_id, where: kyb.id == ^document_id and kyb.type == ^"C" and kyb.status == ^"A", select: %{kyb: kyb, document_type: d.title})
        case document_info do
          nil -> {:not_found, "Company KYB not found"}
          _document -> {:ok, document_info.kyb, document_info.document_type}
        end
    end
  end

  defp validateDirector(director_id) do
    case director_id do
      nil -> {:field_error, %{director_id: "can't be blank"}}
      "" -> {:field_error, %{director_id: "can't be blank"}}
      director_id ->
#         director_info = Repo.one(from d in Directors, where: d.id == ^director_id and d.is_primary != "Y" and is_nil(d.employee_id), select: d)
         director_info = Repo.one(from d in Directors, where: d.id == ^director_id, select: d)
         case director_info do
           nil -> {:not_found, "already have upload"}
           _directors -> {:ok, director_info}
         end
    end
  end

  defp getCompanyInfo(company_id, type) do
    case type do
      "company" ->
        company_info = Repo.one(from c in Commanall, where: c.id == ^company_id and not is_nil(c.accomplish_userid), select: c)
        case company_info do
          nil -> {:not_found, "Company information not found"}
          _directors -> {:ok, company_info}
        end
      "director" ->
        company_info = Repo.one(from c in Commanall, where: c.company_id == ^company_id and not is_nil(c.accomplish_userid), select: c)
        case company_info do
          nil -> {:not_found, "Company information not found"}
          _directors -> {:ok, company_info}
        end
    end

  end

  def getDocumentTypeAndId(documenttype_id) do
    case documenttype_id do
      19 -> {"4", "Driving Licence"}
      10 -> {"2", "Passport"}
      9 -> {"3", "National ID"}
      _ -> {"3", "National ID"}
    end
  end
end
