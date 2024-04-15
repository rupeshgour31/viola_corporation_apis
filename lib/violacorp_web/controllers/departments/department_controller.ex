defmodule ViolacorpWeb.Departments.DepartmentController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Departments
  alias Violacorp.Schemas.Employee
  alias ViolacorpWeb.Departments.DepartmentView

  @doc "inserts a department to Departments table"
  def insertDepartment(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      department_name = if is_nil(params["department_name"]) do
      else
        params["department_name"]
        |> String.split(~r{ })
        |> Enum.map(&String.capitalize(&1))
        |> Enum.join(" ")
      end

      department = %{
        "company_id" => params["company_id"],
        "department_name" => department_name,
        "number_of_employee" => params["number_of_employee"],
        "inserted_by" => commanid
      }

      changeset = Departments.changeset(%Departments{}, department)
      case Repo.insert(changeset) do
        {:ok, department} -> render(conn, DepartmentView, "showidname.json", department: department)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a department to Departments table"
  def updateDepartment(conn, %{"id" => id, "department" => params}) do
    department = Repo.get!(Departments, id)
    changeset = Departments.changeset(department, params)
    case Repo.update(changeset) do
      {:ok, department} -> render(conn, DepartmentView, "showidname.json", department: department)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "gets all departments for company from Departments table"
  def getAllDepartments(conn, _params) do

    %{"id" => company_id} = conn.assigns[:current_user]

    department = Repo.all(from d in Departments, where: d.company_id == ^company_id)
    render(conn, DepartmentView, "index.json", department: department)
  end

  @doc "gets all departments for company from Departments table"
  def getFilteredDepartments(conn, params) do

    %{"id" => company_id} = conn.assigns[:current_user]

    department_name = params["department_name"]

    department = if department_name != "" do
      (from d in Departments, where: like(d.department_name, ^"%#{department_name}%") and d.company_id == ^company_id, select: %{id: d.id, company_id: d.company_id, department_name: d.department_name, number_of_employee: d.number_of_employee}) |> Repo.paginate(params)
    else
      (from d in Departments, where: d.company_id == ^company_id, select: %{id: d.id, company_id: d.company_id, department_name: d.department_name, number_of_employee: d.number_of_employee}) |> Repo.paginate(params)
    end

    total_count = Enum.count(department)
    json conn, %{status_code: "200", total_count: total_count, data: department.entries, page_number: department.page_number, total_pages: department.total_pages}
  end

  @doc "gets single department for company from Departments table"
  def getSingleDepartment(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]
    department = Repo.one(from d in Departments, where: d.id == ^params["id"] and d.company_id == ^company_id)
    render(conn, DepartmentView, "show.json", department: department)
  end

  @doc "Delete a single department with given id, plus sets to null all employees' departments_id"
  def deleteDepartment(conn, params) do
    %{"id" => company_id} = conn.assigns[:current_user]

    department = Repo.get_by(Departments, id: params["id"], company_id: company_id)
    if is_nil(department) do
      json conn, %{status_code: "4003", message: "No department found"}
    else

    dep_employees = Repo.all from e in Employee, where: e.departments_id == ^params["id"]

    if is_nil(dep_employees) do
      case Repo.delete(department) do
        {:ok, _commanall} -> json conn, %{status_code: "200", message: "Success, department deleted"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      _ok = Enum.each(
        dep_employees,
        fn x ->
          transaction = %{
            "departments_id" => nil,
          }
          changeset_employee = Employee.departmentToNull(x, transaction)

          case Repo.update(changeset_employee) do
            {:ok, _commanall} -> ""
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      )
      Repo.delete(department)
      json conn, %{status_code: "200", data: "Success, department deleted"}
    end
  end
  end
end
