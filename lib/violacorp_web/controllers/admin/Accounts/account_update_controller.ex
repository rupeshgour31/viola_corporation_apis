defmodule ViolacorpWeb.Admin.Accounts.AccountUpdateController do
  use Phoenix.Controller
  #  alias Violacorp.Models.ThirdpartyStatusUpdate
#  alias Violacorp.Models.KycDocuments
  alias Violacorp.Models.KycDocumentsV2

  #  def account_check_status(conn, params)do
  #
  #    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
  #    if type == "A" do
  #      type = params["type"]
  #      delete = Map.delete(params, "type")
  #      new_params = Map.merge(delete, %{"admin_id" => admin_id})
  #
  #
  #      case type do
  #        "CB" -> a = ThirdpartyStatusUpdate.clearBankUpdateStatus(new_params)
  #                json conn, a
  #        "AC" -> a = ThirdpartyStatusUpdate.accomplishUpdateStatus(new_params)
  #                json conn, a
  #        "CD" -> a = ThirdpartyStatusUpdate.cardUpdateStatus(new_params)
  #                json conn, a
  #        _ -> json conn, "TYPE DOES NOT EXIST"
  #      end
  #
  #    else
  #      json conn, "MUST BE ADMIN"
  #    end
  #  end


  def directorKycOverrideV2(conn, params)do

    %{"id" => admin_id} = conn.assigns[:current_user]

    result = KycDocumentsV2.directorKycOverride(params, admin_id)
    case result do
      {:ok, data} ->
        json conn, %{status_code: "200", message: data}
      {:error, changeset} ->
        render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} ->
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: message
               }
             }
      {:already_exist, add} ->
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: add
               }
             }
    end
  end

  @doc"employee kyc override"
  def employeeKycOverrideV2(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case KycDocumentsV2.employeeKycOverride(params, admin_id) do
      {:ok, data} ->
        json conn, %{status_code: "200", message: data}
      {:error, changeset} ->
        render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} ->
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: message
               }
             }
      {:already_exist, add} ->
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: add
               }
             }
    end
  end
@doc" "

  def directorKycCommentsV2(conn,params) do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    data = KycDocumentsV2.directorCommentSteps(params, admin_id)
    if type == "A"  do
      case data do
        {:ok, message} -> json conn, %{status_code: "200", message: message}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end


  @doc "active_user_proof/document/comment"
  def employeeKycCommentsV2(conn, params)do
    with true <-  (Enum.all?(["kycdocuments_id", "status", "comments"], &(Map.has_key?(params, &1)))) do
      %{"id" => admin_id} = conn.assigns[:current_user]
#      case KycDocuments.insert_active_user_kyc_proof_comment(params, admin_id) do
      case KycDocumentsV2.employeeCommentSteps(params, admin_id) do
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:ok, message} -> json conn, %{status_code: "200", message: message}
        {:document_error, message} -> json conn, %{status_code: "4004", document_error: %{message: message}}
        {:status_error, message} -> json conn, %{status_code: "4003", errors: %{status: message}}
        {:validation_error, message} -> json conn, message
      end
    else
      false ->
        json conn, %{status_code: "4004", parameter: %{error: "Required parameters: [kycdocuments_id, director_id, status, comments]"}}
    end
  end


end
