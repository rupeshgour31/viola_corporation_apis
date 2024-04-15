defmodule ViolacorpWeb.Admin.Accounts.AccountsController do
  use Phoenix.Controller

  alias Violacorp.Models.Accounts

  @doc """
    Accounts List With Search
  """
  def getAllAccounts(conn, params)do
    data = Accounts.get_accounts(params)
    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
      data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def getAllaccountsTransactions(conn, params) do
    data = Accounts.get_transactions(params)
    conn
    |>put_view(ViolacorpWeb.AccountsView)
    |>render("index_with_pagination.json", data: data)
  end

  def accountsTransactionReciept(conn, params) do

    data = Accounts.accountsTransactionReciept(params)
    case data do
      nil->  json conn, %{status_code: "4004", msg: "Record not found"}
      _data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc """
    Accounts List With Search
  """
  def getAllAccounts_v2(conn, params)do
    data = Accounts.get_accounts(params)
    conn
    |> put_view(ViolacorpWeb.SuccessView)
    |> render("success.json", response: data)
  end

  def getAllaccountsTransactions_v2(conn, params) do
    data = Accounts.get_transactions(params)
    conn
    |>put_view(ViolacorpWeb.AccountsView)
    |>render("index_with_pagination.json", data: data)
  end

  def accountsTransactionReciept_v2(conn, params) do
    data = Accounts.accountsTransactionReciept(params)
    case data do
      nil -> conn
             |> put_view(ViolacorpWeb.ErrorView)
             |> render("recordNotFound.json")
      _data -> conn
               |> put_view(ViolacorpWeb.SuccessView)
               |> render("success.json", response: data)
    end
  end

  @doc """
    accounts Balance Refresh
  """
  def accountBalanceRefresh(conn, %{"account_id" => account_id} = _params) do
    case Accounts.balanceRefresh(account_id) do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:Invalid_account, message} ->
        json conn, %{status_code: "4004",errors: %{message: message}}
      {:third_party_error, code, message} ->
        json conn, %{status_code: code, errors: %{message: message}}
    end
  end

  @doc """
    accounts Balance Refresh
  """
  def accountBalanceRefresh_v2(conn, %{"account_id" => account_id} = _params) do
    case Accounts.balanceRefresh(account_id) do
      {:ok, message} ->
            conn
            |> put_view(ViolacorpWeb.SuccessView)
            |> render("success.json", response: message)
      {:error, changeset} ->
            conn
            |> put_view(ViolacorpWeb.ErrorView)
            |> render("error.json", changeset: changeset)
      {:Invalid_account, _message} ->
        conn
        |> put_view(ViolacorpWeb.SuccessView)
        |> render("accountNotFound.json")
#        json conn, %{status_code: "4004",errors: %{message: message}} # message is "Account not Found"
      {:third_party_error, code, message} ->
        json conn, %{status_code: code, errors: %{message: message}}
    end
  end
end
