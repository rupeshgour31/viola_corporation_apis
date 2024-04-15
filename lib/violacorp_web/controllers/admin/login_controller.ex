defmodule ViolacorpWeb.Admin.LoginController do
  use Phoenix.Controller
  require Logger

  alias  Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Libraries.Loginhistory


  @doc "admin login"
  def login(conn, params) do
    unless map_size(params) == 0 do
      adminUser = Repo.one(
        from a in Administratorusers, where: a.email_id == ^params["email_id"] and a.password == ^params["password"],
                                      select: %{
                                        id: a.id,
                                        viola_id: a.unique_id,
                                        email_id: a.email_id,
                                        status: a.status,
                                        is_primary: a.is_primary,
                                        role: a.role,
                                        fullname: a.fullname,
                                        l_name: a.permissions
                                      }
      )

      #    check if record is empty
      if is_nil(adminUser) do
        Loginhistory.addAdminLoginHistory(params["email_id"], nil, nil, nil, nil)
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
        |> halt
      else
        case adminUser.status do
          "A" ->
            abc = conn
                  |> assign_token(adminUser, params)
            case String.valid?(abc) do
              false -> Loginhistory.addAdminLoginHistory(adminUser, nil, nil, nil, nil)
                       conn
                       |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :assign_token_failed)
                       |> halt
              _ ->
                Loginhistory.addAdminLoginHistory(adminUser, nil, nil, nil, nil)
                json  conn,
                      %{
                        status_code: "200",
                        token: abc,
                        email_id: adminUser.email_id,
                        role: adminUser.role,
                        fullname: adminUser.fullname,
                        id: adminUser.id,
                        status: adminUser.status,
                        is_primary: adminUser.is_primary,
                        l_name: adminUser.l_name
                      }
            end
          "D" ->
            Loginhistory.addAdminLoginHistory(adminUser, nil, nil, nil, nil)
            conn
            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :userDeactive)
            |> halt

          "B" ->
            Loginhistory.addAdminLoginHistory(adminUser, nil, nil, nil, nil)
            conn
            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :userBlocked)
            |> halt

          _ ->
            Loginhistory.addAdminLoginHistory(adminUser, nil, nil, nil, nil)
            conn
            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
            |> halt
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc  "if password match assigns token"
  def assign_token(_status, admin, _params) do
    keyfortoken = Application.get_env(:violacorp, :tokenKey)
    payload = %{
      "email" => admin.email_id,
      "type" => "A",
      "id" => admin.id,
      "is_primary" => admin.is_primary,
    }
    token = create_token(keyfortoken, payload)
    new_admin = Repo.get(Administratorusers, admin.id)
    if is_map(new_admin) do

      token_map =
        %{
          api_token: token
        }

      token_changeset = Administratorusers.changesetToken(new_admin, token_map)

      case Repo.update(token_changeset) do
        {:ok, _admin} -> token
        {:error, _changeset} ->
          Logger.warn("Token update failed in assign token for #{admin.id}")
      end
    else
      Logger.warn("Query on in assign token has failed for #{admin.id}")
    end
  end

  @doc "Create Token"
  def create_token(key_for_token, payload) do
    Phoenix.Token.sign(ViolacorpWeb.Endpoint, key_for_token, payload)
  end

  def logoutAdmin(conn, _params)do
    %{"type" => _type, "id" => admin_id} = conn.assigns[:current_user]
    admin = Repo.one(from a in Administratorusers, where: a.id == ^admin_id, select: a)
    case admin do
      nil ->
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "No user found"
               }
             }
      data ->
        up = %{
          api_token: nil
        }
        changeset = Administratorusers.changesetToken(data, up)
        Repo.update(changeset)
        json conn, %{status_code: "200", message: "Logout Successful"}
    end
  end

  def resetTokenAdmin(conn, params)do
    unless map_size(params) == 0 do

      admin = Repo.get_by(Administratorusers, id: params["id"])

      # check if record is empty
      if is_nil(admin) do
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :recordNotFound)
        |> halt
      else
        abc = conn
              |> assign_token(admin, admin)
        case abc do
          "fail" ->
            conn
            |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :assign_token_failed)
            |> halt
          _ -> json  conn,
                     %{
                       code: "1010",
                       status: "success",
                       status_code: "200",
                       token: abc,
                       email: admin.email_id
                     }
        end
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end
end
