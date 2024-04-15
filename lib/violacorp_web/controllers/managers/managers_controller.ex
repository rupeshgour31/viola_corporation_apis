defmodule ViolacorpWeb.Managers.ManagersController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Employee
  alias ViolacorpWeb.Managers.ManagerView

  def insertManager(conn, _params) do
    text  conn, "insertManager"
  end

  def updateManager(conn, params) do
    text  conn, "updateManager #{params["id"]}"
  end

  @doc "gets all managers for a company from Employee table"
  def getAllManagers(conn, params) do
    manager = Repo.all(from e in Employee, where: e.company_id == ^params["companyId"] and e.is_manager == "Y")
    render(conn, ManagerView, "index.json", manager: manager)
  end

  @doc "gets single managers for a company from Employee table"
  def getSingleManager(conn, params) do
    manager = Repo.one(
      from e in Employee, where: e.id == ^params["id"] and e.company_id == ^params["companyId"] and e.is_manager == "Y"
    )
    render(conn, ManagerView, "show.json", manager: manager)
  end

end
