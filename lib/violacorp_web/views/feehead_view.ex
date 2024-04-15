defmodule ViolacorpWeb.FeeheadView do
  use ViolacorpWeb, :view
 alias  ViolacorpWeb.FeeheadView

  def render("show.json", %{feehead: feehead}) do
    %{status_code: "200", data: render_one(feehead, FeeheadView, "feehead.json")}
  end

  def render("feehead.json", %{feehead: feehead}) do
    %{id: feehead.id, title: feehead.title, status: feehead.status, inserted_at: feehead.inserted_at, updated_at: feehead.updated_at}
  end
end
