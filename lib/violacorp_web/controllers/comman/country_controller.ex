defmodule ViolacorpWeb.Comman.CountryController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Kyccountry
  alias ViolacorpWeb.Comman.CountryView

  @doc "inserts a country to countries table"
  def insertCountry(conn, params) do
    unless map_size(params) == 0 do
      %{"commanall_id" => commanid} = conn.assigns[:current_user]
      country = %{
        "country_name" => params["country_name"],
        "country_iso_3" => params["country_iso_3"],
        "country_iso_2" => params["country_iso_2"],
        "country_isdcode" => params["country_isdcode"],
        "inserted_by" => commanid
      }
      changeset = Countries.changeset(%Countries{}, country)
      case Repo.insert(changeset) do
        {:ok, country} -> render(conn, CountryView, "show.json", country: country)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "updates a country to countries table"
  def updateCountry(conn, %{"id" => id, "country" => params}) do
    country = Repo.get!(Countries, id)
    changeset = Countries.changeset(country, params)
    case Repo.update(changeset) do
      {:ok, country} -> render(conn, CountryView, "show.json", country: country)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc "gets all countries list from countries table"
  def getAllCountry(conn, _params) do
    country = Repo.all(from c in Countries, where: c.status == "A")
    render(conn, CountryView, "index.json", country: country)

  end
  @doc "gets all countries list from countries table"
  def getAllCountryv1(conn, _params) do
    country = Repo.all(from c in Countries)
    render(conn, CountryView, "index.json", country: country)

  end

  @doc "gets single country from countries table"
  def getSingleCountry(conn, params) do
    country = Repo.one(from c in Countries, where: c.id == ^params["id"])
    render(conn, CountryView, "show.json", country: country)
  end

  @doc"get active KycCountry list"
  def getKycCountry(conn, _params) do

    case Cachex.get!(:vcorp, "kyc_country") do
      nil ->
        data = Repo.all(
          from k in Kyccountry, where: k.status == ^"A",
                                select: %{
                                  title: k.title
                                }
        )
        add = case data do
          [] -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
          data -> data
        end
        Cachex.start_link(:vcorp)
        Cachex.put(:vcorp, "kyc_country", add)
        json conn, %{status_code: "200", data: add}
      getCache -> json conn, %{status_code: "200", data: getCache}
    end
  end
end
