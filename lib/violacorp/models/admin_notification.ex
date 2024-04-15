defmodule Violacorp.Models.AdminNotification do
#  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Administratorusers

@doc "
     This is for update browser token
"
  def updateToken(params,admin_id) do
    admin = Repo.get_by(Administratorusers, id: admin_id)
    if !is_nil(admin)do
      token =  %{"browser_token" => params["browsertoken"]}
      changeset = Administratorusers.changesetBrowserToken(admin, token)
      _result =  case Repo.update(changeset) do
        {:ok, _data} -> {:ok, "Success, Browser Token Updated"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      nil
    end
  end

  @doc "
     This is for delete browser token
"
  def deleteToken(_params,admin_id) do
    admin = Repo.get_by(Administratorusers, id: admin_id)
    token = %{"browser_token" =>  ""}
    if !is_nil(admin) do
      changeset = Administratorusers.changesetSDeleteBrowserToken(admin, token)
      _result =  case Repo.update(changeset) do
        {:ok, _data} ->  {:ok,"Success, Browser Token Deleted"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      nil
    end
  end

  @doc "
      This is for update notification status for admin
        "
 def update_notification_status(params)do
        admin = Repo.get_by(Administratorusers, id: params["id"])
    if !is_nil(admin)do
        update = Administratorusers.changesetNotificationStatus(admin, %{"notification_status" => params["status"]})
        case Repo.update(update) do
          {:ok, _changeset} -> {:ok, "Notification Status has been Updated"}
          {:error, changeset} -> {:error, changeset}
        end
    else
        {:error_message, "Record not Found."}
    end
 end
end