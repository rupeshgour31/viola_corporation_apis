defmodule ViolacorpWeb.Projects.ProjectsView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Projects.ProjectsView

  def render("index.json", %{projects: projects}) do
    %{status_code: "200", data: render_many(projects, ProjectsView, "project.json")}
  end

  def render("show.json", %{projects: projects}) do
    %{status_code: "200", data: render_one(projects, ProjectsView, "project.json")}
  end

  def render("project.json", %{projects: projects}) do
    %{id: projects.id, company_id: projects.company_id, project_name: projects.project_name, start_date: projects.start_date}

  end
end
