defmodule ViolacorpWeb.Admin.AdminController do
  use ViolacorpWeb, :controller
  alias Violacorp.Repo
  import Ecto.Query

  require Logger

  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Adminaccounts
  alias Violacorp.Schemas.Adminbeneficiaries
  alias Violacorp.Schemas.Admintransactions
  alias Violacorp.Schemas.Contactus
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Beneficiaries
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Schemas.Duefees
  alias Violacorp.Schemas.UpdateHistory
  alias Violacorp.Schemas.Addressdirectors
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Tags

  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Notification.SettlementNotification
  alias Violacorp.Libraries.Commontools

  alias  Violacorp.Models.Admin

  def check_params(available, required) do
    Enum.all?(required, &(Map.has_key?(available, &1)))
  end

  def check_value(params) do
    cond do
      params["adminAccountId"] == "" and params["amount"] == "" and params["beneficairyAccountId"] == "" ->
        {
          :error,
          %{adminAccountId: ["can't be blank"], amount: ["can't be blank"], beneficairyAccountId: ["can't be blank"]}
        }
      params["adminAccountId"] == "" ->
        {:error, %{adminAccountId: ["can't be blank"]}}
      params["beneficairyAccountId"] == "" ->
        {:error, %{beneficairyAccountId: ["can't be blank"]}}
      params["amount"] == "" ->
        {:error, %{amount: ["can't be blank"]}}
      params["adminAccountId"] != "" and params["beneficairyAccountId"] != "" and params["adminAccountId"] != "" ->
        {:ok, "ok"}
    end
  end

  def getAdminProfile(conn, params)do
    data = Admin.adminProfile(params)
    case data do
      nil -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "  Admin Self profile view "
  def adminSelfprofileInfo(conn, _params)do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    if  type == "A"  do
      data = Admin.self_Profile(admin_id)
      case data do
        nil ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "User not found!"
                 }
               }
        data ->
          json conn, %{status_code: "200", data: data}
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end

  def changePasswordAdminSelf(conn, params) do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    if  type == "A"  do
      case Admin.adminChangePassword(params, admin_id)do
        {:ok, message} ->
          conn
          |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:error_message, error_message} ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: error_message
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end

  def changePassword(conn, params) do
    %{"id" => _admin_id, "type" => type} = conn.assigns[:current_user]
    if  type == "A"  do
      case Admin.changePassword(params)do
        {:ok, message} ->
          conn
          |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:error_message, error_message} ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: error_message
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end
  @doc "creates admin function"
  def createAdmin(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]

      chk_admin = Repo.one(
        from cd in Administratorusers, where: cd.email_id == ^params["email_id"], limit: 1, select: cd.id
      )
      if is_nil(chk_admin) do
        chk_admin_cont = Repo.one(
          from cont in Administratorusers, where: cont.contact_number == ^params["contact_number"],
                                           limit: 1,
                                           select: cont.id
        )
        if is_nil(chk_admin_cont) do
          admin_data = Repo.one from a in Administratorusers, where: not is_nil(a.unique_id),
                                                              limit: 1,
                                                              order_by: [
                                                                desc: a.id
                                                              ],
                                                              select: %{
                                                                id: a.id,
                                                                unique_id: a.unique_id
                                                              }
          new_unique_id = if !is_nil(admin_data) do
            unique_id = admin_data.unique_id
            last_unique_id = unique_id
                             |> String.split("VIOLA00", trim: true)
                             |> Enum.take(1)
                             |> Enum.join()
            String.to_integer(last_unique_id) + 1
          else
            1
          end
          viola_unique_id = "VIOLA00#{new_unique_id}"
          admin = %{
            "fullname" => params["fullname"],
            "role" => params["role"],
            "unique_id" => viola_unique_id,
            "contact_number" => params["contact_number"],
            "email_id" => params["email_id"],
            "password" => params["password"],
            "inserted_by" => admin_id
          }
          admin_changeset = Administratorusers.changeset(%Administratorusers{}, admin)

          case Repo.insert(admin_changeset) do
            {:ok, _response} ->
              json conn, %{status_code: "200", message: "Congratulations! Admin Registration is Now Complete."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   contact_number: "already exist."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 email_id: "already exist."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
    this function for update admin information
  """
  def updateAdmin(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id, "is_primary" => is_primary} = conn.assigns[:current_user]

      case is_primary do
        "Y" ->
          check_admin = Repo.one(
            from ad in Administratorusers,
            where: ad.id != ^params["id"] and (
              ad.email_id == ^params["email_id"] or ad.contact_number == ^params["contact_number"]),
            limit: 1,
            select: ad
          )
          if is_nil(check_admin) do
            case Repo.get(Administratorusers, params["id"]) do
              nil ->
                json conn,
                     %{
                       status_code: "4004",
                       errors: %{
                         message: "Record not found."
                       }
                     }

              admin_users ->
                admin = %{
                  "fullname" => params["fullname"],
                  "role" => params["role"],
                  "contact_number" => params["contact_number"],
                  "email_id" => params["email_id"],
                  "status" => params["status"],
                  "is_primary" => params["is_primary"]
                }
                admin_changeset = Administratorusers.changeset_update(admin_users, admin)
                case Repo.update(admin_changeset) do
                  {:ok, _response} ->
                    json conn, %{status_code: "200", message: "Information updated."}
                  {:error, changeset} ->
                    conn
                    |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                end
            end
          else
            message = cond  do
              check_admin.email_id == params["email_id"] -> %{email_id: "already exist."}
              check_admin.contact_number == params["contact_number"] -> %{contact_number: "already exist."}
              true -> %{email_id: "already exist."}
            end
            json conn, %{status_code: "4003", errors: message}
          end
        "N" ->
          conn
          |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :permission_message)
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getAdmin(conn, _params) do
    text  conn, "getAdmin"
  end

  @doc "contact us function"
  def contactUs(conn, params) do
    unless map_size(params) == 0 do
      new_message = %{
        "firstname" => params["firstname"],
        "lastname" => params["lastname"],
        "email" => params["email"],
        "contact_number" => params["contact_number"],
        "message" => params["message"]
      }
      changeset_contact = Contactus.changeset(%Contactus{}, new_message)

      case Repo.insert(changeset_contact) do
        {:ok, _response} ->
          render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Congratulations! Message has been sent.")
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "settlement "
  def settlement(conn, params) do
    username = params["username"]
    password = params["sec_password"]
    request_id = params["request_id"]
    viola_username = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_username and password == viola_password do
      admin_account_id = params["adminAccountId"]
      beneficiary_account_id = params["beneficairyAccountId"]
      enter_amount = params["amount"]

      amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
      currency = "GBP"

      # Admin Sender Details
      sender_details = Repo.get_by(Adminaccounts, id: admin_account_id)

      # Beneficiry Receiver Details
      receiver_details = Repo.get_by(Adminbeneficiaries, id: beneficiary_account_id)


      check_pay_amount = String.to_float("#{amount}")
      check_balance = String.to_float("#{sender_details.balance}")

      if check_balance >= check_pay_amount do

        #      remark = %{"from" => "#{compnay_info.company_name} <br> #{ff_code}-#{ss_code}-#{tt_code} #{sender_details.account_number}", "to" => "#{compnay_info.company_name}"}

        #        from_name = sender_details.account_name
        #        to_name = receiver_details.fullname

        _reference = "#{Commontools.randnumber(8)}"
        #        transaction_id = Integer.to_string(Commontools.randnumber(10))
        transaction_id = Integer.to_string(Commontools.getUniqueNumber(admin_account_id, 10))
        #        paymentInstructionIdentification = "#{Commontools.randnumber(8)}"
        paymentInstructionIdentification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
        #        instructionIdentification = "#{Commontools.randnumber(8)}"
        instructionIdentification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
        #        d_identification = "#{Commontools.randnumber(8)}"
        d_identification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
        #        reference = "#{Commontools.randnumber(8)}"
        #        reference = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
        reference = receiver_details.description
        balance = String.to_float("#{sender_details.balance}") - String.to_float("#{amount}")

        c_iban = "GBR#{receiver_details.sort_code}#{receiver_details.account_number}"
        today = DateTime.utc_now

        inserted_by = if !is_nil(request_id) or request_id != "",
                         do: request_id, else: sender_details.administratorusers_id

        transaction = %{
          "adminaccounts_id" => admin_account_id,
          "amount" => check_pay_amount,
          "currency" => sender_details.currency,
          "from_user" => sender_details.iban_number,
          "to_user" => c_iban,
          "reference_id" => reference,
          "transaction_id" => transaction_id,
          "mode" => "D",
          "identification" => sender_details.iban_number,
          "description" => "Settlement Transaction",
          "transaction_date" => today,
          "status" => "D",
          "inserted_by" => inserted_by
        }

        changeset = Admintransactions.changeset(%Admintransactions{}, transaction)

        case Repo.insert(changeset) do
          {:ok, data} -> ids = data.id
                         trans_status = Repo.get_by(Admintransactions, id: ids)

                         # else external
                         accountDetails = %{
                           amount: amount,
                           currency: currency,
                           paymentInstructionIdentification: paymentInstructionIdentification,
                           d_name: sender_details.account_name,
                           d_iban: sender_details.iban_number,
                           d_code: "BBAN",
                           d_identification: d_identification,
                           d_issuer: "VIOLA",
                           d_proprietary: "Sender",
                           instructionIdentification: instructionIdentification,
                           endToEndIdentification: transaction_id,
                           c_name: receiver_details.fullname,
                           c_iban: c_iban,
                           c_proprietary: "PRTY_COUNTRY_SPECIFIC",
                           reference: reference
                         }
                         #                         Logger.warn "Settlement Transaction Input: #{~s(#{accountDetails})}"

                         output = Clearbank.paymentAToEB(accountDetails)

                         #                         Logger.warn "Settlement Transaction Output: #{~s(#{output})}"

                         if !is_nil(output["transactions"]) do
                           res = get_in(output["transactions"], [Access.at(0)])
                           response = res["response"]
                           reference = res["endToEndIdentification"]

                           if response == "Accepted" do

                             # Update Sender Balance
                             senderbal = %{balance: balance}
                             changesetSender = Adminaccounts.changesetUpdateBalance(sender_details, senderbal)
                             Repo.update(changesetSender)

                             update_status = %{
                               "status" => "S",
                               "end_to_en_identifier" => reference,
                               "response" => response
                             }
                             changeset_transaction = Admintransactions.changesetUpdateStatus(
                               trans_status,
                               update_status
                             )
                             Repo.update(changeset_transaction)
                             if !is_nil(receiver_details) and !is_nil(amount) do
                               SettlementNotification.sender(receiver_details.id, amount)
                             end
                             json conn, %{status_code: "200", message: "Transaction Successfully."}
                           else
                             update_status = %{"response" => response}
                             changeset_transaction = Admintransactions.changesetUpdateStatus(
                               trans_status,
                               update_status
                             )
                             Repo.update(changeset_transaction)
                             json conn,
                                  %{
                                    status_code: "5001",
                                    errors: %{
                                      message: response
                                    }
                                  }
                           end
                         else
                           json conn,
                                %{
                                  status_code: "4004",
                                  errors: %{
                                    message: "Transaction not allowed."
                                  }
                                }
                         end
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Insufficient fund."
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "You do not have permission to any update, Please contact to administrator."
             }
           }
    end
  end

  @doc "admin Account settlement "
  def accountSettlement(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]


    case check_params(params, ["adminAccountId", "beneficairyAccountId", "amount"]) do
      true ->
        case check_value(params) do
          {:ok, "ok"} ->

            admin_account_id = params["adminAccountId"]
            beneficiary_account_id = params["beneficairyAccountId"]
            enter_amount = params["amount"]

            amount = if enter_amount =~ ".", do: enter_amount, else: "#{enter_amount}.00"
            currency = "GBP"

            # Admin Sender Details
            sender_details = Repo.get_by(Adminaccounts, id: admin_account_id)
            if !is_nil(sender_details) do

              # Beneficiry Receiver Details
              receiver_details = Repo.get_by(Adminbeneficiaries, id: beneficiary_account_id)
              if !is_nil(receiver_details) do
                check_pay_amount = String.to_float("#{amount}")
                check_balance = String.to_float("#{sender_details.balance}")

                if check_balance >= check_pay_amount do

                  transaction_id = Integer.to_string(Commontools.getUniqueNumber(admin_account_id, 10))
                  paymentInstructionIdentification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
                  instructionIdentification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
                  d_identification = "#{Commontools.getUniqueNumber(admin_account_id, 8)}"
                  reference = receiver_details.description
                  balance = String.to_float("#{sender_details.balance}") - String.to_float("#{amount}")

                  c_iban = "GBR#{receiver_details.sort_code}#{receiver_details.account_number}"
                  today = DateTime.utc_now

                  transaction = %{
                    "adminaccounts_id" => admin_account_id,
                    "amount" => check_pay_amount,
                    "currency" => sender_details.currency,
                    "from_user" => sender_details.iban_number,
                    "to_user" => c_iban,
                    "reference_id" => reference,
                    "transaction_id" => transaction_id,
                    "mode" => "D",
                    "identification" => sender_details.iban_number,
                    "description" => "Settlement Transaction",
                    "transaction_date" => today,
                    "status" => "D",
                    "inserted_by" => "99999#{admin_id}"
                  }

                  changeset = Admintransactions.changeset(%Admintransactions{}, transaction)

                  case Repo.insert(changeset) do
                    {:ok, data} ->
                      ids = data.id
                      trans_status = Repo.get_by(Admintransactions, id: ids)

                      # else external
                      accountDetails = %{
                        amount: amount,
                        currency: currency,
                        paymentInstructionIdentification: paymentInstructionIdentification,
                        d_name: sender_details.account_name,
                        d_iban: sender_details.iban_number,
                        d_code: "BBAN",
                        d_identification: d_identification,
                        d_issuer: "VIOLA",
                        d_proprietary: "Sender",
                        instructionIdentification: instructionIdentification,
                        endToEndIdentification: transaction_id,
                        c_name: receiver_details.fullname,
                        c_iban: c_iban,
                        c_proprietary: "PRTY_COUNTRY_SPECIFIC",
                        reference: reference
                      }
                      #                         Logger.warn "Settlement Transaction Input: #{~s(#{accountDetails})}"

                      output = Clearbank.paymentAToEB(accountDetails)

                      #                         Logger.warn "Settlement Transaction Output: #{~s(#{output})}"

                      if !is_nil(output["transactions"]) do
                        res = get_in(output["transactions"], [Access.at(0)])
                        response = res["response"]
                        endtoend_id = res["endToEndIdentification"]

                        if response == "Accepted" do

                          # Update Sender Balance
                          senderbal = %{balance: balance}
                          changesetSender = Adminaccounts.changesetUpdateBalance(sender_details, senderbal)
                          Repo.update(changesetSender)

                          update_status = %{
                            "status" => "S",
                            "end_to_en_identifier" => endtoend_id,
                            "response" => response
                          }
                          changeset_transaction = Admintransactions.changesetUpdateStatus(
                            trans_status,
                            update_status
                          )
                          Repo.update(changeset_transaction)
                          if !is_nil(receiver_details) and !is_nil(amount) do
                            SettlementNotification.sender(receiver_details.id, amount)
                          end
                          json conn, %{status_code: "200", message: "Transaction Successfully."}
                        else
                          update_status = %{"response" => response}
                          changeset_transaction = Admintransactions.changesetUpdateStatus(
                            trans_status,
                            update_status
                          )
                          Repo.update(changeset_transaction)
                          json conn,
                               %{
                                 status_code: "5001",
                                 errors: %{
                                   message: response
                                 }
                               }
                        end
                      else
                        json conn,
                             %{
                               status_code: "4004",
                               errors: %{
                                 message: "Transaction not allowed."
                               }
                             }
                      end
                    {:error, changeset} ->
                      conn
                      |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
                else
                  json conn,
                       %{
                         status_code: "4004",
                         errors: %{
                           message: "Insufficient fund."
                         }
                       }
                end
              else
                json conn,
                     %{
                       status_code: "4004",
                       errors: %{
                         message: "Invalid Settlement account"
                       }
                     }
              end
            else
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "Invalid Admin Account"
                     }
                   }
            end
          {:error, message} -> json conn, %{status_code: "4003", errors: message}
        end
      false ->
        json conn,
             %{
               status_code: "4003",
               message: "Please enter required key names: (adminAccountId, beneficiaryAccountId, amount)"
             }
    end
  end

  def all_duefees(conn, _params) do
    duefees = Repo.all(
      from d in Duefees, left_join: cmn in assoc(d, :commanall),
                         left_join: comp in assoc(cmn, :company),
                         on: comp.id == cmn.company_id,
                         select: %{
                           commanall_id: d.commanall_id,
                           transactions_id: d.transactions_id,
                           amount: d.amount,
                           description: d.description,
                           total_cards: d.total_cards,
                           remark: d.remark,
                           type: d.type,
                           status: d.status,
                           reason: d.reason,
                           pay_date: d.pay_date,
                           next_date: d.next_date,
                           inserted_at: d.inserted_at,
                           inserted_by: d.inserted_by,
                           updated_at: d.updated_at,
                           email_id: cmn.email_id,
                           company_id: comp.id,
                           company_name: comp.company_name
                         }
    )

    json conn, %{status_code: "200", data: duefees}
  end

  def single_duefees(conn, params) do
    if is_nil(params["email_id"]) or params["email_id"] == "" do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Please send email_id"
             }
           }
    else
      duefees = Repo.all(
        from d in Duefees, left_join: cmn in assoc(d, :commanall),
                           where: cmn.email_id == ^params["email_id"],
                           left_join: comp in assoc(cmn, :company),
                           on: comp.id == cmn.company_id,
                           select: %{
                             commanall_id: d.commanall_id,
                             transactions_id: d.transactions_id,
                             amount: d.amount,
                             description: d.description,
                             total_cards: d.total_cards,
                             remark: d.remark,
                             type: d.type,
                             status: d.status,
                             reason: d.reason,
                             pay_date: d.pay_date,
                             next_date: d.next_date,
                             inserted_at: d.inserted_at,
                             inserted_by: d.inserted_by,
                             updated_at: d.updated_at,
                             email_id: cmn.email_id,
                             company_id: comp.id,
                             company_name: comp.company_name
                           }
      )

      json conn, %{status_code: "200", data: duefees}
    end
  end




  #  def fee_transactions(conn, params) do
  #
  #    type_credit = Application.get_env(:violacorp, :internal_fee)
  #    if is_nil(params["email_id"]) or params["email_id"] == "" do
  #      json conn, %{status_code: "4004",errors: %{message: "Please send email_id"}}
  #    else
  #      duefees = Repo.all(from d in Transactions, where: d in j, left_join: cmn in assoc(d, :commanall), where: cmn.email_id == ^params["email_id"], left_join: comp in assoc(cmn, :company), on: comp.id == cmn.company_id,
  #                                            select: %{commanall_id: d.commanall_id,
  #                                              transactions_id: d.transactions_id,
  #                                              amount: d.amount,
  #                                              description: d.description,
  #                                              total_cards: d.total_cards,
  #                                              remark: d.remark,
  #                                              type: d.type,
  #                                              status: d.status,
  #                                              reason: d.reason,
  #                                              pay_date: d.pay_date,
  #                                              next_date: d.next_date,
  #                                              inserted_at: d.inserted_at,
  #                                              inserted_by: d.inserted_by,
  #                                              updated_at: d.updated_at,
  #                                              email_id: cmn.email_id,
  #                                              company_id: comp.id,
  #                                              company_name: comp.company_name
  #                                            })
  #
  #      json conn, %{status_code: "200", data: duefees}
  #    end
  #  end



  def update_existing_trans_remark(conn, params) do

    all_company = case params["commanall_id"] do
      nil -> Repo.all(
               from c in Commanall,
               where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
               left_join: comp in assoc(c, :company),
               left_join: com_ac in assoc(comp, :companyaccounts),
               where: not is_nil(com_ac.inserted_at),
               order_by: [
                 asc: c.id
               ],
               select: %{
                 commanid: c.id,
                 compid: c.company_id
               }
             )
      "" -> Repo.all(
              from c in Commanall,
              where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
              left_join: comp in assoc(c, :company),
              left_join: com_ac in assoc(comp, :companyaccounts),
              where: not is_nil(com_ac.inserted_at),
              order_by: [
                asc: c.id
              ],
              select: %{
                commanid: c.id,
                compid: c.company_id
              }
            )
      _ -> Repo.all(
             from c in Commanall,
             where: c.id == ^params["commanall_id"] and c.status == ^"A" and not is_nil(c.company_id) and not is_nil(
               c.accomplish_userid
             ),
             left_join: comp in assoc(c, :company),
             left_join: com_ac in assoc(comp, :companyaccounts),
             where: not is_nil(com_ac.inserted_at),
             order_by: [
               asc: c.id
             ],
             select: %{
               commanid: c.id,
               compid: c.company_id
             }
           )


    end


    Repo.all(
      from c in Commanall, where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
                           left_join: comp in assoc(c, :company),
                           left_join: com_ac in assoc(comp, :companyaccounts),
                           where: not is_nil(com_ac.inserted_at),
                           order_by: [
                             asc: c.id
                           ],
                           select: %{
                             commanid: c.id,
                             compid: c.company_id
                           }
    )


    Enum.each all_company, fn v ->
      commanid = v.commanid
      compid = v.compid

      transactions = Repo.all(from t in Transactions, where: t.commanall_id == ^commanid and t.company_id == ^compid)

      #IO.inspect(transactions)
      Enum.each transactions, fn t ->
        remark = if is_nil(t.remark) do
          %{}
        else
          Poison.decode!(t.remark)
        end
        new_remark =
          if !Map.has_key?(remark, "from_info") && !Map.has_key?(remark, "to_info") do
            case t.transaction_type do

              "A2A" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} A2A  MISSING from_info/to_info")

                from_company = Repo.get(Company, t.company_id)
                case t.category do
                  "AA" ->
                    from = Repo.get(Companybankaccount, t.bank_id)
                    if is_nil(t.beneficiaries_id) do
                      %{
                        "from_info" => %{
                          "owner_name" => "#{from_company.company_name}",
                          "card_number" => "",
                          "sort_code" => update_sort_code(from.sort_code),
                          "account_number" => "#{from.account_number}"
                        },
                        "to_info" => %{
                          "owner_name" => "",
                          "card_number" => "",
                          "sort_code" => "",
                          "account_number" => ""
                        }
                      }
                    else
                      beneficiary = Repo.get(Beneficiaries, t.beneficiaries_id)
                      %{
                        "from_info" => %{
                          "owner_name" => "#{from_company.company_name}",
                          "card_number" => "",
                          "sort_code" => update_sort_code(from.sort_code),
                          "account_number" => "#{from.account_number}"
                        },
                        "to_info" => %{
                          "owner_name" => "#{beneficiary.first_name} #{beneficiary.last_name}",
                          "card_number" => "",
                          "sort_code" => update_sort_code(beneficiary.sort_code),
                          "account_number" => "#{beneficiary.account_number}"
                        }
                      }
                    end

                  "MV" ->
                    from = Repo.get(Companybankaccount, t.bank_id)
                    from_company = Repo.get(Company, t.company_id)
                    to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                    %{
                      "from_info" => %{
                        "owner_name" => "#{from_company.company_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code(from.sort_code),
                        "account_number" => "#{from.account_number}"
                      },
                      "to_info" => %{
                        "owner_name" => "#{from_company.company_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code("#{to.accomplish_account_id}"), #  "#{to.accomplish_account_id}"
                        "account_number" => "#{to.accomplish_account_number}"
                      }
                    }
                end

              "A2C" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} A2C MISSING from_info/to_info")
                to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                %{
                  "from_info" => %{
                    "owner_name" => "#{remark["from_name"]}",
                    "card_number" => "",
                    "sort_code" => update_sort_code("#{to.accomplish_account_id}"), # "#{to.accomplish_account_id}"
                    "account_number" => "#{to.accomplish_account_number}"
                  },
                  "to_info" => %{
                    "owner_name" => "#{remark["to_name"]}",
                    "card_number" => "#{remark["to"]}",
                    "sort_code" => "",
                    "account_number" => ""
                  }
                }

              "C2A" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} C2A MISSING from_info/to_info")
                to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                %{
                  "to_info" => %{
                    "owner_name" => "#{remark["from_name"]}",
                    "card_number" => "",
                    "sort_code" => update_sort_code("#{to.accomplish_account_id}"), # "#{to.accomplish_account_id}"
                    "account_number" => "#{to.accomplish_account_number}"
                  },
                  "from_info" => %{
                    "owner_name" => "#{remark["to_name"]}",
                    "card_number" => "#{remark["to"]}",
                    "sort_code" => "",
                    "account_number" => ""
                  }
                }


              "A2O" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} A2O MISSING from_info/to_info")
                from = Repo.get_by(Companyaccounts, company_id: t.company_id)
                from_company = Repo.get(Company, t.company_id)
                %{
                  "from_info" => %{
                    "owner_name" => "#{from_company.company_name}",
                    "card_number" => "",
                    "sort_code" => update_sort_code("#{from.accomplish_account_id}"), # "#{from.accomplish_account_id}"
                    "account_number" => "#{from.accomplish_account_number}"
                  },
                  "to_info" => %{
                    "owner_name" => "Viola Corporate",
                    "card_number" => "",
                    "sort_code" => "",
                    "account_number" => ""
                  }
                }


              "C2O" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} C2O MISSING from_info/to_info")
                employee = Repo.get(Employee, t.employee_id)
                %{
                  "to_info" => %{
                    "owner_name" => "#{remark["to"]}",
                    "card_number" => "",
                    "sort_code" => "",
                    "account_number" => ""
                  },
                  "from_info" => %{
                    "owner_name" => "#{employee.first_name} #{employee.last_name}",
                    "card_number" => "#{remark["from"]}",
                    "sort_code" => "",
                    "account_number" => ""
                  }
                }

              "B2A" ->
                #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} B2A  MISSING from_info/to_info")
                from_company = Repo.get(Company, t.company_id)
                to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                case t.category do
                  "TU" -> # topup OLD
                    %{
                      "from_info" => %{
                        "owner_name" => "#{remark["from"]}",
                        "card_number" => "",
                        "sort_code" => "",
                        "account_number" => ""
                      },
                      "to_info" => %{
                        "owner_name" => "#{from_company.company_type}",
                        "card_number" => "",
                        "sort_code" => update_sort_code("#{to.accomplish_account_id}"),
                        "account_number" => "#{to.accomplish_account_number}"
                      }
                    }

                  "MV" ->
                    from = Repo.get_by(Companybankaccount, company_id: t.company_id)
                    %{
                      "from_info" => %{
                        "owner_name" => "#{from_company.company_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code(from.sort_code),
                        "account_number" => "#{from.account_number}"
                      },
                      "to_info" => %{
                        "owner_name" => "#{from_company.company_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code("#{to.accomplish_account_id}"), # "#{to.accomplish_account_id}"
                        "account_number" => "#{to.accomplish_account_number}"
                      }
                    }
                end

              "C2I" -> #IO.inspect("company_id:#{t.company_id}, transactions_id:#{t.id} C2I MISSING from_info/to_info")
                case t.category do
                  "POS" ->
                    employee = Repo.get(Employee, t.employee_id)
                    %{
                      "from_info" => %{
                        "owner_name" => "#{employee.first_name} #{employee.last_name}",
                        "card_number" => "#{remark["from"]}",
                        "sort_code" => "",
                        "account_number" => ""
                      },
                      "to_info" => %{
                        "owner_name" => "#{remark["to"]}",
                        "card_number" => "",
                        "sort_code" => "",
                        "account_number" => ""
                      }
                    }

                  "CT" ->
                    from = Repo.get_by(Companyaccounts, company_id: t.company_id)
                    %{
                      "from_info" => %{
                        "owner_name" => "#{remark["from_name"]}",
                        "card_number" => "",
                        "sort_code" => update_sort_code(from.sort_code),
                        "account_number" => "#{from.account_number}"
                      },
                      "to_info" => %{
                        "owner_name" => "#{remark["to_name"]}",
                        "card_number" => "#{remark["to"]}",
                        "sort_code" => "",
                        "account_number" => ""
                      }
                    }
                end
            end
          else
            %{}

          end
        merged = Map.merge(remark, new_remark)
        changeset = Transactions.changesetDescriptionRemark(t, %{"remark" => Poison.encode!(merged)})
        Repo.update(changeset)
      end
    end

    json conn, "ok"
  end

  def remove_info(conn, params) do

    all_company = case params["commanall_id"] do
      nil -> Repo.all(
               from c in Commanall,
               where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
               left_join: comp in assoc(c, :company),
               left_join: com_ac in assoc(comp, :companyaccounts),
               where: not is_nil(com_ac.inserted_at),
               order_by: [
                 asc: c.id
               ],
               select: %{
                 commanid: c.id,
                 compid: c.company_id
               }
             )
      "" -> Repo.all(
              from c in Commanall,
              where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
              left_join: comp in assoc(c, :company),
              left_join: com_ac in assoc(comp, :companyaccounts),
              where: not is_nil(com_ac.inserted_at),
              order_by: [
                asc: c.id
              ],
              select: %{
                commanid: c.id,
                compid: c.company_id
              }
            )
      _ -> Repo.all(
             from c in Commanall,
             where: c.id == ^params["commanall_id"] and c.status == ^"A" and not is_nil(c.company_id) and not is_nil(
               c.accomplish_userid
             ),
             left_join: comp in assoc(c, :company),
             left_join: com_ac in assoc(comp, :companyaccounts),
             where: not is_nil(com_ac.inserted_at),
             order_by: [
               asc: c.id
             ],
             select: %{
               commanid: c.id,
               compid: c.company_id
             }
           )


    end

    #    all_company = Repo.all(
    #      from c in Commanall, where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
    #                           left_join: comp in assoc(c, :company),
    #                           left_join: com_ac in assoc(comp, :companyaccounts),
    #                           where: not is_nil(com_ac.inserted_at),
    #                           order_by: [asc: c.id],
    #                           select: %{
    #                             commanid: c.id,
    #                             compid: c.company_id
    #                           }
    #    )
    Enum.each all_company, fn v ->
      commanid = v.commanid
      compid = v.compid
      transactions = Repo.all(from t in Transactions, where: t.commanall_id == ^commanid and t.company_id == ^compid)
      Enum.each transactions, fn t ->
        if !is_nil(t.remark) do
          original = Poison.decode!(t.remark)
          if Map.has_key?(original, "from_info") && Map.has_key?(original, "to_info") do
            new_remark = Map.drop(original, ["from_info", "to_info"])
            changeset = Transactions.changesetDescriptionRemark(t, %{"remark" => Poison.encode!(new_remark)})
            Repo.update(changeset)
          end
        end
      end
      text conn, "ok done"
    end
  end

  def update_remark(conn, params) do

    all_company = case params["commanall_id"] do
      nil -> Repo.all(
               from c in Commanall,
               where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
               left_join: comp in assoc(c, :company),
               left_join: com_ac in assoc(comp, :companyaccounts),
               where: not is_nil(com_ac.inserted_at),
               order_by: [
                 asc: c.id
               ],
               select: %{
                 commanid: c.id,
                 compid: c.company_id
               }
             )
      "" -> Repo.all(
              from c in Commanall,
              where: c.status == ^"A" and not is_nil(c.company_id) and not is_nil(c.accomplish_userid),
              left_join: comp in assoc(c, :company),
              left_join: com_ac in assoc(comp, :companyaccounts),
              where: not is_nil(com_ac.inserted_at),
              order_by: [
                asc: c.id
              ],
              select: %{
                commanid: c.id,
                compid: c.company_id
              }
            )
      _ -> Repo.all(
             from c in Commanall,
             where: c.id == ^params["commanall_id"] and c.status == ^"A" and not is_nil(c.company_id) and not is_nil(
               c.accomplish_userid
             ),
             left_join: comp in assoc(c, :company),
             left_join: com_ac in assoc(comp, :companyaccounts),
             where: not is_nil(com_ac.inserted_at),
             order_by: [
               asc: c.id
             ],
             select: %{
               commanid: c.id,
               compid: c.company_id
             }
           )


    end

    Enum.each all_company, fn v ->
      commanid = v.commanid
      compid = v.compid

      transactions = Repo.all(from t in Transactions, where: t.commanall_id == ^commanid and t.company_id == ^compid)

      #IO.inspect(transactions)
      Enum.each transactions, fn t ->
        remark = if is_nil(t.remark) do
          %{}
        else
          Poison.decode!(t.remark)
        end
        new_remark =
          if !Map.has_key?(remark, "from_info") && !Map.has_key?(remark, "to_info") do
            case t.transaction_type do
              "A2A" ->
                from_company = Repo.get(Company, t.company_id)
                case t.category do
                  "AA" ->
                    from = Repo.get(Companybankaccount, t.bank_id)
                    if !is_nil(t.beneficiaries_id) do
                      beneficiary = Repo.get(Beneficiaries, t.beneficiaries_id)
                      if t.transaction_mode == "D" do
                        %{
                          "from_info" => %{
                            "owner_name" => "#{from_company.company_name}",
                            "card_number" => "",
                            "sort_code" => update_sort_code(from.sort_code),
                            "account_number" => "#{from.account_number}"
                          },
                          "to_info" => %{
                            "owner_name" => "#{beneficiary.first_name} #{beneficiary.last_name}",
                            "card_number" => "",
                            "sort_code" => update_sort_code(beneficiary.sort_code),
                            "account_number" => "#{beneficiary.account_number}"
                          }
                        }
                      else
                        %{
                          "to_info" => %{
                            "owner_name" => "#{from_company.company_name}",
                            "card_number" => "",
                            "sort_code" => update_sort_code(from.sort_code),
                            "account_number" => "#{from.account_number}"
                          },
                          "from_info" => %{
                            "owner_name" => "#{beneficiary.first_name} #{beneficiary.last_name}",
                            "card_number" => "",
                            "sort_code" => update_sort_code(beneficiary.sort_code),
                            "account_number" => "#{beneficiary.account_number}"
                          }
                        }
                      end
                    end
                  "MV" ->
                    from = Repo.get(Companybankaccount, t.bank_id)
                    to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                    %{
                      "from_info" => %{
                        "owner_name" => "#{from.account_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code(from.sort_code),
                        "account_number" => "#{from.account_number}"
                      },
                      "to_info" => %{
                        "owner_name" => "Card Management Account",
                        "card_number" => "",
                        "sort_code" => "#{to.accomplish_account_id}", #  "#{to.accomplish_account_id}"
                        "account_number" => "#{to.accomplish_account_number}"
                      }
                    }
                  _ -> %{}
                end
              "B2A" ->
                to = Repo.get_by(Companyaccounts, company_id: t.company_id)
                case t.category do
                  "MV" ->
                    from = Repo.get_by(Companybankaccount, company_id: t.company_id)
                    %{
                      "to_info" => %{
                        "owner_name" => "#{from.account_name}",
                        "card_number" => "",
                        "sort_code" => update_sort_code(from.sort_code),
                        "account_number" => "#{from.account_number}"
                      },
                      "from_info" => %{
                        "owner_name" => "Card Management Account",
                        "card_number" => "",
                        "sort_code" => "#{to.accomplish_account_id}",
                        "account_number" => "#{to.accomplish_account_number}"
                      }
                    }
                  _ -> %{}
                end
              _ -> %{}
            end
          else
            %{}
          end
        merged = if !is_nil(new_remark), do: Map.merge(remark, new_remark), else: remark
        changeset = Transactions.changesetDescriptionRemark(t, %{"remark" => Poison.encode!(merged)})
        Repo.update(changeset)
      end
    end

    json conn, "ok"
  end



  # update sort code
  def update_sort_code(sort_code) do

    ff_code = String.slice(sort_code, 0..1)
    ss_code = String.slice(sort_code, 2..3)
    tt_code = String.slice(sort_code, 4..5)

    _output = "#{ff_code}-#{ss_code}-#{tt_code}"

  end

  def remove_cache(conn, params) do
    username = params["username"]
    sec_password = params["sec_password"]
    key = params["key"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      Cachex.del(:vcorp, key)
    else
      json conn,
           %{
             status_code: "402",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end
    json conn, %{status_code: "200", message: "Reset completed"}
  end

  @doc "Update History"

  def getUpdatedHistory(conn, params) do
    type = params["type"]
    data = cond do

      type == "D" ->
        (
          from b in UpdateHistory,
               where: b.directors_id == ^params["id"],
               left_join: a in assoc(b, :directors),
               on: a.id == b.directors_id,
               select: %{
                 id: b.id,
                 first_name: a.first_name,
                 middle_name: a.middle_name,
                 last_name: a.last_name,
                 field_name: b.field_name,
                 old_value: b.old_value,
                 new_value: b.new_value,
               }
          )
        |> order_by(desc: :id)
        |> Repo.paginate(params)

      type == "C" ->
        (
          from b in UpdateHistory,
               where: b.company_id == ^params["id"],
               left_join: a in assoc(b, :company),
               on: b.company_id == a.id,
               select: %{
                 id: b.id,
                 company_name: a.company_name,
                 field_name: b.field_name,
                 old_value: b.old_value,
                 new_value: b.new_value,
               }
          )
        |> order_by(desc: :id)
        |> Repo.paginate(params)

      type == "E" ->
        (
          from b in UpdateHistory,
               where: b.employee_id == ^params["id"],
               left_join: a in assoc(b, :employee),
               on: b.employee_id == a.id,
               select: %{
                 id: b.id,
                 first_name: a.first_name,
                 middle_name: a.middle_name,
                 last_name: a.last_name,
                 field_name: b.field_name,
                 old_value: b.old_value,
                 new_value: b.new_value,
               }
          )
        |> order_by(desc: :id)
        |> Repo.paginate(params)
    end
    json conn,
         %{
           status_code: "200",
           total_pages: data.total_pages,
           total_entries: data.total_entries,
           page_size: data.page_size,
           page_number: data.page_number,
           data: data.entries
         }
  end

  def sort_gender(conn, params) do
    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      case params["type"] do
        "E" ->
          employees = Repo.all(from e in Employee)
          Enum.each(
            employees,
            fn (employee) ->
              gender = case employee.title do
                "Mr" -> "M"
                "Mrs" -> "F"
                "Miss" -> "F"
                "Ms" -> "F"
                nil -> nil
                _ -> nil
              end
              if !is_nil(gender) and employee.gender != gender do
                changeset = Employee.update_gender(employee, %{"gender" => gender})
                Repo.update(changeset)
              end
            end
          )
          json conn, %{status_code: "200", message: "Employees gender sorted"}
        "D" ->
          directors = Repo.all(from d in Directors)
          Enum.each(
            directors,
            fn (director) ->
              gender = case director.title do
                "Mr" -> "M"
                "Mrs" -> "F"
                "Miss" -> "F"
                "Ms" -> "F"
                nil -> nil
                _ -> nil
              end
              if !is_nil(gender) and director.gender != gender do
                changeset = Directors.update_gender(director, %{"gender" => gender})
                Repo.update(changeset)
              end
            end
          )
          json conn, %{status_code: "200", message: "Directors gender sorted"}
        nil ->
          json conn,
               %{
                 status_code: "4002",
                 errors: %{
                   message: "Please send type param"
                 }
               }
        _ ->
          json conn,
               %{
                 status_code: "4002",
                 errors: %{
                   message: "Invalid type param"
                 }
               }
      end
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

  def updateConutryAddress(conn, params) do
    sec_password = params["sec_password"]
    username = params["username"]
    _type = params["type"]
    id = params["id"]
    country = params["country"]
    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)
    if username == viola_user and sec_password == viola_password do
      case params["type"] do
        "D" ->
          getaddress = Repo.get_by(Addressdirectors, id: id)
          if !is_nil(getaddress) do
            change_map = %{country: country}
            update_changeset = Addressdirectors.changesetUpdateCountry(getaddress, change_map)
            case Repo.update(update_changeset) do
              {:ok, _data} -> json conn, %{status_code: "200", message: "Success! Address Updated"}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Record Not Found"
                   }
                 }
          end
        _ ->
          getaddress = Repo.get_by(Address, id: id)
          if !is_nil(getaddress) do
            change_map = %{country: country}
            update_changeset = Address.changesetUpdateCountry(getaddress, change_map)
            case Repo.update(update_changeset) do
              {:ok, _data} -> json conn, %{status_code: "200", message: "Success! Address Updated"}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Record Not Found"
                   }
                 }
          end
      end
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


  def cb_update_tp_status(conn, params) do
    %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
    if  type == "A"  do
      admin = Repo.get_by(Administratorusers, id: admin_id, secret_password: params["secret_password"])
      if !is_nil(admin) do
        case Repo.one(from c in Commanall, where: c.id == ^params["commanall_id"] and not is_nil(c.company_id)) do
          nil -> ""
          commanall_struc ->

            comp_bank = Repo.get_by(Companybankaccount, company_id: commanall_struc.company_id, currency: "GBP")

            new_status = case params["status"] do
              "Active" -> "A"
              "Closed" -> "B"
              "Suspend" -> "D"
            end
            with {:ok, _message} <- (
              if new_status == "B" do
                ViolacorpWeb.Comman.ManualServiceController.mv_money_cb(commanall_struc, comp_bank)
              else
                {:ok, "carry on"}
              end) do
              # Call Clear Bank
              cb_status = case new_status do
                "A" -> "Enabled"
                "B" -> "Closed"
                _ -> "Suspended"
              end
              body_string = %{
                              "status" => cb_status,
                              "statusReason" => "Other"
                            }
                            |> Poison.encode!
              string = ~s(#{body_string})
              request = %{
                commanall_id: commanall_struc.id,
                requested_by: "99999",
                account_id: comp_bank.account_id,
                body: string
              }
              res = Clearbank.account_status(request)
              if res["status_code"] == "204" or res["status_code"] == "409" do
                # Update acc status
                comp_bank
                |> Companybankaccount.changesetStatus(%{"status" => new_status})
                |> Repo.update()

                cmn_status = case new_status do
                  "A" -> "Company Active"
                  "B" -> "Company Block"
                  _ -> "Company De-Active"
                end
                add_comments = %{
                  administratorusers_id: admin_id,
                  commanall_id: commanall_struc.id,
                  description: params["reason"],
                  status: cmn_status
                }
                %Tags{}
                |> Tags.changeset(add_comments)
                |> Repo.insert()
              end
              json conn, %{status_code: "200", message: "Company bank account status updated"}
            end
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 message: "Incorrect Password"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end

  end

  def cache_reset(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      servers_list = Application.get_env(:violacorp, :server_list)
      cache_key = params["cache_key"]
      if !is_nil(servers_list) and is_list(servers_list) do
        Enum.each servers_list, fn server ->
          url = "#{server}/api/cache_remover"
          header = %{
            "cache-control" => "no-cache",
            "content-type" => "application/json",
          }
          body = %{"cache_key" => cache_key}
          with {:ok, _message} <- post_http(url, header, Poison.encode!(body)) do
            :ok
          else
            {:error, _message} ->
              Logger.warn("Failed to delete cache key #{cache_key} on #{server}")
              :ok
          end
        end
        Cachex.del(:vcorp, cache_key)
        json conn, %{status_code: "200", message: "Cache key removed"}
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Unable to delete cache: server list empty (:server_list)"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "Update Permission Required, Please Contact Administrator."
             }
           }
    end
  end

  defp post_http(url, header, body) do
    case HTTPoison.post(url, body, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: 404}} -> {:error, "404 not found!"}
      {:ok, %{status_code: 401, body: _body}} -> {:error, "401"}
      {:ok, %{status_code: 400}} -> {:error, "Bad request!"}
      {:ok, %{status_code: 500}} -> {:error, "Internal server error"}
      {:error, %{reason: reason}} -> {:error, "#{reason}"}
    end
  end

  def cache_remover(conn, params) do
    cache_key = params["cache_key"]
    with {:ok, true} <- Cachex.del(:vcorp, cache_key) do
      conn
      |> put_status(200)
      |> json(%{status_code: "200", message: "Cache deleted succesfully"})
    else
      _ ->
        conn
        |> put_status(404)
        |> json(%{status_code: "4004", message: "Failed to Delete Cache"})
    end
  end

  def get_system_vetting(conn, _params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A" do
      env_vetting = Application.get_env(:violacorp, :vetting_method)
      vetting = case env_vetting do
        "fourstop" -> "4S"
        "gbg" -> "GBG"
        _ -> "GBG"
      end
      json conn, %{status_code: "200", data: vetting}
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end
  end

end
