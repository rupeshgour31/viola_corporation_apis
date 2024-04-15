defmodule Violacorp.Models.Admin do
import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Administratorusers
  #alias  Violacorp.Schemas.Adminaccounts


def adminProfile(params)do

          _admin = Repo.one(from a in Administratorusers, where: a.id == ^params["id"],
          select: %{
                    fullname: a.fullname,
                    role: a.role,
                    unique_id: a.unique_id,
                    email_id: a.email_id,
                    contact_number: a.contact_number,
                    inserted_at: a.inserted_at,
                    status: a.status
          })
end

 @doc "
      This method for self admin profile view
      "
 def self_Profile(admin_id)do
     admin = Repo.one(from a in Administratorusers, where: a.id == ^admin_id,
                                                    select: %{
                                                      fullname: a.fullname,
                                                      role: a.role,
                                                      unique_id: a.unique_id,
                                                      email_id: a.email_id,
                                                      contact_number: a.contact_number,
                                                      inserted_at: a.inserted_at,
                                                      status: a.status
                                                    })
     get = Repo.one(from ad in Administratorusers, where: ad.id == ^admin_id and not is_nil(ad.browser_token), select: ad)
     merge = if !is_nil(get) do
          %{browser_token: "Yes"}
     else
          %{browser_token: "No"}
     end
     _final = Map.merge(admin,merge)

 end

def adminChangePassword(params,admin_id)do
    commanall = Repo.get!(Administratorusers, admin_id)
    changeset = %{password: params["new_password"]}
    if params["new_password"] == params["confirm_password"] do
            new_changeset = Administratorusers.changeset_password(commanall, changeset)
            case Repo.update(new_changeset) do
              {:ok, _message} -> {:ok, "Success, password changed"}
              {:error, changeset} -> {:error, changeset}
            end
      else
       {:error_message,"Password does not match, try again"}
    end
end
def changePassword(params)do
  commanall = Repo.get!(Administratorusers, params["id"])
  changeset = %{password: params["new_password"]}
  if params["new_password"] == params["confirm_password"] do
    new_changeset = Administratorusers.changeset_password(commanall, changeset)
    case Repo.update(new_changeset) do
      {:ok, _message} -> {:ok, "Success, password changed"}
      {:error, changeset} -> {:error, changeset}
    end
  else
    {:error_message,"Password does not match, try again"}
  end
end


end
