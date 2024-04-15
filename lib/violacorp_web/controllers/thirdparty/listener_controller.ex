defmodule ViolacorpWeb.Thirdparty.ListenerController do
  use ViolacorpWeb, :controller

  import Ecto.Query
  import Plug.Conn
  require Logger
  alias Violacorp.Repo

  @moduledoc "Webhook Listener Controller"

  alias Violacorp.Libraries.Signature
  alias Violacorp.Libraries.Signaturedev
  alias Violacorp.Schemas.Listener
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Libraries.Notification.SendNotification
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Accomplish

  # Account Create
  def verifySignature(conn, params) do

    [incoming_signature] = get_req_header(conn, "digitalsignature")

    type = params["Type"]
    version = params["Version"]

    accountid = params["Payload"]["AccountId"]
    accountname = params["Payload"]["AccountName"]
    accountholderlabel = params["Payload"]["AccountHolderLabel"]
    iban = params["Payload"]["AccountIdentifiers"]["IBAN"]
    bban = params["Payload"]["AccountIdentifiers"]["BBAN"]

    timestampcreated = params["Payload"]["TimestampCreated"]
    accounttype = params["Payload"]["AccountType"]
    nonce = params["Nonce"]

    string_body = "{\"Type\":\"#{type}\",\"Version\":#{version},\"Payload\":{\"AccountId\":\"#{
      accountid
    }\",\"AccountName\":\"#{accountname}\",\"AccountHolderLabel\":\"#{
      accountholderlabel
    }\",\"AccountIdentifiers\":{\"IBAN\":\"#{iban}\",\"BBAN\":\"#{bban}\"},\"TimestampCreated\":\"#{
      timestampcreated
    }\",\"AccountType\":\"#{accounttype}\"},\"Nonce\":#{nonce}}"

    public_key_reference = params["public_key_reference"]
    sign_algo = params["sign_algo"]
    endpoint = params["endpoint"]

    # GENERATE OUR SIGNATURE
    header = %{
      "content-type" => "application/json"
    }
    body_verify = %{
      "message" => string_body,
      "key-reference" => public_key_reference,
      "sign-algo" => sign_algo,
      "signature" => incoming_signature
    }


    verify = post_http(endpoint, header, Poison.encode!(body_verify))

    json conn, verify

  end

  # POST HTTP
  defp post_http(url, header, body) do
    case HTTPoison.post(url, body, header, [recv_timeout: 50_000]) do
      {:ok, %{status_code: 200, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 202, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 201, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 400, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 403, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "Record not found"
      {:ok, %{status_code: 409, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:ok, %{status_code: 503}} -> "Internal server error"
      {:error, %{reason: reason}} -> reason
    end
  end

  # Account Create
  def accountCreated(conn, params) do

    [incoming_signature] = get_req_header(conn, "digitalsignature")

    type = params["Type"]
    version = params["Version"]

    accountid = params["Payload"]["AccountId"]
    accountname = params["Payload"]["AccountName"]
    accountholderlabel = params["Payload"]["AccountHolderLabel"]
    iban = params["Payload"]["AccountIdentifiers"]["IBAN"]
    bban = params["Payload"]["AccountIdentifiers"]["BBAN"]

    timestampcreated = params["Payload"]["TimestampCreated"]
    accounttype = params["Payload"]["AccountType"]
    nonce = params["Nonce"]

    string_body = "{\"Type\":\"#{type}\",\"Version\":#{version},\"Payload\":{\"AccountId\":\"#{
      accountid
    }\",\"AccountName\":\"#{accountname}\",\"AccountHolderLabel\":\"#{
      accountholderlabel
    }\",\"AccountIdentifiers\":{\"IBAN\":\"#{iban}\",\"BBAN\":\"#{bban}\"},\"TimestampCreated\":\"#{
      timestampcreated
    }\",\"AccountType\":\"#{accounttype}\"},\"Nonce\":#{nonce}}"

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    signature_verify = if otp_mode == "dev", do: Signaturedev.verify_signature(incoming_signature, string_body), else: Signature.verify_signature(incoming_signature, string_body)

    # Insert request data to Listener Table
    listener = %{
      nonce: "#{params["Nonce"]}",
      type: params["Type"],
      request: string_body
    }
    listener_changeset = Listener.changeset(%Listener{}, listener)

    existing_listeners = Repo.all(from l in Listener, where: l.nonce == ^"#{nonce}")

    if Enum.count(existing_listeners) > 1 do
      # Generate Signature
      body = %{"Nonce" => params["Nonce"]}
             |> Poison.encode!
      string = ~s(#{body})
      keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)
      conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
      json conn, %{"Nonce": params["Nonce"]}
    else
      case Repo.insert(listener_changeset) do
        {:ok, listener} ->

          # Generate Signature
          body = %{"Nonce" => params["Nonce"]}
                 |> Poison.encode!
          string = ~s(#{body})
          keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

          header = %{
            "DigitalSignature" => keys["signature"],
            "content-type" => "application/json",
            "verify_status" => "#{signature_verify["status"]}"
          }

          # Check if account is present in Accounts
          account = Repo.get_by(Companybankaccount, account_id: params["Payload"]["AccountId"], status: "A")

          status = if is_nil(account), do: "R", else: "A"
          account_id = if is_nil(account), do: nil, else: account.id

          # insert record in table
          if is_nil(account_id) do

            account_info = Repo.get_by(Companybankaccount, account_name: accountname, status: "F")
            if !is_nil(account_info) do
              lan = String.length(iban)
              bank_code = String.slice(iban, 4..7)
              sort_code = String.slice(iban, 8..13)
              account_number = String.slice(iban, 14..lan)

              bankAccount = %{
                "account_id" => accountid,
                "account_number" => account_number,
                "iban_number" => iban,
                "bban_number" => bban,
                "currency" => "GBP",
                "sort_code" => sort_code,
                "bank_code" => bank_code,
                "status" => "A",
                "response" => string_body
              }
              changeset = Companybankaccount.changesetUpdate(account_info, bankAccount)
              Repo.update(changeset)
            end
          end

          existing_listener = Repo.get(Listener, listener.id)
          listener = %{
            accounts_id: "#{account_id}",
            header_response: Poison.encode!(header),
            response: body,
            status: status
          }
          listener_changeset_two = Listener.changesetUpdate(existing_listener, listener)
          Repo.update(listener_changeset_two)

          conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
          json conn, %{"Nonce": params["Nonce"]}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end

  end

  # Account Disabled
  def accountDisabled(conn, params) do
#    [incoming_signature] = get_req_header(conn, "digitalsignature")

    [data] = conn.assigns.raw_body

    # Insert request data to Listener Table
    listener = %{
      nonce: "#{params["Nonce"]}",
      type: params["Type"],
      request: data
    }

    nonce = params["Nonce"]
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    listener_changeset = Listener.changeset(%Listener{}, listener)
    existing_listeners = Repo.all(from l in Listener, where: l.nonce == ^"#{nonce}")

    if Enum.count(existing_listeners) > 1 do
      # Generate Signature
      body = %{"Nonce" => params["Nonce"]}
             |> Poison.encode!
      string = ~s(#{body})
      keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)
      conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
      json conn, %{"Nonce": params["Nonce"]}
    else

      case Repo.insert(listener_changeset) do
        {:ok, listener} ->

          # Generate Signature
          body = %{"Nonce" => params["Nonce"]}
                 |> Poison.encode!
          string = ~s(#{body})
          keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

          header = %{
            "DigitalSignature" => keys["signature"],
            "content-type" => "application/json"
          }

          existing_listener = Repo.get(Listener, listener.id)
          listener = %{
            header_response: Poison.encode!(header),
            response: body,
            status: "R"
          }
          listener_changeset_two = Listener.changeset(existing_listener, listener)
          Repo.update(listener_changeset_two)

          conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
          json conn, %{"Nonce": params["Nonce"]}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  # Transaction Rejected
  def transactionRejected(conn, params) do
#    [incoming_signature] = get_req_header(conn, "digitalsignature")

    [data] = conn.assigns.raw_body

    # Insert request data to Listener Table
    listener = %{
      nonce: "#{params["Nonce"]}",
      type: params["Type"],
      request: data
    }

    nonce = params["Nonce"]
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    listener_changeset = Listener.changeset(%Listener{}, listener)
    existing_listeners = Repo.all(from l in Listener, where: l.nonce == ^"#{nonce}")

    if Enum.count(existing_listeners) > 1 do
      # Generate Signature
      body = %{"Nonce" => params["Nonce"]}
             |> Poison.encode!
      string = ~s(#{body})
      keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)
      conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
      json conn, %{"Nonce": params["Nonce"]}
    else
      case Repo.insert(listener_changeset) do
        {:ok, listener} ->

          # Generate Signature
          body = %{"Nonce" => params["Nonce"]}
                 |> Poison.encode!
          string = ~s(#{body})
          keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

          header = %{
            "DigitalSignature" => keys["signature"],
            "content-type" => "application/json"
          }

          existing_listener = Repo.get(Listener, listener.id)
          listener = %{
            header_response: Poison.encode!(header),
            response: body,
            status: "R"
          }
          listener_changeset_two = Listener.changeset(existing_listener, listener)
          Repo.update(listener_changeset_two)

          conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
          json conn, %{"Nonce": params["Nonce"]}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  # Transaction Settled
  def transactionSettled(conn, params) do
    [incoming_signature] = get_req_header(conn, "digitalsignature")

    type = params["Type"]
    version = params["Version"]
    transactionId = params["Payload"]["TransactionId"]
    status = params["Payload"]["Status"]
    scheme = params["Payload"]["Scheme"]
    endToEndTransactionId = params["Payload"]["EndToEndTransactionId"]
    enter_amount = "#{params["Payload"]["Amount"]}"
    amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
    timestampModified = params["Payload"]["TimestampModified"]
    currencyCode = params["Payload"]["CurrencyCode"]
    debitCreditCode = params["Payload"]["DebitCreditCode"]
    reference = params["Payload"]["Reference"]
    is_return = params["Payload"]["IsReturn"]

    accountIban = params["Payload"]["Account"]["IBAN"]
    accountBban = params["Payload"]["Account"]["BBAN"]
    accountName = params["Payload"]["Account"]["AccountName"]
    institutionName = params["Payload"]["Account"]["InstitutionName"]

    counterpart_account_iban = params["Payload"]["CounterpartAccount"]["IBAN"]
    counterpart_account_bban = params["Payload"]["CounterpartAccount"]["BBAN"]
    counterpart_account_name = params["Payload"]["CounterpartAccount"]["AccountName"]
    counterpart_account_institutionName = params["Payload"]["CounterpartAccount"]["InstitutionName"]

    actualEndToEndTransactionId = params["Payload"]["ActualEndToEndTransactionId"]
    nonce = params["Nonce"]

    string_body = "{\"Type\":\"#{type}\",\"Version\":#{version},\"Payload\":{\"TransactionId\":\"#{
      transactionId
    }\",\"Status\":\"#{status}\",\"Scheme\":\"#{scheme}\",\"EndToEndTransactionId\":\"#{
      endToEndTransactionId
    }\",\"Amount\":\"#{amount}\",\"TimestampModified\":\"#{timestampModified}\",\"CurrencyCode\":\"#{
      currencyCode
    }\",\"DebitCreditCode\":\"#{debitCreditCode}\",\"Reference\":\"#{reference}\",\"IsReturn\":\"#{
      is_return
    }\",\"Account\":{\"IBAN\":\"#{accountIban}\",\"BBAN\":\"#{accountBban}\",\"AccountName\":\"#{
      accountName
    }\",\"InstitutionName\":\"#{institutionName}\"},\"CounterpartAccount\":{\"IBAN\":\"#{
      counterpart_account_iban
    }\",\"BBAN\":\"#{counterpart_account_bban}\",\"AccountName\":\"#{
      counterpart_account_name
    }\",\"InstitutionName\":\"#{counterpart_account_institutionName}\"},\"ActualEndToEndTransactionId\":\"#{
      actualEndToEndTransactionId
    }\"},\"Nonce\":#{nonce}}"
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    signature_verify = if otp_mode == "dev", do: Signaturedev.verify_signature(incoming_signature, string_body), else: Signature.verify_signature(incoming_signature, string_body)

    # Insert request data to Listener Table
    listener = %{
      nonce: "#{params["Nonce"]}",
      type: params["Type"],
      request: string_body
    }
    listener_changeset = Listener.changeset(%Listener{}, listener)

    existing_listeners = Repo.all(from l in Listener, where: l.nonce == ^"#{nonce}")

    if Enum.count(existing_listeners) > 1 do
      # Generate Signature
      body = %{"Nonce" => params["Nonce"]}
             |> Poison.encode!
      string = ~s(#{body})
      keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)
      conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
      json conn, %{"Nonce": params["Nonce"]}
    else
      case Repo.insert(listener_changeset) do
        {:ok, listener} ->

          # Generate Signature
          body = %{"Nonce" => params["Nonce"]}
                 |> Poison.encode!
          string = ~s(#{body})
          keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

          header = %{
            "DigitalSignature" => keys["signature"],
            "content-type" => "application/json",
            "verify_status" => "#{signature_verify["status"]}"
          }

          existing_listener = Repo.get(Listener, listener.id)
          listener = %{
            accounts_id: endToEndTransactionId,
            header_response: Poison.encode!(header),
            response: body,
            status: "A"
          }
          listener_changeset_two = Listener.changesetUpdate(existing_listener, listener)
          Repo.update(listener_changeset_two)

          # check enetoend transaction id in db
          transaction_mode = if debitCreditCode == "Debit", do: "D", else: "C"
          check_transaction = Repo.get_by(
            Transactions,
            transaction_id: endToEndTransactionId,
            transaction_type: "A2A",
            transaction_mode: transaction_mode
          )
          if is_nil(check_transaction) do
            account_info = Repo.get_by(Companybankaccount, iban_number: accountIban, status: "A")
            if !is_nil(account_info) do
              company_id = account_info.company_id
              account_balance = account_info.balance

              accountid = account_info.account_id
              db_balance = account_info.balance
              response = Clearbank.view_account(accountid)
              res = get_in(response["account"]["balances"], [Access.at(0)])
              balance = Decimal.from_float(res["amount"])

              if balance !== db_balance do
                accountBalance = %{balance: balance}
                changeset = Companybankaccount.changesetUpdateBalance(account_info, accountBalance)
                Repo.update(changeset)
              end

              #            common_all = Repo.get_by(Commanall, company_id: company_id)
              common_all = Repo.one(
                from cmn in Commanall, where: cmn.company_id == ^company_id,
                                       left_join: c in assoc(cmn, :contacts),
                                       on: c.is_primary == "Y",
                                       left_join: d in assoc(cmn, :devicedetails),
                                       on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                       preload: [
                                         contacts: c,
                                         devicedetails: d
                                       ]
              )

              type_debit = Application.get_env(:violacorp, :transfer_debit)
              type_credit = Application.get_env(:violacorp, :transfer_credit)

              api_type = if debitCreditCode == "Debit", do: type_debit, else: type_credit

              lan = String.length(accountIban)
              account_number = String.slice(accountIban, 14..lan)

              bban_lan = String.length(counterpart_account_bban)
              sort_code = String.slice(counterpart_account_bban, 4..10)
              accountNumber = String.slice(counterpart_account_bban, 10..bban_lan)
              ff_code = String.slice(sort_code, 0..1)
              ss_code = String.slice(sort_code, 2..3)
              tt_code = String.slice(sort_code, 4..5)
              accountInfo = "#{ff_code} - #{ss_code} - #{tt_code}  #{accountNumber}"

              remark = if debitCreditCode == "Credit" do
                %{
                  "from" => "#{counterpart_account_name} -break- #{accountInfo} #{counterpart_account_institutionName}",
                  "to" => accountName,
                  "from_account" => accountNumber,
                  "to_account" => account_number,
                  "from_info" => %{
                    "owner_name" => "#{counterpart_account_name}",
                    "card_number" => "",
                    "sort_code" => "#{ff_code}-#{ss_code}-#{tt_code}",
                    "account_number" => "#{accountNumber}"
                  },
                  "to_info" => %{
                    "owner_name" => "#{accountName}",
                    "card_number" => "",
                    "sort_code" => "#{account_info.sort_code}",
                    "account_number" => "#{account_info.account_number}"
                  }
                }
              else
                %{
                  "to" => "#{counterpart_account_name} -break- #{accountInfo} #{counterpart_account_institutionName}",
                  "from" => accountName,
                  "to_account" => accountNumber,
                  "from_account" => account_number,
                  "to_info" => %{
                    "owner_name" => "#{counterpart_account_name}",
                    "card_number" => "",
                    "sort_code" => "#{ff_code}-#{ss_code}-#{tt_code}",
                    "account_number" => "#{accountNumber}"
                  },
                  "from_info" => %{
                    "owner_name" => "#{accountName}",
                    "card_number" => "",
                    "sort_code" => "#{account_info.sort_code}",
                    "account_number" => "#{account_info.account_number}"
                  }
                }
              end

              balance = if debitCreditCode == "Debit",
                           do: String.to_float("#{account_balance}") - String.to_float("#{amount}"),
                           else: String.to_float("#{account_balance}") + String.to_float("#{amount}")

              description = %{
                scheme: scheme,
                institutionName: counterpart_account_institutionName,
                accountName: counterpart_account_name,
                iban: counterpart_account_iban,
                bban: counterpart_account_bban
              }

              transaction = %{
                "commanall_id" => common_all.id,
                "company_id" => company_id,
                "bank_id" => account_info.id,
                "amount" => amount,
                "fee_amount" => 0.00,
                "final_amount" => amount,
                "balance" => balance,
                "previous_balance" => account_balance,
                "cur_code" => currencyCode,
                "transaction_id" => endToEndTransactionId,
                "transactions_id_api" => reference,
                "transaction_date" => timestampModified,
                "transaction_mode" => transaction_mode,
                "api_type" => api_type,
                "transaction_type" => "A2A",
                "category" => "AA",
                "status" => "S",
                "description" => Poison.encode!(description),
                "remark" => Poison.encode!(remark),
                "inserted_by" => common_all.id
              }
              changeset = Transactions.changesetWebhook(%Transactions{}, transaction)
              Repo.insert(changeset)

              if debitCreditCode == "Credit" and !is_nil(common_all) do
                amount_notification = Commontools.sort_amount(amount, 2, "decimal")
                SendNotification.sender(
                  "credit_bank_transaction",
                  %{
                    contact_code: if is_nil(Enum.at(common_all.contacts, 0)) do
                      nil
                    else
                      Enum.at(common_all.contacts, 0).code
                    end,
                    contact_number: if is_nil(Enum.at(common_all.contacts, 0)) do
                      nil
                    else
                      Enum.at(common_all.contacts, 0).contact_number
                    end,
                    email_id: common_all.email_id,
                    token: if is_nil(common_all.devicedetails) do
                      nil
                    else
                      common_all.devicedetails.token
                    end,
                    token_type: if is_nil(common_all.devicedetails) do
                      nil
                    else
                      common_all.devicedetails.type
                    end,
                    as_login: common_all.as_login
                  },
                  %{
                    :amount => amount_notification,
                    :sender_name => counterpart_account_name,
                    :receiver_name => accountName
                  }
                )
              end
            else

              # check transaction for admin
              transaction_mode = if debitCreditCode == "Debit", do: "D", else: "C"
#              check_transaction = Repo.get_by(Admintransactions, reference_id: reference, mode: transaction_mode)
              check_transaction = Repo.one(from adm in Admintransactions, where: adm.reference_id == ^reference and (adm.transaction_id == ^endToEndTransactionId or adm.end_to_en_identifier == ^endToEndTransactionId) and adm.mode == ^transaction_mode)
              if is_nil(check_transaction) do

                # check iban number for admin account
                admin_account_info = Repo.get_by(Adminaccounts, iban_number: accountIban, status: "A")
                if !is_nil(admin_account_info) do

                  adminaccounts_id = admin_account_info.id
                  from_user = if (debitCreditCode == "Debit"), do: accountIban, else: counterpart_account_iban
                  to_user = if (debitCreditCode == "Debit"), do: counterpart_account_iban, else: accountIban
                  identification = if (debitCreditCode == "Debit"), do: accountIban, else: counterpart_account_iban
                  transaction = %{
                    "adminaccounts_id" => adminaccounts_id,
                    "from_user" => from_user,
                    "to_user" => to_user,
                    "amount" => amount,
                    "currency" => currencyCode,
                    "transaction_date" => timestampModified,
                    "reference_id" => reference,
                    "transaction_id" => transactionId,
                    "api_status" => status,
                    "end_to_en_identifier" => endToEndTransactionId,
                    "mode" => transaction_mode,
                    "identification" => identification,
                    "response" => Poison.encode!(params),
                    "status" => "S",
                    "inserted_by" => admin_account_info.administratorusers_id
                  }

                  changeset = Admintransactions.changeset(%Admintransactions{}, transaction)
                  Repo.insert(changeset)
                end
              end
            end
          else
            # CALL TOPUP if TRANSACTION CATEGORY IS 'MV' and if a Credit transaction is not already in place
            if !is_nil(check_transaction) and check_transaction.category == "MV" and transaction_mode == "D" do
              check_call = Repo.get_by(Transactions, transaction_id: endToEndTransactionId, transaction_mode: "C")
              if is_nil(check_call) do
                call_topup(check_transaction)
              end
            end
          end
          conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
          json conn, %{"Nonce": params["Nonce"]}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

  defp call_topup(transDetails) do

    trans_status = transDetails
    commanid = transDetails.commanall_id
    id = transDetails.company_id
    amount = transDetails.final_amount
    unique_id = Integer.to_string(Commontools.randnumber(10))
    clearbank_id = transDetails.bank_id
    currency = "GBP"
    # Company Receiver Details
    company_account_details = Repo.get_by(Companyaccounts, company_id: id, currency_code: "GBP")
    _get_company = Repo.get(Company, company_account_details.company_id)

    sender_details = Repo.get_by(Companybankaccount, id: clearbank_id, company_id: id, status: "A")


    sort_code = if !is_nil(sender_details.sort_code) do
      ff_code = String.slice(sender_details.sort_code, 0..1)
      ss_code = String.slice(sender_details.sort_code, 2..3)
      tt_code = String.slice(sender_details.sort_code, 4..5)

      "#{ff_code}-#{ss_code}-#{tt_code}"
    else
      ""
    end
    remark_too = %{
      "from" => "Card Management Account -break- Fund Received",
      "to" => "Online Business Account",
      "to_info" =>
      %{
        "owner_name" => sender_details.account_name,
        "card_number" => "",
        "sort_code" => sort_code,
        "account_number" => "#{sender_details.account_number}"
      },
      "from_info" =>
      %{
        "owner_name" => "Card Management Account",
        "card_number" => "",
        "sort_code" => "#{company_account_details.accomplish_account_id}",
        "account_number" => "#{company_account_details.accomplish_account_number}"
      }
    }

    # Admin  Receiver Details
    receiver_details = Repo.get_by(Adminaccounts, type: "Accomplish")
    today = DateTime.utc_now

    type_debit = Application.get_env(:violacorp, :movefund_debit)
    type_credit = Application.get_env(:violacorp, :movefund_credit)
    type = Application.get_env(:violacorp, :general_credit)
    account_id = company_account_details.accomplish_account_id

    # Call Accomplish
    request = %{
      type: type,
      notes: "",
      amount: amount,
      currency: currency,
      account_id: account_id
    }

    # Send to Accomplish
    response = Accomplish.load_money(request)
    response_code = response["result"]["code"]
    _response_message = response["result"]["friendly_message"]

    if response_code == "0000" do

      available_balance = String.to_float("#{company_account_details.available_balance}") + String.to_float("#{amount}")

      transaction_account = %{
        "commanall_id" => commanid,
        "company_id" => id,
        "amount" => amount,
        "account_id" => company_account_details.id,
        "fee_amount" => 0.00,
        "final_amount" => amount,
        "cur_code" => currency,
        "balance" => available_balance,
        "previous_balance" => company_account_details.available_balance,
        "transaction_id" => unique_id,
        "transactions_id_api" => response["info"]["original_source_id"],
        "transaction_date" => today,
        "api_type" => type_credit,
        "transaction_mode" => "C",
        "transaction_type" => "B2A",
        "category" => "MV",
        "description" => "Fund received from online business account",
        "status" => "S",
        "remark" => Poison.encode!(remark_too),
        "inserted_by" => commanid
      }
      changeset_account = Transactions.changesetClearbankWorker(%Transactions{}, transaction_account)

      case Repo.insert(changeset_account) do
        {:ok, _data} ->  # Update Account Transaction Status
          update_status = %{"status" => "S"}
          changeset_transaction = Transactions.changesetUpdateStatus(trans_status, update_status)
          Repo.update(changeset_transaction)

          company_account_details
          |> Companyaccounts.changesetBalance(%{"available_balance" => available_balance})
          |> Repo.update()

        {:error, changeset} ->
          rx_end_date = DateTime.utc_now
          update_status = %{
            "status" => "P",
            "description" => Poison.encode!(changeset),
            "transaction_end_date" => rx_end_date
          }
          changeset_transaction = Transactions.changesetUpdateStatus(transDetails, update_status)
          Repo.update(changeset_transaction)
      end
    else
    Logger.warn "Card Management Topup Failed t_id: #{trans_status.id}"
      # Add Refund
      accountDetails = %{
        amount: amount,
        currency: currency,
        paymentInstructionIdentification: "#{Commontools.randnumber(8)}",
        d_name: receiver_details.account_name,
        d_iban: receiver_details.iban_number,
        d_code: "BBAN",
        d_identification: "#{Commontools.randnumber(8)}",
        d_issuer: "VIOLA",
        d_proprietary: "Sender",
        instructionIdentification: "#{Commontools.randnumber(8)}",
        endToEndIdentification: unique_id,
        c_name: sender_details.account_name,
        c_iban: sender_details.iban_number,
        c_proprietary: "Receiver",
        c_code: "BBAN",
        c_identification: "#{Commontools.randnumber(8)}",
        c_issuer: "VIOLA",
        reference: "#{Commontools.randnumber(8)}"
      }
      refund =  Clearbank.paymentAToIB(accountDetails)
      if !is_nil(refund["transactions"]) do
        ref_res = get_in(refund["transactions"], [Access.at(0)])
        response = ref_res["response"]
        if response == "Accepted" do

          refund_balance = String.to_float("#{sender_details.balance}") + String.to_float("#{amount}")

          transaction_return = %{
            "commanall_id" => commanid,
            "company_id" => id,
            "related_with_id" => trans_status.id,
            "amount" => amount,
            "bank_id" => clearbank_id,
            "fee_amount" => 0.00,
            "final_amount" => amount,
            "cur_code" => currency,
            "balance" => refund_balance,
            "previous_balance" => sender_details.balance,
            "transaction_id" => Commontools.randnumber(10),
            "transaction_date" => today,
            "api_type" => type_debit,
            "transaction_mode" => "C",
            "transaction_type" => "A2A",
            "category" => "MV",
            "description" => "",
            "status" => "R",
            "remark" => transDetails.remark,
            "inserted_by" => commanid
          }
          changeset_account = Transactions.changesetClearbankWorker(%Transactions{}, transaction_return)
          Repo.insert(changeset_account)
          # update existing transaction status to 'F'
          changeset_transaction = Transactions.changesetDescription(trans_status, %{"status" => "F"})
          Repo.update(changeset_transaction)
        else
          update_status = %{"status" => "P", "description" => Poison.encode!(ref_res)}
          changeset_transaction = Transactions.changesetDescription(trans_status, update_status)
          Repo.update(changeset_transaction)
        end
      end
    end

  end

  # paymentMessageAssessmentFailed
  def paymentMessageAssessmentFailed(conn, params) do
    [incoming_signature] = get_req_header(conn, "digitalsignature")

    # {"Type":"PaymentMessageAssesmentFailed","Version":1,"Payload":{"MessageId":"17e6c8699f724185a6c8c4bb570ee264","PaymentMethodType":"FasterPayments","AssesmentFailure":[{"EndToEndId":"1315946933","Reasons":["UnexecutableCode.InboundPaymentDisabled ; Inbound payments disabled"]}],"AccountIdentification":{"Debtor":{"IBAN":"GB52CLRB04043100000306","BBAN":"CLRB04043100000306"},"Creditors":[{"Reference":"45422182","Amount":13.0,"IBAN":"GB21CLRB04056810000070","BBAN":"CLRB04056810000070"}]}},"Nonce":13110556}

    type = params["Type"]
    version = params["Version"]
    messageId = params["Payload"]["MessageId"]
    paymentMethodType = params["Payload"]["PaymentMethodType"]

    [assesmentFailure] = params["Payload"]["AssesmentFailure"]
    endToEndId = assesmentFailure["EndToEndId"]

    iban = params["Payload"]["AccountIdentification"]["Debtor"]["IBAN"]
    bban = params["Payload"]["AccountIdentification"]["Debtor"]["BBAN"]

    [creditors] = params["Payload"]["AccountIdentification"]["Creditors"]
    reference = creditors["Reference"]
    amount = creditors["Amount"]
    ciban = creditors["IBAN"]
    cbban = creditors["BBAN"]

    nonce = params["Nonce"]

    _chlLength = Enum.count(assesmentFailure["Reasons"])

    first_reason = List.first(assesmentFailure["Reasons"])
    last_reason = List.last(assesmentFailure["Reasons"])
    all_reasons = assesmentFailure["Reasons"]

    string_body_initial = Enum.reduce_while(all_reasons, "", fn x, acc ->
      is_last = x == last_reason
      is_first = x == first_reason
      cond do
        is_first and is_last ->
          final_string = "[\"#{x}\"]"
          {:halt, final_string}
        is_first ->
          reason = "[\"#{x}\","
          {:cont, reason}
        is_last ->
          reason = "\"#{x}\"]"
          total_reason = "#{acc}#{reason}"
          {:halt, total_reason}
        Enum.member?(all_reasons, x) -> reason = "\"#{x}\","
                                        {:cont, "#{acc}#{reason}"}
        true ->
          reason = ""
          {:halt, "#{reason}"}
      end
    end)
    string_body = if string_body_initial == "" do
      "{\"Type\":\"#{type}\",\"Version\":#{version},\"Payload\":{\"MessageId\":\"#{
        messageId
      }\",\"PaymentMethodType\":\"#{paymentMethodType}\",\"AssesmentFailure\":[{\"EndToEndId\":\"#{
        endToEndId
      }\",\"Reasons\":[\"\"]}],\"AccountIdentification\":{\"Debtor\":{\"IBAN\":\"#{iban}\",\"BBAN\":\"#{
        bban
      }\"},\"Creditors\":[{\"Reference\":\"#{reference}\",\"Amount\":#{amount},\"IBAN\":\"#{ciban}\",\"BBAN\":\"#{
        cbban
      }\"}]}},\"Nonce\":#{nonce}}"
    else
      "{\"Type\":\"#{type}\",\"Version\":#{version},\"Payload\":{\"MessageId\":\"#{
        messageId
      }\",\"PaymentMethodType\":\"#{paymentMethodType}\",\"AssesmentFailure\":[{\"EndToEndId\":\"#{
        endToEndId
      }\",\"Reasons\":#{string_body_initial}}],\"AccountIdentification\":{\"Debtor\":{\"IBAN\":\"#{iban}\",\"BBAN\":\"#{
        bban
      }\"},\"Creditors\":[{\"Reference\":\"#{reference}\",\"Amount\":#{amount},\"IBAN\":\"#{ciban}\",\"BBAN\":\"#{
        cbban
      }\"}]}},\"Nonce\":#{nonce}}"
    end

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    signature_verify = if otp_mode == "dev", do: Signaturedev.verify_signature(incoming_signature, string_body), else: Signature.verify_signature(incoming_signature, string_body)

    #    # Insert request data to Listener Table
    #    listener = %{
    #      nonce: "#{params["Nonce"]}",
    #      type: params["Type"],
    #      request: string_body
    #    }
    #    listener_changeset = Listener.changeset(%Listener{}, listener)

    #    [data] = conn.assigns.raw_body

    # Insert request data to Listener Table
    listener = %{
      nonce: "#{params["Nonce"]}",
      type: params["Type"],
      request: string_body
    }
    listener_changeset = Listener.changeset(%Listener{}, listener)

    existing_listeners = Repo.all(from l in Listener, where: l.nonce == ^"#{nonce}")

    if Enum.count(existing_listeners) > 1 do
      # Generate Signature
      body = %{"Nonce" => params["Nonce"]}
             |> Poison.encode!
      string = ~s(#{body})
      keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)
      conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
      json conn, %{"Nonce": params["Nonce"]}
    else
      case Repo.insert(listener_changeset) do
        {:ok, listener} ->

          # Generate Signature
          body = %{"Nonce" => params["Nonce"]}
                 |> Poison.encode!
          string = ~s(#{body})
          keys = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

          header = %{
            "DigitalSignature" => keys["signature"],
            "content-type" => "application/json",
            "verify_status" => "#{signature_verify["status"]}"
          }

          existing_listener = Repo.get(Listener, listener.id)
          listener = %{
            accounts_id: endToEndId,
            header_response: Poison.encode!(header),
            response: body,
            status: "A"
          }
          listener_changeset_two = Listener.changesetUpdate(existing_listener, listener)
          Repo.update(listener_changeset_two)

          # Update Transaction
          check_transaction = Repo.get_by(Transactions, transaction_id: endToEndId, transaction_type: "A2A")
          if !is_nil(check_transaction) do
            reason = assesmentFailure["Reasons"]
            responseData = Stream.with_index(reason, 1)
                           |> Enum.reduce(%{}, fn ({v, k}, acc) -> Map.put(acc, k, v) end)
            update_transaction = %{status: "F", description: Poison.encode!(responseData)}
            changeset = Transactions.changesetUpdateStatus(check_transaction, update_transaction)
            Repo.update(changeset)
          else
            account_info = Repo.get_by(Companybankaccount, iban_number: iban, status: "A")
            if !is_nil(account_info) do
              company_id = account_info.company_id
              common_all = Repo.get_by(Commanall, company_id: company_id)

              lan = String.length(iban)
              account_number = String.slice(iban, 14..lan)

              clan = String.length(ciban)
              caccount_number = String.slice(ciban, 14..clan)

              remark = %{"from" => account_number, "to" => caccount_number}

              type_debit = Application.get_env(:violacorp, :transfer_debit)

              reason = assesmentFailure["Reasons"]
              responseData = Stream.with_index(reason, 1)
                             |> Enum.reduce(%{}, fn ({v, k}, acc) -> Map.put(acc, k, v) end)

              transaction = %{
                "commanall_id" => common_all.id,
                "company_id" => company_id,
                "bank_id" => account_info.id,
                "amount" => amount,
                "fee_amount" => 0.00,
                "final_amount" => amount,
                "balance" => 0.00,
                "previous_balance" => 0.00,
                "cur_code" => "GBP",
                "transaction_id" => endToEndId,
                "transactions_id_api" => reference,
                "transaction_date" => DateTime.utc_now,
                "transaction_mode" => "D",
                "api_type" => type_debit,
                "transaction_type" => "A2A",
                "category" => "AA",
                "status" => "F",
                "description" => Poison.encode!(responseData),
                "remark" => Poison.encode!(remark),
                "inserted_by" => common_all.id
              }
              changeset = Transactions.changesetWebhook(%Transactions{}, transaction)
              Repo.insert(changeset)
            end
          end

          conn = Plug.Conn.put_resp_header(conn, "DigitalSignature", keys["signature"])
          json conn, %{"Nonce": params["Nonce"]}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end

end