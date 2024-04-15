defmodule ViolacorpWeb.Main.CronController do
  use ViolacorpWeb, :controller
  import Ecto.Query
  require Logger
  alias Violacorp.Repo

  alias ViolacorpWeb.Comman.TestController

  alias Violacorp.Schemas.Cronsetup
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Duefees
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Feerules
  alias Violacorp.Schemas.Employeecards

  alias Violacorp.Workers.DailyCardbalancesSender
  #  alias Violacorp.Workers.PendingMonthlyFee
  #  alias Violacorp.Workers.SuccessMonthlyFee

  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish
  #  alias Violacorp.Libraries.Fees

  #  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController

  # Load POS Transaction for Employee
  def employeeTransaction do

    # Cron Limit
    cron_limit = Repo.one from c in Cronsetup, where: c.type == ^"E",
                                               select: %{
                                                 id: c.id,
                                                 limit: c.limit,
                                                 offset: c.offset
                                               }

    # Total Employee
    total_employee = Repo.one from c in Commanall,
                              where: c.status == ^"A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                              select: count(c.id)


    limits = cron_limit.limit
    offset = cron_limit.offset

    update_offset = offset + limits

    offset_value = if update_offset > total_employee do
      0
    else
      update_offset
    end

    current_datetime = DateTime.utc_now
    cronsetup = Repo.get(Cronsetup, cron_limit.id)
    update_cron = %{
      "total_rows" => total_employee,
      "limit" => limits,
      "offset" => offset_value,
      "type" => "E",
      "last_update" => current_datetime
    }
    changeset_cronsetup = Cronsetup.changeset(cronsetup, update_cron)
    Repo.update(changeset_cronsetup)

    all_employee = Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                           order_by: [
                             asc: c.id
                           ],
                           limit: ^limits,
                           offset: ^offset,
                           select: %{
                             commanid: c.id,
                             employee_id: c.employee_id,
                             accomplish_userid: c.accomplish_userid
                           }
    )

    Enum.each all_employee, fn emp ->
      load_params = %{
        "worker_type" => "pending_transactions_updater",
        "employee_id" => emp.employee_id
      }
      Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
    end

  end

  # Load POS Success Transaction for Employee
  def employeeSuccessTransaction do

    # Cron Limit
    cron_limit = Repo.one from c in Cronsetup, where: c.type == ^"E",
                                               select: %{
                                                 id: c.id,
                                                 limit: c.limit,
                                                 offset: c.offset
                                               }

    # Total Employee
    total_employee = Repo.one from c in Commanall,
                              where: c.status == ^"A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                              select: count(c.id)


    limits = cron_limit.limit
    offset = cron_limit.offset

    update_offset = offset + limits

    offset_value = if update_offset > total_employee do
      0
    else
      update_offset
    end

    current_datetime = DateTime.utc_now
    cronsetup = Repo.get(Cronsetup, cron_limit.id)
    update_cron = %{
      "total_rows" => total_employee,
      "limit" => limits,
      "offset" => offset_value,
      "type" => "E",
      "last_update" => current_datetime
    }
    changeset_cronsetup = Cronsetup.changeset(cronsetup, update_cron)
    Repo.update(changeset_cronsetup)

    all_employee = Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                           order_by: [
                             asc: c.id
                           ],
                           limit: ^limits,
                           offset: ^offset,
                           select: %{
                             commanid: c.id,
                             employee_id: c.employee_id,
                             accomplish_userid: c.accomplish_userid
                           }
    )

    Enum.each all_employee, fn emp ->
      load_params = %{
        "worker_type" => "success_transactions_updater",
        "employee_id" => emp.employee_id
      }
      Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
    end

  end

  # Load Manual Transaction for Company
  def companyTransaction do

    # Cron Limit
    cron_limit = Repo.one from c in Cronsetup, where: c.type == ^"C",
                                               select: %{
                                                 id: c.id,
                                                 limit: c.limit,
                                                 offset: c.offset
                                               }

    # Total Company
    total_company = Repo.one from c in Commanall,
                             where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
                             select: count(c.id)


    limits = cron_limit.limit
    offset = cron_limit.offset

    update_offset = offset + limits

    offset_value = if update_offset > total_company do
      0
    else
      update_offset
    end

    current_datetime = DateTime.utc_now
    cronsetup = Repo.get(Cronsetup, cron_limit.id)
    update_cron = %{
      "total_rows" => total_company,
      "limit" => limits,
      "offset" => offset_value,
      "type" => "C",
      "last_update" => current_datetime
    }
    changeset_cronsetup = Cronsetup.changeset(cronsetup, update_cron)
    Repo.update(changeset_cronsetup)

    all_company = Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
                           order_by: [
                             asc: c.id
                           ],
                           limit: ^limits,
                           offset: ^offset,
                           select: %{
                             commanid: c.id,
                             company_id: c.company_id,
                             accomplish_userid: c.accomplish_userid
                           }
    )

    Enum.each all_company, fn comp ->
      load_params = %{
        "worker_type" => "manual_load",
        "commanall_id" => comp.commanid,
        "company_id" => comp.company_id
      }
      Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

    end

  end

  # Monthly Fee for Company
  def companyMonthlyFee do

    all_company = Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
                           left_join: comp in assoc(c, :company),
                           left_join: com_ac in assoc(comp, :companyaccounts),
                           where: not is_nil(com_ac.inserted_at),
                           order_by: [
                             asc: c.id
                           ],
                           select: %{
                             commanid: c.id,
                             compid: c.company_id,
                             available_balance: com_ac.available_balance,
                             current_balance: com_ac.current_balance,
                             accomplish_account_id: com_ac.accomplish_account_id,
                             companyaccountsid: com_ac.id,
                             inserted_at: com_ac.inserted_at
                           }
    )

    Enum.each all_company, fn v ->

      commanid = v.commanid
      compid = v.compid
      inserted_at = v.inserted_at
      last_duefees = Repo.one(
        from d in Duefees, where: d.commanall_id == ^commanid and d.type == "M" and d.status == "P",
                           order_by: [
                             desc: d.id
                           ],
                           limit: 1,
                           select: %{
                             pay_date: d.pay_date,
                             next_date: d.next_date,
                             amount: d.amount,
                             id: d.id
                           }
      )
      _response = if !is_nil(last_duefees) do
        id = last_duefees.id
        amount = last_duefees.amount
        pay_date = last_duefees.pay_date
        pendingFee(id, amount, pay_date, compid, commanid)
      else
        last_clear_duefees = Repo.one(
          from d in Duefees, where: d.commanall_id == ^commanid and d.type == "M" and d.status == "C",
                             order_by: [
                               desc: d.id
                             ],
                             limit: 1,
                             select: %{
                               pay_date: d.pay_date,
                               next_date: d.next_date,
                               amount: d.amount,
                               status: d.status,
                               id: d.id
                             }
        )
        if !is_nil(last_clear_duefees) do
          pay_date = last_clear_duefees.pay_date
          currentFee(pay_date, compid, commanid)
        else
          currentFee(inserted_at, compid, commanid)
        end
      end


    end
  end


  # Charge Monthly Fee
  def chargeMonthlyFee(conn, _params) do

    today_date = NaiveDateTime.utc_now()
    to_date = [today_date.year, today_date.month, today_date.day]
              |> Enum.map(&to_string/1)
              |> Enum.map(&String.pad_leading(&1, 2, "0"))
              |> Enum.join("-")

    all_company = Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
                           left_join: comp in assoc(c, :company),
                           left_join: com_ac in assoc(comp, :companyaccounts),
                           where: not is_nil(com_ac.inserted_at),
                           order_by: [
                             asc: c.id
                           ],
                           select: %{
                             commanid: c.id,
                             compid: c.company_id,
                             available_balance: com_ac.available_balance,
                             current_balance: com_ac.current_balance,
                             accomplish_account_id: com_ac.accomplish_account_id,
                             companyaccountsid: com_ac.id,
                             inserted_at: com_ac.inserted_at
                           }
    )

    Enum.each all_company, fn v ->

      commanid = v.commanid
      compid = v.compid
      inserted_at = v.inserted_at
      available_balance = v.available_balance
      accomplish_account_id = v.accomplish_account_id
      companyaccountsid = v.companyaccountsid

      count_card = Repo.one from e in Employee, where: e.status == "A" and e.company_id == ^compid,
                                                left_join: c in assoc(e, :employeecards),
                                                where: c.status < "5",
                                                select: count(e.id)

      # case I -> no record in transaction table
      type_credit = Application.get_env(:violacorp, :internal_fee)
      last_transaction = Repo.one from t in Transactions,
                                  where: t.commanall_id == ^commanid and t.api_type == ^type_credit and t.category == ^"FEE" and t.transaction_mode == ^"D" and (
                                    t.status == ^"S" or t.status == ^"P" or t.status == ^"F"),
                                  limit: 1,
                                  order_by: [
                                    desc: t.id
                                  ],
                                  select: %{
                                    status: t.status,
                                    transaction_date: t.transaction_date,
                                    id: t.id
                                  }
      last_trans_date = if is_nil(last_transaction), do: inserted_at, else: last_transaction.transaction_date

      # case II -> get count, how many transaction is pending
      diff = 0
      total_count = 0
      pre_date = [last_trans_date.year, last_trans_date.month, last_trans_date.day]
                 |> Enum.map(&to_string/1)
                 |> Enum.map(&String.pad_leading(&1, 2, "0"))
                 |> Enum.join("-")

      total_pending = pendingCount(last_trans_date, today_date, diff, total_count, pre_date, to_date)

      # case III -> create pending transaction
      request = %{
        commanid: commanid,
        compid: compid,
        accomplish_account_id: accomplish_account_id,
        companyaccountsid: companyaccountsid,
        inserted_at: inserted_at,
        last_trans_date: last_trans_date,
        total_card: count_card,
        total_account: 1,
        balance: available_balance,
        total_pending: total_pending
      }
      if total_pending > 0 do
        # NOTE: this method will need to update on worker (worker set with time withing 30 sec)
        #        insertPending(request)
        #        Exq.enqueue_in(Exq, "pending_monthly_fee", 30, PendingMonthlyFee, [request]) COMMENT FOR TEST
        Logger.warn(~s(pending_monthly_fee: #{Poison.encode!(request)}))
      end
      #      updastePending(request)

      #      Exq.enqueue_in(Exq, "success_monthly_fee", 30, SuccessMonthlyFee, [request])

      Logger.warn(~s(success_monthly_fee: #{Poison.encode!(request)}))
    end
    text conn, "abc"
  end

  # get pending transaction count
  def pendingCount(_last_date, _today_date, diff, total_count, pre_date, to_date)
      when pre_date == to_date or diff > 0 do
    _response = total_count
  end

  def pendingCount(last_date, today_date, _diff, total_count, _pre_date, to_date) do
    change_date = NaiveDateTime.add(last_date, 86400 * 30)
    diff = NaiveDateTime.diff(change_date, today_date)
    total_count = if diff <= 0, do: total_count + 1, else: total_count

    pre_date = [change_date.year, change_date.month, change_date.day]
               |> Enum.map(&to_string/1)
               |> Enum.map(&String.pad_leading(&1, 2, "0"))
               |> Enum.join("-")
    pendingCount(change_date, today_date, diff, total_count, pre_date, to_date)
  end

  #  def insertPending(request) do
  #    Enum.each(1..request.total_pending, fn(_x) ->
  #        # Cate IV -> calculate Fees
  ##        _fee_calculation = Fees.fee_calculation(request)
  #    end)
  #  end

  def updastePending(request) do
    commanid = request.commanid
    #    _balance = String.to_float("#{request.balance}")
    #    _compid = request.compid
    accomplish_account_id = request.accomplish_account_id
    companyaccountsid = request.companyaccountsid

    type_credit = Application.get_env(:violacorp, :internal_fee)
    getAllPendingTransaction = Repo.all from t in Transactions,
                                        where: t.commanall_id == ^commanid and t.api_type == ^type_credit and t.category == ^"FEE" and t.transaction_mode == ^"D" and t.status == ^"P",
                                        order_by: [
                                          desc: t.id
                                        ],
                                        select: %{
                                          transaction_date: t.transaction_date,
                                          fee_amount: t.fee_amount,
                                          id: t.id
                                        }
    Enum.each getAllPendingTransaction, fn v ->
      fee_amount = String.to_float("#{v.fee_amount}")
      account_details = Repo.get(Companyaccounts, companyaccountsid)
      available_balance = String.to_float("#{account_details.available_balance}")

      if available_balance > fee_amount do
        _requestData = %{
          transaction_id: v.id,
          fee_amount: fee_amount,
          accomplish_account_id: accomplish_account_id,
          companyaccountsid: companyaccountsid
        }
        #        _fee_transaction = Fees.fee_transaction(requestData)
      end
    end
  end

  # Charge Pending Fee
  def pendingFee(id, amount, pay_date, compid, commanid) do
    company_list = Repo.one from c in Company, where: c.id == ^compid,
                                               left_join: comman in assoc(c, :commanall),
                                               where: not is_nil(comman.accomplish_userid),
                                               left_join: a in assoc(c, :companyaccounts),
                                               where: a.status == "1",
                                               select: %{
                                                 id: c.id,
                                                 available_balance: a.available_balance,
                                                 current_balance: a.current_balance,
                                                 currency_code: a.currency_code,
                                                 account_number: a.account_number,
                                                 accomplish_account_id: a.accomplish_account_id,
                                                 email_id: comman.email_id,
                                                 company_name: c.company_name,
                                                 company_type: c.company_type,
                                                 commanall_id: comman.id,
                                                 companyaccountsid: a.id
                                               }
    if !is_nil(company_list) do
      # check amount is sufficiant or not
      balance = String.to_float("#{company_list.available_balance}") - String.to_float("#{amount}")
      if balance > 0 do
        today = DateTime.utc_now
        remark = %{"from" => company_list.currency_code, "to" => "Viola Corporate"}

        type_credit = Application.get_env(:violacorp, :internal_fee)
        charge_fee = String.to_float("#{amount}")

        transaction_id = Integer.to_string(Commontools.randnumber(10))
        transactions = %{
          "commanall_id" => commanid,
          "company_id" => compid,
          "amount" => 0.00,
          "fee_amount" => charge_fee,
          "final_amount" => charge_fee,
          "cur_code" => company_list.currency_code,
          "balance" => balance,
          "previous_balance" => company_list.available_balance,
          "transaction_id" => transaction_id,
          "transaction_date" => today,
          "transaction_mode" => "D",
          "transaction_type" => "A2O",
          "api_type" => type_credit,
          "category" => "FEE",
          "description" => "Charge monthly fee",
          "remark" => Poison.encode!(remark),
          "inserted_by" => commanid
        }
        changeset = Transactions.changesetFee(%Transactions{}, transactions)
        case Repo.insert(changeset) do
          {:ok, data} ->
            ids = data.id
            request = %{
              type: "228",
              notes: "Monthly Fee Charges", # Limited Debit   or  Monthly Fee Charges
              amount: charge_fee,
              currency: company_list.currency_code,
              account_id: company_list.accomplish_account_id
            }
            # Send to Accomplish
            response = Accomplish.load_money(request)
            response_code = response["result"]["code"]
            response_message = response["result"]["friendly_message"]
            transactions_id_api = response["info"]["original_source_id"]
            if response_code == "0000" do
              trans_status = Repo.get(Transactions, ids)
              update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
              changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
              Repo.update(changeset_transaction)

              # UPDATE BALANCE
              gets_account = Accomplish.get_account(company_list.accomplish_account_id)
              current_balance = gets_account["info"]["balance"]
              available_balance = gets_account["info"]["available_balance"]
              update_balance = %{
                "available_balance" => available_balance,
                "current_balance" => current_balance
              }
              account_details = Repo.get(Companyaccounts, company_list.companyaccountsid)
              changeset_companyaccount = Companyaccounts.changesetBalance(account_details, update_balance)
              Repo.update(changeset_companyaccount)

              # UPDATE PENDING ROW
              duefeeInfo = Repo.get(Duefees, id)
              update_status = %{"transactions_id" => ids, "status" => "C"}
              changeset_dueefee = Duefees.changesetStatus(duefeeInfo, update_status)
              Repo.update(changeset_dueefee)

              _response = "Transaction Successfuly"
            else
              trans_status = Repo.get(Transactions, ids)
              update_status = %{"description" => response_message}
              changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
              Repo.update(changeset_transaction)
              _response = "#{response_message}"
            end
        end
      else

        today = NaiveDateTime.utc_now()
        change_date = NaiveDateTime.add(pay_date, 86400 * 30)

        diff = NaiveDateTime.diff(change_date, today)

        pre_date = [change_date.year, change_date.month, change_date.day]
                   |> Enum.map(&to_string/1)
                   |> Enum.map(&String.pad_leading(&1, 2, "0"))
                   |> Enum.join("-")
        to_date = [today.year, today.month, today.day]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")
        next_date = NaiveDateTime.add(change_date, 86400 * 30)

        if pre_date == to_date or diff < 0 do

          # Pull All cards
          count_card = Repo.one from e in Employee, where: e.status == "A" and e.company_id == ^compid,
                                                    left_join: c in assoc(e, :employeecards),
                                                    where: c.status < "5",
                                                    select: count(e.id)

          # Pull Monthly Fee
          get_monthly = Repo.one from f in Feerules, where: f.type == ^"M" and f.status == ^"A",
                                                     select: %{
                                                       monthly_fee: f.monthly_fee,
                                                       per_card_fee: f.per_card_fee,
                                                       minimum_card: f.minimum_card,
                                                       vat: f.vat,
                                                     }
          monthly_fee = get_monthly.monthly_fee
          card_limit = get_monthly.minimum_card
          per_card_fee = get_monthly.per_card_fee
          vat = get_monthly.vat
          extra_card = count_card - card_limit
          extra_amt = String.to_integer("#{extra_card}") * String.to_float("#{per_card_fee}")
          charge_fee = if card_limit < count_card do
            if String.to_float("#{vat}") > 0 do
              total_fee = String.to_float("#{monthly_fee}") + String.to_float("#{extra_amt}")
              cal_vat = String.to_float("#{total_fee}") * String.to_float("#{vat}") / 100
              (String.to_float("#{total_fee}") + String.to_float("#{cal_vat}"))
            else
              (String.to_float("#{monthly_fee}") + String.to_float("#{extra_amt}"))
            end
          else
            monthly_fee
          end
          fees_data = if extra_card > 0 do
            [
              %{
                fees_name: "Monthly subscription",
                quantity: card_limit,
                unit_price: per_card_fee,
                tax: vat,
                total_unit: monthly_fee
              },
              %{
                fees_name: "Extra Card/s Charges",
                quantity: extra_card,
                unit_price: per_card_fee,
                tax: vat,
                total_unit: extra_amt
              }
            ]
          else
            [
              %{
                fees_name: "Monthly subscription",
                quantity: card_limit,
                unit_price: per_card_fee,
                tax: vat,
                total_unit: charge_fee
              }
            ]
          end
          check_pending_entry = Repo.one(
            from d in Duefees,
            where: d.commanall_id == ^commanid and d.pay_date == ^change_date,
            select: %{
              id: d.id
            }
          )
          IO.inspect(check_pending_entry)

          if check_pending_entry == nil do
            # store due fee
            duefees = %{
              "commanall_id" => commanid,
              "amount" => charge_fee,
              "total_cards" => count_card,
              "remark" => Poison.encode!(fees_data),
              "description" => "Charge monthly fee",
              "pay_date" => change_date,
              "next_date" => next_date,
              "reason" => "Not sufficient funds",
              "inserted_by" => commanid
            }
            changeset = Duefees.changeset(%Duefees{}, duefees)
            Repo.insert(changeset)
            _response = "Not sufficient funds."
          else
            # Check due fees
            last_duefees = Repo.one(
              from d in Duefees, where: d.commanall_id == ^commanid and d.type == "M",
                                 order_by: [
                                   desc: d.id
                                 ],
                                 limit: 1,
                                 select: %{
                                   pay_date: d.pay_date,
                                 }
            )
            pay_date = last_duefees.pay_date
            change_date = NaiveDateTime.add(pay_date, 86400 * 30)
            next_date = NaiveDateTime.add(change_date, 86400 * 30)
            diff = NaiveDateTime.diff(change_date, today)
            if diff >= 0 do
              _response = "Not sufficient funds."
            else
              # store due fee
              duefees = %{
                "commanall_id" => commanid,
                "amount" => charge_fee,
                "total_cards" => count_card,
                "remark" => Poison.encode!(fees_data),
                "description" => "Charge monthly fee",
                "pay_date" => change_date,
                "next_date" => next_date,
                "reason" => "Not sufficient funds",
                "inserted_by" => commanid
              }
              changeset = Duefees.changeset(%Duefees{}, duefees)
              Repo.insert(changeset)
              _response = "Not sufficient funds."
            end
          end
        else
          _response = "Date not allowed."
        end
      end
    else
      _response = "Account not found"
    end
  end

  # Charge Current Fee
  def currentFee(fee_date, compid, commanid) do
    today = NaiveDateTime.utc_now()
    change_date = NaiveDateTime.add(fee_date, 86400 * 30)

    diff = NaiveDateTime.diff(change_date, today)

    pre_date = [change_date.year, change_date.month, change_date.day]
               |> Enum.map(&to_string/1)
               |> Enum.map(&String.pad_leading(&1, 2, "0"))
               |> Enum.join("-")
    to_date = [today.year, today.month, today.day]
              |> Enum.map(&to_string/1)
              |> Enum.map(&String.pad_leading(&1, 2, "0"))
              |> Enum.join("-")
    next_date = NaiveDateTime.add(change_date, 86400 * 30)

    if pre_date == to_date or diff < 0 do
      company_list = Repo.one from c in Company, where: c.id == ^compid,
                                                 left_join: comman in assoc(c, :commanall),
                                                 where: not is_nil(comman.accomplish_userid),
                                                 left_join: a in assoc(c, :companyaccounts),
                                                 where: a.status == "1",
                                                 select: %{
                                                   id: c.id,
                                                   available_balance: a.available_balance,
                                                   current_balance: a.current_balance,
                                                   currency_code: a.currency_code,
                                                   account_number: a.account_number,
                                                   accomplish_account_id: a.accomplish_account_id,
                                                   email_id: comman.email_id,
                                                   company_name: c.company_name,
                                                   company_type: c.company_type,
                                                   commanall_id: comman.id,
                                                   companyaccountsid: a.id
                                                 }
      if !is_nil(company_list) do
        # Pull All cards
        count_card = Repo.one from e in Employee, where: e.status == "A" and e.company_id == ^compid,
                                                  left_join: c in assoc(e, :employeecards),
                                                  where: c.status < "5",
                                                  select: count(e.id)

        # Pull Monthly Fee
        get_monthly = Repo.one from f in Feerules, where: f.type == ^"M" and f.status == ^"A",
                                                   select: %{
                                                     monthly_fee: f.monthly_fee,
                                                     per_card_fee: f.per_card_fee,
                                                     minimum_card: f.minimum_card,
                                                     vat: f.vat,
                                                   }
        monthly_fee = get_monthly.monthly_fee
        card_limit = get_monthly.minimum_card
        per_card_fee = get_monthly.per_card_fee
        currency = company_list.currency_code
        vat = get_monthly.vat
        extra_card = count_card - card_limit
        extra_amt = String.to_integer("#{extra_card}") * String.to_float("#{per_card_fee}")
        charge_fee = if card_limit < count_card do
          if String.to_float("#{vat}") > 0 do
            total_fee = String.to_float("#{monthly_fee}") + String.to_float("#{extra_amt}")
            cal_vat = String.to_float("#{total_fee}") * String.to_float("#{vat}") / 100
            (String.to_float("#{total_fee}") + String.to_float("#{cal_vat}"))
          else
            (String.to_float("#{monthly_fee}") + String.to_float("#{extra_amt}"))
          end
        else
          monthly_fee
        end

        # check amount is sufficiant or not
        balance = String.to_float("#{company_list.available_balance}") - String.to_float("#{charge_fee}")
        fees_data = if extra_card > 0 do
          [
            %{
              fees_name: "Monthly subscription",
              quantity: card_limit,
              unit_price: per_card_fee,
              tax: vat,
              total_unit: monthly_fee
            },
            %{
              fees_name: "Extra Card/s Charges",
              quantity: extra_card,
              unit_price: per_card_fee,
              tax: vat,
              total_unit: extra_amt
            }
          ]
        else
          [
            %{
              fees_name: "Monthly subscription",
              quantity: card_limit,
              unit_price: per_card_fee,
              tax: vat,
              total_unit: charge_fee
            }
          ]
        end

        if balance > 0 do

          remark = %{"from" => company_list.currency_code, "to" => "Viola Corporate"}

          type_credit = Application.get_env(:violacorp, :internal_fee)

          transaction_id = Integer.to_string(Commontools.randnumber(10))
          transactions = %{
            "commanall_id" => commanid,
            "company_id" => compid,
            "amount" => 0.00,
            "fee_amount" => charge_fee,
            "final_amount" => charge_fee,
            "cur_code" => currency,
            "balance" => balance,
            "previous_balance" => company_list.available_balance,
            "transaction_id" => transaction_id,
            "transaction_date" => today,
            "transaction_mode" => "D",
            "transaction_type" => "A2O",
            "api_type" => type_credit,
            "category" => "FEE",
            "description" => "Charge monthly fee",
            "remark" => Poison.encode!(remark),
            "inserted_by" => commanid
          }
          changeset = Transactions.changesetFee(%Transactions{}, transactions)
          case Repo.insert(changeset) do
            {:ok, data} ->
              ids = data.id
              request = %{
                type: "228",
                notes: "Monthly Fee Charges", # Limited Debit   or  Monthly Fee Charges
                amount: charge_fee,
                currency: currency,
                account_id: company_list.accomplish_account_id
              }
              # Send to Accomplish
              response = Accomplish.load_money(request)
              response_code = response["result"]["code"]
              response_message = response["result"]["friendly_message"]
              transactions_id_api = response["info"]["original_source_id"]
              if response_code == "0000" do
                trans_status = Repo.get(Transactions, ids)
                update_status = %{"status" => "S", "transactions_id_api" => transactions_id_api}
                changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                Repo.update(changeset_transaction)

                gets_account = Accomplish.get_account(company_list.accomplish_account_id)
                current_balance = gets_account["info"]["balance"]
                available_balance = gets_account["info"]["available_balance"]
                update_balance = %{
                  "available_balance" => available_balance,
                  "current_balance" => current_balance
                }
                account_details = Repo.get(Companyaccounts, company_list.companyaccountsid)
                changeset_companyaccount = Companyaccounts.changesetBalance(
                  account_details,
                  update_balance
                )
                Repo.update(changeset_companyaccount)

                # store due fee
                duefees = %{
                  "commanall_id" => commanid,
                  "transactions_id" => ids,
                  "amount" => charge_fee,
                  "total_cards" => count_card,
                  "remark" => Poison.encode!(fees_data),
                  "description" => "Charge monthly fee",
                  "pay_date" => change_date,
                  "next_date" => next_date,
                  "status" => "C",
                  "inserted_by" => commanid
                }
                changeset = Duefees.changeset(%Duefees{}, duefees)
                Repo.insert(changeset)

                #                       DEPRECATED
                #                       data = %{
                #                         :section => "monthly_fees",
                #                         :commanall_id => commanid,
                #                         :company_name => "Viola Group",
                #                         :receipt_date => to_date,
                #                         :receipt_number => transaction_id,
                #                         :receipt_reference => "",
                #                         :fees => fees_data,
                #                         :subtotal_price => charge_fee,
                #                         :total_tax => "0.00",
                #                         :total_price => charge_fee,
                #                       }
                #                       AlertsController.sendEmail(data)


                commandata = Repo.one from cmn in Commanall, where: cmn.id == ^commanid,
                                                             left_join: m in assoc(cmn, :contacts),
                                                             on: m.is_primary == "Y",
                                                             left_join: d in assoc(cmn, :devicedetails),
                                                             on: d.is_delete == "N" and (
                                                               d.type == "A" or d.type == "I"),
                                                             select: %{
                                                               id: cmn.id,
                                                               email_id: cmn.email_id,
                                                               as_login: cmn.as_login,
                                                               code: m.code,
                                                               contact_number: m.contact_number,
                                                               token: d.token,
                                                               token_type: d.type,
                                                             }
                data = [
                  %{
                    section: "monthly_fees",
                    type: "E",
                    email_id: commandata.email_id,
                    data: %{
                      :company_name => "Viola Group",
                      :receipt_date => to_date,
                      :receipt_number => transaction_id,
                      :receipt_reference => "",
                      :fees => fees_data,
                      :subtotal_price => charge_fee,
                      :total_tax => "0.00",
                      :total_price => charge_fee
                    }
                    # Content
                  },
                  %{
                    section: "monthly_fees",
                    type: "S",
                    contact_code: commandata.code,
                    contact_number: commandata.contact_number,
                    data: %{
                      :company_name => "Viola Group",
                      :receipt_date => to_date,
                      :receipt_number => transaction_id,
                      :receipt_reference => "",
                      :fees => fees_data,
                      :subtotal_price => charge_fee,
                      :total_tax => "0.00",
                      :total_price => charge_fee
                    }
                    # Content# Content
                  },
                  %{
                    section: "monthly_fees",
                    type: "N",
                    token: commandata.token,
                    push_type: commandata.token_type, # "I" or "A"
                    login: commandata.as_login, # "Y" or "N"
                    data: %{
                      :company_name => "Viola Group",
                      :receipt_date => to_date,
                      :receipt_number => transaction_id,
                      :receipt_reference => "",
                      :fees => fees_data,
                      :subtotal_price => charge_fee,
                      :total_tax => "0.00",
                      :total_price => charge_fee
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)


                _response = "Charged monthly fee"
              else
                check_pending_entry = Repo.one(
                  from d in Duefees,
                  where: d.commanall_id == ^commanid and d.pay_date == ^change_date,
                  select: %{
                    id: d.id
                  }
                )
                if check_pending_entry == nil do
                  # store due fee
                  duefees = %{
                    "commanall_id" => commanid,
                    "amount" => charge_fee,
                    "total_cards" => count_card,
                    "remark" => Poison.encode!(fees_data),
                    "description" => "Charge monthly fee",
                    "pay_date" => change_date,
                    "next_date" => next_date,
                    "reason" => response_message,
                    "inserted_by" => commanid
                  }
                  changeset = Duefees.changeset(%Duefees{}, duefees)
                  Repo.insert(changeset)
                end
                trans_status = Repo.get(Transactions, ids)
                update_status = %{"description" => response_message}
                changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
                Repo.update(changeset_transaction)
                _response = "#{response_message}"
              end
          end
        else
          check_pending_entry = Repo.one(
            from d in Duefees,
            where: d.commanall_id == ^commanid and d.pay_date == ^change_date,
            select: %{
              id: d.id
            }
          )
          if check_pending_entry == nil do
            # store due fee
            duefees = %{
              "commanall_id" => commanid,
              "amount" => charge_fee,
              "total_cards" => count_card,
              "remark" => Poison.encode!(fees_data),
              "description" => "Charge monthly fee",
              "pay_date" => change_date,
              "next_date" => next_date,
              "reason" => "Not sufficient funds",
              "inserted_by" => commanid
            }
            changeset = Duefees.changeset(%Duefees{}, duefees)
            Repo.insert(changeset)
            _response = "Not sufficient funds."
          else
            _response = "Not sufficient funds."
          end
        end
      else
        _response = "Company account is not exist."
      end
    else
      _response = "Date not allowed."
    end

  end

  # Company Balance Refresh
  def companyRefreshBalance(conn, params) do

    company_id = params["id"]
    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do

      # get accomplish user id
      commanall = Repo.one from c in Commanall, where: c.company_id == ^company_id,
                                                select: %{
                                                  id: c.id,
                                                  accomplish_userid: c.accomplish_userid
                                                }

      response = if commanall.accomplish_userid != nil do
        userid = commanall.accomplish_userid
        commanallid = commanall.id
        TestController.update_account_balance(commanallid, userid)
      else
        %{"response_code" => "404", "response_message" => "Record not found!"}
      end

      response_code = if response["response_code"] == "0000" do
        "200"
      else
        response["response_code"]
      end

      response_msg = if response["response_code"] == "0000" do
        "Balance Refreshed"
      else
        response["response_message"]
      end

      json conn, %{status_code: response_code, message: response_msg}

    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end


  # Employee Balance Refresh
  def employeeRefreshBalance(conn, params) do

    employee_id = params["id"]
    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do

      # call Load Pending Transaction method
      pending_load_params = %{
        "worker_type" => "pending_transactions_updater",
        "employee_id" => employee_id
      }
      success_load_params = %{
        "worker_type" => "success_transactions_updater",
        "employee_id" => employee_id
      }
      Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [pending_load_params], max_retries: 1)
      Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [success_load_params], max_retries: 1)

      # get accomplish user id
      commanall = Repo.one from c in Commanall, where: c.employee_id == ^employee_id,
                                                select: %{
                                                  id: c.id,
                                                  accomplish_userid: c.accomplish_userid
                                                }

      response = if commanall.accomplish_userid != nil do
        userid = commanall.accomplish_userid
        TestController.update_card_balance(userid)
      else
        %{"response_code" => "404", "response_message" => "Record not found!"}
      end

      response_code = if response["response_code"] == "0000" do
        "200"
      else
        response["response_code"]
      end

      response_msg = if response["response_code"] == "0000" do
        "Balance Refreshed"
      else
        response["response_message"]
      end

      json conn, %{status_code: response_code, message: response_msg}

    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end


  # Load POS transaction for employee cards
  def employeePosTransaction(conn, params) do

    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do

      all_employee = Repo.all(
        from c in Commanall, where: c.status == ^"A" and not is_nil(c.employee_id) and not is_nil(c.accomplish_userid),
                             order_by: [
                               asc: c.id
                             ],
                             select: %{
                               commanid: c.id,
                               employee_id: c.employee_id,
                               accomplish_userid: c.accomplish_userid
                             }
      )

      Enum.each all_employee, fn emp ->
        employee_id = emp.employee_id
        commanall_id = emp.commanid
        user_id = emp.accomplish_userid

        # get company id
        employee_com = Repo.get(Employee, employee_id)
        company_id = employee_com.company_id

        today = DateTime.utc_now
        to_date = [today.year, today.month, today.day]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")
        from_date = "2018-06-01"

        status = "0" # 0 = success and 1 = pending
        start_index = "0"
        page_size = "50"

        request = "?user_id=#{user_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{status}&start_index=#{
          start_index
        }&page_size=#{page_size}"

        response = Accomplish.get_success_transaction(request)

        if !is_nil(response) do
          response_code = response["result"]["code"]
          if response_code == "0000" do
            Enum.each response["transactions"], fn v ->
              type = v["info"]["type"]
              text_msg = if type == 38 do
                "Purchase ONLINE"
              else
                if type == 46 do
                  "ATM Withdrawal"
                else
                  if type == 48 do
                    "Purchase Offline"
                  else
                    nil
                  end
                end
              end
              if !is_nil(text_msg) do
                ids = v["info"]["id"]
                [check_transaction] = Repo.all from a in Transactions, where: a.pos_id == ^ids,
                                                                       select: count(a.pos_id)
                if check_transaction == 0 do
                  # check pending row
                  server_date = v["info"]["server_date"]
                  amount = v["info"]["amount"]

                  accomplish_card_id = v["info"]["account_id"]
                  employeecards = Repo.get_by!(Employeecards, accomplish_card_id: accomplish_card_id)
                  employeecards_id = employeecards.id
                  currency = employeecards.currency_code
                  to_card = employeecards.last_digit

                  last_pending_transaction = Repo.one(
                    from t in Transactions,
                    where: t.commanall_id == ^commanall_id and t.category == ^"POS" and t.amount == ^amount and t.employeecards_id == ^employeecards_id and t.status == ^"P",
                    order_by: [
                      desc: t.id
                    ],
                    limit: 1,
                    select: %{
                      id: t.id,
                      description: t.description
                    }
                  )

                  notes = v["info"]["notes"]
                  response_notes = String.split(notes, "-", trim: true)
                  notes_last_value = response_notes
                                     |> Enum.take(-1)
                                     |> Enum.join()
                  if is_nil(last_pending_transaction) do
                    operation = v["info"]["operation"]
                    date_utc = v["info"]["date_utc"]
                    transaction_id = v["info"]["original_source_id"]
                    remark = %{"from" => to_card, "to" => notes_last_value}
                    api_transaction_date = %{"server_date" => server_date, "utc_date" => date_utc}
                    transaction_mode = if operation == "Debit" do
                      "D"
                    else
                      "C"
                    end
                    # Create POS transaction
                    transaction = %{
                      "commanall_id" => commanall_id,
                      "company_id" => company_id,
                      "employee_id" => employee_id,
                      "employeecards_id" => employeecards_id,
                      "pos_id" => ids,
                      "amount" => amount,
                      "fee_amount" => 0.00,
                      "final_amount" => amount,
                      "cur_code" => currency,
                      "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                      "transactions_id_api" => transaction_id,
                      "server_date" => server_date,
                      "transaction_date" => date_utc,
                      "api_transaction_date" => Poison.encode!(api_transaction_date),
                      "transaction_mode" => transaction_mode,
                      "transaction_type" => "C2O",
                      "category" => "POS",
                      "status" => "S",
                      "description" => notes,
                      "remark" => Poison.encode!(remark),
                      "inserted_by" => commanall_id
                    }
                    IO.inspect(transaction)
                    changeset_transaction = Transactions.changeset_pos(%Transactions{}, transaction)
                    Repo.insert(changeset_transaction)
                  else
                    last_notes = last_pending_transaction.description
                    response_notes_db = String.split(last_notes, "/", trim: true)
                    notes_last_value_db = response_notes_db
                                          |> Enum.take(1)
                                          |> Enum.join()

                    response_notes_live = String.split(notes, "/", trim: true)
                    notes_last_value_live = response_notes_live
                                            |> Enum.take(1)
                                            |> Enum.join()
                    if notes_last_value_db == notes_last_value_live do
                      transaction_id = v["info"]["original_source_id"]
                      trans_status = Repo.get(Transactions, last_pending_transaction.id)
                      update_status = %{"status" => "S", "pos_id" => ids, "transactions_id_api" => transaction_id}
                      IO.inspect(update_status)
                      changeset_transaction = Transactions.changesetUpdateStatusApi(trans_status, update_status)
                      Repo.update(changeset_transaction)
                    end
                  end
                else
                  # Update pos remark in transaction
                  notes = v["info"]["notes"]
                  response_notes = String.split(notes, "-", trim: true)
                  notes_last_value = response_notes
                                     |> Enum.take(-1)
                                     |> Enum.join()

                  accomplish_card_id = v["info"]["account_id"]
                  employeecards = Repo.get_by!(Employeecards, accomplish_card_id: accomplish_card_id)
                  from_card = employeecards.last_digit

                  remark = %{"from" => from_card, "to" => notes_last_value}
                  trans_status = Repo.get_by!(Transactions, pos_id: ids)
                  update_status = %{"remark" => Poison.encode!(remark)}
                  IO.inspect(update_status)
                  changeset_transaction = Transactions.changesetUpdateStatusApi(trans_status, update_status)
                  Repo.update(changeset_transaction)
                end
              end
            end
          end
        end
      end

      json conn,
           %{
             status_code: "200",
             data: %{
               message: "Load POS transaction in viola corporate."
             }
           }

    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end


  # Load POS transaction for employee cards
  def employeeCardsBalance do
    Exq.enqueue(Exq, "daily_cardsbalances_sender", DailyCardbalancesSender, [], max_retries: 3)
  end

end