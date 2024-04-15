defmodule ViolacorpWeb.Comman.CurrencyController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Currencies
  alias ViolacorpWeb.Comman.CurrencyView

  @doc "inserts a currency to currencies table"
  def insertCurrency(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]

      currency = %{
        "countries_id" => params["countries_id"],
        "currency_name" => params["currency_name"],
        "currency_code" => params["currency_code"],
        "currency_symbol" => params["currency_symbol"],
        "inserted_by" => commanid
      }

      changeset = Currencies.changeset(%Currencies{}, currency)
      case Repo.insert(changeset) do
        {:ok, currency} -> render(conn, CurrencyView, "show.json", currency: currency)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a currency to currencies table"
  def updateCurrency(conn, %{"id" => id, "currency" => params}) do
    currency = Repo.get!(Currencies, id)
    changeset = Currencies.changeset(currency, params)
    case Repo.update(changeset) do
      {:ok, currency} -> render(conn, CurrencyView, "show.json", currency: currency)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end
  @doc "gets all currencies list from currencies table"
  def getAllCurrency(conn, _params) do
    currency = Repo.all(from c in Currencies, where: c.status == "A")
    render(conn, CurrencyView, "index.json", currency: currency)
  end

  @doc "gets single currency from currencies table"
  def getSingleCurrency(conn, params) do
    currency = Repo.one(from c in Currencies, where: c.id == ^params["id"])
    render(conn, CurrencyView, "show.json", currency: currency)
  end

end
