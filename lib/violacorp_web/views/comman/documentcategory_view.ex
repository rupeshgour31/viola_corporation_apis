defmodule ViolacorpWeb.Comman.DocumentcategoryView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Comman.DocumentcategoryView
  alias ViolacorpWeb.Comman.DocumenttypeView

  def render("index.json", %{documentcategory: documentcategory}) do
    %{status_code: "200", data: render_many(documentcategory, DocumentcategoryView, "documentcategory.json")}
  end

  def render("show.json", %{documentcategory: documentcategory}) do
    %{status_code: "200", data: render_one(documentcategory, DocumentcategoryView, "documentcategory.json")}
  end

  def render("AddressProofList.json", %{documentcategory: documentcategory}) do
    %{status_code: "200", data: render_many(documentcategory.documenttype, DocumenttypeView, "documenttype.json", as: :documenttype)}
  end

  def render("IdProofList.json", %{documentcategory: documentcategory}) do
    %{status_code: "200", data: render_many(documentcategory.documenttype, DocumenttypeView, "documenttype.json", as: :documenttype)}
  end

  def render("documentcategory.json", %{documentcategory: documentcategory}) do
    %{id: documentcategory.id, title: documentcategory.title, code: documentcategory.code}
  end

end
