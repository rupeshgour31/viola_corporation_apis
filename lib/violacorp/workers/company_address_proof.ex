defmodule Violacorp.Workers.CompanyAddressProof do

  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Workers.UpdateTrustlevel

  def perform(params) do

    commanall_id = params["commanall_id"]
    check_addproof = Repo.one(from log in Thirdpartylogs, where: log.commanall_id == ^commanall_id and like(log.section, "%Address Proof%") and log.status == ^"S", limit: 1, select: log)
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
          "user_id" => params["user_id"],
          "commanall_id" => params["commanall_id"],
          "request_id" => params["request_id"],
        }
        Exq.enqueue_in(Exq, "update_trustlevel", 10, UpdateTrustlevel, [trust_level])
      end
    end
  end

end
