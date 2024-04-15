defmodule ViolacorpWeb.Admin.Employee.AdministratorController do
  use Phoenix.Controller

  alias  Violacorp.Models.Employee

  @doc "Get All Administrator User"
  def getAll_administrator(conn, params)do
    data = Employee.get_administrator(params)
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries,
          page_size: data.page_size, page_number: data.page_number, data: data.entries,
        }
  end


end
