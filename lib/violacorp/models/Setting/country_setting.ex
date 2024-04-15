defmodule Violacorp.Models.Settings.CountrySetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Kyccountry
  @moduledoc false

  @doc "Settings Country List"

  def countries_list(params) do

    filtered = if !is_nil(params["status"]) or !is_nil(params["country_iso_2"]) or !is_nil(params["country_name"]) or !is_nil(params["country_isdcode"]) do
          params
          |> Map.take(~w(country_iso_2 country_name country_isdcode status))
          |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      else
          %{"status" => "A"} |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      end
      (from a in Countries,
           having: ^filtered,
           select: %{
             id: a.id,
             country_name: a.country_name,
             country_iso2: a.country_iso_2,
             country_iso3: a.country_iso_3,
             country_code: a.country_isdcode,
             status: a.status
           })
     |> order_by(asc: :country_name)
     |> Repo.paginate(params)
  end

   def kyc_countries_list(params) do
    _data = (from k in Kyccountry, order_by: [asc: k.title],
                 select: %{id: k.id,title: k.title, status: k.status})
           |> Repo.paginate(params)
  end

  def update_KycCountryStatus(params)do
    id = params["id"]
    status = %{status: params["status"]}
    data = Repo.get_by(Kyccountry, id: id)
    if !is_nil(data)do
      changeset = Kyccountry.changeset(data, status)
      case Repo.update(changeset)do
        {:ok, _message} -> {:ok,"KycCountry Status Updated Successfully"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc "edit country"
  def edit_country(params) do
    country = Repo.get_by(Countries, id: params["id"])
    if !is_nil(country) do
      map = %{
        "status" => params["status"]
      }
      changeset = Countries.updateChangeset(country, map)
      case Repo.update(changeset) do
        {:ok, _changeset} -> {:ok, "Record updated"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:not_found, "Record not found!"}
    end
  end
end