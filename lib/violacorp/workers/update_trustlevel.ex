defmodule Violacorp.Workers.UpdateTrustlevel do
  alias Violacorp.Repo
  require Logger

  alias Violacorp.Schemas.Commanall

  alias Violacorp.Libraries.Accomplish

  def perform(params) do

    commanall_id = params["commanall_id"]
    user_id = params["user_id"]

    # get information
    comman_data = Repo.get!(Commanall, commanall_id)

    response = Accomplish.get_user(user_id)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do

      trust_level = %{trust_level: response["security"]["trust_level"]}
      changeset_commanall = Commanall.updateTrustLevel(comman_data, trust_level)
      case Repo.update(changeset_commanall) do
        {:ok, _data} -> Logger.warn "Update Trust level call: Response Trust Level Updated."
        {:error, changeset} -> Logger.warn "Update Trust level call: validation issue #{~s(#{changeset})}"
      end
    else
      Logger.warn "Update Trust level call: Failed Response #{response_message}"
    end
  end
end