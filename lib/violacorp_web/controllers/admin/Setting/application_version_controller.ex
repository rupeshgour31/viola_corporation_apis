defmodule ViolacorpWeb.Admin.Settings.ApplicationVersionController do
  use Phoenix.Controller

  alias Violacorp.Settings.ApplicationVersionSetting
  @moduledoc false

  @doc " Admin Application Version"

  def applicationVersion(conn, params) do
    data = ApplicationVersionSetting.application_version(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

end
