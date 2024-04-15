defmodule ViolacorpWeb.Admin.Settings.CurrencyController do
  use Phoenix.Controller

  alias Violacorp.Settings.CurrenciesSetting
  @moduledoc false

  @doc "Settings Currency List"

  def currenciesList(conn, params) do
    data = CurrenciesSetting.currencies_list(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def currenciesGetAll(conn, params) do
    data = CurrenciesSetting.currenciesGetAll(params)
    json conn, %{status_code: "200", data: data}
  end

  @doc "edit currency"
  def update_currency(conn, params)do
    unless map_size(params) == 0 do
      case CurrenciesSetting.edit_currency(params)do
        {:ok, message} ->
          conn
          |>put_view(ViolacorpWeb.SuccessView)
          |> render("success.json", response: message)
        {:error, changeset} ->
          conn
          |> put_view(ViolacorpWeb.ErrorView)
          |> render("error.json", changeset: changeset)
        {:not_found, changeset} ->
          conn
          |>put_view(ViolacorpWeb.ErrorView)
          |>render("recordNotFound.json", error: changeset)
        {:error_message, message} -> json conn , %{status_code: "4004", errors: %{message: message}}
      end
    else
      conn
      |>render(ViolacorpWeb.ErrorView, "errorNoParameter.json")
    end
  end


end
