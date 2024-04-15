defmodule ViolacorpWeb.Admin.AlertswitchController do
  use ViolacorpWeb, :controller
  alias Violacorp.Repo
  import Ecto.Query
  @moduledoc false

  alias Violacorp.Schemas.Alertswitch

  @doc "getAll List from alert switch  table"
  def getAllAlertswitch(conn, params)do
    filtered = params
               |> Map.take(~w( section))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    list_alert_switch =  Alertswitch
                      |> where(^filtered)
                      |> select([a], %{id: a.id,email: a.email, section: a.section, notification: a.notification, sms: a.sms, inserted_by: a.inserted_by, inserted_at: a.inserted_at})
                      |> order_by(desc: :updated_at)
                      |> Repo.paginate(params)

    if !is_nil(list_alert_switch)do
      json conn, %{status_code: "200",total_pages: list_alert_switch.total_pages,total_entries: list_alert_switch.total_entries, page_size: list_alert_switch.page_size, page_number: list_alert_switch.page_number, data: list_alert_switch.entries}

    else
      conn
      |> put_view(ViolacorpWeb.ErrorView)
      |> render("recordNotFound.json")
    end
end

  @doc "get single record from alert switch  table"
  def singleAlertswitch(conn, params) do
    single_alerts_switch = Repo.get_by(Alertswitch, id: params["id"])

    case single_alerts_switch do
      nil ->
        conn
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("recordNotFound.json")
      data -> json conn,  %{status_code: "200", data: data}
    end
end


  @doc "add  records in alert switch  table"
  def insertAlertswitch(conn, params)do
      unless map_size(params) == 0 do
          username = params["username"]
          sec_password = params["sec_password"]
          request_id = params["request_id"]
          viola_user = Application.get_env(:violacorp, :username)
          viola_password = Application.get_env(:violacorp, :password)

         if username == viola_user and sec_password == viola_password do
            check_section = Repo.get_by(Alertswitch, Section: params["section"], status: "A")
            if is_nil(check_section) do
              alert_switch = %{
                "section" => params["section"],
                "email"  => params["email"],
                "notification"  => params["notification"],
                "sms"   => params["sms"],
                "subject"   => params["subject"],
                "templatefile"   => params["templatefile"],
                "sms_body"   => params["sms_body"],
                "notification_body"   => params["notification_body"],
                "layoutfile"   => params["layoutfile"],
                "inserted_by" =>  request_id
              }
              changeset = Alertswitch.changeset(%Alertswitch{}, alert_switch)
              case Repo.insert(changeset) do
                {:ok, _data} -> json conn , %{status_code: "200", msg: "Section Added"}
                {:error,changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              json conn, %{status_code: "4003",errors: %{section: "already exist"}}
            end
         else
             json conn, %{status_code: "402",errors: %{message: "You have not permission to any update, Please contact to administrator."}}
         end
      else
         conn
         |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
      end
  end

  @doc "edit data in  alert switch table"
  def editAlertSwitch(conn, params)do
      unless map_size(params) == 0 do
          username = params["username"]
          sec_password = params["sec_password"]
          _request_id = params["request_id"]
          viola_user = Application.get_env(:violacorp, :username)
          viola_password = Application.get_env(:violacorp, :password)

         if username == viola_user and sec_password == viola_password do
            alert_switch = Repo.get_by(Alertswitch, id: params["id"])
            if !is_nil(alert_switch) do
               map = %{
                  "section" => params["section"],
                  "email" => params["email"],
                  "sms" => params["sms"],
                  "notification" => params["notification"],
                  "subject"   => params["subject"],
                  "templatefile"   => params["templatefile"],
                  "sms_body"   => params["sms_body"],
                  "notification_body"   => params["notification_body"],
                  "layoutfile"   => params["layoutfile"],
                  "status" => params["status"]
               }
               changeset = Alertswitch.changeset(alert_switch, map)
                case Repo.update(changeset)do
                  {:ok, _data} -> json conn , %{status_code: "200", msg: "Record Updated"}
                  {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                end
            else
                json conn, %{status_code: "4003", error: %{msg: "id doesn't exists"}}
            end
         else
              json conn, %{status_code: "402",errors: %{message: "You have not permission to any update, Please contact to administrator."}}
         end
     else
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
     end
  end
end
