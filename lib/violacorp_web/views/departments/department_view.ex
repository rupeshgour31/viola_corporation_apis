defmodule ViolacorpWeb.Departments.DepartmentView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Departments.DepartmentView

  def render("index.json", %{department: department}) do
    %{status_code: "200", data: render_many(department, DepartmentView, "department.json")}
  end

  def render("show.json", %{department: department}) do
    %{status_code: "200", data: render_one(department, DepartmentView, "department.json")}
  end

  def render("showidname.json", %{department: department}) do
    %{status_code: "200", data: render_one(department, DepartmentView, "showid_only.json")}
  end

  def render("department.json", %{department: department}) do
    %{id: department.id, company_id: department.company_id, department_name: department.department_name, number_of_employee: department.number_of_employee}
  end

  def render("showid_only.json", %{department: department}) do
    %{id: department.id, department_name: department.department_name}
  end
end
