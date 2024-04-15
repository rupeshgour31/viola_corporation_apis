defmodule Violacorp.Workers.EmployeeAddressProof do
  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Workers.PhysicalCard
  alias Violacorp.Workers.UpdateTrustlevel

  def perform(params) do

    commanall_id = params["commanall_id"]
    check_addproof = Repo.one(from log in Thirdpartylogs, where: log.commanall_id == ^commanall_id and like(log.section, "%Address Proof%") and log.status == ^"S", limit: 1, select: log)
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
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "employee_id" => params["employee_id"],
          "request_id" => params["request_id"],
        }
        emp_company_id = employee.company_id

        # UPDATE TRUST LEVEL
        trust_level = %{
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "request_id" => params["request_id"],

        }
        Exq.enqueue_in(Exq, "update_trustlevel", 10, UpdateTrustlevel, [trust_level])

        # Check Clear Bank Account
        check_clearBank = Repo.get_by(Companybankaccount, company_id: emp_company_id, status: "A")

        createCard = if !is_nil(check_clearBank) do
          if Decimal.cmp("#{check_clearBank.balance}", Decimal.from_float(0.0)) == :gt  do
            "Yes"
          else
            "No"
          end
        else
          "No"
        end

        if createCard == "Yes" do
          # Create Physical Card
          #        Exq.enqueue(Exq, "physical_card", PhysicalCard, [request], max_retries: 1)
          Exq.enqueue_in(Exq, "physical_card", 15, PhysicalCard, [request])
        end

      else
        update_status = %{"status" => "AP"}
        commanall_changeset = Employee.changesetStatus(employee, update_status)
        Repo.update(commanall_changeset)
      end
    end
  end
end