defmodule Violacorp.Settings.DepartmentListSetting do

  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Departments
  @moduledoc false

  @doc "Settings Departments List"

  def departments_list(params) do
#    filtered = params
#               |> Map.take(~w(department_name))
#               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    department_name = params["department_name"]
            (from a in Departments,
                  select: %{
                    id: a.id,
                    department_name: a.department_name,
                    number_of_employee: a.number_of_employee,
                    status: a.status
                  })
            |> where([a], like(a.department_name, ^"%#{department_name}%"))
            |> order_by(desc: :id)
            |> Repo.paginate(params)
  end

end
