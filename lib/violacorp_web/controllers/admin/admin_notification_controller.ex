defmodule ViolacorpWeb.Admin.AdminNotificationController do
  use Phoenix.Controller

  alias Violacorp.Models.AdminNotification

#  alias Violacorp.Libraries.Notification

   @doc "
          This method for store browser token into database
     "
  def storeBrowserToken(conn, params)do
      %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
      if type == "A" do
          data = AdminNotification.updateToken(params,admin_id)
          if !is_nil(data) do
                case data do
                  {:ok, _data} -> json conn, %{status_code: "200", message: "Success, Browser Token Updated"}
                  {:error, changeset} ->
                    conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                end
          else
            json conn, %{status_code: "4004", errors: %{message: "Could not update browser token"}}
          end
      else
        json conn, %{status_code: "4004",errors: %{ message: "You have not permission to access this endpoint."}}
      end
  end

  @doc "
          This method for delete browser token into database
     "
  def deleteBrowserToken(conn, params)do
     %{"id" => admin_id,  "type" => type} = conn.assigns[:current_user]
      if type == "A" do
          data = AdminNotification.deleteToken(params, admin_id)
          if !is_nil(data) do
              case data do
                {:ok, _data} -> json conn, %{status_code: "200",message: "Success, Browser Token Deleted"}
                {:error, changeset} ->
                  conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
          else
            json conn, %{status_code: "4004", errors: %{message: "Record Not Found"}}
          end
      else
        json conn, %{status_code: "4004",errors: %{message: "You have not permission to access this endpoint."}}
      end
  end

  @doc "
          This method for update notification status for administrator user
     "
  def updateNotificationStatus(conn, params) do
      %{"type" => type, "id" => _id} = conn.assigns[:current_user]
      if type == "A"  do
          data = AdminNotification.update_notification_status(params)
          case data do
            {:ok, _data} -> json conn, %{status_code: "200", message: "Success, notification status Updated"}
            {:error, changeset} ->
                                  conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            {:error_message, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
          end
      else
        json conn, %{status_code: "4002", errors: %{message: "Update Permission Required, Please Contact Administrator."}}
      end
  end
end
