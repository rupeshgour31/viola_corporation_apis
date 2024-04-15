defmodule ViolacorpWeb.Admin.KycDocuments.KycDocumentsController do
  use Phoenix.Controller

#alias Violacorp.Models.KycDocuments
alias Violacorp.Models.KycDocumentsV2

  def directorDocumentUpload(conn, params)do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case KycDocumentsV2.directorUploadSteps(params, admin_id)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} ->
        json conn, %{status_code: "4004", message: message}
      {:errors, response} -> json conn, %{status_code: "4003", errors: response}
    end
  end

  @doc""
  def employeeDocumentUpload(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case KycDocumentsV2.employeeUploadSteps(params, admin_id)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:doesNotExist, message} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "4002.json", message: message)

    end
  end

  end
