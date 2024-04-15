defmodule ViolacorpWeb.CountryView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.CountryView

  def render("index.json", %{country: country}) do

    %{status_code: "200", data: render_many(country, CountryView, "country.json")}
  end

  def render("country.json", %{country: country}) do
    %{id: country.id, country_name: country.country_name,  status: country.status}
  end


  def render("active_countries.json", %{country: country})do
    %{status_code: "200", data: render_many(country, CountryView, "country.json")}

  end

  def render("d_active_countries.json", %{country: country})do
    %{status_code: "200",total_count: country.total_entries, page_number: country.page_number, total_pages: country.total_pages, data: render_many(country, CountryView, "country.json")}

  end

end
