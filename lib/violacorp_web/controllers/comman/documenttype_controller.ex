defmodule ViolacorpWeb.Comman.DocumenttypeController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Documenttype
  alias ViolacorpWeb.Comman.DocumenttypeView

  @doc "inserts a documentType to documentType table"
  def insertDocumenttype(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      documenttype = %{
        "documentcategory_id" => params["documentcategory_id"],
        "title" => params["title"],
        "code" => params["code"],
        "description" => params["description"],
        "inserted_by" => commanid
      }

      changeset = Documenttype.changeset(%Documenttype{}, documenttype)
      case Repo.insert(changeset) do
        {:ok, documenttype} -> render(conn, DocumenttypeView, "show.json", documenttype: documenttype)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a documentType to documentType table"
  def updateDocumenttype(conn, %{"id" => id, "documentType" => params}) do
    documenttype = Repo.get!(Documenttype, id)
    changeset = Documenttype.changeset(documenttype, params)
    case Repo.update(changeset) do
      {:ok, documenttype} -> render(conn, DocumenttypeView, "show.json", documenttype: documenttype)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "gets all documentTypes from documentType table"
  def getAllDocumenttype(conn, _params) do
    documenttype = Repo.all(Documenttype)
    render(conn, DocumenttypeView, "index.json", documenttype: documenttype)
  end
  @doc "gets single documentType from documentType table"
  def getSingleDocumenttype(conn, params) do
    documenttype = Repo.one(from d in Documenttype, where: d.id == ^params["id"])
    render(conn, DocumenttypeView, "show.json", documenttype: documenttype)
  end

  @doc "gets documentTypes for AddressProof from documentType table"
  def getAddressProofList(conn, _params) do
    documenttype = Repo.all(from d in Documenttype, where: d.documentcategory_id == 1)
    render(conn, DocumenttypeView, "onlytitle.json", documenttype: documenttype)
  end

  @doc "gets documentTypes for IdProof from documentType table"
  def getIdProofList(conn, _params) do
    documenttype = Repo.all(from d in Documenttype, where: d.documentcategory_id == 2)
    render(conn, DocumenttypeView, "onlytitle.json", documenttype: documenttype)
  end

end
