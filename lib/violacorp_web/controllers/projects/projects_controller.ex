defmodule ViolacorpWeb.Projects.ProjectsController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Projects
  alias ViolacorpWeb.Projects.ProjectsView

  @doc "inserts a project to Projects table"
  def insertProject(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      project_name = if is_nil(params["project_name"]) do
      else
        params["project_name"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end
      project = %{
        "company_id" => params["company_id"],
        "project_name" => project_name,
        "start_date" => params["start_date"],
        "inserted_by" => commanid
      }

      changeset = Projects.changeset(%Projects{}, project)
      case Repo.insert(changeset) do
        {:ok, projects} -> render(conn, ProjectsView, "show.json", projects: projects)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a project to Projects table"
  def updateProject(conn, %{"id" => id, "projects" => params}) do
    project = Repo.get!(Projects, id)
    changeset = Projects.changeset(project, params)
    case Repo.update(changeset) do
      {:ok, projects} -> render(conn, ProjectsView, "show.json", projects: projects)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "soft deletes a project to Projects table"
  def softDeleteProject(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    project = Repo.get(Projects, params["id"])
    if project != nil do
    if project.company_id == company_id and project.is_delete == "N" do
    newparams = %{"is_delete" => "Y"}
    changeset = Projects.deleteChangeset(project, newparams)
    case Repo.update(changeset) do
      {:ok, _projects} -> json conn, %{status_code: "200", message: "Project deleted successfully"}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
    else
    cond do
      project.company_id != company_id -> json conn, %{status_code: "4003", message: "Project not available for your company"}
      project.is_delete == "Y" -> json conn, %{status_code: "4003", message: "Project already deleted"}
    end
  end
  else
      json conn, %{status_code: "4003", message: "Project not found"}
  end
  end

  @doc "gets all projects for a company from Projects table"
  def getAllProjects(conn, _params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    projects = Repo.all(from p in Projects, where: p.company_id == ^company_id and p.is_delete == "N")
    render(conn, ProjectsView, "index.json", projects: projects)
  end

  @doc "gets all projects for a company from Projects table"
  def getFilteredProjects(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    project_name = params["project_name"]

    projects = if project_name != "" do
                    (from p in Projects, where: like(p.project_name, ^"%#{project_name}%") and p.company_id == ^company_id and p.is_delete == "N", select: %{id: p.id, company_id: p.company_id, project_name: p.project_name, start_date: p.start_date}) |> Repo.paginate(params)
               else
                    (from p in Projects, where: p.company_id == ^company_id and p.is_delete == "N", select: %{id: p.id, company_id: p.company_id, project_name: p.project_name, start_date: p.start_date}) |> Repo.paginate(params)

               end
    total_count = Enum.count(projects)

    json conn, %{status_code: "200", total_count: total_count, data: projects.entries, page_number: projects.page_number, total_pages: projects.total_pages}
  end

  @doc "gets a single project for a company from Projects table"
  def getSingleProject(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    projects = Repo.one(from p in Projects, where: p.id == ^params["id"] and p.company_id == ^company_id and p.is_delete == "N")
    render(conn, ProjectsView, "show.json", projects: projects)
  end
end
