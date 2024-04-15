defmodule Violacorp.Libraries.BusinessLimits do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Amountlimits
  alias Violacorp.Schemas.Dwmtransactions

  def limits_check(commanall_id, amount, type) do

    existing_rule = Repo.get_by(Amountlimits, commanall_id: commanall_id, status: "A")
    rule = case existing_rule do
      nil ->
        %{
          daily_transactions_amount: Application.get_env(:violacorp, :max_load_per_day_amount),
          monthly_transaction_limit: Application.get_env(:violacorp, :max_load_per_month_amount),
          yearly_transactions_amount: Application.get_env(:violacorp, :max_load_per_year_amount),
          type: type
        }
      #GET RULE FROM CONFIG
      _ ->
        %{
          daily_transactions_amount: existing_rule.daily_transactions_amount,
          monthly_transaction_limit: existing_rule.monthly_transaction_limit,
          yearly_transactions_amount: existing_rule.yearly_transactions_amount,
          type: type
        }
      #USER RULE FROM QUERY
    end


    case yearly(commanall_id, rule, amount) do
      true -> case monthly(commanall_id, rule, amount) do
                true -> case daily(commanall_id, rule, amount) do
                          true -> %{status_code: "200", message: "No limits reached"}
                          false -> %{status_code: "4004", message: "daily limit reached"}
                        end
                false -> %{status_code: "4004", message: "monthly limit reached"}
              end
      false -> %{status_code: "4004", message: "yearly limit reached"}
    end
  end


  defp daily(commanall_id, rule, amount) do
    today = Timex.now()
    #Get transactions
    transactions_amount = Repo.get_by(Dwmtransactions, commanall_id: commanall_id, trans_date: today, status: "D")
    if is_nil(transactions_amount) or is_nil(rule.monthly_transaction_limit) do
      true
    else
      trans_total = case rule.type do
        "A" -> Decimal.add(transactions_amount.account_success_amount, amount)
        "C" -> Decimal.add(transactions_amount.card_success_amount, amount)
      end
      cond do
        trans_total < rule.monthly_transaction_limit -> true
        true -> false
      end
    end
  end

  defp monthly(commanall_id, rule, amount) do
    today = Timex.now()
    month = Timex.beginning_of_month(today)
    #Get transactions
    transactions_amount = Repo.get_by(Dwmtransactions, commanall_id: commanall_id, trans_date: month, status: "M")

    if is_nil(transactions_amount) or is_nil(rule.monthly_transaction_limit) do
      true
    else
      trans_total = case rule.type do
        "A" -> Decimal.add(transactions_amount.account_success_amount, amount)
        "C" -> Decimal.add(transactions_amount.card_success_amount, amount)
      end
      cond do
        trans_total < rule.monthly_transaction_limit -> true
        true -> false
      end
    end
  end

  defp yearly(commanall_id, rule, amount) do
    today = Timex.now()
    year = Timex.shift(today, years: -1)
    #Get transactions
    [transactions_amount] = case rule.type do
      "A" ->
        Repo.all(
          from t in Dwmtransactions,
          where: t.commanall_id == ^commanall_id and t.status == "M" and (
            t.trans_date <= ^today and t.trans_date >= ^year),
          select: sum(t.account_success_amount)
        )
      "C" ->
        Repo.all(
          from t in Dwmtransactions,
          where: t.commanall_id == ^commanall_id and t.status == "M" and (
            t.trans_date <= ^today and t.trans_date >= ^year),
          select: sum(t.card_success_amount)
        )
    end
    if is_nil(transactions_amount) or is_nil(rule.monthly_transaction_limit)  do
      true
    else
      trans_total = Decimal.add(transactions_amount, amount)
      cond do
        trans_total < rule.monthly_transaction_limit -> true
        true -> false
      end
    end
  end

end