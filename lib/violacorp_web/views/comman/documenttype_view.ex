defmodule ViolacorpWeb.Comman.DocumenttypeView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Comman.DocumenttypeView

  def render("index.json", %{documenttype: documenttype}) do
    %{status_code: "200", data: render_many(documenttype, DocumenttypeView, "documenttype.json")}
  end

  def render("onlytitle.json", %{documenttype: documenttype}) do
    %{status_code: "200", data: render_many(documenttype, DocumenttypeView, "documenttypeonlytitle.json")}
  end

  def render("show.json", %{documenttype: documenttype}) do
    %{status_code: "200", data: render_one(documenttype, DocumenttypeView, "documenttype.json")}
  end

  def render("documenttype.json", %{documenttype: documenttype}) do
    %{id: documenttype.id, documentcategory_id: documenttype.documentcategory_id, title: documenttype.title, code: documenttype.code, description: documenttype.description}
  end

  def render("documenttypeonlytitle.json", %{documenttype: documenttype}) do
    %{id: documenttype.id, title: documenttype.title}
  end

end
