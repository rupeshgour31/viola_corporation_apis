defmodule ViolacorpWeb.TransactionsView do
  use ViolacorpWeb, :view
  import Ecto.Query
  alias Violacorp.Repo
  alias  ViolacorpWeb.TransactionsView
  alias  ViolacorpWeb.TransactionsRecieptView
  alias Violacorp.Schemas.Companybankaccount


  #CARD MANAGEMENT TOP-UP HISTORY
  def render("index.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "topup.json", as: :topup)
    }
  end

  def render("topup.json", %{topup: topup}) do

    remark = Poison.decode!(topup.remark)
    %{
      to: remark["to"],
      from: remark["from"],
      transaction_id: topup.transaction_id,
      category: topup.category,
      amount: topup.amount,
      transaction_mode: topup.transaction_mode,
      server_date: topup.server_date,
      status: topup.status,
      transaction_date: topup.transaction_date
    }
  end

  @doc" CARD MANAGEMENT -  COMPANY TRANSACTIONS"

  def render("index_companyTransactions.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "companyTransactions.json", as: :transactions)
    }
  end

  def render("companyTransactions.json", %{transactions: transactions}) do

    remark = Poison.decode!(transactions.remark)
    %{
      to: remark["to_name"],
      from: remark["from_name"],
      transaction_id: transactions.transaction_id,
      category: transactions.category,
      amount: transactions.amount,
      transaction_mode: transactions.transaction_mode,
      transaction_date: transactions.transaction_date,
      server_date: transactions.server_date,
      status: transactions.status
    }
  end

  @doc "            USER TRANSACTIONS"

  def render("index_userTransactions.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "userTransactions.json", as: :transactions)
    }
  end

  def render("userTransactions.json", %{transactions: transactions}) do

    remark = Poison.decode!(transactions.remark)
    %{
      to: remark["to_name"],
      from: remark["from_name"],
      transaction_id: transactions.transaction_id,
      category: transactions.category,
      amount: transactions.amount,
      transaction_mode: transactions.transaction_mode,
      server_date: transactions.server_date,
      status: transactions.status,
      remark: transactions.remark,
      updated_at: transactions.updated_at,
    }
  end

  @doc"   POS TRANSACTION"

  def render("index_POS_transactions.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "POS_transactions.json", as: :transactions)
    }
  end
 def render("company_transaction.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "single_company_transaction.json", as: :transactions)
    }
  end

  def render("single_company_transaction.json", %{transactions: transactions})do
    remark = Poison.decode!(transactions.remark)
    %{
      id: transactions.id,
      transaction_id: transactions.transaction_id,
      transaction_type: transactions.transaction_type,
      transaction_mode: transactions.transaction_mode,
      category: transactions.category,
      cur_code: transactions.cur_code,
      amount: transactions.final_amount,
      status: transactions.status,
      updated_at: transactions.updated_at,
      server_date: transactions.server_date,
      to_info: remark["to_info"],
      from_info: remark["from_info"]
    }
  end


  def render("employee_transaction.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "single_employee_transaction.json", as: :transactions)
    }
  end

  def render("single_employee_transaction.json", %{transactions: transactions})do
    remark = Poison.decode!(transactions.remark)
    %{
      id: transactions.id,
      transaction_id: transactions.transaction_id,
      transaction_type: transactions.transaction_type,
      transaction_mode: transactions.transaction_mode,
      category: transactions.category,
      cur_code: transactions.cur_code,
      amount: transactions.final_amount,
      status: transactions.status,
      updated_at: transactions.updated_at,
      server_date: transactions.server_date,
      to: remark["to"],
      to_info: remark["to_name"],
      from: remark["from"],
      from_info: remark["from_name"]
    }
  end

  def render("POS_transactions.json", %{transactions: transactions}) do

    remark = Poison.decode!(transactions.remark)
    %{
      to: remark["to_name"],
      from: remark["from_name"],
      transaction_id: transactions.transaction_id,
      description: transactions.description,
      category: transactions.category,
      amount: transactions.amount,
      transaction_mode: transactions.transaction_mode,
      transaction_date: transactions.transaction_date,
      server_date: transactions.server_date,
      status: transactions.status,
      first_name: transactions.first_name,
      last_name: transactions.last_name
    }
  end

  @doc""

  def render("index_FEE_transactions.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "FEE_transactions.json", as: :transactions)
    }
  end

  def render("FEE_transactions.json", %{transactions: transactions}) do

    remark = Poison.decode!(transactions.remark)
    %{
      to: remark["to_name"],
      from: remark["from_name"],
      transaction_id: transactions.transaction_id,
      description: transactions.description,
      category: transactions.category,
      amount: transactions.amount,
      transaction_mode: transactions.transaction_mode,
      transaction_date: transactions.transaction_date,
      server_date: transactions.server_date,
      status: transactions.status
    }
  end



  def render("pos.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "poss.json", as: :poss)
    }
  end

  def render("poss.json", %{poss: poss}) do

        remark = Poison.decode!(poss.remark)
        %{
          to: remark["to"],
          from: remark["from"],
          cur_code: poss.cur_code,
          transaction_id: poss.transaction_id,
          category: poss.category,
          amount: poss.amount,
          transaction_mode: poss.transaction_mode,
          status: poss.status,
          server_date: poss.server_date,
          updated_at: poss.updated_at,
          first_name: poss.first_name,
          last_name: poss.last_name,
          id: poss.id
        }
  end


  @doc"   RECIEPT TRANSACTION"

  def render("indexTransactionReciept.json", %{data: data}) do

    remark = Poison.decode!(data.remark)
    %{ status_code: "200" ,data: %{

        from_name: remark["from_name"],
        from_account: remark["from"],
        to_name: remark["to_name"],
        to_account: remark["to"],
        transaction_id: data.transaction_id,
        transactions_id_api: data.transactions_id_api,
        status: data.status,
        amount: data.amount,
        fee: data.fee_amount,
        date: data.transaction_date,
        final_amount: data.final_amount,
        notes: data.description,
        receipts: render_many(data.transactionsreceipt, TransactionsRecieptView, "receipts.json", as: :data)
  }}
  end

  def render("credit_debit_transaction.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "credit_debit_transactions.json", as: :creditDebitTx)
    }
  end

  def render("credit_debit_transactions.json", %{creditDebitTx: creditDebitTx})do
    remark = Poison.decode!(creditDebitTx.remark)

    from = (remark["from_info"])
    to = (remark["to_info"])
    from_company_id = Repo.one(from a in Companybankaccount, where: a.account_number == ^from["account_number"] and  like(a.account_name, ^"%#{from["owner_name"]}%") , select: a.company_id)
    to_company_id = Repo.one(from b in Companybankaccount, where: b.account_number == ^to["account_number"] and like(b.account_name, ^"%#{to["owner_name"]}%"), select: b.company_id)
    remark_from = Map.merge(remark["from_info"], %{company_id: from_company_id})
    remark_to = Map.merge(remark["to_info"], %{company_id: to_company_id})

    %{
      id: creditDebitTx.id,
      company_id: creditDebitTx.company_id,
      to_info: remark_to,
      from_info: remark_from,
      transaction_id: creditDebitTx.transaction_id,
      cur_code: creditDebitTx.cur_code,
      transaction_type: creditDebitTx.transaction_type,
      transaction_mode: creditDebitTx.transaction_mode,
      amount: creditDebitTx.final_amount,
      status: creditDebitTx.status,
      updated_at: creditDebitTx.updated_at,
      server_date: creditDebitTx.server_date
    }
  end

  def render("transfer_to_card_management.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "transfer_to_card_managements.json", as: :tsToCardManag)
    }
  end

  def render("transfer_to_card_managements.json", %{tsToCardManag: tsToCardManag})do
    remark = Poison.decode!(tsToCardManag.remark)
    from = (remark["from_info"])
    to = (remark["to_info"])
    from_company_id = Repo.one(from a in Companybankaccount, where: a.account_number == ^from["account_number"] and  like(a.account_name, ^"%#{from["owner_name"]}%") , select: a.company_id)
    to_company_id = Repo.one(from b in Companybankaccount, where: b.account_number == ^to["account_number"] and like(b.account_name, ^"%#{to["owner_name"]}%"), select: b.company_id)
    remark_from = Map.merge(remark["from_info"], %{company_id: from_company_id})
    remark_to = Map.merge(remark["to_info"], %{company_id: to_company_id})

    %{
      id: tsToCardManag.id,
      company_id: from_company_id,
      transaction_id: tsToCardManag.transaction_id,
      transaction_type: tsToCardManag.transaction_type,
      transaction_mode: tsToCardManag.transaction_mode,
      category: tsToCardManag.category,
      cur_code: tsToCardManag.cur_code,
      amount: tsToCardManag.final_amount,
      status: tsToCardManag.status,
      updated_at: tsToCardManag.updated_at,
      server_date: tsToCardManag.server_date,
      to_info: remark_to,
      from_info: remark_from
    }
  end

  def render("online_fee_transaction.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "online_fee_transactions.json", as: :onlinefee)
    }
  end

  def render("online_fee_transactions.json", %{onlinefee: onlinefee})do
    remark = Poison.decode!(onlinefee.remark)
    %{
        id: onlinefee.id,
        category: onlinefee.category,
        transaction_id: onlinefee.transaction_id,
        final_amount: onlinefee.final_amount,
        cur_code: onlinefee.cur_code,
        status: onlinefee.status,
        transaction_date: onlinefee.transaction_date,
        mode: onlinefee.transaction_mode,
        type: onlinefee.transaction_type,
        to: remark["to"],
        from: remark["from"]
    }
  end
  def render("card_management_fee_tx.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "card_management_fee_trans.json", as: :onlinefee)
    }
  end

  def render("card_management_fee_trans.json", %{onlinefee: onlinefee})do
    remark = Poison.decode!(onlinefee.remark)
    %{
      id: onlinefee.id,
      category: onlinefee.category,
      transaction_id: onlinefee.transaction_id,
      company_name: onlinefee.company_name,
      final_amount: onlinefee.final_amount,
      cur_code: onlinefee.cur_code,
      status: onlinefee.status,
      transaction_date: onlinefee.transaction_date,
      mode: onlinefee.transaction_mode,
      type: onlinefee.transaction_type,
      to_info: remark["to"],
      from_info: remark["from"]
    }
  end


  def  render("employee_index.json", %{transactions: transactions}) do
    %{
      status_code: "200",
      total_pages: transactions.total_pages,
      total_entries: transactions.total_entries,
      page_size: transactions.page_size,
      page_number: transactions.page_number,
      data: render_many(transactions, TransactionsView, "employee_card_transaction.json", as: :transactions)
    }
  end

  def render("employee_card_transaction.json", %{transactions: transactions}) do
    remark = Poison.decode!(transactions.remark)

   %{
     id: transactions.id,
     company_name: transactions.company_name,
     cur_code: transactions.cur_code,
     first_name: transactions.first_name,
     last_name: transactions.last_name,
     transaction_id: transactions.transaction_id,
     transaction_type: transactions.transaction_type,
     transaction_mode: transactions.transaction_mode,
     category: transactions.category,
     amount: transactions.amount,
     status: transactions.status,
     updated_at: transactions.updated_at,
     server_date: transactions.server_date,
     to_info: remark["to"],
     from_info: remark["from"]
   }
  end

  def render("index_company_topup.json", %{data: data}) do
    %{
      status_code: "200",
      total_pages: data.total_pages,
      total_entries: data.total_entries,
      page_size: data.page_size,
      page_number: data.page_number,
      data: render_many(data, TransactionsView, "company_topup.json", as: :transactions)
    }
  end

  def render("company_topup.json", %{transactions: transactions}) do

    remark = Poison.decode!(transactions.remark)
    %{
      id: transactions.id,
      to: remark["to_name"],
      from: remark["from_name"],
      transaction_id: transactions.transaction_id,
      category: transactions.category,
      amount: transactions.amount,
      transaction_mode: transactions.transaction_mode,
      transaction_date: transactions.transaction_date,
      server_date: transactions.server_date,
      status: transactions.status
    }
  end
end