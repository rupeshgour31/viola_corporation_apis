defmodule Violacorp.Workers.SuccessMonthlyFee do

  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Libraries.Fees
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Companyaccounts

  def perform(request) do
    IO.inspect("HERE SuccessMonthlyFee.EX")

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
    commanid = request.commanid
#    _balance = String.to_float("#{request.balance}")
#    _compid = request.compid
    accomplish_account_id = request.accomplish_account_id
    companyaccountsid = request.companyaccountsid

    type_credit = Application.get_env(:violacorp, :internal_fee)
    getAllPendingTransaction = Repo.all from t in Transactions, where: t.commanall_id == ^commanid and t.api_type == ^type_credit and t.category == ^"FEE" and t.transaction_mode == ^"D" and t.status == ^"P",
                                                                order_by: [
                                                                  desc: t.id
                                                                ],
                                                                select: %{transaction_date: t.transaction_date, fee_amount: t.fee_amount, id: t.id}
    Enum.each getAllPendingTransaction, fn v ->
      fee_amount = String.to_float("#{v.fee_amount}")
      account_details = Repo.get(Companyaccounts, companyaccountsid)
      available_balance = String.to_float("#{account_details.available_balance}")

      if available_balance > fee_amount do
        requestData = %{transaction_id: v.id, fee_amount: fee_amount, accomplish_account_id: accomplish_account_id, companyaccountsid: companyaccountsid}
        _fee_transaction = Fees.charge_monthly_fee(requestData)
      end
    end
  end
end