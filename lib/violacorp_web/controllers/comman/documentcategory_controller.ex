defmodule ViolacorpWeb.Comman.DocumentcategoryController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Documentcategory
  alias ViolacorpWeb.Comman.DocumentcategoryView


  @doc "inserts a documentCategory to documentCategory table"
  def insertDocumentCategory(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      documentcategory = %{
        "title" => params["title"],
        "code" => params["code"],
        "inserted_by" => commanid
      }

      changeset = Documentcategory.changeset(%Documentcategory{}, documentcategory)
      case Repo.insert(changeset) do
        {:ok, documentcategory} -> render(conn, DocumentcategoryView, "show.json", documentcategory: documentcategory)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a documentCategory to documentCategory table"
  def updateDocumentCategory(conn, %{"id" => id, "documentCategory" => params}) do
    documentcategory = Repo.get!(Documentcategory, id)
    changeset = Documentcategory.changeset(documentcategory, params)
    case Repo.update(changeset) do
      {:ok, documentcategory} -> render(conn, DocumentcategoryView, "show.json", documentcategory: documentcategory)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "gets all documentCategories from documentCategory table"
  def getAllDocumentCategory(conn, _params) do
    documentcategory = Repo.all(Documentcategory)
    render(conn, DocumentcategoryView, "index.json", documentcategory: documentcategory)
  end

  @doc "gets dingle documentCategory from documentCategory table"
  def getSingleDocumentCategory(conn, params) do
    documentcategory = Repo.one(from d in Documentcategory, where: d.id == ^params["id"])
    render(conn, DocumentcategoryView, "show.json", documentcategory: documentcategory)
  end
end
