defmodule ViolacorpWeb.Admin.Settings.DocumentTypeController do
  use Phoenix.Controller

  alias Violacorp.Settings.DocumentTypeSetting
  @moduledoc false

  @doc "Settings Document Type List"

  def documentType(conn, params) do
    data = DocumentTypeSetting.document_type(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

end
