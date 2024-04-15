defmodule Violacorp.Workers.Documentupload do
#  import Ecto.Query
#  alias Violacorp.Repo

#  alias Violacorp.Libraries.Accomplish

  def perform(params) do
#    commanall_id = params["commanall_id"]
    _request = %{
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
      document_id: params["document_id"]
    }
#    response = Accomplish.create_document(request)
#    _response_code = response["result"]["code"]

#    if response_code == "0000" do
#      update_steps = %{"document_upload" => "Y", "status" => "P"}
#      steps_changeset = Thirdpartysteps.changeset(thirdparty, update_steps)
#      Repo.update(steps_changeset)
#    else
#      update_steps = %{
#        "document_upload" => "F",
#        "request" => Poison.encode!(request),
#        "response" => Poison.encode!(response),
#        "status" => "P"
#      }
#      steps_changeset = Thirdpartysteps.changeset(thirdparty, update_steps)
#      Repo.update(steps_changeset)
#    end
  end
end