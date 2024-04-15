defmodule Violacorp.Settings.CurrenciesSetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Currencies
  @moduledoc false

  @doc "Settings Currency List"

  def currencies_list(params) do

       filtered = if !is_nil(params["status"]) or !is_nil(params["currency_name"]) or !is_nil(params["currency_code"])  do
                     params
                     |> Map.take(~w(currency_name currency_code status))
                     |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
                  else
                    %{"status" => "A"} |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
                  end
       (from a in Currencies,
          having: ^filtered,
          select: %{
             id: a.id,
             countries_id: a.countries_id,
             currency_name: a.currency_name,
             currency_code: a.currency_code,
             currency_symbol: a.currency_symbol,
             status: a.status
       })
       |> order_by(asc: :currency_name)
       |> Repo.paginate(params)
  end

  @doc "get Currency list with out paginate"
  def currenciesGetAll(_params) do
    (from a in Currencies,
          where: a.status == ^"A",
          select: %{
            id: a.id,
            countries_id: a.countries_id,
            currency_code: a.currency_code,
            currency_symbol: a.currency_symbol,
          })
    |> order_by(desc: :id)
    |> Repo.all()
  end

  @doc "update currency"

  def edit_currency(params) do
    currency = Repo.get_by(Currencies, id: params["id"])

    if !is_nil(currency) do
      currency_map = %{
        status: params["status"]
      }
      changeset = Currencies.updateChangeset(currency,currency_map)
            case Repo.update(changeset) do
              {:ok, _changeset} -> {:ok, "Record updated"}
              {:error, changeset} -> {:error, changeset}
            end
    else
        {:not_found, "Record not found!"}
    end
  end

end
