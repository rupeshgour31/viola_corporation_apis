defmodule ViolacorpWeb.Comman.GroupfeeView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Comman.GroupfeeView

  def render("index.json", %{groupfee: groupfee}) do
    %{status_code: "200", data: render_many(groupfee, GroupfeeView, "groupfee.json")}
  end

  def render("show.json", %{groupfee: groupfee}) do
    %{status_code: "200", data: render_one(groupfee, GroupfeeView, "groupfee.json")}
  end

  def render("groupfee_paginate.json", %{groupfee: groupfee}) do
    %{status_code: "200", total_count: groupfee.total_entries, page_number: groupfee.page_number, total_pages: groupfee.total_pages, data: render_many(groupfee.entries, GroupfeeView, "groupfee.json", as: :groupfee)}
  end

  def render("groupfee.json", %{groupfee: groupfee}) do
    rules = if !is_nil(groupfee.rules) do
      Poison.decode!(groupfee.rules)
    else
      nil
    end
    %{
      id: groupfee.id,
      title: groupfee.title,
      trans_type: groupfee.trans_type,
      fee_type: groupfee.fee_type,
      amount: groupfee.amount,
      as_default: groupfee.as_default,
      rules: rules,
      status: groupfee.status,
      inserted_at: groupfee.inserted_at,
      updated_at: groupfee.updated_at
    }
  end
end
