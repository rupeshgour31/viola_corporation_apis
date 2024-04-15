defmodule ViolacorpWeb.Admin.Settings.AlertSwitchController do
  use Phoenix.Controller

  alias Violacorp.Settings.AlertSwitchSetting
  @moduledoc false

  @doc " Admin Alert Switch"

  def alertSwitch(conn, params) do
    data = AlertSwitchSetting.alert_switch(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

end
