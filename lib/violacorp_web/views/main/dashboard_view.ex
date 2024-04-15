defmodule ViolacorpWeb.Main.DashboardView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Main.DashboardView

  def render("accounts.json", %{accounts: accounts}) do
    %{status_code: "200", data: render_many(accounts, DashboardView, "account.json", as: :account)}
  end

  def render("employeecards.json", %{employeecards: employeecards}) do
    %{status_code: "200", data: render_many(employeecards, DashboardView, "cards.json", as: :cards)}
  end

  #  card
  def render("cards.json", %{cards: cards}) do
    %{id: cards.id, currency_code: cards.currency_code, last_digit: cards.last_digit, expiry_date: cards.expiry_date, available_balance: cards.available_balance, current_balance: cards.available_balance, card_type: cards.card_type, status: cards.status}
  end

  #  account
  def render("account.json", %{account: account}) do
    %{id: account.id, available_balance: account.available_balance, current_balance: account.available_balance, currency_code: account.currency_code, account_number: account.account_number, user_id: account.accomplish_account_id, expiry_date: account.expiry_date, status: account.status}
  end

end
