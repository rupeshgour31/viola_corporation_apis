defmodule Violacorp.Libraries.TransactionLimits do

  alias Violacorp.Repo
  alias Violacorp.Schemas.Dwmtransactions

  def data(transaction, type) do
    #usage example TransactionLimits.data(%{commanall_id: get_commanall_id.id, amount: amount, status: "S"}, "C")
    #data sent as params when library called
    #    today =  Date.utc_today()
    today =  Date.utc_today()
    week_first_day = getWeekFirstDay(today.day)
    {:ok, week} = Date.new(today.year, today.month, week_first_day)

    month = Timex.beginning_of_month(today.year, today.month)

    merged = Map.merge(transaction, %{today: today, week: week, month: month}) # merged date values for tran_date field

    insert_update_daily = case type do
      "A" -> account_insert_update_daily(merged)
      "C" -> card_insert_update_daily(merged)
    end

    insert_update_weekly = case type do
      "A" -> account_insert_update_weekly(merged)
      "C" -> card_insert_update_weekly(merged)
    end

    insert_update_monthly = case type do
      "A" -> account_insert_update_monthly(merged)
      "C" -> card_insert_update_monthly(merged)
    end


    case insert_update_daily do
      {:ok, _struct} ->
        case insert_update_weekly do
          {:ok, _struct} ->
            case insert_update_monthly do
              {:ok, _struct} -> {:ok, "inserted/update all"}
              {:error, changeset} -> {:error, changeset}
            end

          {:error, changeset} -> {:error, changeset}
        end
      {:error, changeset} -> {:error, changeset}
    end
  end


  def card_insert_update_daily(transaction) do

    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "D", trans_date: transaction.today) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: transaction.amount, card_failed_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: (Decimal.add(post.card_failed_amount,transaction.amount)), card_failed_count: (if is_nil(post.card_failed_count) do 0 else post.card_failed_count end + 1)})
                          end
                          |> Repo.update
    end
    result
  end

  def card_insert_update_weekly(transaction) do

    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "W", trans_date: transaction.week) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: transaction.amount, card_failed_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: (Decimal.add(post.card_failed_amount,transaction.amount)), card_failed_count: (if is_nil(post.card_failed_count) do 0 else post.card_failed_count end + 1) })
                          end
                          |> Repo.update
    end
    result
  end

  def card_insert_update_monthly(transaction) do
    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "M", trans_date: transaction.month) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: transaction.amount, card_success_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: transaction.amount, card_failed_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_success_amount: (Decimal.add(post.card_success_amount,transaction.amount)), card_success_count: (if is_nil(post.card_success_count) do 0 else post.card_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, card_failed_amount: (Decimal.add(post.card_failed_amount,transaction.amount)), card_failed_count: (if is_nil(post.card_failed_count) do 0 else post.card_failed_count end + 1) })
                          end
                          |> Repo.update
    end
    result
  end

  def account_insert_update_daily(transaction) do

    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "D", trans_date: transaction.today) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: transaction.amount, account_failed_count: 1, status: "D", trans_date: transaction.today, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: (Decimal.add(post.account_failed_amount,transaction.amount)), account_failed_count: (if is_nil(post.account_failed_count) do 0 else post.account_failed_count end + 1) })
                          end
                          |> Repo.update
    end
    result
  end

  def account_insert_update_weekly(transaction) do

    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "W", trans_date: transaction.week) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: transaction.amount, account_failed_count: 1, status: "W", trans_date: transaction.week, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: (Decimal.add(post.account_failed_amount,transaction.amount)), account_failed_count: (if is_nil(post.account_failed_count) do 0 else post.account_failed_count end + 1) })
                          end
                          |> Repo.update
    end
    result
  end

  def account_insert_update_monthly(transaction) do
    result = case Repo.get_by(Dwmtransactions, commanall_id: transaction.commanall_id, status: "M", trans_date: transaction.month) do
      nil  -> post = %Dwmtransactions{}
              case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: transaction.amount, account_success_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: transaction.amount, account_failed_count: 1, status: "M", trans_date: transaction.month, inserted_by: transaction.commanall_id})
                          end
                          |> Repo.insert
      post -> case transaction.status do
                            "S" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "P" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_success_amount: (Decimal.add(post.account_success_amount,transaction.amount)), account_success_count: (if is_nil(post.account_success_count) do 0 else post.account_success_count end + 1)})
                            "F" -> Dwmtransactions.changeset(post, %{commanall_id: transaction.commanall_id, account_failed_amount: (Decimal.add(post.account_failed_amount,transaction.amount)), account_failed_count: (if is_nil(post.account_failed_count) do 0 else post.account_failed_count end + 1) })
                          end
                          |> Repo.update
    end
    result
  end


  defp getWeekFirstDay(day) do
    week1 = 1..7
    week2 = 8..14
    week3 = 15..21
    week4 = 22..28
    week5 = 29..31

    cond do
      Enum.member?(week1, day) -> 1
      Enum.member?(week2, day) -> 8
      Enum.member?(week3, day) -> 15
      Enum.member?(week4, day) -> 22
      Enum.member?(week5, day) -> 29
    end
  end

end