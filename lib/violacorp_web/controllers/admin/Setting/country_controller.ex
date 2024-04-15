defmodule ViolacorpWeb.Admin.Settings.CountryController do
  use Phoenix.Controller

  alias Violacorp.Models.Settings.CountrySetting
#  alias ViolacorpWeb.ErrorView
  @moduledoc false

  @doc "Settings Country List"

  def countriesList(conn, params) do
    data = CountrySetting.countries_list(params)
       json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def getKycCountrylist(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      data = CountrySetting.kyc_countries_list(params)
      case data.entries do
        [] -> json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
        _data -> json conn, %{status_code: "200", total_count: data.total_entries, data: data.entries, page_number: data.page_number, total_pages: data.total_pages}
      end
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def updateKycCountryStatus(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      data = CountrySetting.update_KycCountryStatus(params)
      case data do
        {:ok, message} -> json conn, %{status_code: "200", message: message}
        {:error_message, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
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

  @doc "edit country"
  def  countryEdit(conn, params)do
    unless map_size(params) == 0 do
      case CountrySetting.edit_country(params)do
        {:ok, message} ->
          conn
          |>put_view(ViolacorpWeb.SuccessView)
          |>render("success.json", response: message)
        {:error, changeset} ->
          conn
          |> put_view(ViolacorpWeb.ErrorView)
          |> render("error.json", changeset: changeset)
        {:not_found, changeset} ->
          conn
          |>put_view(ViolacorpWeb.ErrorView)
          |>render("recordNotFound.json", error: changeset)
        {:error_message, _message} -> json conn , %{status_code: "4004", errors: %{message: "country already exists"},}
      end
    else
      conn
      |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
    end
  end
end
