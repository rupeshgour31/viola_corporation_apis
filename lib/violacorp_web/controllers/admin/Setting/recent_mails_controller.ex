defmodule ViolacorpWeb.Admin.Settings.RecentMailsController do
  use Phoenix.Controller

  alias  Violacorp.Models.Settings.RecentMailsSetting
  @moduledoc false


  @doc "Settings Recent  Mails"
  def recentMails(conn, params) do
    data =  RecentMailsSetting.recent_mails(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def resendMailView(conn, params)do
    data = RecentMailsSetting.resend_Mail_View(params)
    case  data do
      nil ->
        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
      data ->
        json conn, %{status_code: "200",  data: data}
    end
  end
end
