defmodule ViolacorpWeb.Admin.Settings.DepartmentListController do

  use Phoenix.Controller

  alias Violacorp.Settings.DepartmentListSetting
  @moduledoc false

  @doc "Settings Departments  List"

  def departmentsList(conn, params) do
    data = DepartmentListSetting.departments_list(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end


end
