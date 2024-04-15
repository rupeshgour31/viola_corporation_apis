defmodule ViolacorpWeb.Comman.TestController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Gbg

  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Countries

  #  alias Violacorp.Schemas.Versions

  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Thirdpartylogs
  #  alias Violacorp.Workers.PendingTransactionsUpdater
  #  alias Violacorp.Workers.SuccessTransactionsUpdater
  #  alias Violacorp.Workers.Documentupload

  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController
  alias ViolacorpWeb.Main.DashboardController

  @doc "New User Registration on Accomplish for company"
  def test_accomplish(conn, params) do

    username = params["username"]
    sec_password = params["sec_password"]
    request_id = params["request_id"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do

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

        contact_number = "+#{userdata.code}#{userdata.contact_number}"
        birth_date = userdata.dob
        company_id = userdata.company_id

        gender = if userdata.gender == "M", do: 1, else: 2

        title = if userdata.title == "Mr", do: 1, else: 2

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
        #                              request_id: params["request_id"],
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
        kyc_response = Repo.one(
          from k in Kycdirectors, where: k.directors_id == ^userdata.director_id and k.type == ^"I",
                                  order_by: [
                                    desc: k.id
                                  ],
                                  limit: 1,
                                  select: %{
                                    updated_at: k.updated_at
                                  }
        )
        update_date = kyc_response.updated_at
        kyc_updated_date  = [update_date.year, update_date.month, update_date.day]
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
          country_code: country_code,
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
          request_id: request_id
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
            render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Company registration has been done.")
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

            inserted_by = if !is_nil(request_id) or request_id != "", do: request_id, else: params["id"]

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
              "inserted_by" => inserted_by
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
                render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Company registration has been done.")
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
          json conn, %{status_code: "5001", errors: response_message}
        end

        #         else
        #            json conn, %{status_code: "5001",errors: bank_response}
        #         end

      else
        json conn,
             %{
               status_code: "404",
               errors: %{
                 message: "User not valid."
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

  @doc "Upload document"
  def upload_direct_document(conn, params) do

    comman_id = params["id"]
    comman_all_data = Repo.one from c in Commanall, where: c.id == ^comman_id,
                                                    select: %{
                                                      accomplish_userid: c.accomplish_userid,
                                                      employee_id: c.employee_id
                                                    }
    kyc_document = Repo.one from d in Kycdocuments,
                            where: d.commanall_id == ^comman_id and d.type == "I" and d.status == "A",
                            select: %{
                              document_number: d.document_number,
                              expiry_date: d.expiry_date,
                              issue_date: d.issue_date,
                              file_type: d.file_type,
                              content: d.content,
                              file_location: d.file_location
                            }

    emp_info = Repo.one from e in Employee, where: e.id == ^comman_all_data.employee_id,
                                            select: %{
                                              first_name: e.first_name,
                                              last_name: e.last_name
                                            }


    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)
    aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

    file_name_db = "#{kyc_document.file_location}"
    file_name = file_name_db
                |> String.split(aws_url, trim: true)
                |> Enum.join()

    request = %{
      user_id: comman_all_data.accomplish_userid,
      commanall_id: comman_id,
      first_name: emp_info.first_name,
      last_name: emp_info.last_name,
      file_name: file_name,
      file_extension: ".#{kyc_document.file_type}",
      content: String.replace_leading(kyc_document.content, "data:image/jpeg;base64,", "")
    }

    response = Accomplish.create_document(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Document upload done.")
    else
      json conn,
           %{
             status_code: "5004",
             errors: %{
               message: response_message
             }
           }
    end
  end

  @doc "Create Identification"
  def upload_identification_document(conn, params) do

    comman_id = params["id"]
    comman_all_data = Repo.one from c in Commanall, where: c.id == ^comman_id,
                                                    select: %{
                                                      accomplish_userid: c.accomplish_userid,
                                                      employee_id: c.employee_id
                                                    }
    kyc_document = Repo.one from d in Kycdocuments,
                            where: d.commanall_id == ^comman_id and d.type == "I" and d.status == "A",
                            select: %{
                              document_number: d.document_number,
                              documenttype_id: d.documenttype_id,
                              expiry_date: d.expiry_date,
                              issue_date: d.issue_date,
                              file_type: d.file_type,
                              content: d.content,
                              file_location: d.file_location
                            }

    #    emp_info = Repo.one from e in Employee, where: e.id == ^comman_all_data.employee_id,
    #                                            select: %{
    #                                              first_name: e.first_name,
    #                                              last_name: e.last_name
    #                                            }


    documenttype_id = if kyc_document.documenttype_id == 9 do
      "2"
    else
      if kyc_document.documenttype_id == 10 do
        "0"
      else
        "1"
      end
    end
    request = %{
      user_id: comman_all_data.accomplish_userid,
      commanall_id: comman_id,
      issue_date: kyc_document.issue_date,
      expiry_date: kyc_document.expiry_date,
      type: documenttype_id,
      number: kyc_document.document_number
    }

    response = Accomplish.upload_identification(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    #    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    #    mode = Application.get_env(:violacorp, :aws_mode)
    #    region = Application.get_env(:violacorp, :aws_region)
    #    aws_url = "https://#{image_bucket}.#{region}/#{mode}/"
    #
    #    file_name_db = "#{kyc_document.file_location}"
    #    file_name = file_name_db
    #                |> String.split(aws_url, trim: true)
    #                |> Enum.join()


    if response_code == "0000" do
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification done.")
      #      request = %{
      #        user_id: comman_all_data.accomplish_userid,
      #        commanall_id: comman_id,
      #        first_name: emp_info.first_name,
      #        last_name: emp_info.last_name,
      #        file_name: file_name,
      #        file_extension: ".#{kyc_document.file_type}",
      #        content: String.replace_leading(kyc_document.content, "data:image/jpeg;base64,", "")
      #      }
      #
      #      response = Accomplish.create_document(request)
      #      response_code = response["result"]["code"]
      #      response_message = response["result"]["friendly_message"]
      #      if response_code == "0000" do
      #        render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification & document upload done.")
      #      else
      #        json conn,
      #             %{
      #               status_code: "5004",
      #               errors: %{
      #                 message: response_message
      #               }
      #             }
      #      end
    else
      json conn,
           %{
             status_code: "5004",
             errors: %{
               message: response_message
             }
           }
    end
  end

  @doc "Create Identification"
  def upload_identification_document_director(conn, params) do

    comman_id = params["id"]
    comman_all_data = Repo.one from c in Commanall, where: c.id == ^comman_id,
                                                    select: %{
                                                      accomplish_userid: c.accomplish_userid,
                                                      company_id: c.company_id
                                                    }
    get_director = Repo.one from d in Directors,
                            where: d.company_id == ^comman_all_data.company_id and d.is_primary == ^"Y",
                            select: %{
                              id: d.id,
                              first_name: d.first_name,
                              last_name: d.last_name
                            }
    kyc_document = Repo.one from d in Kycdirectors,
                            where: d.directors_id == ^get_director.id and d.type == "I" and d.status == "A",
                            select: %{
                              document_number: d.document_number,
                              documenttype_id: d.documenttype_id,
                              expiry_date: d.expiry_date,
                              issue_date: d.issue_date,
                              file_location: d.file_location,
                              file_type: d.file_type
                            }

    documenttype_id = if kyc_document.documenttype_id == 9 do
      "2"
    else
      if kyc_document.documenttype_id == 10 do
        "0"
      else
        "1"
      end
    end

    request = %{
      user_id: comman_all_data.accomplish_userid,
      commanall_id: comman_id,
      issue_date: kyc_document.issue_date,
      expiry_date: kyc_document.expiry_date,
      type: documenttype_id,
      number: kyc_document.document_number
    }

    response = Accomplish.upload_identification(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    #    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    #    mode = Application.get_env(:violacorp, :aws_mode)
    #    region = Application.get_env(:violacorp, :aws_region)
    #    aws_url = "https://#{image_bucket}.#{region}/#{mode}/"
    #
    #    file_name_db = "#{kyc_document.file_location}"
    #    file_name = file_name_db
    #                |> String.split(aws_url, trim: true)
    #                |> Enum.join()
    #
    #    %HTTPoison.Response{body: body} = HTTPoison.get!(kyc_document.file_location)
    #    content = Base.encode64(body)

    if response_code == "0000" do
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification done.")
      #      request = %{
      #        user_id: comman_all_data.accomplish_userid,
      #        commanall_id: comman_id,
      #        first_name: get_director.first_name,
      #        last_name: get_director.last_name,
      #        file_name: file_name,
      #        file_extension: "#{kyc_document.file_type}",
      #        content: content
      #      }
      #
      #      response = Accomplish.create_document(request)
      #      response_code = response["result"]["code"]
      #      response_message = response["result"]["friendly_message"]
      #      if response_code == "0000" do
      #        render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification & document upload done.")
      #      else
      #        json conn,
      #             %{
      #               status_code: "5004",
      #               errors: %{
      #                 message: response_message
      #               }
      #             }
      #      end
    else
      json conn,
           %{
             status_code: "5004",
             errors: %{
               message: response_message
             }
           }
    end
  end

  @doc "Create Identification"
  def upload_document_director(conn, params) do

    comman_id = params["id"]
    comman_all_data = Repo.one from c in Commanall, where: c.id == ^comman_id,
                                                    select: %{
                                                      accomplish_userid: c.accomplish_userid,
                                                      company_id: c.company_id
                                                    }
    get_director = Repo.one from d in Directors,
                            where: d.company_id == ^comman_all_data.company_id and d.is_primary == ^"Y",
                            select: %{
                              id: d.id,
                              first_name: d.first_name,
                              last_name: d.last_name
                            }
    kyc_document = Repo.one from d in Kycdirectors,
                            where: d.directors_id == ^get_director.id and d.type == "I" and d.status == "A",
                            select: %{
                              document_number: d.document_number,
                              expiry_date: d.expiry_date,
                              issue_date: d.issue_date,
                              file_location: d.file_location,
                              file_type: d.file_type
                            }

    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)
    aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

    file_name_db = "#{kyc_document.file_location}"
    file_name = file_name_db
                |> String.split(aws_url, trim: true)
                |> Enum.join()

    %HTTPoison.Response{body: body} = HTTPoison.get!(kyc_document.file_location)
    content = Base.encode64(body)

    request = %{
      user_id: comman_all_data.accomplish_userid,
      commanall_id: comman_id,
      first_name: get_director.first_name,
      last_name: get_director.last_name,
      file_name: file_name,
      file_extension: "#{kyc_document.file_type}",
      content: content
    }

    response = Accomplish.create_document(request)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]
    if response_code == "0000" do
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Document upload done.")
    else
      json conn,
           %{
             status_code: "5004",
             errors: %{
               message: response_message
             }
           }
    end

  end

  @doc "Create Identification"
  def test_identification(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
        comman_data = Repo.get!(Commanall, params["commanall_id"])
        check_identification = Repo.one(from log in Thirdpartylogs, where: log.commanall_id == ^commanall_id and like(log.section, "%Create Identification%") and log.status == ^"S", limit: 1, select: log)
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

          request = %{
            "worker_type" => "company_identification",
            "user_id" => params["user_id"],
            "commanall_id" => params["commanall_id"],
            "issue_date" => params["issue_date"],
            "expiry_date" => params["expiry_date"],
            "number" => params["number"],
            "type" => params["type"],
            "verification_status" => verify_status,
            "request_id" => request_id
          }

          Exq.enqueue_in(Exq, "identification", 10, Violacorp.Workers.V1.Identification, [request])

          render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification Done")
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
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Identification"
  def employee_identification(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do

        common_all_id = params["commanall_id"]
        request_id = params["request_id"]

        comman_all_data = Repo.one from c in Commanall, where: c.id == ^common_all_id,
                                                        select: %{
                                                          accomplish_userid: c.accomplish_userid,
                                                          employee_id: c.employee_id
                                                        }
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
          "worker_type" => "create_identification",
          "user_id" => comman_all_data.accomplish_userid,
          "commanall_id" => common_all_id,
          "issue_date" => kyc_document.issue_date,
          "expiry_date" => kyc_document.expiry_date,
          "number" => kyc_document.document_number,
          "type" => documenttype_id,
          "verification_status" => verify_status,
          "employee_id" => comman_all_data.employee_id,
          "request_id" => request_id,
        }

        Exq.enqueue(Exq, "identification", Violacorp.Workers.V1.Identification, [request], max_retries: 1)
        render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Identification Done")
      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Create Document"
  def test_document(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
        request = %{
          user_id: params["user_id"],
          commanall_id: params["commanall_id"],
          first_name: params["first_name"],
          last_name: params["last_name"],
          file_name: params["file_name"],
          file_extension: params["file_extension"],
          content: params["content"]
        }

        response = Accomplish.create_document(request)

        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do
          render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Documentation Done")
        else
          json conn,
               %{
                 status_code: "5004",
                 errors: %{
                   message: response_message
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "New User Registration on Accomplish for employee"
  def create_employee(commanid, request_id) do

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

    contact_number = "+#{userdata.code}#{userdata.contact_number}"
    birth_date = userdata.date_of_birth
    _employee_id = userdata.employee_id

    gender = if userdata.gender == "M", do: 1, else: 2

    title = if userdata.title == "Mr", do: 1, else: 2
    kyc_response = Repo.one(
      from k in Kycdocuments, where: k.commanall_id == ^commanid and k.type == ^"I",
                              order_by: [
                                desc: k.id
                              ],
                              limit: 1,
                              select: %{
                                updated_at: k.updated_at
                              }
    )

    update_date = kyc_response.updated_at
    kyc_updated_date  = [update_date.year, update_date.month, update_date.day]
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
      country_code: country_code,
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
      request_id: request_id
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
      _message = "200"
    else
      _message = response_message
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

  @doc "send data to GBG"
  def employee_verify_GBG(commanall_id) do

    userdata = Repo.one from commanall in Commanall, where: commanall.id == ^commanall_id,
                                                     left_join: address in assoc(commanall, :address),
                                                     where: address.is_primary == "Y",
                                                     left_join: e in assoc(commanall, :employee),
                                                     left_join: kyc in assoc(commanall, :kycdocuments),
                                                     where: kyc.type == ^"I",
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
                                                       document_id: kyc.id,
                                                       documenttype_id: kyc.documenttype_id,
                                                       document_number: kyc.document_number,
                                                       expiry_date: kyc.expiry_date,
                                                       country: kyc.country,
                                                       company_id: e.company_id,
                                                     }
    if !is_nil(userdata) do

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
      if check_data["status"] == "A" do
        update_data = %{
          reference_id: check_data["authenticate_id"],
          status: check_data["status"],
          fourstop_response: check_data["request_response"]
        }
        changeset = Kycdocuments.updateGBGResponse(kyc_document, update_data)
        Repo.update(changeset)
        %{"status" => "200", "message" => "Success"}
      else
        update_data = %{
          reference_id: check_data["authenticate_id"],
          status: check_data["status"],
          fourstop_response: check_data["request_response"]
        }
        changeset = Kycdocuments.updateGBGResponse(kyc_document, update_data)
        Repo.update(changeset)
        message = if check_data["status"] == "RF", do: "Kyc refer by GBG", else: "Kyc rejected by GBG"
        %{"status" => "5008", "message" => message}
      end
    else
      %{"status" => "5008", "message" => "Id proof not uploaded."}
    end
  end

  @doc "Get Details for exist user"
  def getuser(conn, params) do

    userid = params["id"]
    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do
      response = Accomplish.get_user(userid)
      render(conn, ViolacorpWeb.SuccessView, "success.json", response: response)
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

  @doc "Get Details for exist user"
  def check_cards(conn, params) do

    employee_id = params["id"]
    commandata = Repo.one from commanall in Commanall, where: commanall.employee_id == ^employee_id,
                                                       select: %{
                                                         id: commanall.id,
                                                         acc_id: commanall.accomplish_userid
                                                       }
    if commandata == nil do
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Employee id is incorrect."
             }
           }
    else
      response = Accomplish.get_user(commandata.acc_id)

      response_code = response["result"]["code"]
      response_message = response["result"]["friendly_message"]

      if response_code == "0000" do

        Enum.each response["account"], fn post ->
          accomplish_card_id = post["info"]["id"]
          employee = Repo.one from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id,
                                                       select: %{
                                                         id: e.id
                                                       }

          if employee == nil do
            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^post["info"]["currency"],
                                                           select: c.id
            card_number = post["info"]["number"]
            last_digit = Commontools.lastfour(card_number)
            status = post["info"]["status"]
            employeecard = %{
              "employee_id" => employee_id,
              "currencies_id" => currencies_id,
              "currency_code" => post["info"]["currency"],
              "last_digit" => "#{last_digit}",
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"],
              "accomplish_card_id" => post["info"]["id"],
              "bin_id" => post["info"]["bin_id"],
              "expiry_date" => post["info"]["security"]["expiry_date"],
              "source_id" => post["info"]["original_source_id"],
              "activation_code" => post["info"]["security"]["activation_code"],
              "status" => status,
              "card_type" => "P",
              "inserted_by" => commandata.id
            }
            changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
            Repo.insert(changeset_comacc)
            if status == "12" do
              commanall_data = Repo.get!(Commanall, commandata.id)
              card_request = %{"card_requested" => "Y"}
              changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
              Repo.update(changeset_commanall)
            end
            getemployee = Repo.get!(Employee, employee_id)
            [count_card] = Repo.all from d in Employeecards,
                                    where: d.employee_id == ^employee_id and (
                                      d.status == "1" or d.status == "4" or d.status == "12"),
                                    select: %{
                                      count: count(d.id)
                                    }
            new_number = %{"no_of_cards" => count_card.count}
            cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
            Repo.update(cards_changeset)
          end
        end
        json conn,
             %{
               status_code: "200",
               data: %{
                 message: response_message
               }
             }
      else
        json conn,
             %{
               status_code: "5004",
               errors: %{
                 message: response_message
               }
             }
      end
    end
  end

  @doc "Update Employee Card Balance"
  def update_card_balance(userid) do

    response = Accomplish.get_user(userid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      Enum.each response["account"], fn post ->
        accomplish_card_id = post["info"]["id"]
        employee = Repo.one from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id,
                                                     select: %{
                                                       id: e.id,
                                                       employee_id: e.employee_id,
                                                       available_balance: e.available_balance,
                                                       current_balance: e.current_balance
                                                     }

        if employee != nil do
          db_avi_balance = to_string(employee.available_balance)
          db_cur_balance = to_string(employee.current_balance)
          ser_avi_balance = post["info"]["available_balance"]
          ser_cur_balance = post["info"]["balance"]

          #            # call pending transaction method
          #            load_params = %{
          #              "employee_id" => employee.employee_id
          #            }
          #            Exq.enqueue(Exq, "pending_transactions_updater", PendingTransactionsUpdater, [load_params], max_retries: 1)
          #            Exq.enqueue(Exq, "success_transactions_updater", SuccessTransactionsUpdater, [load_params], max_retries: 1)

          if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do
            employeecard = Repo.get!(Employeecards, employee.id)
            update_balance = %{
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"]
            }
            changeset_employeecard = Employeecards.changesetBalance(employeecard, update_balance)
            Repo.update(changeset_employeecard)
          end
        end
      end
    end

    _return_response = %{"response_code" => response_code, "response_message" => response_message}

  end

  @doc "Update Employee Card Balance"
  def update_single_card_balance(card_id, userid) do

    response = Accomplish.get_user(userid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      Enum.each response["account"], fn post ->
        accomplish_card_id = post["info"]["id"]
        employee = Repo.one from e in Employeecards,
                            where: e.id == ^card_id and e.accomplish_card_id == ^accomplish_card_id,
                            select: %{
                              id: e.id,
                              employee_id: e.employee_id,
                              available_balance: e.available_balance,
                              current_balance: e.current_balance
                            }
        if employee != nil do
          db_avi_balance = to_string(employee.available_balance)
          db_cur_balance = to_string(employee.current_balance)
          ser_avi_balance = post["info"]["available_balance"]
          ser_cur_balance = post["info"]["balance"]

          if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do
            # call pending transaction method
            load_params = %{
              "worker_type" => "pending_single_transactions_updater",
              "employee_id" => employee.employee_id,
              "accomplish_card_id" => accomplish_card_id,
            }
            Exq.enqueue(
              Exq,
              "transactions",
              Violacorp.Workers.V1.Transactions,
              [load_params],
              max_retries: 1
            )

            employeecard = Repo.get!(Employeecards, employee.id)
            update_balance = %{
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"]
            }
            changeset_employeecard = Employeecards.changesetBalance(employeecard, update_balance)
            Repo.update(changeset_employeecard)
          end
        end
      end
    end

    _return_response = %{"response_code" => response_code, "response_message" => response_message}

  end

  @doc "Update Employee Card Balance"
  def update_single_card_balance_new(card_id, accountid) do

    response = Accomplish.get_account(accountid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      accomplish_card_id = response["info"]["id"]
      employee = Repo.one from e in Employeecards, where: e.id == ^card_id,
                                                   select: %{
                                                     id: e.id,
                                                     employee_id: e.employee_id,
                                                     available_balance: e.available_balance,
                                                     current_balance: e.current_balance
                                                   }

      if employee != nil do
        db_avi_balance = to_string(employee.available_balance)
        db_cur_balance = to_string(employee.current_balance)
        ser_avi_balance = response["info"]["available_balance"]
        ser_cur_balance = response["info"]["balance"]

        if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do
          # call pending transaction method
          load_params = %{
            "worker_type" => "pending_single_transactions_updater",
            "employee_id" => employee.employee_id,
            "accomplish_card_id" => accomplish_card_id,
          }
          Exq.enqueue(
            Exq,
            "transactions",
            Violacorp.Workers.V1.Transactions,
            [load_params],
            max_retries: 1
          )

          employeecard = Repo.get!(Employeecards, employee.id)
          update_balance = %{
            "available_balance" => response["info"]["available_balance"],
            "current_balance" => response["info"]["balance"]
          }
          changeset_employeecard = Employeecards.changesetBalance(employeecard, update_balance)
          Repo.update(changeset_employeecard)
        end
      end
    end

    _return_response = %{"response_code" => response_code, "response_message" => response_message}

  end

  @doc "Update Company Account Balance"
  def update_account_balance(commanid, userid) do

    response = Accomplish.get_user(userid)
    response_code = response["result"]["code"]
    response_message = response["result"]["friendly_message"]

    if response_code == "0000" do
      Enum.each response["account"], fn post ->

        accomplish_acc_id = post["info"]["id"]
        company = Repo.one from c in Companyaccounts, where: c.accomplish_account_id == ^accomplish_acc_id,
                                                      select: %{
                                                        id: c.id,
                                                        company_id: c.company_id,
                                                        available_balance: c.available_balance,
                                                        current_balance: c.current_balance
                                                      }
        if company != nil do
          db_avi_balance = to_string(company.available_balance)
          db_cur_balance = to_string(company.current_balance)
          ser_avi_balance = post["info"]["available_balance"]
          ser_cur_balance = post["info"]["balance"]

          if db_avi_balance !== ser_avi_balance or db_cur_balance !== ser_cur_balance do

            # call manual load method
            load_params = %{
              "worker_type" => "manual_load",
              "commanall_id" => commanid,
              "company_id" => company.company_id
            }
            Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 1)

            companyaccount = Repo.get!(Companyaccounts, company.id)
            update_balance = %{
              "available_balance" => post["info"]["available_balance"],
              "current_balance" => post["info"]["balance"]
            }
            changeset_companyaccount = Companyaccounts.changesetBalance(companyaccount, update_balance)
            Repo.update(changeset_companyaccount)

          end
        end
      end
    end

    _return_response = %{"response_code" => response_code, "response_message" => response_message}

  end

  @doc "Create card"
  def create_card(conn, params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

    # Check Clear Bank Account
    check_clearBank = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")

    if is_nil(check_clearBank) do
      json conn,
           %{
             status_code: "4005",
             errors: %{
               message: "You does not have Online Business Account."
             }
           }
    else
      if Decimal.cmp("#{check_clearBank.balance}", Decimal.from_float(0.0)) == :gt  do
        # get request card details
        requrestcard = Repo.get!(Requestcard, params["id"])

        status = params["status"]

        if requrestcard.status == "R" and status == "A" do

          if requrestcard.card_type == "P" do
            json conn, %{status_code: "4006", message: "Allow only virtual card request."}
          end

          # Get Comman All Data
          #        commandata = Repo.one from commanall in Commanall, where: commanall.employee_id == ^requrestcard.employee_id,
          #                                                           select: %{
          #                                                             id: commanall.id,
          #                                                             commanall_id: commanall.accomplish_userid
          #                                                           }
          commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id,
                                                       select: %{
                                                         id: cmn.id,
                                                         commanall_id: cmn.accomplish_userid,
                                                         email_id: cmn.email_id,
                                                         as_login: cmn.as_login,
                                                       }

          mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
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


          type = Application.get_env(:violacorp, :card_type)
          accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
          accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)
          fulfilment_config_id = Application.get_env(:violacorp, :fulfilment_config_id_v)

          bin_id = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_bin_id)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_bin_id)
            else
              Application.get_env(:violacorp, :gbp_card_bin_id)
            end
          end

          number = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_number)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_number)
            else
              Application.get_env(:violacorp, :gbp_card_number)
            end
          end

          request = %{
            type: type,
            bin_id: bin_id,
            number: number,
            currency: requrestcard.currency,
            user_id: commandata.commanall_id,
            status: 1,
            fulfilment_config_id: fulfilment_config_id,
            fulfilment_notes: "create cards for user",
            fulfilment_reason: 1,
            fulfilment_status: 1,
            latitude: accomplish_latitude,
            longitude: accomplish_longitude,
            position_description: "",
            acceptance2: 2,
            acceptance: 1
          }

          response = Accomplish.create_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                           select: c.id

            # Insert employee card details
            card_number = response["info"]["number"]
            last_digit = Commontools.lastfour(card_number)
            employeecard = %{
              "employee_id" => requrestcard.employee_id,
              "currencies_id" => currencies_id,
              "currency_code" => response["info"]["currency"],
              "last_digit" => "#{last_digit}",
              "available_balance" => response["info"]["available_balance"],
              "current_balance" => response["info"]["balance"],
              "accomplish_card_id" => response["info"]["id"],
              "bin_id" => response["info"]["bin_id"],
              "accomplish_account_number" => response["info"]["number"],
              "expiry_date" => response["info"]["security"]["expiry_date"],
              "source_id" => response["info"]["original_source_id"],
              "status" => response["info"]["status"],
              "inserted_by" => commanid
            }

            changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)

            request_card_params = %{"status" => "A"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            case Repo.insert(changeset_comacc) do
              {:ok, _director} ->
                getemployee = Repo.get!(Employee, requrestcard.employee_id)
                [count_card] = Repo.all from d in Employeecards,
                                        where: d.employee_id == ^requrestcard.employee_id and (
                                          d.status == "1" or d.status == "4" or d.status == "12"),
                                        select: %{
                                          count: count(d.id)
                                        }
                new_number = %{"no_of_cards" => count_card.count}
                cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                Repo.update(cards_changeset)


                # ALERTS
                card_type = if requrestcard.card_type == "V" do
                  "virtual"
                end
                employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                               select: %{
                                                                 first_name: employee.first_name,
                                                                 last_name: employee.last_name
                                                               }
                #              data = %{
                #                :section => "cardrequest_approved",
                #                :commanall_id => commandata.id,
                #                :card_type => card_type,
                #                :currency => requrestcard.currency,
                #                :employee_name => "#{employee.first_name} #{employee.last_name}"
                #              }
                #              AlertsController.sendEmail(data)
                #              AlertsController.sendNotification(data)
                #              AlertsController.sendSms(data)
                #              AlertsController.storeNotification(data)

                data = [
                  %{
                    section: "cardrequest_approved",
                    type: "E",
                    email_id: commandata.email_id,
                    data: %{
                      :card_type => card_type,
                      :currency => requrestcard.currency,
                      :employee_name => "#{employee.first_name} #{employee.last_name}"
                    }
                    # Content
                  },
                  %{
                    section: "cardrequest_approved",
                    type: "S",
                    contact_code: mobiledata.code,
                    contact_number: mobiledata.contact_number,
                    data: %{
                      :card_type => card_type,
                      :currency => requrestcard.currency,
                      :employee_name => "#{employee.first_name} #{employee.last_name}"
                    }
                    # Content
                  },
                  %{
                    section: "cardrequest_approved",
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
                      :card_type => card_type,
                      :currency => requrestcard.currency,
                      :employee_name => "#{employee.first_name} #{employee.last_name}"
                    }
                    # Content
                  }
                ]
                V2AlertsController.main(data)

                json conn, %{status_code: "200", message: "Card Approved."}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "5001",
                   errors: %{
                     message: response_message
                   }
                 }
          end

        else

          if requrestcard.status == "R" and status == "C" do
            request_card_params = %{"status" => "C"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            # Get Comman All Data
            #          commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id, left_join: m in assoc(cmn, :contacts), where: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), where: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
            #                                                       select: %{
            #                                                         id: cmn.id,
            #                                                         email_id: cmn.email_id,
            #                                                         as_login: cmn.as_login,
            #                                                         code: m.code,
            #                                                         contact_number: m.contact_number,
            #                                                         token: d.token,
            #                                                         token_type: d.type,
            #                                                       }


            commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id,
                                                         select: %{
                                                           id: cmn.id,
                                                           commanall_id: cmn.accomplish_userid,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                         }

            mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
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

            employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                           select: %{
                                                             first_name: employee.first_name,
                                                             last_name: employee.last_name
                                                           }

            card_type = if requrestcard.card_type == "V" do
              "virtual"
            end

            # ALERTS DEPRECATED
            #          data = %{
            #            :section => "cardrequest_rejected",
            #            :commanall_id => commandata.id,
            #            :card_type => card_type,
            #            :currency => requrestcard.currency,
            #            :employee_name => "#{employee.first_name} #{employee.last_name}"
            #          }
            #          AlertsController.sendEmail(data)
            #          AlertsController.sendNotification(data)
            #          AlertsController.sendSms(data)
            #          AlertsController.storeNotification(data)


            data = [
              %{
                section: "cardrequest_rejected",
                type: "E",
                email_id: commandata.email_id,
                data: %{
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              },
              %{
                section: "cardrequest_rejected",
                type: "S",
                contact_code: mobiledata.code,
                contact_number: mobiledata.contact_number,
                data: %{
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              },
              %{
                section: "cardrequest_rejected",
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
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              }
            ]
            V2AlertsController.main(data)


            json conn, %{status_code: "200", message: "Card Rejected."}
          else
            json conn, %{status_code: "4006", message: "card already approved."}
          end

        end
      else
        json conn,
             %{
               status_code: "404",
               errors: %{
                 message: "You have to deposit some amount into Online Business Account to order a card."
               }
             }
      end
    end

  end

  @doc "Create Physical Card"
  def create_physical_card(conn, params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]

    # Check Clear Bank Account
    check_clearBank = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")

    if is_nil(check_clearBank) do
      json conn,
           %{
             status_code: "4005",
             errors: %{
               message: "You does not have Online Business Account."
             }
           }
    else
      if Decimal.cmp("#{check_clearBank.balance}", Decimal.from_float(0.0)) == :gt  do
        # get request card details
        requrestcard = Repo.get!(Requestcard, params["id"])

        status = params["status"]
        if requrestcard.status == "R" and status == "A" do

          if requrestcard.card_type == "V" do
            json conn, %{status_code: "4006", message: "Allow only physical card request."}
          end

          # Get Comman All Data
          commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id,
                                                       select: %{
                                                         id: cmn.id,
                                                         commanall_id: cmn.accomplish_userid,
                                                         email_id: cmn.email_id,
                                                         as_login: cmn.as_login,
                                                       }

          mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
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

          type = Application.get_env(:violacorp, :card_type)
          accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
          accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)
          fulfilment_config_id = Application.get_env(:violacorp, :fulfilment_config_id_p)

          bin_id = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_bin_id)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_bin_id)
            else
              Application.get_env(:violacorp, :gbp_card_bin_id)
            end
          end

          number = if requrestcard.currency == "USD" do
            Application.get_env(:violacorp, :usd_card_number)
          else
            if requrestcard.currency == "EUR" do
              Application.get_env(:violacorp, :eur_card_number)
            else
              Application.get_env(:violacorp, :gbp_card_number)
            end
          end

          request = %{
            type: type,
            bin_id: bin_id,
            number: number,
            currency: requrestcard.currency,
            user_id: commandata.commanall_id,
            status: 12,
            fulfilment_config_id: fulfilment_config_id,
            fulfilment_notes: "create cards for user",
            fulfilment_reason: 1,
            fulfilment_status: 1,
            latitude: accomplish_latitude,
            longitude: accomplish_longitude,
            position_description: "",
            acceptance2: 2,
            acceptance: 1
          }

          response = Accomplish.create_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                           select: c.id
            # Insert employee card details
            card_number = response["info"]["number"]
            last_digit = Commontools.lastfour(card_number)
            employeecard = %{
              "employee_id" => requrestcard.employee_id,
              "currencies_id" => currencies_id,
              "currency_code" => response["info"]["currency"],
              "last_digit" => "#{last_digit}",
              "available_balance" => response["info"]["available_balance"],
              "current_balance" => response["info"]["balance"],
              "accomplish_card_id" => response["info"]["id"],
              "bin_id" => response["info"]["bin_id"],
              "accomplish_account_number" => response["info"]["number"],
              "expiry_date" => response["info"]["security"]["expiry_date"],
              "source_id" => response["info"]["original_source_id"],
              "activation_code" => response["info"]["security"]["activation_code"],
              "status" => response["info"]["status"],
              "card_type" => "P",
              "inserted_by" => commanid
            }

            changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)

            # Update Request card Status
            request_card_params = %{"status" => "A"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)

            # Update commanall card_requested
            commanall_data = Repo.get!(Commanall, commandata.id)
            card_request = %{"card_requested" => "Y"}
            changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
            Repo.update(changeset_commanall)

            case Repo.insert(changeset_comacc) do
              {:ok, _response} -> getemployee = Repo.get!(Employee, requrestcard.employee_id)
                                  [count_card] = Repo.all from d in Employeecards,
                                                          where: d.employee_id == ^requrestcard.employee_id and (
                                                            d.status == "1" or d.status == "4" or d.status == "12"),
                                                          select: %{
                                                            count: count(d.id)
                                                          }
                                  new_number = %{"no_of_cards" => count_card.count}
                                  cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                                  Repo.update(cards_changeset)

                                  # ALERTS
                                  card_type = if requrestcard.card_type == "V" do
                                    "virtual"
                                  else
                                    "physical"
                                  end
                                  employee = Repo.one from employee in Employee,
                                                      where: employee.id == ^requrestcard.employee_id,
                                                      select: %{
                                                        first_name: employee.first_name,
                                                        last_name: employee.last_name
                                                      }

                                  #                                data = %{
                                  #                                  :section => "cardrequest_approved",
                                  #                                  :commanall_id => commandata.id,
                                  #                                  :card_type => card_type,
                                  #                                  :currency => requrestcard.currency,
                                  #                                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                                  #                                }
                                  #                                AlertsController.sendEmail(data)
                                  #                                AlertsController.sendNotification(data)
                                  #                                AlertsController.sendSms(data)
                                  #                                AlertsController.storeNotification(data)

                                  data = [
                                    %{
                                      section: "cardrequest_approved",
                                      type: "E",
                                      email_id: commandata.email_id,
                                      data: %{
                                        :card_type => card_type,
                                        :currency => requrestcard.currency,
                                        :employee_name => "#{employee.first_name} #{employee.last_name}"
                                      }
                                      # Content
                                    },
                                    %{
                                      section: "cardrequest_approved",
                                      type: "S",
                                      contact_code: mobiledata.code,
                                      contact_number: mobiledata.contact_number,
                                      data: %{
                                        :card_type => card_type,
                                        :currency => requrestcard.currency,
                                        :employee_name => "#{employee.first_name} #{employee.last_name}"
                                      }
                                      # Content
                                    },
                                    %{
                                      section: "cardrequest_approved",
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
                                        :card_type => card_type,
                                        :currency => requrestcard.currency,
                                        :employee_name => "#{employee.first_name} #{employee.last_name}"
                                      }
                                      # Content
                                    }
                                  ]
                                  V2AlertsController.main(data)


                                  render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Card Approved.")
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
          else
            json conn,
                 %{
                   status_code: "5002",
                   errors: %{
                     message: response_message
                   }
                 }
          end

        else
          if requrestcard.status == "R" and status == "C" do
            request_card_params = %{"status" => "C"}
            changeset = Requestcard.updatestatus_changeset(requrestcard, request_card_params)
            Repo.update(changeset)
            # Get Comman All Data

            commandata = Repo.one from cmn in Commanall, where: cmn.employee_id == ^requrestcard.employee_id,
                                                         select: %{
                                                           id: cmn.id,
                                                           commanall_id: cmn.accomplish_userid,
                                                           email_id: cmn.email_id,
                                                           as_login: cmn.as_login,
                                                         }

            mobiledata = Repo.one from m in Contacts, where: m.commanall_id == ^commandata.id and m.is_primary == "Y",
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
            employee = Repo.one from employee in Employee, where: employee.id == ^requrestcard.employee_id,
                                                           select: %{
                                                             first_name: employee.first_name,
                                                             last_name: employee.last_name
                                                           }

            card_type = if requrestcard.card_type == "V" do
              "virtual"
            else
              "physical"
            end

            # ALERTS
            data = %{
              :section => "cardrequest_rejected",
              :commanall_id => commandata.id,
              :card_type => card_type,
              :currency => requrestcard.currency,
              :employee_name => "#{employee.first_name} #{employee.last_name}"
            }
            #          AlertsController.sendEmail(data)
            #          AlertsController.sendNotification(data)
            #          AlertsController.sendSms(data)
            AlertsController.storeNotification(data)

            data = [
              %{
                section: "cardrequest_rejected",
                type: "E",
                email_id: commandata.email_id,
                data: %{
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              },
              %{
                section: "cardrequest_rejected",
                type: "S",
                contact_code: mobiledata.code,
                contact_number: mobiledata.contact_number,
                data: %{
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              },
              %{
                section: "cardrequest_rejected",
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
                  :card_type => card_type,
                  :currency => requrestcard.currency,
                  :employee_name => "#{employee.first_name} #{employee.last_name}"
                }
                # Content
              }
            ]
            V2AlertsController.main(data)
            json conn, %{status_code: "200", message: "Card Rejected."}
          else
            json conn, %{status_code: "4006", message: "card already approved."}
          end
        end
      else
        json conn,
             %{
               status_code: "4005",
               errors: %{
                 message: "You have to deposit some amount into Online Business Account to order a card."
               }
             }
      end
    end


  end

  @doc "Create Account"
  def create_account(conn, params) do
    unless map_size(params) == 0 do
      currency = params["currency"]

      username = params["username"]
      sec_password = params["sec_password"]
      request_id = params["request_id"]
      inserted_by = if !is_nil(request_id) or request_id != "", do: request_id, else: 99999

      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do

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
        commanall = Repo.get!(Commanall, params["id"])
        user_id = commanall.accomplish_userid
        company_id = commanall.company_id
        commanall_id = params["id"]

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
          longitude: accomplish_longitude
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
          last_account = if last_account_number == nil do
            1
          else
            last_account_number + 1
          end
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
            "inserted_by" => inserted_by
          }

          changeset_comacc = Companyaccounts.changeset(%Companyaccounts{}, companyaccount)

          case Repo.insert(changeset_comacc) do
            {:ok, _response} -> render(conn, ViolacorpWeb.SuccessView, "success.json", response: "Inserted All")
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

      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Company Create Account Manualy"
  def update_account(conn, params) do
    userid = params["id"]
    username = params["username"]
    sec_password = params["sec_password"]

    viola_user = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_user and sec_password == viola_password do

      company_detail = Repo.get_by(Commanall, id: userid)
      if company_detail != nil do
        company_id = company_detail.company_id
        accomplish_userid = company_detail.accomplish_userid

        if accomplish_userid != nil do

          check_account = Repo.one(
            from x in Companyaccounts, where: x.company_id == ^company_id, limit: 1, select: count(x.id)
          )

          if check_account == 0 do

            # Call Accomplish
            response = Accomplish.get_user(accomplish_userid)
            response_code = response["result"]["code"]
            response_message = response["result"]["friendly_message"]

            if response_code == "0000" do
              if is_nil(response["account"]) do
                json conn,
                     %{
                       status_code: "5001",
                       errors: %{
                         message: "Account not null in third party response."
                       }
                     }
              else
                check_status = Enum.each response["account"], fn response_account ->
                  accountType = response_account["info"]["name"]

                  # get only E-wallet type Account
                  if accountType == "E-Wallet" do

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

                    currencies_id = Repo.one from c in Currencies,
                                             where: c.currency_code == ^response_account["info"]["currency"],
                                             select: c.id

                    # Insert company account details
                    companyaccount = %{
                      "company_id" => company_id,
                      "currencies_id" => currencies_id,
                      "currency_code" => response_account["info"]["currency"],
                      "available_balance" => response_account["info"]["available_balance"],
                      "current_balance" => response_account["info"]["balance"],
                      "account_number" => last_account,
                      "accomplish_account_id" => response_account["info"]["id"],
                      "bin_id" => response_account["info"]["bin_id"],
                      "accomplish_account_number" => response_account["info"]["number"],
                      "expiry_date" => response_account["info"]["security"]["expiry_date"],
                      "source_id" => response_account["info"]["original_source_id"],
                      "status" => response_account["info"]["status"],
                      "inserted_by" => 1
                    }

                    comAccChangeset = Companyaccounts.changeset(%Companyaccounts{}, companyaccount)
                    case Repo.insert(comAccChangeset) do
                      {:ok, _response} ->
                        status_map = %{"status" => "A"}
                        updateStatus = Commanall.updateStatus(company_detail, status_map)
                        Repo.update(updateStatus)
                        true
                      {:error, _changeset} ->
                        false
                    end
                  end
                end
                case check_status do
                  :ok ->
                    render(
                      conn,
                      ViolacorpWeb.SuccessView,
                      "success.json",
                      response: "Company registration has been done."
                    )
                  :error ->
                    json conn,
                         %{
                           status_code: "4003",
                           errors: %{
                             message: "Something is missing"
                           }
                         }
                end
              end
            else
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
                   status_code: "4003",
                   errors: %{
                     message: "Account Already Found!"
                   }
                 }
          end

        else
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   message: "Company account not found on third party."
                 }
               }
        end
      else
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 message: "Company details not found!"
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

  @doc "Company Generate card for employee"
  def generate_card(conn, params) do
    %{"commanall_id" => commanid, "id" => company_id} = conn.assigns[:current_user]
    employee_id = params["employee_id"]
    currency = params["currency"]
    card_type = params["card_type"]

    # Check Clear Bank Account
    check_clearBank = Repo.get_by(Companybankaccount, company_id: company_id, status: "A")

    if is_nil(check_clearBank) do
      json conn,
           %{
             status_code: "4005",
             errors: %{
               message: "You does not have Online Business Account."
             }
           }
    else
      if Decimal.cmp("#{check_clearBank.balance}", Decimal.from_float(0.0)) == :gt  do

        # Get Comman All Data
        commandata = Repo.one from commanall in Commanall, where: commanall.employee_id == ^employee_id,
                                                           select: %{
                                                             id: commanall.id,
                                                             commanall_id: commanall.accomplish_userid
                                                           }
        if is_nil(commandata) do
          json conn,
               %{
                 status_code: "404",
                 errors: %{
                   message: "Enter correct employee id"
                 }
               }
        else

          if is_nil(commandata.commanall_id) do
            json conn,
                 %{
                   status_code: "404",
                   errors: %{
                     message: "Employee account is not active"
                   }
                 }
          else
            type = Application.get_env(:violacorp, :card_type)
            accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
            accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)

            fulfilment_config_id = if card_type == "V" do
              Application.get_env(:violacorp, :fulfilment_config_id_v)
            else
              Application.get_env(:violacorp, :fulfilment_config_id_p)
            end

            status = if card_type == "V", do: 1, else: 12

            bin_id = if currency == "USD" do
              Application.get_env(:violacorp, :usd_card_bin_id)
            else
              if currency == "EUR" do
                Application.get_env(:violacorp, :eur_card_bin_id)
              else
                Application.get_env(:violacorp, :gbp_card_bin_id)
              end
            end

            number = if currency == "USD" do
              Application.get_env(:violacorp, :usd_card_number)
            else
              if currency == "EUR" do
                Application.get_env(:violacorp, :eur_card_number)
              else
                Application.get_env(:violacorp, :gbp_card_number)
              end
            end

            request = %{
              type: type,
              bin_id: bin_id,
              number: number,
              currency: currency,
              user_id: commandata.commanall_id,
              status: status,
              fulfilment_config_id: fulfilment_config_id,
              fulfilment_notes: "create cards for user",
              fulfilment_reason: 1,
              fulfilment_status: 1,
              latitude: accomplish_latitude,
              longitude: accomplish_longitude,
              position_description: "",
              acceptance2: 2,
              acceptance: 1
            }

            response = Accomplish.create_card(request)

            response_code = response["result"]["code"]
            response_message = response["result"]["friendly_message"]

            if response_code == "0000" do

              currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                             select: c.id

              # Insert employee card details
              card_number = response["info"]["number"]
              last_digit = Commontools.lastfour(card_number)
              employeecard = %{
                "employee_id" => employee_id,
                "currencies_id" => currencies_id,
                "currency_code" => response["info"]["currency"],
                "last_digit" => "#{last_digit}",
                "available_balance" => response["info"]["available_balance"],
                "current_balance" => response["info"]["balance"],
                "accomplish_card_id" => response["info"]["id"],
                "bin_id" => response["info"]["bin_id"],
                "accomplish_account_number" => response["info"]["number"],
                "expiry_date" => response["info"]["security"]["expiry_date"],
                "activation_code" => response["info"]["security"]["activation_code"],
                "source_id" => response["info"]["original_source_id"],
                "status" => response["info"]["status"],
                "card_type" => card_type,
                "inserted_by" => commanid
              }


              changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
              case Repo.insert(changeset_comacc) do
                {:ok, _director} ->
                  getemployee = Repo.get!(Employee, employee_id)
                  [count_card] = Repo.all from d in Employeecards,
                                          where: d.employee_id == ^employee_id and (
                                            d.status == "1" or d.status == "4" or d.status == "12"),
                                          select: %{
                                            count: count(d.id)
                                          }
                  new_number = %{"no_of_cards" => count_card.count}
                  cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
                  Repo.update(cards_changeset)

                  # Update commanall card_requested
                  if card_type == "P" do
                    commanall_data = Repo.get!(Commanall, commandata.id)
                    card_request = %{"card_requested" => "Y"}
                    changeset_card_request = Commanall.changesetRequest(commanall_data, card_request)
                    Repo.update(changeset_card_request)
                  end
                  json conn, %{status_code: "200", message: "Generate Card."}
                {:error, changeset} ->
                  conn
                  |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
              end
            else
              json conn,
                   %{
                     status_code: "5001",
                     errors: %{
                       message: response_message
                     }
                   }
            end

          end
        end
      else
        json conn,
             %{
               status_code: "4005",
               errors: %{
                 message: "You have to deposit some amount into Online Business Account to order a card."
               }
             }
      end
    end

  end


  @doc "Adminh Generate card for employee"
  def admin_generate_card(conn, params) do

    unless map_size(params) == 0 do
      sec_password = params["sec_password"]
      username = params["username"]
      admin_id = if !is_nil(params["request_id"]), do: params["request_id"], else: 99999
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)

      if username == viola_user and sec_password == viola_password do
        employee_id = params["employeeId"]
        currency = params["currency"]
        card_type = params["card_type"]
        description = params["description"]

        # Get Comman All Data
        commandata = Repo.one from commanall in Commanall, where: commanall.employee_id == ^employee_id,
                                                           select: %{
                                                             id: commanall.id,
                                                             commanall_id: commanall.accomplish_userid
                                                           }

        if is_nil(commandata) do
          json conn,
               %{
                 status_code: "404",
                 errors: %{
                   message: "Enter correct employee id"
                 }
               }
        end

        if is_nil(commandata.commanall_id) do
          json conn,
               %{
                 status_code: "404",
                 errors: %{
                   message: "Employee account is not active"
                 }
               }
        end

        type = Application.get_env(:violacorp, :card_type)
        accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
        accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)

        fulfilment_config_id = if card_type == "V" do
          Application.get_env(:violacorp, :fulfilment_config_id_v)
        else
          Application.get_env(:violacorp, :fulfilment_config_id_p)
        end

        status = if card_type == "V" do
          1
        else
          12
        end

        bin_id = if currency == "USD" do
          Application.get_env(:violacorp, :usd_card_bin_id)
        else
          if currency == "EUR" do
            Application.get_env(:violacorp, :eur_card_bin_id)
          else
            Application.get_env(:violacorp, :gbp_card_bin_id)
          end
        end

        number = if currency == "USD" do
          Application.get_env(:violacorp, :usd_card_number)
        else
          if currency == "EUR" do
            Application.get_env(:violacorp, :eur_card_number)
          else
            Application.get_env(:violacorp, :gbp_card_number)
          end
        end

        request = %{
          type: type,
          bin_id: bin_id,
          number: number,
          currency: currency,
          user_id: commandata.commanall_id,
          status: status,
          fulfilment_config_id: fulfilment_config_id,
          fulfilment_notes: "create cards for user",
          fulfilment_reason: 1,
          fulfilment_status: 1,
          latitude: accomplish_latitude,
          longitude: accomplish_longitude,
          position_description: "",
          acceptance2: 2,
          acceptance: 1
        }

        response = Accomplish.create_card(request)
        response_code = response["result"]["code"]
        response_message = response["result"]["friendly_message"]

        if response_code == "0000" do

          currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                         select: c.id

          # Insert employee card details
          card_number = response["info"]["number"]
          last_digit = Commontools.lastfour(card_number)
          employeecard = %{
            "employee_id" => employee_id,
            "currencies_id" => currencies_id,
            "currency_code" => response["info"]["currency"],
            "last_digit" => "#{last_digit}",
            "available_balance" => response["info"]["available_balance"],
            "current_balance" => response["info"]["balance"],
            "accomplish_card_id" => response["info"]["id"],
            "bin_id" => response["info"]["bin_id"],
            "accomplish_account_number" => response["info"]["number"],
            "expiry_date" => response["info"]["security"]["expiry_date"],
            "activation_code" => response["info"]["security"]["activation_code"],
            "source_id" => response["info"]["original_source_id"],
            "status" => response["info"]["status"],
            "card_type" => card_type,
            "reason" => description,
            "inserted_by" => admin_id
          }

          changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
          case Repo.insert(changeset_comacc) do
            {:ok, _director} ->
              getemployee = Repo.get!(Employee, employee_id)
              [count_card] = Repo.all from d in Employeecards,
                                      where: d.employee_id == ^employee_id and (
                                        d.status == "1" or d.status == "4" or d.status == "12"),
                                      select: %{
                                        count: count(d.id)
                                      }
              new_number = %{"no_of_cards" => count_card.count}
              cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
              Repo.update(cards_changeset)

              # Update commanall card_requested
              if card_type == "P" do
                commanall_data = Repo.get!(Commanall, commandata.id)
                card_request = %{"card_requested" => "Y"}
                changeset_card_request = Commanall.changesetRequest(commanall_data, card_request)
                Repo.update(changeset_card_request)
              end
              json conn, %{status_code: "200", message: "Generate Card."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
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
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  @doc "Enable or Desable Card"
  def admin_deactive_card(conn, params) do
    unless map_size(params) == 0 do

      username = params["username"]
      sec_password = params["sec_password"]

      viola_user = System.get_env("VC_VIOLA_USERNAME")
      viola_password = System.get_env("VC_VIOLA_PASSWORD")

      if username == viola_user and sec_password == viola_password do

        if params["new_status"] == "4" or params["new_status"] == "1" do
          get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])

          # Call to accomplish
          request = %{urlid: get_card.accomplish_card_id, status: params["new_status"]}
          response = Accomplish.activate_deactive_card(request)

          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do
            changeset = %{status: params["new_status"], reason: params["reason"], change_status: "A"}
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
                 status_code: "4003",
                 errors: %{
                   message: "#{params["new_status"]} not accepted."
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Admin Block Card"
  def admin_block_card(conn, params) do
    unless map_size(params) == 0 do

      username = params["username"]
      sec_password = params["sec_password"]

      viola_user = System.get_env("VC_VIOLA_USERNAME")
      viola_password = System.get_env("VC_VIOLA_PASSWORD")

      if username == viola_user and sec_password == viola_password do

        get_card = Repo.get_by!(Employeecards, id: params["cardid"], employee_id: params["employee_id"])
        if get_card.status == "4" do

          changeset = %{status: "5", reason: params["reason"], change_status: "A"}
          new_changeset = Employeecards.changesetStatus(get_card, changeset)
          if new_changeset.valid? do

            get_employee = Repo.get_by(Employee, id: params["employee_id"])
            get_company = Repo.get_by(Commanall, company_id: get_employee.company_id)
            get_account = Repo.get_by!(
              Companyaccounts,
              company_id: get_employee.company_id,
              currency_code: get_card.currency_code
            )
            check_status = if get_card.available_balance > Decimal.new(0.00) do

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
      else
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Get Success Transaction List"
  def get_success_transaction(conn, params) do
    unless map_size(params) == 0 do
      user_id = params["user_id"]
      account_id = params["account_id"]
      from_date = params["from_date"]
      to_date = params["to_date"]
      #    status = params["status"]
      start_index = params["start_index"]
      page_size = params["page_size"]

      request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&start_index=#{
        start_index
      }&page_size=#{page_size}"

      response = Accomplish.get_success_transaction(request)

      json conn, response
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Get Pending Transaction List"
  def get_pending_transaction(conn, params) do
    unless map_size(params) == 0 do
      user_id = params["user_id"]
      account_id = params["account_id"]
      from_date = params["from_date"]
      to_date = params["to_date"]
      status = params["status"]
      start_index = params["start_index"]
      page_size = params["page_size"]

      request = "?user_id=#{user_id}&account_id=#{account_id}&from_date=#{from_date}&to_date=#{to_date}&status=#{
        status
      }&start_index=#{start_index}&page_size=#{page_size}"

      response = Accomplish.get_success_transaction(request)

      json conn, response
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "Update Trust Level Manualy"
  def updateTrustLevel(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        commanall_id = params["commanall_id"]

        userdata = Repo.one from c in Commanall, where: c.id == ^commanall_id and not is_nil(c.accomplish_userid),
                                                 select: c
        if userdata != nil do
          user_id = userdata.accomplish_userid
          response = Accomplish.get_user(user_id)
          response_code = response["result"]["code"]
          response_message = response["result"]["friendly_message"]

          if response_code == "0000" do

            trust_level = response["security"]["trust_level"]
            partytrust_level = %{trust_level: trust_level}
            changeset_party = Commanall.updateTrustLevel(userdata, partytrust_level)

            case Repo.update(changeset_party) do
              {:ok, _data} ->
                json conn, %{status_code: "200", message: "Trust Level Updated."}
              {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
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
                 status_code: "4002",
                 errors: %{
                   message: "Invalid Id"
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  def blockUnBlockCompany(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        commanall_id = params["commanall_id"]

        company_data = Repo.one from c in Commanall, where: c.id == ^commanall_id and not is_nil(c.accomplish_userid),
                                                     select: %{
                                                       company_id: c.company_id
                                                     }
        if !is_nil(company_data) do

          get_employees = Repo.one from e in Employee, where: e.company_id == ^company_data.company_id,
                                                       select: %{
                                                         ids: fragment("GROUP_CONCAT(?)", e.id)
                                                       }

          if !is_nil(get_employees) do

            # call card block un block
            load_params = %{
              "worker_type" => "block_unblock",
              "employee_ids" => get_employees.ids,
              "new_status" => params["new_status"],
              "reason" => params["reason"]
            }
            Exq.enqueue(Exq, "cards", Violacorp.Workers.V1.Cards, [load_params], max_retries: 10)

            case params["new_status"] do
              "1" -> json conn, %{status_code: "200", message: "Cards Activate Successfully."}
              "4" -> json conn, %{status_code: "200", message: "Cards block Successfully."}
            end
          else
            json conn, %{status_code: "200", message: "Cards block Done."}
          end
        else
          json conn,
               %{
                 status_code: "4003",
                 errors: %{
                   message: "Company Does not Activated"
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
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def director_verify_GBG(conn, params) do

    username = params["username"]
    password = params["sec_password"]
    viola_username = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_username and password == viola_password do
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
        dob = get_director.date_of_birth
        if !is_nil(dob) do
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
            if check_data["status"] == "A" do
              update_data = %{
                reference_id: check_data["authenticate_id"],
                status: check_data["status"],
                fourstop_response: check_data["request_response"]
              }
              changeset = Kycdirectors.updateGBGResponse(kyc_document, update_data)
              Repo.update(changeset)
              json conn, %{status_code: "200", message: "Success"}
            else
              update_data = %{
                reference_id: check_data["authenticate_id"],
                status: check_data["status"],
                fourstop_response: check_data["request_response"]
              }
              changeset = Kycdirectors.updateGBGResponse(kyc_document, update_data)
              Repo.update(changeset)
              message = if check_data["status"] == "RF", do: "Kyc refer by GBG", else: "Kyc rejected by GBG"
              json conn, %{status_code: "5008", message: message}
            end
        else
          json conn, %{status_code: "5008", message: "Director birth date not found."}
        end
      else
        json conn, %{status_code: "5008", message: "Id proof not uploaded."}
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

  @doc"employee gbg verification by admin"
  def employeeGBGVerify(conn, params) do

    username = params["username"]
    password = params["sec_password"]
    viola_username = Application.get_env(:violacorp, :username)
    viola_password = Application.get_env(:violacorp, :password)

    if username == viola_username and password == viola_password do
      commanall_id = params["commanall_id"]
      response = employee_verify_GBG(commanall_id)
      if response["status"] == "200" do
        json conn, %{status_code: response["status"], message: response["message"]}
      else
        json conn, %{status_code: response["status"], message: response["message"]}
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

  def updateDirectorEmployee(conn, _params) do
    getDirector = Repo.all from d in Directors, where: d.as_employee == ^"Y" and not is_nil(d.email_id), select: d
    if !is_nil(getDirector) do
      Enum.each getDirector, fn director ->
        director_email = director.email_id
        director_id = director.id
        commonall = Repo.one from c in Commanall, where: c.email_id == ^director_email and not is_nil(c.employee_id),
                                                  select: c
        if !is_nil(commonall) do
          employee = Repo.one from e in Employee, where: e.id == ^commonall.employee_id, select: e
          employee_id = employee.id
          employee_map = %{"director_id" => director_id}
          director_map = %{"employee_id" => employee_id}
          chnageset_employee = Employee.changesetDirector(employee, employee_map)
          chnageset_director = Directors.changesetEmployee(director, director_map)
          Repo.update(chnageset_employee)
          Repo.update(chnageset_director)
        else
          #            IO.inspect(director_email)
        end
      end
    end
    text conn, "done"
  end

  def checkDirectorEmail(conn, _params) do
    getDirector = Repo.all from d in Directors,
                           where: d.as_employee == ^"Y" and is_nil(d.email_id),
                           left_join: contact in assoc(d, :contactsdirectors),
                           select: %{
                             director_id: d.id,
                             contact_number: contact.contact_number,
                             contact_id: contact.id
                           }
    json conn, getDirector
  end

  def checkExistDirector(conn, _params) do
    getDirector = Repo.all from d in Directors, where: d.as_employee == ^"Y" and not is_nil(d.email_id), select: d
    if !is_nil(getDirector) do
      map = Stream.with_index(getDirector, 1)
            |> Enum.reduce(
                 %{},
                 fn ({v, k}, director) ->
                   director_email = v.email_id
                   director_id = v.id
                   commonall = Repo.one from c in Commanall,
                                        where: c.email_id == ^director_email and not is_nil(c.employee_id), select: c
                   if is_nil(commonall) do
                     response_emp = %{email_id: director_email, id: director_id}
                     Map.put(director, k, response_emp)
                   else
                     Map.put(director, k, %{})
                   end
                 end
               )
      json conn, map
    end

  end

  def showDirectorEmployee(conn, _params) do
    getDirector = Repo.all from d in Directors, where: d.as_employee == ^"Y" and not is_nil(d.email_id), select: d
    map = Stream.with_index(getDirector, 1)
          |> Enum.reduce(
               %{},
               fn ({v, k}, director) ->
                 director_email = v.email_id
                 director_id = v.id
                 commonall = Repo.one from c in Commanall,
                                      where: c.email_id == ^director_email and not is_nil(c.employee_id), select: c
                 response_emp = %{email_id: director_email, id: director_id}
                 if !is_nil(commonall) do
                   Map.put(director, k, response_emp)
                 else
                   Map.put(director, "not_exist_email", response_emp)
                 end
               end
             )
    json conn, map
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

  def companyUploadIdProof(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
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
                end

                file_name = case id_document.documenttype_id do
                  19 -> "Driving Licence"
                  10 -> "Passport"
                  9 -> "National ID"
                end

                request = %{
                  worker_type: "company_id_proof",
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
                  request_id: request_id,
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
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def companyUploadAddressProof(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
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
            address_document = Repo.one(from ak in Kycdirectors, where: ak.directors_id == ^director_id and ak.status == "A" and ak.type == "A",
                                                                 select: %{
                                                                   id: ak.id,
                                                                   address_file_location: ak.file_location,
                                                                   address_documenttype_id: ak.documenttype_id
                                                                 })

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
                end

                document_name = case address_document.address_documenttype_id do
                  1 -> "Utility Bill"
                  2 -> "Council Tax"
                  21 -> "Driving Licence"
                end

                request = %{
                  worker_type: "company_address_proof",
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
                  request_id: request_id,

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
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end

    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end


  def employeeUploadAddressProof(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
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
                end

                document_name = case address_document.address_documenttype_id do
                  1 -> "Utility Bill"
                  2 -> "Council Tax"
                  21 -> "Driving Licence"
                end

                request = %{
                  worker_type: "employee_address_proof",
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
                  request_id: request_id,
                }
                Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
                json conn, %{ status_code: "200", message: "We are processing employee document."}
              else
                json conn, %{status_code: "4004", errors: %{message: "Employee document not found."}}
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
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def employeeUploadIdProof(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
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
              end

              file_name = case id_document.documenttype_id do
                19 -> "Driving Licence"
                10 -> "Passport"
                9 -> "National ID"
              end

              request = %{
                worker_type: "employee_id_proof",
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
                request_id: request_id,
              }
              Exq.enqueue_in(Exq, "upload_document", 15, Violacorp.Workers.V1.UploadDocument, [request])
              json conn, %{ status_code: "200", message: "We are processing employee document."}
            else
              json conn, %{status_code: "4004", errors: %{message: "Employee document not found."}}
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
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def employeeCardGenerate(conn, params) do
    unless map_size(params) == 0 do

      sec_password = params["sec_password"]
      username = params["username"]
      commanall_id = params["commanall_id"]
      request_id = params["request_id"]
      viola_user = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_user and sec_password == viola_password do
        employee_detail = Repo.get_by(Commanall, id: commanall_id)
        if !is_nil(employee_detail) do
          employee = Repo.get(Employee, employee_detail.employee_id)
          # Check Clear Bank Account
          check_clearBank = Repo.get_by(Companybankaccount, company_id: employee.company_id, status: "A")

          createCard = if !is_nil(check_clearBank) do
            if Decimal.cmp("#{check_clearBank.balance}", Decimal.from_float(0.0)) == :gt  do
              "Yes"
            else
              "No"
            end
          else
            "No"
          end
          request = %{
            "worker_type" => "physical_card",
            "user_id" => employee_detail.accomplish_userid,
            "commanall_id" => commanall_id,
            "employee_id" => employee_detail.employee_id,
            "request_id" => request_id,
          }

          if createCard == "Yes" do
            # Create Physical Card
            #        Exq.enqueue(Exq, "physical_card", PhysicalCard, [request], max_retries: 1)
            Exq.enqueue_in(Exq, "cards", 15, Violacorp.Workers.V1.Cards, [request])
          end
          json conn, %{ status_code: "200", message: "We are processing to generate physical card."}
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
        json conn,
             %{
               status_code: "402",
               errors: %{
                 message: "You have not permission to any update, Please contact to administrator."
               }
             }
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

end