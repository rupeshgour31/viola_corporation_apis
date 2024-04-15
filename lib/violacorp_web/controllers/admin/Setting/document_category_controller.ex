defmodule ViolacorpWeb.Admin.Settings.DocumentCategoryController do
  use Phoenix.Controller

  alias Violacorp.Settings.DocumentCategorySetting
  @moduledoc false


  @doc "Settings Document Category List"

  def documentCategory(conn, params) do
    data = DocumentCategorySetting.document_category(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end


end
