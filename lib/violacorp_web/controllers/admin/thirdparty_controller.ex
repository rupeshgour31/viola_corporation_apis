defmodule ViolacorpWeb.Admin.ThirdpartyController do
  use Phoenix.Controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Address

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Gbg
  alias ViolacorpWeb.Main.V2AlertsController
  alias ViolacorpWeb.Main.DashboardController
  alias Violacorp.Models.FourstopModel
  alias Violacorp.Workers.SendEmail
  alias Violacorp.Mailer

  #  alias Violacorp.Workers.PhysicalCard
  #  alias Violacorp.Workers.CompanyIdentification
  #  alias Violacorp.Workers.CreateIdentification

  @doc "Create Account on clear bank by admin"
  def createBankAccount(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]

      # create array data for send to accomplish
      userdata = Repo.one from commanall in Commanall, where: commanall.id == ^params["commanall_id"],
                                                       left_join: company in assoc(commanall, :company),
                                                       select: %{
                                                         company_id: company.id,
                                                         company_name: company.company_name,
                                                         email_id: commanall.email_id
                                                       }

      company_id = userdata.company_id
      #      get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")
      #      if is_nil(get_card) do

      owner_name = userdata.company_name
      send_account_name = String.replace(owner_name, ~r/[-$*?@().'\/#,]/, "");
      send_owner_name = String.replace(owner_name, ~r/[-$*?@().'\/#,]/, "");
      sortcode = Application.get_env(:violacorp, :sortcode)

      body_string = %{
                      "accountName" => send_account_name,
                      "owner" => %{
                        "name" => send_owner_name
                      },
                      "sortCode" => sortcode
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})

      account_info = Repo.get_by(Companybankaccount, account_name: send_account_name, status: "F")
      if !is_nil(account_info) do
        bankAccount = %{"status" => "D"}
        changeset = Companybankaccount.changesetStatus(account_info, bankAccount)
        Repo.update(changeset)
      end

      # Add Data Before Call
      bankAccountFirst = %{
        "company_id" => company_id,
        "account_name" => send_account_name,
        "status" => "F",
        "inserted_by" => "99999#{admin_id}"
      }
      changesetFirstCall = Companybankaccount.changesetFirstCall(%Companybankaccount{}, bankAccountFirst)
      Repo.insert(changesetFirstCall)

      # Call Clear Bank
      response = Clearbank.create_account(string)

      if !is_nil(response["account"]) do

        iban = response["account"]["iban"]
        account_id = response["account"]["id"]
        account_name = response["account"]["name"]
        bban = response["account"]["bban"]
        type = response["account"]["type"]

        res = get_in(response["account"]["balances"], [Access.at(0)])
        status = res["status"]
        currency = res["currency"]
        balance = res["amount"]

        lan = String.length(iban)
        #    iso = String.slice(string, 0..1)
        #    iban = String.slice(string, 2..3)
        bank_code = String.slice(iban, 4..7)
        sort_code = String.slice(iban, 8..13)
        account_number = String.slice(iban, 14..lan)

        bankAccount = %{
          "company_id" => company_id,
          "account_id" => account_id,
          "account_number" => account_number,
          "account_name" => account_name,
          "iban_number" => iban,
          "bban_number" => bban,
          "currency" => currency,
          "balance" => balance,
          "sort_code" => sort_code,
          "bank_code" => bank_code,
          "bank_type" => type,
          "request" => body_string,
          "status" => "A",
          "response" => Poison.encode!(response),
          "bank_status" => status,
          "inserted_by" => "99999#{admin_id}"
        }

        get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
        if is_nil(get_card) do
          changeset = Companybankaccount.changeset(%Companybankaccount{}, bankAccount)
          case Repo.insert(changeset) do
            {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Account created successfully"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          changeset = Companybankaccount.changeset(get_card, bankAccount)
          case Repo.update(changeset) do
            {:ok, _bankAccount} -> json conn, %{status_code: "200", message: "Account created successfully"}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      else
        bankAccount = %{
          "company_id" => company_id,
          "request" => body_string,
          "response" => Poison.encode!(response),
          "status" => "F",
          "inserted_by" => "99999#{admin_id}"
        }
        get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
        if is_nil(get_card) do
          changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, bankAccount)
          case Repo.insert(changeset) do
            {:ok, _bankAccount} ->
              json conn,
                   %{
                     status_code: "5001",
                     errors: %{
                       message: Poison.encode!(response)
                     }
                   }
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          changeset = Companybankaccount.changesetFailed(get_card, bankAccount)
          case Repo.update(changeset) do
            {:ok, _bankAccount} ->
              json conn,
                   %{
                     status_code: "5001",
                     errors: %{
                       message: Poison.encode!(response)
                     }
                   }
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      end
      #    else
      #      json conn,
      #           %{
      #             status_code: "4004",
      #             errors: %{
      #               message: "Company already, have account"
      #             }
      #           }
      #    end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
    create company card management account
  """
  def createAccomplishAccount(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      currency = params["currency"]

      type = Application.get_env(:violacorp, :ewallet_type)
      accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
      accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)

      bin_id = if currency == "USD" do
        Application.get_env(:violacorp, :usd_acc_bin_id)
      else
        if currency == "EUR" do
          Application.get_env(:violacorp, :eur_acc_bin_id)
        else
          Application.get_env(:violacorp, :gbp_acc_bin_id)
        end
      end

      number = if currency == "USD" do
        Application.get_env(:violacorp, :usd_acc_number)
      else
        if currency == "EUR" do
          Application.get_env(:violacorp, :eur_acc_number)
        else
          Application.get_env(:violacorp, :gbp_acc_number)
        end
      end

      # Get User Id
      commanall = Repo.one(
        from cm in Commanall, where: cm.id == ^params["id"] and not is_nil(cm.accomplish_userid), select: cm
      )

      if !is_nil(commanall) do
        user_id = commanall.accomplish_userid
        company_id = commanall.company_id
        commanall_id = params["id"]

        chk_account = Repo.one(
          from ca in Companyaccounts, where: ca.company_id == ^company_id and ca.currency_code == ^currency, select: ca
        )
        if !is_nil(chk_account) do
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Company already, have account"
                 }
               }
        else
          # Add Currency
          request_currency = %{
            currency: currency,
            user_id: user_id
          }
          _respnse_currency = Accomplish.create_currency(request_currency)

          request = %{
            type: type,
            bin_id: bin_id,
            number: number,
            currency: currency,
            user_id: user_id,
            commanall_id: commanall_id,
            latitude: accomplish_latitude,
            longitude: accomplish_longitude,
            request_id: "99999#{admin_id}"
          }
          response = Accomplish.create_account(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            last_account_number = Repo.one(
              from x in Companyaccounts, order_by: [
                desc: x.account_number
              ],
                                         limit: 1,
                                         select: x.account_number
            )
            last_account = if is_nil(last_account_number), do: 1, else: last_account_number + 1
            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                           select: c.id
            # Insert company account details
            companyaccount = %{
              "company_id" => company_id,
              "currencies_id" => currencies_id,
              "currency_code" => response["info"]["currency"],
              "available_balance" => response["info"]["available_balance"],
              "current_balance" => response["info"]["balance"],
              "account_number" => last_account,
              "accomplish_account_id" => response["info"]["id"],
              "bin_id" => response["info"]["bin_id"],
              "accomplish_account_number" => response["info"]["number"],
              "expiry_date" => response["info"]["security"]["expiry_date"],
              "source_id" => response["info"]["original_source_id"],
              "status" => response["info"]["status"],
              "inserted_by" => "99999#{admin_id}"
            }

            changeset_comacc = Companyaccounts.changeset(%Companyaccounts{}, companyaccount)

            case Repo.insert(changeset_comacc) do
              {:ok, _response} -> json conn, %{status_code: "200", message: "Company account created."}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "5003",
                   errors: %{
                     message: response_message
                   }
                 }
          end
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Company not valid"
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
    Employee Card Enable or Disable by admin
  """
  def cardEnableDisable(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    if params["new_status"] == "4" or params["new_status"] == "1" do
      get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])

      # Call to accomplish
      request = %{urlid: get_card.accomplish_card_id, status: params["new_status"]}
      response = Accomplish.activate_deactive_card(request)

      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]

      if response_code == "0000" do
        changeset = %{status: params["new_status"], reason: "#{admin_id}_#{params["reason"]}", change_status: "A"}
        new_changeset = Employeecards.changesetStatus(get_card, changeset)
        case Repo.update(new_changeset) do
          {:ok, _commanall} -> if params["new_status"] == "1" do
                                 json conn, %{status_code: "200", message: "Success, Card Activated!"}
                               else
                                 json conn, %{status_code: "200", message: "Success, Card Deactivated!"}
                               end
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn,
             %{
               status_code: response_code,
               errors: %{
                 message: response_message
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Only Enable disable card status accepted."
             }
           }
    end
  end

  @doc """
    Employee Card Block By Admin
  """
  def blockCard(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  def blockCard(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    cond do
      is_nil(params["cardid"]) || params["cardid"] == "" ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 cardid: "Can't be blank."
               }
             }
      is_nil(params["reason"]) || params["reason"] == "" ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 reason: "Can't be blank."
               }
             }
      is_nil(params["employee_id"]) || params["employee_id"] == "" ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 employee_id: "Can't be blank."
               }
             }
      true ->
        get_card = Repo.get_by(Employeecards, id: params["cardid"], employee_id: params["employee_id"])
        if get_card.status == "4" do

          changeset = %{status: "5", reason: "#{admin_id}_#{params["reason"]}", change_status: "A"}
          new_changeset = Employeecards.changesetStatus(get_card, changeset)
          if new_changeset.valid? do

            get_employee = Repo.get_by(Employee, id: params["employee_id"])
            get_company = Repo.get_by(Commanall, company_id: get_employee.company_id)
            if !is_nil(get_company) do
              get_account = Repo.get_by(
                Companyaccounts,
                company_id: get_employee.company_id,
                currency_code: get_card.currency_code
              )

              check_status = if get_card.available_balance > Decimal.new(0.00) do
                if !is_nil(get_account) do
                  reclaim_params =
                    %{
                      commanid: get_company.id,
                      companyid: get_employee.company_id,
                      employeeId: get_card.employee_id,
                      card_id: get_card.id,
                      account_id: get_account.id,
                      amount: get_card.available_balance,
                      type: "C2A",
                      description: "Reclaim of all funds due to card being blocked"
                    }
                  _response = DashboardController.reclaimFunds(reclaim_params)
                else
                  %{
                    status_code: "4004",
                    errors: %{
                      message: "Company Account not found for move card amount."
                    }
                  }
                end
              else
                %{status_code: "200", message: "done"}
              end
              if check_status.status_code == "200" do
                # Call to accomplish
                request = %{urlid: get_card.accomplish_card_id, status: 6}
                response = Accomplish.activate_deactive_card(request)
                response_code = response["result"]["code"]
                response_message = response["result"]["friendly_message"]
                if response_code == "0000" do

                  case Repo.update(new_changeset) do
                    {:ok, _commanall} ->
                      commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^params["employee_id"],
                                                                   select: %{
                                                                     id: cmn.id,
                                                                     commanall_id: cmn.accomplish_userid,
                                                                     email_id: cmn.email_id,
                                                                     as_login: cmn.as_login,
                                                                   }

                      mobiledata = Repo.one from m in Contacts,
                                            where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
                                            select: %{
                                              code: m.code,
                                              contact_number: m.contact_number
                                            }

                      devicedata = Repo.one from d in Devicedetails,
                                            where: d.commanall_id == ^commandata.id and d.is_delete == "N" and (
                                              d.type == "A" or d.type == "I"),
                                            select: %{
                                              token: d.token,
                                              token_type: d.type
                                            }
                      getemployee = Repo.get!(Employee, params["employee_id"])
                      [count_card] = Repo.all from d in Employeecards,
                                              where: d.employee_id == ^params["employee_id"] and (
                                                d.status == "1" or d.status == "4" or d.status == "12"),
                                              select: %{
                                                count: count(d.id)
                                              }
                      new_number = %{"no_of_cards" => count_card.count}
                      cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                      Repo.update(cards_changeset)

                      #                          # ALERTS
                      #                          data = %{
                      #                            :section => "block_card",
                      #                            :commanall_id => getemail.id,
                      #                            :employee_name => "#{getemployee.first_name} #{getemployee.last_name}",
                      #                            :card => get_card.last_digit
                      #                          }
                      #                          AlertsController.sendEmail(data)
                      #                          AlertsController.sendNotification(data)
                      #                          AlertsController.sendSms(data)
                      #                          AlertsController.storeNotification(data)

                      data = [
                        %{
                          section: "block_card",
                          type: "E",
                          email_id: commandata.email_id,
                          data: %{
                            :card => get_card.last_digit,
                            :employee_name => "#{getemployee.first_name} #{getemployee.last_name}"
                          }
                          # Content
                        },
                        %{
                          section: "block_card",
                          type: "S",
                          contact_code: mobiledata.code,
                          contact_number: mobiledata.contact_number,
                          data: %{
                            :card => get_card.last_digit,
                            :employee_name => "#{getemployee.first_name} #{getemployee.last_name}"
                          }
                          # Content
                        },
                        %{
                          section: "block_card",
                          type: "N",
                          token: if is_nil(devicedata) do
                            nil
                          else
                            devicedata.token
                          end,
                          push_type: if is_nil(devicedata) do
                            nil
                          else
                            devicedata.token_type
                          end, # "I" or "A"
                          login: commandata.as_login, # "Y" or "N"
                          data: %{
                            :card => get_card.last_digit,
                            :employee_name => "#{getemployee.first_name} #{getemployee.last_name}"
                          }
                          # Content
                        }
                      ]
                      V2AlertsController.main(data)

                      json conn, %{status_code: "200", message: "Card has been Blocked"}

                    {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                  end
                else
                  json conn,
                       %{
                         status_code: response_code,
                         errors: %{
                           messages: response_message
                         }
                       }
                end

              else
                json conn, check_status
              end
            else
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "Employee Company Not found."
                     }
                   }
            end
          else
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: new_changeset)
          end
        else
          if get_card.status == "1" do
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "The card needs to be deactivated"
                   }
                 }
          else
            if get_card.status == "5" do
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "The card is already blocked"
                     }
                   }
            end
          end
        end
    end
  end

  @doc """
    company Registration on thirdparty
  """
  def companyAuthorized(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    # create array data for send to accomplish
    userdata = Repo.one from commanall in Commanall, where: commanall.id == ^params["id"],
                                                     left_join: address in assoc(commanall, :address),
                                                     where: address.is_primary == "Y",
                                                     left_join: contacts in assoc(commanall, :contacts),
                                                     where: contacts.is_primary == "Y",
                                                     left_join: company in assoc(commanall, :company),
                                                     left_join: directors in assoc(company, :directors),
                                                     where: directors.is_primary == "Y",
                                                     select: %{
                                                       company_id: company.id,
                                                       company_name: company.company_name,
                                                       email_id: commanall.email_id,
                                                       address_line_one: address.address_line_one,
                                                       address_line_two: address.address_line_two,
                                                       countries_id: address.countries_id,
                                                       city: address.city,
                                                       post_code: address.post_code,
                                                       county: address.county,
                                                       town: address.town,
                                                       contact_number: contacts.contact_number,
                                                       code: contacts.code,
                                                       director_id: directors.id,
                                                       verify_kyc: directors.verify_kyc,
                                                       title: directors.title,
                                                       first_name: directors.first_name,
                                                       last_name: directors.last_name,
                                                       position: directors.position,
                                                       dob: directors.date_of_birth,
                                                       gender: directors.gender
                                                     }
    if !is_nil(userdata) do
      country_code = Application.get_env(:violacorp, :accomplish_country_code)
      currency_code = Application.get_env(:violacorp, :currency_code)
      is_primary = Application.get_env(:violacorp, :accomplish_is_primary)
      latitude = Application.get_env(:violacorp, :accomplish_latitude)
      longitude = Application.get_env(:violacorp, :accomplish_longitude)
      position_description = Application.get_env(:violacorp, :accomplish_position_description)
      time_zone = Application.get_env(:violacorp, :accomplish_time_zone)
      password = Application.get_env(:violacorp, :accomplish_password)
      secret_answer_1 = Application.get_env(:violacorp, :accomplish_secret_answer_1)
      secret_answer_2 = Application.get_env(:violacorp, :accomplish_secret_answer_2)
      secret_question_1 = Application.get_env(:violacorp, :accomplish_secret_question_1)
      secret_question_2 = Application.get_env(:violacorp, :accomplish_secret_question_2)
      security_code = Application.get_env(:violacorp, :accomplish_security_code)

      birth_date = userdata.dob
      company_id = userdata.company_id

      gender = if userdata.gender == "M", do: 1, else: 2

      title = if userdata.title == "Mr", do: 1, else: 2

      [acc_country_code, calling_code] = Commontools.get_acc_country_code(userdata.countries_id)
      contact_number = "+#{calling_code}#{userdata.contact_number}"
      #        get_version = Repo.one(from v in Versions, select: %{api_enable: v.api_enable})
      #        check_api = get_version.api_enable
      #
      #        bank_response = if check_api == "Y" do
      #                          get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")
      #                          if is_nil(get_card) do
      #                            # Call to clear bank
      #                            new_company_name = userdata.company_name
      #                            new_comman_id = params["id"]
      #                            owner_name = "#{new_company_name} #{new_comman_id}"
      #
      #                            clearBankArray = %{
      #                              new_company_name: new_company_name,
      #                              new_comman_id: new_comman_id,
      #                              owner_name: owner_name,
      #                              company_id: company_id,
      #                              request_id: "99999#{admin_id}",
      #                            }
      #                            clearbank_api(clearBankArray)
      #                          else
      #                            "success"
      #                          end
      #                        else
      #                          "success"
      #                        end

      #        if  bank_response == "success" do

      # Get four stop data

      id_document = Repo.one from k in Kycdirectors,
                             where: k.directors_id == ^userdata.director_id and k.status == "A" and k.type == "I",
                             limit: 1,
                             select: %{
                               id: k.id,
                               documenttype_id: k.documenttype_id,
                               document_number: k.document_number,
                               expiry_date: k.expiry_date,
                               file_location: k.file_location,
                               issue_date: k.issue_date,
                               updated_at: k.updated_at
                             }
      if !is_nil(id_document) do
        update_date = id_document.updated_at
        kyc_updated_date = [update_date.year, update_date.month, update_date.day]
                           |> Enum.map(&to_string/1)
                           |> Enum.map(&String.pad_leading(&1, 2, "0"))
                           |> Enum.join("")
        gbg_response = "GBG Viola Id #{userdata.director_id} date #{kyc_updated_date}"
        fourStopData = if userdata.verify_kyc == "gbg",
                          do: get_gbg_info(userdata.director_id, "director"), else: get_fourstop_info(params["id"])
        #        updated_gbg_response = String.replace("#{fourStopData} #{gbg_response}", " ", "0")
        request = %{
          address_line1: userdata.address_line_one,
          address_line2: userdata.address_line_two,
          city_town: userdata.town,
          country_code: acc_country_code,
          postal_zip_code: userdata.post_code,
          state_region: userdata.county,
          code: currency_code,
          address: userdata.email_id,
          is_primary: is_primary,
          latitude: latitude,
          longitude: longitude,
          position_description: position_description,
          date_of_birth: birth_date,
          first_name: userdata.first_name,
          gender: gender,
          job_title: userdata.position,
          last_name: userdata.last_name,
          nick_name: userdata.first_name,
          title: title,
          number: contact_number,
          time_zone: time_zone,
          password: password,
          secret_answer_1: secret_answer_1,
          secret_answer_2: secret_answer_2,
          secret_question_1: secret_question_1,
          secret_question_2: secret_question_2,
          security_code: security_code,
          status: 1,
          gbg_Data: fourStopData,
          gbg_response: "L #{fourStopData} #{gbg_response}",
          request_id: "99999#{admin_id}"
        }
        response = Accomplish.register(request, params["id"])
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do

          # Update Comman All data
          comman_data = Repo.get!(Commanall, params["id"])
          commanall_params = %{
            "accomplish_userid" => response["info"]["id"], #response_account["user_id"]
            "request" => Poison.encode!(request),
            "response" => Poison.encode!(response)
          }
          commanChangeset = Commanall.registration_accomplish(comman_data, commanall_params)
          Repo.update(commanChangeset)

          # call company Identification
          verify_status = get_gbg_verificationStatus(userdata.director_id, "director")
          type = case id_document.documenttype_id do
            10 -> "0"
            9 -> "2"
            _ -> "1"
          end
          request = %{
            "user_id" => response["info"]["id"],
            "commanall_id" => params["id"],
            "issue_date" => id_document.issue_date,
            "expiry_date" => id_document.expiry_date,
            "number" => id_document.document_number,
            "type" => type,
            "verification_status" => verify_status,
            "request_id" => "99999#{admin_id}",
            "worker_type" => "company_identification"
          }

          Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

          if is_nil(response["account"]) do
            #                    data = %{
            #                      :section => "registration_welcome",
            #                      :commanall_id => params["id"],
            #                      :company_name => userdata.company_name
            #                    }
            #                    AlertsController.sendEmail(data)
            #                    AlertsController.sendNotification(data)
            #                    AlertsController.sendSms(data)
            #                    AlertsController.storeNotification(data)
            json conn, %{status_code: "200", message: "Company registration has been done."}
          else
            response_account = get_in(response["account"], [Access.at(0), "info"])
            last_account_number = Repo.one(
              from x in Companyaccounts, order_by: [
                desc: x.account_number
              ],
                                         limit: 1,
                                         select: x.account_number
            )
            last_account = if last_account_number == nil do
              1
            else
              last_account_number + 1
            end
            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response_account["currency"],
                                                           select: c.id

            # Insert company account details
            companyaccount = %{
              "company_id" => company_id,
              "currencies_id" => currencies_id,
              "currency_code" => response_account["currency"],
              "available_balance" => response_account["available_balance"],
              "current_balance" => response_account["balance"],
              "account_number" => last_account,
              "accomplish_account_id" => response_account["id"],
              "bin_id" => response_account["bin_id"],
              "accomplish_account_number" => response_account["number"],
              "expiry_date" => response_account["security"]["expiry_date"],
              "source_id" => response_account["original_source_id"],
              "status" => response_account["status"],
              "inserted_by" => "99999#{admin_id}"
            }

            comAccChangeset = Companyaccounts.changeset(%Companyaccounts{}, companyaccount)

            case Repo.insert(comAccChangeset) do
              {:ok, _response} -> # ALERTS
                #                        data = %{
                #                          :section => "registration_welcome",
                #                          :commanall_id => params["id"],
                #                          :company_name => userdata.company_name
                #                        }
                #                        AlertsController.sendEmail(data)
                #                        AlertsController.sendNotification(data)
                #                        AlertsController.sendSms(data)
                #                        AlertsController.storeNotification(data)
                json conn, %{status_code: "200", message: "Company registration has been done."}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          end
        else
          # Update Comman All data
          comman_data = Repo.get!(Commanall, params["id"])
          commanall_params = %{
            "request" => Poison.encode!(request),
            "response" => Poison.encode!(response)
          }
          commanChangeset = Commanall.registration_accomplish(comman_data, commanall_params)
          Repo.update(commanChangeset)
          json conn,
               %{
                 status_code: "5001",
                 errors: %{
                   message: response_message
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "directors document not found"
               }
             }
      end

      #         else
      #                    json conn, %{status_code: "5001", errors: %{message: bank_response}}
      #         end

    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "User not valid."
             }
           }
    end
  end


  @doc """
    this function for company authorization
  """
  def companyAuthorizedV1(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    new_comman_id = params["id"]
    account_type = params["account_type"]

    userdata = Repo.one(from com in Commanall, where: com.id == ^new_comman_id, select: com)
    case userdata do
      nil -> json conn,
                  %{
                    status_code: "4004",
                    errors: %{
                      message: "User not valid."
                    }
                  }
      company_info ->
        company_name = Repo.one(from c in Company, where: c.id == ^company_info.company_id, select: c.company_name)
        check_account = Repo.get_by(Companybankaccount, company_id: company_info.company_id, status: "A")
        bank_response = case check_account do
          nil -> # Call to clear bank
            clearBankArray = %{
              new_company_name: company_name,
              new_comman_id: new_comman_id,
              owner_name: "#{company_name} #{new_comman_id}",
              company_id: company_info.company_id,
              request_id: "99999#{admin_id}"
            }
            clearbank_api(clearBankArray)

          _account -> "success"
        end
        if bank_response == "success" do
          if is_nil(company_info.start_date) or company_info.start_date == "" do
            Commanall.chagesetStartDate(company_info, %{start_date: Date.utc_today()})
            |> Repo.update()
          end

          case account_type do
            "CB" ->
              status_map = %{"status" => "A"}
              updateStatus = Commanall.updateStatus(company_info, status_map)
              Repo.update(updateStatus)

              _emaildata = %{
                             :from => "no-reply@violacorporate.com",
                             :to => company_info.email_id,
                             :subject => "Your ViolaCorporate account is ready",
                             :company_name => company_name,
                             :templatefile => "new_global_template.html",
                             :layoutfile => "company_registration_welcome.html"
                           }
                           |> SendEmail.sendemail()
                           |> Mailer.deliver_later()
              json conn, %{status_code: "200", message: "Company registration has been done."}

            "AC" ->
              case accomplish_api(company_info, admin_id) do
                {:ok, message} ->
                  json conn, %{status_code: "200", message: "Company registration has been done."}
                {:error_validation, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                {:acc_error, response_message} ->
                  json conn,
                       %{
                         status_code: "5001",
                         errors: %{
                           message: response_message
                         }
                       }
                {:error, message} ->
                  json conn,
                       %{
                         status_code: "4004",
                         errors: %{
                           message: message
                         }
                       }
              end
          end
        else
          json conn,
               %{
                 status_code: "5001",
                 errors: %{
                   message: bank_response
                 }
               }
        end
    end
  end

  ## call accomplish api
  defp accomplish_api(userdata, admin_id) do
    country_code = Application.get_env(:violacorp, :accomplish_country_code)
    currency_code = Application.get_env(:violacorp, :currency_code)
    is_primary = Application.get_env(:violacorp, :accomplish_is_primary)
    latitude = Application.get_env(:violacorp, :accomplish_latitude)
    longitude = Application.get_env(:violacorp, :accomplish_longitude)
    position_description = Application.get_env(:violacorp, :accomplish_position_description)
    time_zone = Application.get_env(:violacorp, :accomplish_time_zone)
    password = Application.get_env(:violacorp, :accomplish_password)
    secret_answer_1 = Application.get_env(:violacorp, :accomplish_secret_answer_1)
    secret_answer_2 = Application.get_env(:violacorp, :accomplish_secret_answer_2)
    secret_question_1 = Application.get_env(:violacorp, :accomplish_secret_question_1)
    secret_question_2 = Application.get_env(:violacorp, :accomplish_secret_question_2)
    security_code = Application.get_env(:violacorp, :accomplish_security_code)

    with {:ok, address} <- get_address(userdata),
         {:ok, contact} <- get_contact(userdata),
         {:ok, director} <- get_primary_director(userdata),
         {:ok, document} <- get_director_kyc(director.director_id)
      do

      [acc_country_code, calling_code] = Commontools.get_acc_country_code(address.countries_id)
      contact_number = "+#{calling_code}#{contact.contact_number}"
      birth_date = director.dob
      company_id = userdata.company_id

      gender = if director.gender == "M", do: 1, else: 2

      title = if director.title == "Mr", do: 1, else: 2
      update_date = document.updated_at
      kyc_updated_date = [update_date.year, update_date.month, update_date.day]
                         |> Enum.map(&to_string/1)
                         |> Enum.map(&String.pad_leading(&1, 2, "0"))
                         |> Enum.join("")
      gbg_response = "GBG Viola Id #{director.director_id} date #{kyc_updated_date}"
      fourStopData = if director.verify_kyc == "gbg",
                        do: get_gbg_info(director.director_id, "director"), else: get_fourstop_info(userdata.id)
      #        updated_gbg_response = String.replace("#{fourStopData} #{gbg_response}", " ", "0")
      request = %{
        address_line1: address.address_line_one,
        address_line2: address.address_line_two,
        city_town: address.town,
        country_code: acc_country_code,
        postal_zip_code: address.post_code,
        state_region: address.county,
        code: currency_code,
        address: userdata.email_id,
        is_primary: is_primary,
        latitude: latitude,
        longitude: longitude,
        position_description: position_description,
        date_of_birth: birth_date,
        first_name: director.first_name,
        gender: gender,
        job_title: director.position,
        last_name: director.last_name,
        nick_name: director.first_name,
        title: title,
        number: contact_number,
        time_zone: time_zone,
        password: password,
        secret_answer_1: secret_answer_1,
        secret_answer_2: secret_answer_2,
        secret_question_1: secret_question_1,
        secret_question_2: secret_question_2,
        security_code: security_code,
        status: 1,
        gbg_Data: fourStopData,
        gbg_response: "L #{fourStopData} #{gbg_response}",
        request_id: "99999#{admin_id}"
      }
      response = Accomplish.register(request, userdata.id)
      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]
      if response_code == "0000" do

        Commanall.registration_accomplish(
          userdata,
          %{
            "accomplish_userid" => response["info"]["id"], #response_account["user_id"]
            "request" => Poison.encode!(request),
            "response" => Poison.encode!(response)
          }
        )
        |> Repo.update()

        # call company Identification
        verify_status = get_gbg_verificationStatus(director.director_id, "director")
        type = case document.documenttype_id do
          10 -> "0"
          9 -> "2"
          _ -> "1"
        end
        request = %{
          "user_id" => response["info"]["id"],
          "commanall_id" => userdata.id,
          "issue_date" => document.issue_date,
          "expiry_date" => document.expiry_date,
          "number" => document.document_number,
          "type" => type,
          "verification_status" => verify_status,
          "request_id" => "99999#{admin_id}",
          "worker_type" => "company_identification"
        }

        Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

        if is_nil(response["account"]) do
          #                    data = %{
          #                      :section => "registration_welcome",
          #                      :commanall_id => params["id"],
          #                      :company_name => userdata.company_name
          #                    }
          #                    AlertsController.sendEmail(data)
          #                    AlertsController.sendNotification(data)
          #                    AlertsController.sendSms(data)
          #                    AlertsController.storeNotification(data)
          {:ok, "Company registration has been done."}
        else
          response_account = get_in(response["account"], [Access.at(0), "info"])
          last_account_number = Repo.one(
            from x in Companyaccounts, order_by: [
              desc: x.account_number
            ],
                                       limit: 1,
                                       select: x.account_number
          )
          last_account = if is_nil(last_account_number), do: 1, else: last_account_number + 1
          currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response_account["currency"],
                                                         select: c.id

          # Insert company account details
          companyaccount = %{
            "company_id" => company_id,
            "currencies_id" => currencies_id,
            "currency_code" => response_account["currency"],
            "available_balance" => response_account["available_balance"],
            "current_balance" => response_account["balance"],
            "account_number" => last_account,
            "accomplish_account_id" => response_account["id"],
            "bin_id" => response_account["bin_id"],
            "accomplish_account_number" => response_account["number"],
            "expiry_date" => response_account["security"]["expiry_date"],
            "source_id" => response_account["original_source_id"],
            "status" => response_account["status"],
            "inserted_by" => "99999#{admin_id}"
          }

          comAccChangeset = Companyaccounts.changeset(%Companyaccounts{}, companyaccount)

          case Repo.insert(comAccChangeset) do
            {:ok, _response} -> # ALERTS
              #                        data = %{
              #                          :section => "registration_welcome",
              #                          :commanall_id => params["id"],
              #                          :company_name => userdata.company_name
              #                        }
              #                        AlertsController.sendEmail(data)
              #                        AlertsController.sendNotification(data)
              #                        AlertsController.sendSms(data)
              #                        AlertsController.storeNotification(data)
              {:ok, "Company registration has been done."}
            {:error, changeset} -> {:error_validation, changeset}
          end
        end
      else
        # Update Comman All data
        commanall_params = %{
          "request" => Poison.encode!(request),
          "response" => Poison.encode!(response)
        }
        commanChangeset = Commanall.registration_accomplish(userdata, commanall_params)
        Repo.update(commanChangeset)
        {:acc_error, response_message}
      end
    end
  end

  defp get_address(userdata) do
    get_address = Repo.one(
      from address in Address, where: address.commanall_id == ^userdata.id and address.is_primary == "Y",
                               limit: 1,
                               select: %{
                                 address_line_one: address.address_line_one,
                                 address_line_two: address.address_line_two,
                                 countries_id: address.countries_id,
                                 city: address.city,
                                 post_code: address.post_code,
                                 county: address.county,
                                 town: address.town,
                               }
    )
    case get_address do
      nil -> {:error, "address information not found"}
      address -> {:ok, address}
    end
  end

  defp get_contact(userdata) do
    get_contact = Repo.one(
      from c1 in Contacts, where: c1.commanall_id == ^userdata.id and c1.is_primary == "Y",
                           limit: 1,
                           select: %{
                             contact_number: c1.contact_number,
                             code: c1.code
                           }
    )
    case get_contact do
      nil -> {:error, "contact information not found"}
      contact -> {:ok, contact}
    end
  end

  defp get_primary_director(userdata) do
    get_director = Repo.one(
      from dir in Directors, where: dir.company_id == ^userdata.company_id and dir.is_primary == "Y",
                             limit: 1,
                             select: %{
                               director_id: dir.id,
                               verify_kyc: dir.verify_kyc,
                               title: dir.title,
                               first_name: dir.first_name,
                               last_name: dir.last_name,
                               position: dir.position,
                               dob: dir.date_of_birth,
                               gender: dir.gender
                             }
    )
    case get_director do
      nil -> {:error, "director information not found"}
      director -> {:ok, director}
    end
  end

  defp get_director_kyc(director_id) do
    id_document = Repo.one from k in Kycdirectors,
                           where: k.directors_id == ^director_id and k.status == "A" and k.type == "I",
                           limit: 1,
                           select: %{
                             id: k.id,
                             documenttype_id: k.documenttype_id,
                             document_number: k.document_number,
                             expiry_date: k.expiry_date,
                             file_location: k.file_location,
                             issue_date: k.issue_date,
                             updated_at: k.updated_at
                           }
    case id_document do
      nil -> {:error, "KYC not found"}
      document -> {:ok, document}
    end
  end

  @doc "Call to clear bank"
  def clearbank_api(params) do

    company_id = params.company_id
    new_comman_id = params.new_comman_id
    request_id = if !is_nil(params.request_id) or params.request_id != "", do: params.request_id, else: new_comman_id

    # Call Clear Bank
    body_string = %{
                    "accountName" => params.owner_name,
                    "owner" => %{
                      "name" => params.new_company_name
                    },
                    "sortCode" => ""
                  }
                  |> Poison.encode!
    string = ~s(#{body_string})
    response_bank = Clearbank.create_account(string)
    _response = if !is_nil(response_bank["account"]) do
      iban = response_bank["account"]["iban"]
      account_id = response_bank["account"]["id"]
      account_name = response_bank["account"]["name"]
      bban = response_bank["account"]["bban"]
      type = response_bank["account"]["type"]

      res = get_in(response_bank["account"]["balances"], [Access.at(0)])
      status = res["status"]
      currency = res["currency"]
      balance = res["amount"]

      lan = String.length(iban)
      #    iso = String.slice(string, 0..1)
      #    iban = String.slice(string, 2..3)
      bank_code = String.slice(iban, 4..7)
      sort_code = String.slice(iban, 8..13)
      account_number = String.slice(iban, 14..lan)

      bankAccount = %{
        "company_id" => company_id,
        "account_id" => account_id,
        "account_number" => account_number,
        "account_name" => account_name,
        "iban_number" => iban,
        "bban_number" => bban,
        "currency" => currency,
        "balance" => balance,
        "sort_code" => sort_code,
        "bank_code" => bank_code,
        "bank_type" => type,
        "bank_status" => status,
        "status" => "A",
        "request" => body_string,
        "response" => Poison.encode!(response_bank),
        "inserted_by" => request_id
      }

      get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
      if is_nil(get_card) do
        changeset = Companybankaccount.changeset(%Companybankaccount{}, bankAccount)
        case Repo.insert(changeset) do
          {:ok, _bankAccount} ->
            "success"
          {:error, _changeset} ->
            "Server not responding."
        end
      else
        changeset = Companybankaccount.changeset(get_card, bankAccount)
        case Repo.update(changeset) do
          {:ok, _bankAccount} ->
            "success"
          {:error, _changeset} ->
            "failed"
        end
      end
    else
      bankAccount = %{
        "company_id" => company_id,
        "request" => body_string,
        "response" => Poison.encode!(response_bank),
        "status" => "F",
        "inserted_by" => request_id
      }
      get_card = Repo.get_by(Companybankaccount, company_id: company_id, status: "F")
      if is_nil(get_card) do
        changeset = Companybankaccount.changesetFailed(%Companybankaccount{}, bankAccount)
        Repo.insert(changeset)
        response_bank["title"]
      else
        changeset = Companybankaccount.changesetFailed(get_card, bankAccount)
        Repo.update(changeset)
        response_bank["title"]
      end
    end

  end

  @doc """
      Company Identifications
  """
  def compayIdentification(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    commanall_id = params["commanall_id"]
    comman_data = Repo.get!(Commanall, params["commanall_id"])
    if !is_nil(comman_data) do
      if !is_nil(comman_data.accomplish_userid) do
        check_identification = Repo.one(
          from log in Thirdpartylogs,
          where: log.commanall_id == ^commanall_id and like(
            log.section,
            "%Create Identification%"
                 ) and log.status == ^"S",
          limit: 1,
          select: log
        )
        if is_nil(check_identification) do

          director_data = Repo.one(
            from d in Directors, where: d.company_id == ^comman_data.company_id and d.is_primary == ^"Y",
                                 order_by: [
                                   asc: d.id
                                 ],
                                 limit: 1,
                                 select: d.id
          )
          verify_status = get_gbg_verificationStatus(director_data, "director")
          id_document = Repo.one from k in Kycdirectors,
                                 where: k.directors_id == ^director_data and k.status == "A" and k.type == "I",
                                 select: %{
                                   id: k.id,
                                   documenttype_id: k.documenttype_id,
                                   document_number: k.document_number,
                                   expiry_date: k.expiry_date,
                                   file_location: k.file_location,
                                   issue_date: k.issue_date,
                                 }
          if !is_nil(id_document) do
            type = case id_document.documenttype_id do
              10 -> "0"
              9 -> "2"
              _ -> "1"
            end
            request = %{
              "user_id" => comman_data.accomplish_userid,
              "commanall_id" => params["commanall_id"],
              "issue_date" => id_document.issue_date,
              "expiry_date" => id_document.expiry_date,
              "number" => id_document.document_number,
              "type" => type,
              "verification_status" => verify_status,
              "request_id" => "99999#{admin_id}",
              "worker_type" => "company_identification"
            }

            Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])
            json conn, %{status_code: "200", message: "Identification Done"}

          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "directors Id proof not found"
                   }
                 }
          end
        else
          if !is_nil(comman_data.accomplish_userid) do
            update_map = %{status: "A"}
            changeset = Commanall.updateStatus(comman_data, update_map)
            Repo.update(changeset)
          end
          render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification Done")
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Company not registration on third party"
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Record not found!"
             }
           }
    end
  end

  def get_gbg_verificationStatus(commanall_id, section) do
    kyc_response = case section do
      "director" ->
        Repo.one(
          from k in Kycdirectors, where: k.directors_id == ^commanall_id and k.type == ^"I",
                                  order_by: [
                                    desc: k.id
                                  ],
                                  limit: 1,
                                  select: k.fourstop_response
        )
      "employee" ->
        Repo.one(
          from k in Kycdocuments, where: k.commanall_id == ^commanall_id and k.type == ^"I",
                                  order_by: [
                                    desc: k.id
                                  ],
                                  limit: 1,
                                  select: k.fourstop_response
        )
    end
    if !is_nil(kyc_response) do
      gbg_data = Poison.decode!(kyc_response)
      _output = if !is_nil(gbg_data["response"]) do
        response = gbg_data["response"]
        string = response["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
        band_text = string["AuthenticateSPResult"]["BandText"]
        _authenticationID = string["AuthenticateSPResult"]["AuthenticationID"]
        _profileState = string["AuthenticateSPResult"]["ProfileState"]

        case band_text do
          "Pass" -> "1"
          "Refer" -> "0"
          _ -> "0"
        end
      else
        "0"
      end
    else
      "0"
    end
  end

  @doc """
      directors kyc verification
  """
  def directorKycVerification(conn, params) do
    director_id = params["director_id"]
    document_id = params["document_id"]
    get_director = Repo.one from d in Directors, where: d.id == ^director_id,
                                                 left_join: dr in assoc(d, :addressdirectors),
                                                 left_join: kyc in assoc(d, :kycdirectors),
                                                 where: kyc.type == "I" and kyc.id == ^document_id,
                                                 select: %{
                                                   id: d.id,
                                                   title: d.title,
                                                   first_name: d.first_name,
                                                   middle_name: d.middle_name,
                                                   last_name: d.last_name,
                                                   gender: d.gender,
                                                   date_of_birth: d.date_of_birth,
                                                   employee_id: d.employee_id,
                                                   address_line_one: dr.address_line_one,
                                                   address_line_two: dr.address_line_two,
                                                   town: dr.town,
                                                   post_code: dr.post_code,
                                                   documenttype_id: kyc.documenttype_id,
                                                   document_number: kyc.document_number,
                                                   expiry_date: kyc.expiry_date,
                                                   issue_date: kyc.issue_date,
                                                   country: kyc.country,
                                                 }
    if !is_nil(get_director) do
      if !is_nil(get_director.date_of_birth) && !is_nil(get_director.document_number) && !is_nil(
        get_director.address_line_one
      ) && !is_nil(get_director.expiry_date) do
        dob = get_director.date_of_birth
        expiry_date = get_director.expiry_date
        passport_number = if get_director.documenttype_id == 10, do: "#{get_director.document_number}", else: ""
        passport_expiry_day = if get_director.documenttype_id == 10, do: "#{expiry_date.day}", else: ""
        passport_expiry_month = if get_director.documenttype_id == 10, do: "#{expiry_date.month}", else: ""
        passport_expiry_year = if get_director.documenttype_id == 10, do: "#{expiry_date.year}", else: ""
        driving_number = if get_director.documenttype_id == 19, do: "#{get_director.document_number}", else: nil
        gender = if get_director.gender === "M", do: "Male", else: "Female"

        director_company_id = Repo.one(from d in Directors, where: d.id == ^director_id, limit: 1, select: d.company_id)
        commanall_id = Repo.one(from c in Commanall, where: c.company_id == ^director_company_id, select: c.id)

        # get countries name from db
        countries_id = Repo.one(from com in Company, where: com.id == ^director_company_id, select: com.countries_id)
        #        country_name = Repo.one(from cn in Countries, where: cn.id == ^countries_id, select: cn.country_name)
        country_name = if is_nil(get_director.country) do
          _country_title = Repo.one(from cn in Countries, where: cn.id == ^countries_id, select: cn.country_name)
        else
          _country_title = get_director.country
        end

        vetting_mode = Application.get_env(:violacorp, :vetting_method)

        if vetting_mode == "fourstop" do

          check_data = FourstopModel.main_vetting(commanall_id, director_id, document_id)

          case check_data do
            {:ok, _data} -> json conn, %{status_code: "200", message: "Success"}
            {:error, message} -> json conn, %{status_code: "5008", message: message}
          end
        else
          add = %{
            category: "D",
            title: "#{get_director.title}",
            forename: "#{get_director.first_name}",
            middlename: "#{get_director.middle_name}",
            surname: "#{get_director.last_name}",
            gender: gender,
            dobDay: "#{dob.day}",
            dobMonth: "#{dob.month}",
            dobYear: "#{dob.year}",
            country: country_name,
            street: "#{get_director.address_line_two}",
            city: "#{get_director.town}",
            zipPostcode: "#{get_director.post_code}",
            building: "#{get_director.address_line_one}",
            passportNumber: passport_number,
            passportExpiryDay: passport_expiry_day,
            passportExpiryMonth: passport_expiry_month,
            passportExpiryYear: passport_expiry_year,
            countryOfOrigin: country_name,
            drivingLicenceNumber: driving_number,
            commanall_id: commanall_id
          }
          check_data = Gbg.kyc_verify(add)
          kyc_document = Repo.get_by(Kycdirectors, id: document_id)
          director = Repo.get_by(Directors, id: get_director.id)
          changeset = Directors.changesetVerifyKyc(director, %{verify_kyc: "gbg"})
          Repo.update(changeset)
          update_data = %{
            reference_id: check_data["authenticate_id"],
            status: check_data["status"],
            fourstop_response: check_data["request_response"]
          }
          changeset = Kycdirectors.updateGBGResponse(kyc_document, update_data)
          Repo.update(changeset)

          if !is_nil(get_director.employee_id) do
            updateDirectorAsEmployee(get_director.employee_id, get_director.document_number, update_data)
          end
          if check_data["status"] == "A" do
            json conn, %{status_code: "200", message: "Success"}
          else
            message = if check_data["status"] == "RF", do: "Kyc refer by GBG", else: "Kyc rejected by GBG"
            json conn, %{status_code: "5008", message: message}
          end
        end
      else
        message = cond  do
          is_nil(get_director.date_of_birth) -> "Director birth date is missing."
          is_nil(get_director.document_number) -> "Director KYC document number is missing."
          is_nil(get_director.address_line_one) -> "Director address is missing."
          is_nil(get_director.expiry_date) -> "Director KYC expiry date is missing."
          true -> "some document needed information missing."
        end
        json conn, %{status_code: "5008", message: message}
      end
    else
      json conn, %{status_code: "5008", message: "Id proof not uploaded."}
    end
  end

  @doc """
      employee kyc verification
  """
  def employeeKycVerification(conn, params) do

    commanall_id = params["commanall_id"]
    document_id = params["document_id"]
    userdata = Repo.one from commanall in Commanall, where: commanall.id == ^commanall_id,
                                                     left_join: address in assoc(commanall, :address),
                                                     where: address.is_primary == "Y",
                                                     left_join: e in assoc(commanall, :employee),
                                                     left_join: kyc in assoc(commanall, :kycdocuments),
                                                     where: kyc.type == ^"I" and kyc.id == ^document_id,
                                                     order_by: [
                                                       desc: kyc.id
                                                     ],
                                                     limit: 1,
                                                     select: %{
                                                       address_line_one: address.address_line_one,
                                                       address_line_two: address.address_line_two,
                                                       city: address.city,
                                                       post_code: address.post_code,
                                                       county: address.county,
                                                       town: address.town,
                                                       employee_id: e.id,
                                                       title: e.title,
                                                       first_name: e.first_name,
                                                       last_name: e.last_name,
                                                       middle_name: e.middle_name,
                                                       birth_date: e.date_of_birth,
                                                       gender: e.gender,
                                                       director_id: e.director_id,
                                                       document_id: kyc.id,
                                                       documenttype_id: kyc.documenttype_id,
                                                       document_number: kyc.document_number,
                                                       expiry_date: kyc.expiry_date,
                                                       country: kyc.country,
                                                       company_id: e.company_id,
                                                     }
    if !is_nil(userdata) do

      if !is_nil(userdata.birth_date) && !is_nil(userdata.document_number) && !is_nil(
        userdata.address_line_one
      ) && !is_nil(userdata.expiry_date) do
        dob = userdata.birth_date
        expiry_date = userdata.expiry_date
        passport_number = if userdata.documenttype_id == 10, do: "#{userdata.document_number}", else: ""
        passport_expiry_day = if userdata.documenttype_id == 10, do: "#{expiry_date.day}", else: ""
        passport_expiry_month = if userdata.documenttype_id == 10, do: "#{expiry_date.month}", else: ""
        passport_expiry_year = if userdata.documenttype_id == 10, do: "#{expiry_date.year}", else: ""
        driving_number = if userdata.documenttype_id == 19, do: "#{userdata.document_number}", else: nil
        gender = if userdata.gender === "M", do: "Male", else: "Female"
        middle_name = if !is_nil(userdata.middle_name), do: userdata.middle_name, else: ""

        # get countries name from db
        countries_id = Repo.one(from com in Company, where: com.id == ^userdata.company_id, select: com.countries_id)
        #      country_name = Repo.one(from cn in Countries, where: cn.id == ^countries_id, select: cn.country_name)
        country_name = if is_nil(userdata.country) do
          _country_title = Repo.one(from cn in Countries, where: cn.id == ^countries_id, select: cn.country_name)
        else
          _country_title = userdata.country
        end

        vetting_mode = Application.get_env(:violacorp, :vetting_method)

        if vetting_mode == "fourstop" do
          check_data = FourstopModel.main_vetting(commanall_id, nil, document_id)

          case check_data do
            {:ok, _data} -> json conn, %{status_code: "200", message: "Success"}
            {:error, message} -> json conn, %{status_code: "5008", message: message}
          end
        else
          request_data = %{
            title: "#{userdata.title}",
            forename: "#{userdata.first_name}",
            middlename: "#{middle_name}",
            surname: "#{userdata.last_name}",
            gender: gender,
            dobDay: "#{dob.day}",
            dobMonth: "#{dob.month}",
            dobYear: "#{dob.year}",
            country: country_name,
            street: "#{userdata.address_line_two}",
            city: "#{userdata.town}",
            zipPostcode: "#{userdata.post_code}",
            building: "#{userdata.address_line_one}",
            passportNumber: passport_number,
            passportExpiryDay: passport_expiry_day,
            passportExpiryMonth: passport_expiry_month,
            passportExpiryYear: passport_expiry_year,
            countryOfOrigin: country_name,
            drivingLicenceNumber: driving_number,
            commanall_id: commanall_id
          }
          check_data = Gbg.kyc_verify(request_data)
          kyc_document = Repo.get(Kycdocuments, userdata.document_id)
          employee = Repo.get(Employee, userdata.employee_id)
          changeset = Employee.changesetVerifyKyc(employee, %{"verify_kyc" => "gbg"})
          Repo.update(changeset)
          update_data = %{
            reference_id: check_data["authenticate_id"],
            status: check_data["status"],
            fourstop_response: check_data["request_response"]
          }
          changeset = Kycdocuments.updateGBGResponse(kyc_document, update_data)
          Repo.update(changeset)

          if !is_nil(userdata.director_id) do
            updateEmployeeAsDirector(userdata.director_id, userdata.document_number, update_data)
          end
          if check_data["status"] == "A" do
            json conn, %{status_code: "200", message: "kyc verification done."}
          else
            message = if check_data["status"] == "RF", do: "Kyc refer by GBG", else: "Kyc rejected by GBG"
            json conn,
                 %{
                   status_code: "5008",
                   errors: %{
                     message: message
                   }
                 }
          end
        end
      else
        message = cond  do
          is_nil(userdata.birth_date) -> "Employee birth date is missing."
          is_nil(userdata.document_number) -> "Employee KYC document number is missing."
          is_nil(userdata.address_line_one) -> "Employee address is missing."
          is_nil(userdata.expiry_date) -> "Employee KYC expiry date is missing."
          true -> "some document needed information missing."
        end
        json conn, %{status_code: "5008", message: message}
      end

    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Id proof not uploaded."
             }
           }
    end
  end

  @doc """
     create employee registration on Third party
  """
  def employeeRegistation(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    commanid = params["commanall_id"]
    # create array data for send to accomplish
    userdata = Repo.one from commanall in Commanall, where: commanall.id == ^commanid,
                                                     left_join: address in assoc(commanall, :address),
                                                     where: address.is_primary == "Y",
                                                     left_join: contacts in assoc(commanall, :contacts),
                                                     where: contacts.is_primary == "Y",
                                                     left_join: employee in assoc(commanall, :employee),
                                                     select: %{
                                                       email_id: commanall.email_id,
                                                       address_line_one: address.address_line_one,
                                                       address_line_two: address.address_line_two,
                                                       countries_id: address.countries_id,
                                                       city: address.city,
                                                       town: address.town,
                                                       post_code: address.post_code,
                                                       county: address.county,
                                                       contact_number: contacts.contact_number,
                                                       code: contacts.code,
                                                       first_name: employee.first_name,
                                                       last_name: employee.last_name,
                                                       date_of_birth: employee.date_of_birth,
                                                       gender: employee.gender,
                                                       title: employee.title,
                                                       verify_kyc: employee.verify_kyc,
                                                       employee_id: employee.id
                                                     }
    if !is_nil(userdata) do
      country_code = Application.get_env(:violacorp, :accomplish_country_code)
      currency_code = Application.get_env(:violacorp, :currency_code)
      is_primary = Application.get_env(:violacorp, :accomplish_is_primary)
      latitude = Application.get_env(:violacorp, :accomplish_latitude)
      longitude = Application.get_env(:violacorp, :accomplish_longitude)
      position_description = Application.get_env(:violacorp, :accomplish_position_description)
      time_zone = Application.get_env(:violacorp, :accomplish_time_zone)
      password = Application.get_env(:violacorp, :accomplish_password)
      secret_answer_1 = Application.get_env(:violacorp, :accomplish_secret_answer_1)
      secret_answer_2 = Application.get_env(:violacorp, :accomplish_secret_answer_2)
      secret_question_1 = Application.get_env(:violacorp, :accomplish_secret_question_1)
      secret_question_2 = Application.get_env(:violacorp, :accomplish_secret_question_2)
      security_code = Application.get_env(:violacorp, :accomplish_security_code)

      [acc_country_code, calling_code] = Commontools.get_acc_country_code(userdata.countries_id)
      contact_number = "+#{calling_code}#{userdata.contact_number}"
      birth_date = userdata.date_of_birth
      _employee_id = userdata.employee_id

      gender = if userdata.gender == "M", do: 1, else: 2

      title = if userdata.title == "Mr", do: 1, else: 2
      kyc_response = Repo.one(
        from k in Kycdocuments, where: k.commanall_id == ^commanid and k.type == ^"I" and k.status == ^"A",
                                order_by: [
                                  desc: k.id
                                ],
                                limit: 1,
                                select: k
      )
      if !is_nil(kyc_response) do

        update_date = kyc_response.updated_at
        kyc_updated_date = [update_date.year, update_date.month, update_date.day]
                           |> Enum.map(&to_string/1)
                           |> Enum.map(&String.pad_leading(&1, 2, "0"))
                           |> Enum.join("")
        gbg_response = "GBG Viola Id #{commanid} date #{kyc_updated_date}"

        fourStopData = if userdata.verify_kyc == "gbg",
                          do: get_gbg_info(commanid, "employee"), else: get_fourstop_info(commanid)

        #    updated_gbg_response = String.replace("#{fourStopData} #{gbg_response}", " ", "0")

        request = %{
          address_line1: userdata.address_line_one,
          address_line2: userdata.address_line_two,
          city_town: userdata.town,
          country_code: acc_country_code,
          postal_zip_code: userdata.post_code,
          state_region: userdata.county,
          code: currency_code,
          address: userdata.email_id,
          is_primary: is_primary,
          latitude: latitude,
          longitude: longitude,
          position_description: position_description,
          date_of_birth: birth_date,
          first_name: userdata.first_name,
          gender: gender,
          job_title: "employee",
          last_name: userdata.last_name,
          nick_name: userdata.first_name,
          title: title,
          number: contact_number,
          time_zone: time_zone,
          password: password,
          secret_answer_1: secret_answer_1,
          secret_answer_2: secret_answer_2,
          secret_question_1: secret_question_1,
          secret_question_2: secret_question_2,
          security_code: security_code,
          status: 1,
          gbg_Data: fourStopData,
          gbg_response: "L #{fourStopData} #{gbg_response}",
          request_id: "99999#{admin_id}"
        }
        response = Accomplish.register(request, commanid)
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do
          comman_data = Repo.get!(Commanall, commanid)
          commanall_params = %{
            "accomplish_userid" => response["info"]["id"],
            "request" => Poison.encode!(request),
            "response" => Poison.encode!(response)
          }
          changeset_comman = Commanall.registration_accomplish(comman_data, commanall_params)
          Repo.update(changeset_comman)

          # CAll Employee Identification process
          documenttype_id = if kyc_response.documenttype_id == 9 do
            "2"
          else
            if kyc_response.documenttype_id == 10 do
              "0"
            else
              "1"
            end
          end

          verify_status = get_gbg_verificationStatus(commanid, "employee")

          request = %{
            "user_id" => response["info"]["id"],
            "commanall_id" => commanid,
            "issue_date" => kyc_response.issue_date,
            "expiry_date" => kyc_response.expiry_date,
            "number" => kyc_response.document_number,
            "type" => documenttype_id,
            "verification_status" => verify_status,
            "employee_id" => userdata.employee_id,
            "request_id" => "99999#{admin_id}",
            "worker_type" => "employee_identification"
          }

          Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [request], max_retries: 1)

          json conn, %{status_code: "200", message: "employee registration successfully"}
        else
          json conn,
               %{
                 status_code: response_code,
                 errors: %{
                   message: response_message
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Employee Id Proof kyc not found."
               }
             }
      end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "User not valid."
             }
           }
    end
  end

  @doc "Pull 4stop data"
  def get_fourstop_info(commanall_id) do
    fourstop_data = Repo.one(
      from f in Fourstop, where: f.commanall_id == ^commanall_id,
                          order_by: [
                            desc: f.id
                          ],
                          limit: 1,
                          select: %{
                            stopid: f.stopid,
                            rec: f.rec,
                            confidence_level: f.confidence_level
                          }
    )
    _response = if !is_nil(fourstop_data) do
      case fourstop_data.rec do
        "Approve" ->
          "4s success #{fourstop_data.stopid} confidence_level #{fourstop_data.confidence_level}"
        "Refer" ->
          "4s refer #{fourstop_data.stopid} confidence_level #{
            fourstop_data.confidence_level
          } manual override document uploaded"
        _ ->
          "4s failed manual override document uploaded"
      end
    else
      nil
    end
  end

  def get_gbg_info(commanall_id, section) do

    kyc_response = case section do
      "director" ->
        Repo.one(
          from k in Kycdirectors, where: k.directors_id == ^commanall_id and k.type == ^"I",
                                  order_by: [
                                    desc: k.id
                                  ],
                                  limit: 1,
                                  select: k.fourstop_response
        )
      "employee" ->
        Repo.one(
          from k in Kycdocuments, where: k.commanall_id == ^commanall_id and k.type == ^"I",
                                  order_by: [
                                    desc: k.id
                                  ],
                                  limit: 1,
                                  select: k.fourstop_response
        )
    end
    if !is_nil(kyc_response) do
      gbg_data = Poison.decode!(kyc_response)
      _output = if !is_nil(gbg_data["response"]) do
        response = gbg_data["response"]
        string = response["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
        band_text = string["AuthenticateSPResult"]["BandText"]
        authenticationID = string["AuthenticateSPResult"]["AuthenticationID"]
        profileState = string["AuthenticateSPResult"]["ProfileState"]

        case band_text do
          "Pass" ->
            "GBG SUCCESS #{authenticationID} profileState #{profileState}"
          "Refer" ->
            "GBG REFER manual override FalsePositive #{authenticationID} profileState #{
              profileState
            } documents uploaded"
          _ ->
            "GBG FAILED manual override FalsePositive documents uploaded"
        end
      else
        nil
      end
    else
      nil
    end

  end

  @doc """
    employee Identification
  """
  def employeeIdentification(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]

      common_all_id = params["commanall_id"]

      comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                      select: %{
                                                        accomplish_userid: c.accomplish_userid,
                                                        employee_id: c.employee_id
                                                      }
      if !is_nil(comman_all_data) do
        kyc_document = Repo.one from d in Kycdocuments, where: d.commanall_id == ^common_all_id,
                                                        where: d.type == "I" and d.status == "A",
                                                        limit: 1,
                                                        select: %{
                                                          document_number: d.document_number,
                                                          documenttype_id: d.documenttype_id,
                                                          expiry_date: d.expiry_date,
                                                          issue_date: d.issue_date,
                                                          file_type: d.file_type,
                                                          content: d.content,
                                                          file_name: d.file_name,
                                                          file_location: d.file_location
                                                        }
        if !is_nil(kyc_document) do
          documenttype_id = if kyc_document.documenttype_id == 9 do
            "2"
          else
            if kyc_document.documenttype_id == 10 do
              "0"
            else
              "1"
            end
          end

          verify_status = get_gbg_verificationStatus(common_all_id, "employee")

          request = %{
            "user_id" => comman_all_data.accomplish_userid,
            "commanall_id" => common_all_id,
            "issue_date" => kyc_document.issue_date,
            "expiry_date" => kyc_document.expiry_date,
            "number" => kyc_document.document_number,
            "type" => documenttype_id,
            "verification_status" => verify_status,
            "employee_id" => comman_all_data.employee_id,
            "request_id" => "99999#{admin_id}",
            "worker_type" => "employee_identification"
          }

          Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [request], max_retries: 1)

          json conn, %{status_code: "200", message: "Identification Done"}
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Kyc not found."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "record not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
    company upload id proof on third party
  """
  def companyUploadIdProof(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      commanall_id = params["commanall_id"]
      company_detail = Repo.get_by(Commanall, id: commanall_id)
      if !is_nil(company_detail) do
        company_id = company_detail.company_id
        get_director = Repo.one(
          from d in Directors, where: d.company_id == ^company_id and d.is_primary == "Y",
                               select: %{
                                 id: d.id,
                                 first_name: d.first_name,
                                 last_name: d.last_name
                               }
        )
        if !is_nil(get_director) do
          director_id = get_director.id
          id_document = Repo.one from k in Kycdirectors,
                                 where: k.directors_id == ^director_id and k.status == "A" and k.type == "I",
                                 select: %{
                                   id: k.id,
                                   documenttype_id: k.documenttype_id,
                                   document_number: k.document_number,
                                   expiry_date: k.expiry_date,
                                   file_location: k.file_location,
                                   issue_date: k.issue_date,
                                 }

          # call worker for Id proof
          if !is_nil(id_document) do
            file_data = id_document.file_location
            if !is_nil(file_data) do
              %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
              content = Base.encode64(body)
              file_extension = Path.extname(file_data)

              type = case id_document.documenttype_id do
                19 -> "4"
                10 -> "2"
                9 -> "3"
                _ -> "3"
              end

              file_name = case id_document.documenttype_id do
                19 -> "Driving Licence"
                10 -> "Passport"
                9 -> "National ID"
                _ -> "National ID"
              end

              request = %{
                user_id: company_detail.accomplish_userid,
                commanall_id: commanall_id,
                first_name: get_director.first_name,
                last_name: get_director.last_name,
                type: type,
                subject: "#{file_name}",
                entity: 25,
                file_name: file_name,
                file_extension: file_extension,
                content: content,
                document_id: id_document.id,
                request_id: "99999#{admin_id}",
                worker_type: "company_id_proof",
              }
              Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
              json conn,
                   %{
                     status_code: "200",
                     message: "We are processing company document."
                   }
            else
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "Company director document not found."
                     }
                   }
            end
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Company director document information not found."
                   }
                 }
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Company primary director not found."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Company not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
      company upload address proof on third party
  """
  def companyUploadAddressProof(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]

      commanall_id = params["commanall_id"]

      company_detail = Repo.get_by(Commanall, id: commanall_id)
      if !is_nil(company_detail) do
        company_id = company_detail.company_id
        get_director = Repo.one(
          from d in Directors, where: d.company_id == ^company_id and d.is_primary == "Y",
                               select: %{
                                 id: d.id,
                                 first_name: d.first_name,
                                 last_name: d.last_name
                               }
        )
        if !is_nil(get_director) do
          director_id = get_director.id
          address_document = Repo.one(
            from ak in Kycdirectors, where: ak.directors_id == ^director_id and ak.status == "A" and ak.type == "A",
                                     select: %{
                                       id: ak.id,
                                       address_file_location: ak.file_location,
                                       address_documenttype_id: ak.documenttype_id
                                     }
          )

          if !is_nil(address_document) do
            address_file_data = address_document.address_file_location
            if !is_nil(address_file_data) do
              %HTTPoison.Response{body: body} = HTTPoison.get!(address_file_data)
              address_content = Base.encode64(body)
              address_file_extension = Path.extname(address_file_data)

              address_type = case address_document.address_documenttype_id do
                1 -> "5"
                2 -> "10"
                21 -> "4"
                4 -> "7"
                _ -> "5"
              end

              document_name = case address_document.address_documenttype_id do
                1 -> "Utility Bill"
                2 -> "Council Tax"
                21 -> "Driving Licence"
                4 -> "Bank Statement"
                _ -> "Utility Bill"
              end

              request = %{
                user_id: company_detail.accomplish_userid,
                commanall_id: commanall_id,
                first_name: get_director.first_name,
                last_name: get_director.last_name,
                type: address_type,
                subject: "#{document_name}",
                entity: 15,
                file_name: document_name,
                file_extension: address_file_extension,
                content: address_content,
                document_id: address_document.id,
                request_id: "99999#{admin_id}",
                worker_type: "company_address_proof",
              }
              Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
              json conn,
                   %{
                     status_code: "200",
                     message: "We are processing company document."
                   }
            else
              json conn,
                   %{
                     status_code: "4004",
                     errors: %{
                       message: "Company director document not found."
                     }
                   }
            end
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Company director document information not found."
                   }
                 }
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Company primary director not found."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Company not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
      employee upload id proof on third-party
  """
  def employeeUploadIdProof(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      commanall_id = params["commanall_id"]
      employee_detail = Repo.get_by(Commanall, id: commanall_id)
      if !is_nil(employee_detail) do

        employee = Repo.get(Employee, employee_detail.employee_id)

        id_document = Repo.one from k in Kycdocuments,
                               where: k.commanall_id == ^commanall_id and k.status == "A" and k.type == "I",
                               limit: 1,
                               select: %{
                                 id: k.id,
                                 documenttype_id: k.documenttype_id,
                                 document_number: k.document_number,
                                 expiry_date: k.expiry_date,
                                 file_location: k.file_location,
                                 issue_date: k.issue_date,
                               }

        # call worker for Id proof
        if !is_nil(id_document) do
          file_data = id_document.file_location
          if !is_nil(file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(file_data)
            content = Base.encode64(body)
            file_extension = Path.extname(file_data)

            type = case id_document.documenttype_id do
              19 -> "4"
              10 -> "2"
              9 -> "3"
              _ -> "3"
            end

            file_name = case id_document.documenttype_id do
              19 -> "Driving Licence"
              10 -> "Passport"
              9 -> "National ID"
              _ -> "National ID"
            end

            request = %{
              user_id: employee_detail.accomplish_userid,
              employee_id: employee_detail.employee_id,
              commanall_id: commanall_id,
              first_name: employee.first_name,
              last_name: employee.last_name,
              type: type,
              subject: "#{file_name}",
              entity: 25,
              file_name: file_name,
              file_extension: file_extension,
              content: content,
              document_id: id_document.id,
              request_id: "99999#{admin_id}",
              worker_type: "employee_id_proof",
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
            json conn, %{status_code: "200", message: "We are processing employee document."}
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Employee document not found."
                   }
                 }
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Employee document information not found."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "employee not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
      employee upload address proof on third-party
  """
  def employeeUploadAddressProof(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      commanall_id = params["commanall_id"]
      employee_detail = Repo.get_by(Commanall, id: commanall_id)
      if !is_nil(employee_detail) do
        employee = Repo.get(Employee, employee_detail.employee_id)
        address_document = Repo.one from ak in Kycdocuments,
                                    where: ak.commanall_id == ^params["commanall_id"] and ak.status == "A" and ak.type == "A",
                                    limit: 1,
                                    select: %{
                                      id: ak.id,
                                      address_file_location: ak.file_location,
                                      address_documenttype_id: ak.documenttype_id
                                    }

        # call worker for Id proof
        if !is_nil(address_document) do
          address_file_data = address_document.address_file_location
          if !is_nil(address_file_data) do
            %HTTPoison.Response{body: body} = HTTPoison.get!(address_file_data)
            address_content = Base.encode64(body)
            address_file_extension = Path.extname(address_file_data)

            address_type = case address_document.address_documenttype_id do
              1 -> "5"
              2 -> "10"
              21 -> "4"
              4 -> "7"
              _ -> "5"
            end

            document_name = case address_document.address_documenttype_id do
              1 -> "Utility Bill"
              2 -> "Council Tax"
              21 -> "Driving Licence"
              4 -> "Bank Statement"
              _ -> "Utility Bill"
            end

            request = %{
              user_id: employee_detail.accomplish_userid,
              employee_id: employee_detail.employee_id,
              commanall_id: commanall_id,
              first_name: employee.first_name,
              last_name: employee.last_name,
              type: address_type,
              subject: "#{document_name}",
              entity: 15,
              file_name: document_name,
              file_extension: address_file_extension,
              content: address_content,
              document_id: address_document.id,
              type_of_proof: "Address",
              request_id: "99999#{admin_id}",
              worker_type: "employee_address_proof",
            }
            Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
            json conn, %{status_code: "200", message: "We are processing employee document."}
          else
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: "Employee document not found."
                   }
                 }
          end
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Employee document information not found."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "employee not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc """
    employee card generate first card by admin
  """
  def employeeCardGenerate(conn, params) do
    unless map_size(params) == 0 do
      %{"id" => admin_id} = conn.assigns[:current_user]
      commanall_id = params["commanall_id"]
      employee_detail = Repo.get_by(Commanall, id: commanall_id)
      if !is_nil(employee_detail) do
        employee = Repo.get(Employee, employee_detail.employee_id)
        # Check Clear Bank Account
        count_balance = Repo.one(
          from cb in Companybankaccount, where: cb.company_id == ^employee.company_id and cb.status == ^"A",
                                         select: sum(cb.balance)
        )
        output = if !is_nil(count_balance) && Decimal.cmp("#{count_balance}", Decimal.from_float(0.0)) == :gt,
                    do: "Yes", else: "No"

        request = %{
          "worker_type" => "physical_card",
          "user_id" => employee_detail.accomplish_userid,
          "commanall_id" => commanall_id,
          "employee_id" => employee_detail.employee_id,
          "request_id" => "99999#{admin_id}",
        }

        if output == "Yes" do
          # Create Physical Card
          #        Exq.enqueue(Exq, "physical_card", PhysicalCard, [request], max_retries: 1)
          Exq.enqueue_in(Exq, "cards", 15, Violacorp.Workers.V1.Cards, [request])
        end
        json conn, %{status_code: "200", message: "We are processing to generate physical card."}
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "employee not found."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Get Info Account on clear bank"
  def accountPullTransactions(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      accounts = Repo.get_by(Companybankaccount, id: params["account_id"])
      if !is_nil(accounts) do
        if accounts.currency == "GBP" do
          company_id = accounts.company_id
          commanall_id = Repo.one(from c in Commanall, where: c.company_id == ^company_id, select: c.id)
          load_params = %{
            "commanall_id" => commanall_id,
            "worker_type" => "clearbank_transactions",
          }
          Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
          json conn, %{status_code: "200", message: "Transaction pull successfully"}
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Account not valid"
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Account not found!"
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


  @doc "Get Info Account on clear bank"
  def accountPullTransactionsForDateRange(conn, params) do

    startDateTime = Timex.to_naive_datetime(Date.from_iso8601!(params["start_date"]))
    #    endDateTime = Timex.to_datetime(Date.from_iso8601!(params["end_date"]))

    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      accounts = Repo.get_by(Companybankaccount, id: params["account_id"])
      if !is_nil(accounts) do
        if accounts.currency == "GBP" do
          company_id = accounts.company_id
          commanall_id = Repo.one(from c in Commanall, where: c.company_id == ^company_id, select: c.id)
          load_params = %{
            "commanall_id" => commanall_id,
            "worker_type" => "clearbank_transactions_date_range",
            "start_date_time" => startDateTime,
            "end_date_time" => NaiveDateTime.add(startDateTime, 86400)
            #              "end_date_time" => NaiveDateTime.add(endDateTime, 86400)
          }
          Exq.enqueue(Exq, "transactions", Violacorp.Workers.V1.Transactions, [load_params], max_retries: 1)
          json conn, %{status_code: "200", message: "Transaction pull successfully for date '#{params["start_date"]}'"}
        else
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Account not valid"
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4004",
               errors: %{
                 message: "Account not found!"
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


  defp updateDirectorAsEmployee(employee_id, document_number, changeset_map) do
    emp_commanall_id = Repo.one(from com in Commanall, where: com.employee_id == ^employee_id, select: com.id)
    if !is_nil(emp_commanall_id) do
      employee = Repo.get(Employee, employee_id)
      changeset = Employee.changesetVerifyKyc(employee, %{"verify_kyc" => "gbg"})
      Repo.update(changeset)
      kyc_document = Repo.one(
        from k1 in Kycdocuments,
        where: k1.commanall_id == ^emp_commanall_id and k1.document_number == ^document_number and k1.type == ^"I",
        order_by: [
          desc: k1.id
        ],
        limit: 1
      )
      if !is_nil(kyc_document) do
        changeset = Kycdocuments.updateGBGResponse(kyc_document, changeset_map)
        Repo.update(changeset)
      end
    end
  end
  defp updateEmployeeAsDirector(director_id, document_number, changeset_map) do
    director = Repo.get_by(Directors, id: director_id)
    if !is_nil(director) do
      changeset = Directors.changesetVerifyKyc(director, %{verify_kyc: "gbg"})
      Repo.update(changeset)
      kyc_document = Repo.one(
        from k1 in Kycdirectors,
        where: k1.directors_id == ^director_id and k1.document_number == ^document_number and k1.type == ^"I",
        order_by: [
          desc: k1.id
        ],
        limit: 1
      )
      if !is_nil(kyc_document) do
        changeset = Kycdirectors.updateGBGResponse(kyc_document, changeset_map)
        Repo.update(changeset)
      end
    end
  end
end