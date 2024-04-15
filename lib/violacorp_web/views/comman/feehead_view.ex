defmodule ViolacorpWeb.Comman.FeeheadView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Comman.FeeheadView

  def render("index.json", %{feehead: feehead}) do
    %{status_code: "200", data: render_many(feehead, FeeheadView, "feehead.json")}
  end

  def render("show.json", %{feehead: feehead}) do
    %{status_code: "200", data: render_one(feehead, FeeheadView, "feehead.json")}
  end

  def render("feehead_paginate.json", %{feehead: feehead}) do
    %{status_code: "200", total_count: feehead.total_entries, page_number: feehead.page_number, total_pages: feehead.total_pages, data: render_many(feehead.entries, FeeheadView, "feehead.json", as: :feehead)}
  end

  def render("feehead.json", %{feehead: feehead}) do
    %{id: feehead.id, title: feehead.title, status: feehead.status, inserted_at: feehead.inserted_at, updated_at: feehead.updated_at}
  end
end
