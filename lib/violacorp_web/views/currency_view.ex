defmodule ViolacorpWeb.CurrencyView do
  use ViolacorpWeb, :view


  def render("show.json", %{currency: currency}) do
    %{status_code: "200", data: render_one(currency, CurrencyView, "currency.json")}
  end

  def render("currency.json", %{currency: currency}) do
    %{id: currency.id, countries_id: currency.countries_id, currency_name: currency.currency_name, currency_code: currency.currency_code, currency_symbol: currency.currency_symbol}
  end

end
