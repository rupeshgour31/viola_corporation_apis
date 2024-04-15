defmodule ViolacorpWeb.MoneyrequestView do
  use ViolacorpWeb, :view

  alias  ViolacorpWeb.MoneyrequestView

  def render("index.json", %{money: money})do
    %{status_code: "200",total_pages: money.total_pages,total_entries: money.total_entries,
      page_size: money.page_size, page_number: money.page_number,
       data: render_many(money, MoneyrequestView, "show.json")}
  end

  def render("show.json", %{money: _money})do



  end

end
