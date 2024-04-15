defmodule Violacorp.Workers.V1.UploadDocument do

  import Ecto.Query
  alias Violacorp.Repo
  require Logger
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Documenttype
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Libraries.Accomplish


  def perform(params) do
    case params["worker_type"] do
      "company_id_proof" ->
        Map.delete(params, "worker_type")
        |> company_id_proof()
      "company_address_proof" ->
        Map.delete(params, "worker_type")
        |> company_address_proof()
      "employee_id_proof" ->
        Map.delete(params, "worker_type")
        |> employee_id_proof()
      "employee_address_proof" ->
        Map.delete(params, "worker_type")
        |> employee_address_proof()
      "director_id_proof" ->
        Map.delete(params, "worker_type")
        |> director_id_proof()
      "director_address_proof" ->
        Map.delete(params, "worker_type")
        |> director_address_proof()
      "company_kyb_upload" ->
        Map.delete(params, "worker_type")
        |> company_kyb_upload()
      "other_director_document" ->
        Map.delete(params, "worker_type")
        |> other_director_document()
      _ ->
        Logger.warn("Worker: #{params["worker_type"]} not found in Cards")
        :ok
    end
  end

  @doc """
    company Id proof upload on Accomplish
  """
  def company_id_proof(params) do
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
              worker_type: "company_address_proof"
            }
            Exq.enqueue_in(Exq, "upload_document", 10, Violacorp.Workers.V1.UploadDocument, [request])
          end
        end
      end
    end
  end

  @doc """
    Company Address proof upload on Accomplish
  """
  def company_address_proof(params) do
    commanall_id = params["commanall_id"]
    check_addproof = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Address Proof%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_addproof) do
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
        company_detail = Repo.get_by(Commanall, id: params["commanall_id"])

        status_map = %{"status" => "A"}
        updateStatus = Commanall.updateStatus(company_detail, status_map)
        Repo.update(updateStatus)

        # UPDATE TRUST LEVEL
        trust_level = %{
          "worker_type" => "update_trustlevel",
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "request_id" => params["request_id"],
        }
        Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [trust_level])

        get_other_director = Repo.all(
          from d in Directors, where: d.company_id == ^company_detail.company_id and d.is_primary != "Y", select: d
        )
        if get_other_director != [] do
          get_other_director
          |> Stream.with_index
          |> Enum.reduce(
               1,
               fn (num_idx, _acc) ->
                 {director_info, idx} = num_idx
                 call_time = (idx + 1) * 10
                 # call for other director kyc
                 request = %{
                   user_id: params["user_id"],
                   director_id: director_info.id,
                   first_name: director_info.first_name,
                   last_name: director_info.last_name,
                   call_time: call_time,
                   worker_type: "other_director_document"
                 }
                 Exq.enqueue_in(Exq, "upload_document", 5, Violacorp.Workers.V1.UploadDocument, [request])
               end
             )
        end

        kyb_info = Repo.all(
          from kyb in Kycdocuments,
          where: kyb.commanall_id == ^params["commanall_id"] and kyb.type == ^"C" and kyb.status == ^"A", select: kyb
        )
        if kyb_info != [] do
          kyb_info
          |> Stream.with_index
          |> Enum.reduce(
               1,
               fn (num_idx, _acc) ->
                 {kyb, idx} = num_idx
                 count = Enum.count(get_other_director)
                 call_time = if count != 0, do: (idx + count) * 15, else: (idx + 1) * 15

                 file_data = kyb.file_location
                 if !is_nil(file_data) do
                   %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
                   content = Base.encode64(body)
                   file_extension = Path.extname(file_data)
                   kyb_type = Repo.one(from t in Documenttype, where: t.id == ^kyb.documenttype_id, select: t.title)

                   request = %{
                     user_id: params["user_id"],
                     first_name: params["first_name"],
                     last_name: params["last_name"],
                     type: "12",
                     subject: "#{kyb_type}",
                     entity: 26,
                     file_name: "#{kyb_type}",
                     file_extension: file_extension,
                     content: content,
                     document_id: kyb.id,
                     worker_type: "company_kyb_upload"
                   }
                   Exq.enqueue_in(Exq, "upload_document", call_time, Violacorp.Workers.V1.UploadDocument, [request])
                 end
               end
             )
        end
      end
    end
  end

  @doc """
    employee Id proof upload on Accomplish
  """
  def employee_id_proof(params) do
    # check Id Proof uploaded
    commanall_id = params["commanall_id"]
    check_idproof = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Id Proof%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_idproof) do

      employee_id = params["employee_id"]

      employee = Repo.get(Employee, employee_id)
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
        request_id: params["request_id"]
      }
      response = Accomplish.create_document(request)
      response_code = response["result"]["code"]

      if response_code == "0000" do

        address_document = Repo.one from ak in Kycdocuments,
                                    where: ak.commanall_id == ^params["commanall_id"] and ak.status == "A" and ak.type == "A",
                                    limit: 1,
                                    select: %{
                                      id: ak.id,
                                      address_file_location: ak.file_location,
                                      address_documenttype_id: ak.documenttype_id
                                    }

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
              employee_id: params["employee_id"],
              commanall_id: params["commanall_id"],
              first_name: employee.first_name,
              last_name: employee.last_name,
              type: address_type,
              subject: "#{document_name}",
              entity: 15,
              file_name: document_name,
              file_extension: address_file_extension,
              content: address_content,
              document_id: address_document.id,
              type_of_proof: "Address",
              request_id: params["request_id"],
              worker_type: "employee_address_proof"
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
          end
        end

      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)
      end
    end
  end

  @doc """
    employee address proof upload on accomplish
  """
  def employee_address_proof(params) do
    commanall_id = params["commanall_id"]
    check_addproof = Repo.one(
      from log in Thirdpartylogs,
      where: log.commanall_id == ^commanall_id and like(log.section, "%Address Proof%") and log.status == ^"S",
      limit: 1,
      select: log
    )
    if is_nil(check_addproof) do
      employee_id = params["employee_id"]

      employee = Repo.get(Employee, employee_id)
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
        request_id: params["request_id"]
      }
      response = Accomplish.create_document(request)
      response_code = response["result"]["code"]

      if response_code == "0000" do

        request = %{
          "worker_type" => "physical_card",
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "employee_id" => params["employee_id"],
          "request_id" => params["request_id"],
        }
        emp_company_id = employee.company_id

        # UPDATE TRUST LEVEL
        trust_level = %{
          "worker_type" => "update_trustlevel",
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "request_id" => params["request_id"],

        }
        Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [trust_level])

        # Check Clear Bank Account
        #        check_clearBank = Repo.get_by(Companybankaccount, company_id: emp_company_id, status: "A")
        count_balance = Repo.one(
          from cb in Companybankaccount, where: cb.company_id == ^emp_company_id and cb.status == ^"A",
                                         select: sum(cb.balance)
        )
        output = if !is_nil(count_balance) && Decimal.cmp("#{count_balance}", Decimal.from_float(0.0)) == :gt,
                    do: "Yes", else: "No"

        if output == "Yes" do
          # Create Physical Card
          #        Exq.enqueue(Exq, "physical_card", PhysicalCard, [request], max_retries: 1)
          Exq.enqueue_in(Exq, "cards", 15, Violacorp.Workers.V1.Cards, [request])
        end

      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)
      end
    end
  end

  @doc """
    director Id proof upload on Accomplish
  """
  def director_id_proof(params) do

    request = %{
      user_id: params["user_id"],
      director_id: params["director_id"],
      first_name: params["first_name"],
      last_name: params["last_name"],
      entity: params["entity"],
      type: params["type"],
      subject: params["subject"],
      file_name: params["file_name"],
      file_extension: params["file_extension"],
      content: params["content"],
      document_id: params["document_id"],
    }

    response = Accomplish.upload_director_document(request)
    response_code = response["result"]["code"]
    if response_code == "0000" do

      ## Check Permission For Upload Address Proof
      check_permission = Application.get_env(:violacorp, :upload_kyc)
      if check_permission == "BOTH" do
        director_id = params["director_id"]
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
              director_id: director_id,
              first_name: params["first_name"],
              last_name: params["last_name"],
              type: address_type,
              subject: "#{document_name}",
              entity: 15,
              file_name: document_name,
              file_extension: address_file_extension,
              content: address_content,
              document_id: address_document.id,
              worker_type: "director_address_proof"
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
          end
        end
      end
    else
      Logger.warn(
        "Failed Upload Director ID Proof kyc director id : #{params["director_id"]}, message: #{
          response["result"]["message"]
        }"
      )
    end
  end

  @doc """
    director address proof upload on Accomplish
  """
  def director_address_proof(params) do
    request = %{
      user_id: params["user_id"],
      director_id: params["director_id"],
      first_name: params["first_name"],
      last_name: params["last_name"],
      entity: params["entity"],
      type: params["type"],
      subject: params["subject"],
      file_name: params["file_name"],
      file_extension: params["file_extension"],
      content: params["content"],
      document_id: params["document_id"],
    }
    response = Accomplish.upload_director_document(request)
    response_code = response["result"]["code"]
    if response_code == "0000" do
      Logger.warn("director id : #{params["director_id"]} address proof uploaded on third party")
    else
      Logger.warn(
        "Failed Upload Director Address kyc director id : #{params["director_id"]}, message: #{
          response["result"]["message"]
        }"
      )
    end
  end

  @doc """
    company kyb upload on accomplish
  """
  def company_kyb_upload(params) do
    request = %{
      user_id: params["user_id"],
      first_name: params["first_name"],
      last_name: params["last_name"],
      entity: params["entity"],
      type: params["type"],
      subject: params["subject"],
      file_name: params["file_name"],
      file_extension: params["file_extension"],
      content: params["content"],
      document_id: params["document_id"],
    }
    response = Accomplish.upload_companyKyb_document(request)
    response_code = response["result"]["code"]
    if response_code == "0000" do
      Logger.warn("KYB id : #{params["document_id"]} company kyb uploaded, message: #{response["result"]["message"]}")
    else
      Logger.warn("Failed Upload KYB id : #{params["document_id"]}, message: #{response["result"]["message"]}")
    end
  end

  ## function for upload other director kyc
  def other_director_document(params) do
    proof_of_identity = Repo.one(
      from ki in Kycdirectors,
      where: ki.directors_id == ^params["director_id"] and ki.type == ^"I" and ki.status == ^"A",
      limit: 1,
      select: %{
        id: ki.id,
        documenttype_id: ki.documenttype_id,
        document_number: ki.document_number,
        expiry_date: ki.expiry_date,
        file_location: ki.file_location,
        issue_date: ki.issue_date,
      }
    )

    if !is_nil(proof_of_identity) do
      file_data = proof_of_identity.file_location
      if !is_nil(file_data) do
        %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
        content = Base.encode64(body)
        file_extension = Path.extname(file_data)

        ## get third party document id and document type
        {document_type, document_name} = case proof_of_identity.documenttype_id do
          19 -> {"4", "Driving Licence"}
          10 -> {"2", "Passport"}
          9 -> {"3", "National ID"}
          _ -> {"3", "National ID"}
        end

        request = %{
          user_id: params["user_id"],
          director_id: params["director_id"],
          first_name: params["first_name"],
          last_name: params["last_name"],
          type: document_type,
          subject: "#{document_name}",
          entity: 25,
          file_name: document_name,
          file_extension: file_extension,
          content: content,
          document_id: proof_of_identity.id,
          worker_type: "director_id_proof"
        }
        Exq.enqueue_in(Exq, "upload_document", params["call_time"], Violacorp.Workers.V1.UploadDocument, [request])
      end
    end
  end
end
