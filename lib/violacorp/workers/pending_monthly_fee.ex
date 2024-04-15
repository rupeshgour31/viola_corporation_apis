defmodule Violacorp.Workers.PendingMonthlyFee do
  alias Violacorp.Libraries.Fees

  def perform(request) do
    IO.inspect("HERE PENDINGMONTHLYFEE.EX")

    request = %{commanid: request["commanid"],
      compid: request["compid"],
      accomplish_account_id: request["accomplish_account_id"],
      companyaccountsid: request["companyaccountsid"],
      inserted_at: request["inserted_at"],
      last_trans_date: request["last_trans_date"],
      total_card: request["total_card"],
      total_account: request["total_account"],
      balance: request["balance"],
      total_pending: request["total_pending"]
    }

      Enum.each(1..request.total_pending, fn(_x) ->
        # Cate IV -> calculate Fees
        _fee_calculation = Fees.pending_monthly_fee(request)
      end) |> IO.inspect()
  end
  end