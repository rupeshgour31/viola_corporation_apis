defmodule ViolacorpWeb.Comman.CountryView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Comman.CountryView

  def render("index.json", %{country: country}) do
    %{status_code: "200", data: render_many(country, CountryView, "country.json")}
  end

  def render("show.json", %{country: country}) do
    %{status_code: "200", data: render_one(country, CountryView, "country.json")}
  end

  def render("country.json", %{country: country}) do
    %{id: country.id, country_name: country.country_name, country_iso_2: country.country_iso_2, country_iso_3: country.country_iso_3, country_isdcode: country.country_isdcode}
  end
end
