defmodule ViolacorpWeb.Admin.Setting.SettingController do
  use Phoenix.Controller
  alias Violacorp.Models.Setting
  alias ViolacorpWeb.ErrorView

  @doc "add new country"
  def  insert_country(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
      case Setting.country_add(request)do
        {:ok, message} ->
          conn
          |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
        {:error, changeset} ->
          conn
          |> put_view(ErrorView)
          |> render("error.json", changeset: changeset)
        {:country_name, message} -> json conn , %{status_code: "4003", errors: %{country_name: message}}
        {:country_iso_2, message} -> json conn , %{status_code: "4003", errors: %{country_iso_2: message}}
        {:country_iso_3, message} -> json conn , %{status_code: "4003", errors: %{country_iso_3: message}}
        {:country_isdcode, message} -> json conn , %{status_code: "4003", errors: %{country_isdcode: message}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end


  @doc "get all country list"
  def getCountry(conn, params)do
          country = Setting.countries_list(params)
          case country do
            [] -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: country)
            country  ->
              json conn, %{status_code: "200", data: country}
          end
  end

  @doc "get all activated country"
  def get_single_country(conn, params)do
          country = Setting.single_country(params)
          case country do
              nil -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: country)
               country  ->
               json conn, %{status_code: "200", data: country}
          end
        end

  @doc "get all deactive country"
  def  activeCountry(conn, params)do
    country = Setting.active_country(params)
    case country do
      [] -> render(conn, ErrorView, "recordNotFound.json", data: country)
      country  ->
        conn
        |> render(ViolacorpWeb.CountryView,"d_active_countries.json", country: country)
    end
  end

  @doc "add  currency"
  def insert_currency(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
        unless map_size(params) == 0 do
                case  Setting.add_currency(params, admin_id) do
                    {:ok, message} ->
                    conn
                    |> put_view(ViolacorpWeb.SuccessView)
                    |> render("success.json", response: message)
                    {:error, changeset} ->
                    conn
                    |> put_view(ViolacorpWeb.ErrorView)
                    |> render("error.json", changeset: changeset)
                    {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
                end
        else
          conn
          |>render(ViolacorpWeb.ErrorView,"errorNoParameter.json")
        end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  @doc "insert document category "
  def insert_document_category(conn, params)do
    %{"id" => admin_id} = conn.assigns[:current_user]
    unless map_size(params) == 0 do
      request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
      case Setting.add_document_category(request)do
         {:ok, message} ->
            conn
            |> put_view(ViolacorpWeb.SuccessView)
            |> render("success.json", response: message)
         {:error, changeset} ->
            conn
            |> put_view(ViolacorpWeb.ErrorView)
            |> render("error.json", changeset: changeset)
         {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
      end
    else
      conn
      |>render(ViolacorpWeb.ErrorView,"errorNoParameter.json")
    end
  end

  @doc "edit document category"
  def update_document_category(conn, params)do
     unless map_size(params) == 0 do
          case Setting.edit_documentcategory(params)do
            {:ok, message} ->
            conn
#            |>put_status(:ok)
            |>put_view(ViolacorpWeb.SuccessView)
            |> render("success.json", response: message)
            {:error, changeset} ->
            conn
#            |> put_status(:not_acceptable)
            |> put_view(ViolacorpWeb.ErrorView)
            |> render("error.json", changeset: changeset)
            {:not_found, changeset} ->
              conn
#              |>put_status(:not_found)
              |>put_view(ViolacorpWeb.ErrorView)
              |>render("recordNotFound.json", error: changeset)
            {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
          end
       else
       conn
       |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
     end
  end

  @doc "get all document category "
  def get_all_document_category(conn, params)do
    data =  Setting.get_all_documentCategory(params)
    case data do
      [] -> render(conn, ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data}
    end

  end

  @doc "add document type"
  def insert_document_type(conn, params)do
         %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
         request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
         if type == "A"  do
            case Setting.add_document_type(request)do
              {:ok, _message} -> json conn, %{status_code: "200", message: "Department Added."}
             {:error, changeset}->
               conn
                 |> put_view(ViolacorpWeb.ErrorView)
                 |> render("error.json", changeset: changeset)
              {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
             end
         else
           json conn, %{status_code: "4002", errors: %{
             message: "Update Permission Required, Please Contact Administrator."}
           }
         end
  end

  @doc "update document type"
  def update_document_type(conn, params)do
          unless map_size(params) == 0 do
                     case Setting.edit_document_type(params)do
                     {:ok, message} -> json conn, %{status_code: "200", message: message}
                     {:error, changeset} ->
                     conn
#                         |> put_status(:not_acceptable)
                         |> put_view(ViolacorpWeb.ErrorView)
                         |> render("error.json", changeset: changeset)
                     {:not_found, changeset} ->
                     conn
#                         |>put_status(:not_found)
                         |>put_view(ViolacorpWeb.ErrorView)
                         |>render("recordNotFound.json", error: changeset)
                     {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
                     end
           else
            conn
            |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
          end
  end

  @doc " get all document type type "
  def get_all_documenttype(conn, params)do
      data =  Setting.get_document(params)
      json conn, %{status_code: "200",total_pages: data.total_pages,total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc "add new department"
  def insert_department(conn, params)do
      %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
      request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
          if type == "A"  do
                case Setting.add_department(request)do
                {:ok, _message} -> json conn, %{status_code: "200", message: "Department Added."}
                {:error, changeset}->
                    conn
                    |> put_view(ViolacorpWeb.ErrorView)
                    |> render("error.json", changeset: changeset)
                {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
                end
          else
            json conn, %{status_code: "4002", errors: %{
              message: "Update Permission Required, Please Contact Administrator."}
            }
          end
  end

  @doc"add project"
  def insert_project(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      case Setting.add_project(params, admin_id)do
        {:ok, message} ->
          conn
          |>put_view(ViolacorpWeb.SuccessView)
          |>render("success.json", response: message)
        {:error, changeset}->
          conn
          |> put_view(ViolacorpWeb.ErrorView)
          |> render("error.json", changeset: changeset)
        {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  @doc"add application version"
  def insertApplicationVersion(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
          unless map_size(params) == 0 do
            case Setting.add_appVersion(params, admin_id)do
              {:ok, message} ->
                conn
#                |>put_status(:ok)
                |>put_view(ViolacorpWeb.SuccessView)
                |>render("success.json", response: message)
              {:error, changeset}->
                conn
                |> put_view(ViolacorpWeb.ErrorView)
                |> render("error.json", changeset: changeset)
            end
          else
            conn
            |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
          end
      else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  @doc "edit department"
  def update_departments(conn, params)do

    unless map_size(params) == 0 do
       case Setting.edit_departments(params)do
         {:ok, message} ->
          conn
#         |>put_status(:ok)
          |> put_view(ViolacorpWeb.SuccessView)
          |>render("success.json", response: message)
          {:error, changeset}->
          conn
#         |>put_status(:not_acceptable)
          |>put_view(ViolacorpWeb.ErrorView)
          |>render("error.json", changeset: changeset)
         {:not_found, changeset} ->
           conn
#          |>put_status(:not_found)
           |>put_view(ViolacorpWeb.ErrorView)
           |>render("recordNotFound.json", error: changeset)
         {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
       end
    else
      conn
      |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
    end
  end

  @doc"edit versions"
  def editVersion(conn, params) do

    data = Setting.edit_version(params)
    case data do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:error, changeset} -> conn
                             |>put_view(ViolacorpWeb.ErrorView)
                             |>render("error.json", changeset: changeset)
      {:not_found, _check} -> conn
                             |>put_view(ViolacorpWeb.ErrorView)
                             |>render("recordNotFound.json")
    end
  end

  @doc"get all version"
  def version(conn, params)do
    data =  Setting.get_version(params)
    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc"add alert switch"
  def insertAlertSwitch(conn, params)do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      case Setting.add_alert_switch(params, admin_id)do
        {:ok, message} ->
          conn
#          |>put_status(:ok)
          |>put_view(ViolacorpWeb.SuccessView)
          |>render("success.json", response: message)
        {:error, changeset}->
          conn
#          |> put_status(:not_acceptable)
          |> put_view(ViolacorpWeb.ErrorView)
          |> render("error.json", changeset: changeset)
        {:exist_section, message}->
          json conn, %{status_code: "4003",errors: %{section: message}}
      end
    else
      conn
      |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
    end

  end

  @doc"update project"
  def updateProject(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      case Setting.updateProjectDetail(params)do
        {:ok, message} ->
          conn
          |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:error_message, error_message} ->
          json conn, %{status_code: "4004", errors: %{ message: error_message}}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
end

