defmodule Violacorp.Libraries.HistoryManagement do

  alias Violacorp.Repo
  alias Violacorp.Schemas.UpdateHistory

  def updateHistory(params)do

    changeset = UpdateHistory.changeset(%UpdateHistory{}, params)
      Repo.insert(changeset)
  end

end
