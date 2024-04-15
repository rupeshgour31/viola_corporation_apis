defmodule Violacorp.Workers.EmployeeIdProof do
  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Workers.EmployeeAddressProof

  def perform(params) do

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
              request_id: params["request_id"]
            }
            Exq.enqueue_in(Exq, "employee_address_proof", 15, EmployeeAddressProof, [request])
          end
        end

      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)
      end
    end
  end
end