defmodule ViolacorpWeb.DaseboardView do
  use ViolacorpWeb, :view


  def render("show.json", %{data: data}) do
    %{status_code: "200", data: render_many(data, DaseboardView, "currency.json")}
  end
  def render("currency.json", %{data: data}) do

      %{data: data}

    end

end
