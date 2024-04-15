defmodule ViolacorpWeb.AccountsView do
  use ViolacorpWeb, :view

  import Ecto.Query

  alias Violacorp.Repo

  alias  ViolacorpWeb.AccountsView

#  alias  ViolacorpWeb.Companybankaccount
  alias  Violacorp.Schemas.Companybankaccount
#  alias  ViolacorpWeb.Adminaccounts
  alias  Violacorp.Schemas.Adminaccounts
  alias  Violacorp.Schemas.Adminbeneficiaries

  #  alias  Violacorp.Schemas.Companybankaccount
  #  alias  Violacorp.Schemas.Adminaccounts

  def render("index_with_pagination.json", %{data: data}) do

    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, AccountsView, "accounts.json", as: :accounts)
    }
  end

  def render("accounts.json", %{accounts: accounts}) do
    # %{from_user: "WORKING"}

    from = case accounts.mode do
      "C" ->
        Repo.one(
          from cba in Companybankaccount, where: cba.iban_number == ^accounts.from_user, select: cba.account_name)
      "D" ->
        Repo.one(from cba in Adminaccounts, where: cba.iban_number == ^accounts.from_user, select: cba.account_name)
    end

    to_name = case accounts.mode do
      "D" ->
        Repo.one(from cba in Companybankaccount, where: cba.iban_number == ^accounts.to_user, select: cba.account_name)
      "C" ->
        Repo.one(from cba in Adminaccounts, where: cba.iban_number == ^accounts.to_user, select: cba.account_name)
    end

    to = case to_name do
      nil ->
        long_to = accounts.to_user
        short_to = String.slice(long_to, 10..17)
        Repo.one(from adben in Adminbeneficiaries, where: adben.account_number == ^short_to, select: adben.fullname)
      _ -> to_name
    end

    %{
      from_user: from,
      to_user: to,
      id: accounts.id,
      currency: accounts.currency,
      transaction_id: accounts.transaction_id,
      mode: accounts.mode,
      amount: accounts.amount,
      transaction_date: accounts.transaction_date,
      status: accounts.status
    }
  end
end