defmodule Violacorp.Models.Accounts do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Adminbeneficiaries
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Accomplish


  @doc """
    Accounts List With Search
  """
  def get_accounts(params)do
#    filtered = params
#               |> Map.take(~w(account_number  account_name))
#               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    account_number = params["account_number"]
    account_name = params["account_name"]

    _data = (from a in Adminaccounts,
          where: like(a.account_number, ^"%#{account_number}%") and like(a.account_name, ^"%#{account_name}%"),
          left_join: b in Adminbeneficiaries,
          on: b.adminaccounts_id == a.id,
          select: %{
            id: a.id,
            beneficiary_id: b.id,
            account_number: a.account_number,
            account_name: a.account_name,
            sort_code: a.sort_code,
            currency: a.currency,
            balance: a.balance,
            status: a.status
          })
    |> Repo.paginate(params)
  end

  def get_transactions(params) do

    filtered = params
               |> Map.take(~w( amount transaction_id status mode))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    (from a in Admintransactions,
          having: ^filtered,
          where: a.adminaccounts_id == ^params["id"]
    )
    |>order_by(desc: :id)
    |> Repo.paginate(params)
  end

  def accountsTransactionReciept(params) do

    reciept = (
                from a in Admintransactions,
                     where: a.id == ^params["id"],
                     select: %{
                       id: a.id,
                       currency: a.currency,
                       from_IBAN: a.from_user,
                       to_IBAN: a.to_user,
                       transaction_id: a.transaction_id,
                       reference_id: a.reference_id,
                       transaction_status: a.status,
                       transaction_date: a.transaction_date,
                       amount: a.amount,
                       note: a.description,
                     }
                )
              |> Repo.one()

    case reciept do
      nil -> nil
      _ ->

        ibanfrom = reciept.from_IBAN
        ibanto = reciept.to_IBAN

          from_name = Repo.one(
            from a in Companybankaccount,
            where: a.iban_number == ^ibanfrom,
            select: %{
              name: a.account_name
            }
          )
          to_name = Repo.one(
            from a in Companybankaccount,
            where: a.iban_number == ^ibanto,

            select: %{
              name: a.account_name
            }
          )

          name_to = case to_name do
            nil ->
              q = Repo.one(
                from s in Adminaccounts, where: s.iban_number == ^ibanto,
                                         select: %{
                                           name: s.account_name
                                         }
              )
              case q do
                nil -> %{name: "Card Management"}
                _ -> q
              end
            _ -> to_name
          end

          name_from = case from_name do
            nil -> #%{name: "#NO NAME#"}

              Repo.one(
                from s in Adminaccounts, where: s.iban_number == ^ibanfrom,
                                         select: %{
                                           name: s.account_name
                                         }
              )
            _ -> from_name

          end
         _map = %{
            from_iban: reciept.from_IBAN,
            to_iban: reciept.to_IBAN,
            currency: reciept.currency,
            from: name_from.name,
            to: name_to.name,
            transaction_id: reciept.transaction_id,
            date: reciept.transaction_date,
            reference_id: reciept.reference_id,
            amount: reciept.amount,
            note: reciept.note,
            status: reciept.transaction_status
          }
    end

  end

  @doc """
    balance refresh for admin account
  """
  def balanceRefresh(account_id) do
    get_account = Repo.get_by(Adminaccounts, id: account_id)

    if !is_nil(get_account) do
      if get_account.type === "Account Fee" do
         accAccountBalanceUpdate(get_account)
      else
         cbAccountBalanceUpdate(get_account)
      end
    else
      {:Invalid_account, "Account not found!"}
    end
  end

  # function for clear bank balance update
  defp cbAccountBalanceUpdate(get_account) do
    response =  Clearbank.view_account(get_account.account_id)

    res = get_in(response["account"]["balances"], [Access.at(0)])
    balance = res["amount"]

    accountBalance = %{"balance" => balance, "viola_balance" => balance}
    changeset = Adminaccounts.changesetUpdateViolaBalance(get_account, accountBalance)
    case Repo.update(changeset) do
      {:ok, _bankAccount} -> {:ok, "Balance Updated Successfully"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # function for Accomplish type account balance refresh
  defp accAccountBalanceUpdate(get_account) do
    get_card = Accomplish.get_account(get_account.sort_code)
    response_code =  get_card["result"]["code"]
    response_message =  get_card["result"]["friendly_message"]
    if response_code == "0000" do
      current_balance_card = get_card["info"]["balance"]
      available_balance_card = get_card["info"]["available_balance"]

      accountBalance = %{"balance" => available_balance_card, "viola_balance" => current_balance_card}

      changeset = Adminaccounts.changesetUpdateViolaBalance(get_account, accountBalance)
      case Repo.update(changeset) do
        {:ok, _bankAccount} -> {:ok, "Balance Updated Successfully"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:third_party_error, response_code, response_message}
    end

  end
end
