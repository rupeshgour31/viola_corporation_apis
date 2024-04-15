defmodule Violacorp.Libraries.Accomplish do

  alias Violacorp.Repo
  alias Violacorp.Schemas.Settings
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Thirdpartylogs
  require Logger
  @moduledoc "Accomplish Library"

  # Generate Token
  def get_token do
    today = DateTime.utc_now
    today_date = [today.year, today.month, today.day]
                 |> Enum.map(&to_string/1)
                 |> Enum.map(&String.pad_leading(&1, 2, "0"))
                 |> Enum.join("-")

    url = "#{Application.get_env(:violacorp, :acc_live_url)}oauth/token"
    header = %{"Content-Type" => "application/x-www-form-urlencoded"}
    body = %{
      "grant_type" => Application.get_env(:violacorp, :acc_grant_type),
      "language" => Application.get_env(:violacorp, :acc_language),
      "password" => Application.get_env(:violacorp, :acc_password),
      "program_id" => Application.get_env(:violacorp, :acc_program_id),
      "user_name" => Application.get_env(:violacorp, :acc_username)
    }

    check_token = Repo.get_by(Settings, category: "token")
    if is_nil(check_token) do
      response = post_http(url, header, URI.encode_query(body))
      settings_params = %{
        category: "token",
        access_token: response["access_token"],
        token_type: response["token_type"],
        generate_date: today
      }
      changeset = Settings.changeset(%Settings{}, settings_params)
      Repo.insert(changeset)
      _response_token = %{"access_token" => response["access_token"], "token_type" => response["token_type"]}
    else
      db_date = check_token.generate_date
      exist_date = [db_date.year, db_date.month, db_date.day]
                   |> Enum.map(&to_string/1)
                   |> Enum.map(&String.pad_leading(&1, 2, "0"))
                   |> Enum.join("-")
      if today_date == exist_date do
        _response_token = %{"access_token" => check_token.access_token, "token_type" => check_token.token_type}
      else
        response = post_http(url, header, URI.encode_query(body))
        settings_params = %{
          access_token: response["access_token"],
          token_type: response["token_type"],
          generate_date: today
        }
        changeset = Settings.changeset(check_token, settings_params)
        Repo.update(changeset)
        #        case Repo.update(changeset) do
        #          {:ok, _response} ->IO.inspect("changed")
        #          {:error, changeset} ->IO.inspect(changeset)
        #        end
        _response_token = %{"access_token" => response["access_token"], "token_type" => response["token_type"]}
      end
    end
  end

  # Create New User on Accomplish
  def register(params, user_id) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "address" => %{
        "address_line1" => params.address_line1,
        "address_line2" => params.address_line2,
        "city_town" => params.city_town,
        "country_code" => params.country_code,
        "postal_zip_code" => params.postal_zip_code,
        "state_region" => params.state_region,
        "verification_status" => "1"
      },
      "currency" => [%{"code" => params.code}],
      #      "custom_field" => %{
      #        "acceptance" => "1",
      #        "acceptance2" => "2"
      #      },
      "email" => [
        %{
          "address" => params.address,
          "is_primary" => params.is_primary,
          "verification_status" => "1"
        }
      ],
      "geo_coordinates" => %{
        "latitude" => params.latitude,
        "longitude" => params.longitude,
        "position_description" => params.position_description
      },
      "personal_info" => %{
        "date_of_birth" => params.date_of_birth,
        "first_name" => params.first_name,
        "gender" => params.gender,
        "job_title" => params.job_title,
        "last_name" => params.last_name,
        "nick_name" => params.nick_name,
        "photo" => "",
        "title" => params.title,
        "verification_status" => "1"
      },
      "phone" => [
        %{
          "country_code" => params.country_code,
          "is_primary" => "1",
          "number" => params.number,
          "type" => "1",
          "verification_status" => "0"
        }
      ],
      "preferences" => %{
        "enable_device_authentication" => "0",
        "enable_email_notification" => "1",
        "enable_facebook_account" => "1",
        "enable_promotion_notification" => "1",
        "enable_push_notification" => "1",
        "enable_sms_notification" => "1",
        "preferred_language_code" => "en",
        "time_zone" => params.time_zone
      },
      "security" => %{
        "password" => params.password,
        "secret_answer_1" => params.secret_answer_1,
        "secret_answer_2" => params.secret_answer_2,
        "secret_question_1" => params.secret_question_1,
        "secret_question_2" => params.secret_question_2,
        "security_code" => params.security_code,
        "status" => params.status,
        "trust_level" => 3
      },
      "terms_conditions" => %{
        "acceptance" => "1"
      },
      "custom_field" => %{
        "gbg" => params.gbg_response,
      },
      "validate" => 0
    }

    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    request_id = if Map.has_key?(params, :request_id), do: params.request_id, else: user_id
    # log for request and response
    third_party_log = %{
      commanall_id: "#{user_id}",
      section: "violaTeam#{source_id} ~ Registration",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: request_id
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Create New User on Accomplish
  def create_identification(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/identification/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "identification" => [%{
        "type" => "0",
        "country_of_issue" => Application.get_env(:violacorp, :accomplish_country_code),
        "country_of_residence" => Application.get_env(:violacorp, :accomplish_country_code),
        "issue_date" => params.issue_date,
        "expiry_date" => params.expiry_date,
        "number" => params.number,
        "verification_status" => "1"
        # params.verification_status
      }]
    }
    response = post_http(url, header, Poison.encode!(body))

    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    #    comman_data = Repo.get_by(Commanall, accomplish_userid: user_id)
    commanall_id = params.commanall_id
    third_party_log = %{
      commanall_id: commanall_id,
      section: "violaTeam#{source_id} ~ Create Identification",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Create New User on Accomplish
  def upload_identification(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/identification/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "identification" => [%{
        "type" => params.type,
        "country_of_issue" => Application.get_env(:violacorp, :accomplish_country_code),
        "country_of_residence" => Application.get_env(:violacorp, :accomplish_country_code),
        "issue_date" => params.issue_date,
        "expiry_date" => params.expiry_date,
        "number" => params.number,
        "verification_status" => "1"
        # params.verification_status
      }]
    }

    Logger.warn "Acc Identification Request: #{~s(#{Poison.encode!(body)})}"
    #    Logger.warn "Identification Request: #{body}"
    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    #    comman_data = Repo.get_by(Commanall, accomplish_userid: user_id)
    commanall_id = params.commanall_id
    request_id = params.request_id
    third_party_log = %{
      commanall_id: commanall_id,
      section: "violaTeam#{source_id} ~ Create Identification",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: request_id
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Create New User on Accomplish
  def create_document(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/document/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "first_name" => params.first_name,
        "last_name" => params.last_name,
        "entity" => params.entity,
        "type" => params.type,
        "language" => "en",
        "subject" => params.subject,
        "notes" => "User Identity",
      },
      "attachment" => [%{
        "file_name" => params.file_name,
        "file_extension" => params.file_extension,
        "content" => params.content
      }],
      "validate" => "0"
    }
    new_map = %{
      "attachment" => [%{
        "file_name" => params.file_name,
        "file_extension" => params.file_extension,
        "content" => "document content #{params.document_id}"
      }]
    }
    logBody = Map.merge(body, new_map)
    Logger.warn "Acc Upload Document Request: #{~s(#{Poison.encode!(logBody)})}"

    response = post_http(url, header, Poison.encode!(body))

    response_code = response["result"]["code"]
    if response_code == "0000" do
      Logger.warn "Acc Upload Document Response: #{~s(#{Poison.encode!(response["result"])})}"
    else
      Logger.warn "Acc Upload Document Response: #{~s(#{Poison.encode!(response)})}"
    end

    res_status = if response_code == "0000", do: "S", else: "F"

    response_data = if response_code == "0000", do: response["result"], else: response

    doc_type = if (params.entity == 25), do: "Id Proof", else: "Address Proof"
    request_id = if Map.has_key?(params, :request_id), do: params.request_id, else: params.commanall_id
    request = Map.merge(body, new_map)

    commanall_id = params.commanall_id
    third_party_log = %{
      commanall_id: commanall_id,
      section: "violaTeam#{source_id} ~ #{doc_type}",
      method: "POST",
      request: Poison.encode!(request),
      response: Poison.encode!(response_data),
      status: res_status,
      inserted_by: request_id
    }
    changeset_doc = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset_doc)

    _output = response

  end

  # Create New User on Accomplish
  def upload_director_document(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/document/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "first_name" => params.first_name,
        "last_name" => params.last_name,
        "entity" => params.entity,
        "type" => params.type,
        "language" => "en",
        "subject" => "#{params.subject} - #{params.document_id}",
        "notes" => "Director - #{params.director_id} - #{params.subject}",
      },
      "attachment" => [%{
        "file_name" => params.file_name,
        "file_extension" => params.file_extension,
        "content" => params.content
      }],
      "validate" => "0"
    }
    _response = post_http(url, header, Poison.encode!(body))

    #    response_code = response["result"]["code"]
    #    response_data = if response_code == "0000", do: response["result"], else: response["result"]
  end

  # Company KYB Upload
  def upload_companyKyb_document(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/document/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "first_name" => params.first_name,
        "last_name" => params.last_name,
        "entity" => params.entity,
        "type" => params.type,
        "language" => "en",
        "subject" => "#{params.subject} - #{params.document_id}",
        "notes" => "KYB - #{params.document_id} - #{params.subject}",
      },
      "attachment" => [%{
        "file_name" => params.file_name,
        "file_extension" => params.file_extension,
        "content" => params.content
      }],
      "validate" => "0"
    }
    _response = post_http(url, header, Poison.encode!(body))

  end

  # Get User Details
  def get_user(params) do

    #    otp_mode = Application.get_env(:violacorp, :otp_mode)
    #    _response = if otp_mode == "live" do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/#{params}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    response = gets_http(url, header)

    _output = response
    #    else
    #      %{
    #        "result" => %{
    #          "code" => "4003",
    #          "friendly_message" => "Manually, Stopped this api"
    #        }
    #      }
    #    end

  end

  # Create card
  def create_card(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "type" => params.type,
        "bin_id" => params.bin_id,
        "number" => params.number,
        "currency" => params.currency,
        "user_id" => params.user_id,
        "status" => params.status
      },
      #      "options" => %{
      #        "fulfilment" => %{
      #          "info" => %{
      #            "fulfilment_config_id" => params.fulfilment_config_id,
      #            "fulfilment_notes" => params.fulfilment_notes,
      #            "fulfilment_reason" => params.fulfilment_reason
      #          }
      #        }
      #      },
      "geo_coordinates" => %{
        "latitude" => params.latitude,
        "longitude" => params.longitude
      },
      "custom_field" => %{
        "acceptance2" => params.acceptance2,
        "acceptance" => params.acceptance
      }
    }

    response = post_http(url, header, Poison.encode!(body))

    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end

    # log for request and response
    comman_data = Repo.get_by(Commanall, accomplish_userid: params.user_id)
    request_id = if Map.has_key?(params, :request_id), do: params.request_id, else: comman_data.id
    third_party_log = %{
      commanall_id: comman_data.id,
      section: "violaTeam#{source_id} ~ Create Card",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: request_id
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Create Account
  def create_account(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "type" => params.type,
        "bin_id" => params.bin_id,
        "number" => params.number,
        "currency" => params.currency,
        "user_id" => params.user_id
      },
      "geo_coordinates" => %{
        "latitude" => params.latitude,
        "longitude" => params.longitude,
        "position_description" => ""
      },
      "custom_field" => %{
        "acceptance2" => 2,
        "acceptance" => 1
      }
    }

    response = post_http(url, header, Poison.encode!(body))

    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end

    # log for request and response
    #    comman_data = Repo.get_by(Commanall, accomplish_userid: params.user_id)
    commanall_id = params.commanall_id
    request_by = if !is_nil(params.request_id), do: params.request_id, else: params.commanall_id
    third_party_log = %{
      commanall_id: commanall_id,
      section: "violaTeam#{source_id} ~ Create Account",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: request_by
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Create Account
  def create_currency(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    user_id = params.user_id
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/currency/#{user_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "currency" => [%{"code" => params.currency}]
    }

    post_http(url, header, Poison.encode!(body))

  end

  # Get Card Details
  def get_card(params) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    _response = if otp_mode == "live" do
      token = get_token()
      access_token = token["access_token"]
      token_type = token["token_type"]
      source_id = random_string(6)

      auth = "#{token_type} #{access_token}"
      url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account/#{params}"
      header = %{
        "authorization" => auth,
        "cache-control" => "no-cache",
        "content-type" => "application/json",
        "language" => "en",
        "source_id" => "violaTeam#{source_id}",
        "time_zone" => "UTC +00:00",
        "show_sensitive_data" => "1"
      }
      gets_http(url, header)
    else
      %{
        "result" => %{
          "code" => "4003",
          "friendly_message" => "Manually, Stopped this api"
        }
      }
    end

  end

  # Get Account Details
  def get_account(params) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    _response = if otp_mode == "live" do
      token = get_token()
      access_token = token["access_token"]
      token_type = token["token_type"]
      source_id = random_string(6)

      auth = "#{token_type} #{access_token}"
      url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account/info/#{params}"
      header = %{
        "authorization" => auth,
        "cache-control" => "no-cache",
        "content-type" => "application/json",
        "language" => "en",
        "source_id" => "violaTeam#{source_id}",
        "time_zone" => "UTC +00:00",
        "show_sensitive_data" => "1"
      }

      gets_http(url, header)
    else
      %{
        "result" => %{
          "code" => "4003",
          "friendly_message" => "Manually, Stopped this api"
        }
      }
    end
  end

  # Upload Document
  def upload_document(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/document/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "info" => %{
        "first_name" => params.first_name,
        "last_name" => params.last_name,
        "type" => params.type,
        "language" => params.language,
        "status" => params.status,
        "subject" => params.subject,
        "notes" => params.notes,
        "entity" => params.entity,
        "entity_ID" => params.entity_ID
      },
      "attachment" => [
        %{
          "file_name" => params.file_name,
          "file_extension" => params.file_extension,
          "content" => params.content,
        }
      ],
      "geo_coordinates" => %{
        "latitude" => params.latitude,
        "longitude" => params.latitude,
        "position_description" => params.position_description
      },
      "custom_field" => %{
        "custom notes" => params.custom_notes
      },
      "validate" => "0"
    }
    post_http(url, header, Poison.encode!(body))

  end

  # Load Money
  def load_money(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/transaction"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "info" => %{
        "type" => params.type,
        "notes" => params.notes,
        "amount" => params.amount,
        "currency" => params.currency
      },
      "account" => %{
        "info" => %{
          "id" => params.account_id
        }
      }

    }

    post_http(url, header, Poison.encode!(body))

  end

  # Move Funds
  def move_funds(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/transaction"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "info" => %{
        "type" => params.type,
        "amount" => params.amount,
        "currency" => params.currency
      },
      "account" => %{
        "info" => %{
          "id" => params.account_id
        }
      },
      "transfer" => %{
        "account_info" => %{
          "id" => params.card_id
        }
      },
      "validate" => params.validate
    }

    post_http(url, header, Poison.encode!(body))

  end

  # General Debit for Admin Account
  def get_fee do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/29829"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    gets_http(url, header)

  end

  # Get CVV Details for Card
  def get_cvv(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account/info/#{params}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    gets_http(url, header)

  end

  # Activate Card
  def activate_card(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/#{params}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    gets_http(url, header)

  end

  # Block Card
  def block_card(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "info" => %{
        "status" => params.status
      }
    }
    put_http(url, header, Poison.encode!(body))

  end

  # Enable or Desable Card
  def activate_deactive_card(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/account/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "info" => %{
        "status" => params.status
      }
    }
    put_http(url, header, Poison.encode!(body))

  end

  # change address
  def change_address(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/address/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "address" => %{
        "address_line1" => params.address_line1,
        "address_line2" => params.address_line2,
        "city_town" => params.city_town,
        "country_code" => params.country_code,
        "postal_zip_code" => params.postal_zip_code,
        "state_region" => params.state_region,
        "verification_status" => "1"
      }
    }
    response = put_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Update Address",
      method: "PUT",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # create phone
  def create_phone(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/phone/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "phone" => [
        %{
          "country_code" => params.country_code,
          "is_primary" => params.is_primary,
          "number" => params.number,
          "type" => "1",
          "verification_status" => "1"
        }
      ]
    }
    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Create Mobile",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # create email
  def create_email(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/email/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "email" => [
        %{
          "address" => params.address,
          "is_primary" => params.is_primary,
          "verification_status" => "1"
        }
      ]
    }
    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Create Email",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # delete phone
  def delete_phone(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/phone/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "phone" => [%{
        "id" => params.id
      }]

    }
    response = delete_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Delete Phone",
      method: "DELETE",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # delete email
  def delete_email(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/email/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "email" => [%{
        "id" => params.id
      }]

    }
    response = delete_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Delete Email",
      method: "DELETE",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: 99999
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)
    _output = response
  end

  # Get Success Transaction List
  def get_success_transaction(params) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    _response = if otp_mode == "live" do
      token = get_token()
      access_token = token["access_token"]
      token_type = token["token_type"]
      source_id = random_string(6)

      auth = "#{token_type} #{access_token}"
      url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/transaction/inquiry#{params}"
      header = %{
        "authorization" => auth,
        "cache-control" => "no-cache",
        "content-type" => "application/json",
        "language" => "en",
        "source_id" => "violaTeam#{source_id}",
        "time_zone" => "UTC +00:00"
      }
      gets_http(url, header)
    else
      %{
        "result" => %{
          "code" => "4003",
          "friendly_message" => "Manually, Stopped this api"
        }
      }
    end

  end

  # Get Pending Transaction List
  def get_pending_transaction(params) do
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    _response = if otp_mode == "live" do
      token = get_token()
      access_token = token["access_token"]
      token_type = token["token_type"]
      source_id = random_string(6)

      auth = "#{token_type} #{access_token}"
      url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/transaction/inquiry#{params}"
      header = %{
        "authorization" => auth,
        "cache-control" => "no-cache",
        "content-type" => "application/json",
        "language" => "en",
        "source_id" => "violaTeam#{source_id}",
        "time_zone" => "UTC +00:00"
      }
      gets_http(url, header)
    else
      %{
        "result" => %{
          "code" => "4003",
          "friendly_message" => "Manually, Stopped this api"
        }
      }
    end

  end

  # CREATE GROUP {http://api.nuvopay.com/Service/v1/group}
  def create_group(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/group/"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "info" => %{
        "user_id" => params.user_id,
        "id" => "0",
        "program_id" => "0",
        "type" => params.type,
        "status" => params.status,
        "code" => params.code,
        "name" => params.name
      },
      "details" => %{
        "address" => [%{
          "type" => params.address_type,
          "is_billing" => params.is_billing,
          "address_line1" => params.address_line1,
          "address_line2" => params.address_line2,
          "postal_zip_code" => params.postal_zip_code,
          "city_town" => params.city_town,
          "country_code" => params.country_code
        }],
        "phone" => [%{
          "type" => params.phone_type,
          "country_code" => params.country_code,
          "number" => params.number,
          "verification_status" => params.verification_status
        }],
        "email" => [%{
          "type" => params.email_type,
          "address" => params.address,
          "is_primary" => params.is_primary
        }]
      },
      "validate" => "0"
    }

    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.commanid}",
      section: "violaTeam#{source_id} ~ Create Group",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: "#{params.commanid}"
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response


  end


  # Add Group User {http://api.nuvopay.com/Service/v1/group/user/group_id}
  def create_group_member(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/group/user/#{params.group_id}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    body = %{
      "group_user" => [%{
        "user_id" => params.user_id,
        "role" => params.role,
        "membership_status" => params.membership_status
      }],
      "validate" => "0"
    }

    response = post_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000" do
      "S"
    else
      "F"
    end
    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.commanid}",
      section: "violaTeam#{source_id} ~ Create Group Member",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: "#{params.commanid}"
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response

  end

  # Pull Document Information
  def get_document(params) do

    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/document/#{params}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }
    gets_http(url, header)
  end

  # Change Email ID
  def change_email(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "email" => [%{
        "id" => params.id,
        "address" => params.email_address,
        "verification_status" => params.verify_status
      }]
    }
    response = put_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000", do: "S", else: "F"

    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Change Email",
      method: "PUT",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: params.request_by
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # Change Phone
  def change_mobile(params) do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)

    auth = "#{token_type} #{access_token}"
    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/#{params.urlid}"
    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }

    body = %{
      "phone" => [%{
        "id" => params.id,
        "number" => params.mobile_number,
        "verification_status" => params.verify_status
      }]
    }
    response = put_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000", do: "S", else: "F"

    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Change Mobile",
      method: "PUT",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: params.request_by
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # change date of birth
  def change_Dob(params)do
    token = get_token()
    access_token = token["access_token"]
    token_type = token["token_type"]
    source_id = random_string(6)
    auth = "#{token_type} #{access_token}"

    url = "#{Application.get_env(:violacorp, :acc_live_url)}v1/user/#{params.urlid}"

    header = %{
      "authorization" => auth,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "source_id" => "violaTeam#{source_id}",
      "time_zone" => "UTC +00:00"
    }
    body = %{
      "personal_info" => %{
        "date_of_birth" => params.date_of_birth
      }
    }
    response = put_http(url, header, Poison.encode!(body))
    response_code = response["result"]["code"]
    res_status = if response_code == "0000", do: "S", else: "F"

    # log for request and response
    third_party_log = %{
      commanall_id: "#{params.common_id}",
      section: "violaTeam#{source_id} ~ Change Dob",
      method: "POST",
      request: Poison.encode!(body),
      response: Poison.encode!(response),
      status: res_status,
      inserted_by: params.request_by
    }
    changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
    Repo.insert(changeset)

    _output = response
  end

  # Create New User on 4Stop
  def register_fourstop(employee_id) do
    url = "#{Application.get_env(:violacorp, :fourstop_url)}#{employee_id}"
    header = %{
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "time_zone" => "UTC +00:00"
    }
    gets_http_new(url, header)
  end

  # GET HTTP
  defp gets_http_new(url, header) do
    case HTTPoison.get(url, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:error, %{reason: reason}} -> reason
    end
  end

  # GET HTTP
  defp gets_http(url, header) do
    case HTTPoison.get(url, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        code = response["result"]["code"]
        if code == "5020" do
          check_token = Repo.get_by(Settings, category: "token")
          settings_params = %{generate_date: "2017-07-28"}
          changeset = Settings.changeset(check_token, settings_params)
          Repo.update(changeset)
        end
        Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401, body: body}} ->
        check_token = Repo.get_by(Settings, category: "token")
        settings_params = %{generate_date: "2017-07-28"}
        changeset = Settings.changeset(check_token, settings_params)
        Repo.update(changeset)
        Poison.decode!(body)
      {:ok, %{status_code: 400}} -> "Bad request!"
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:error, %{reason: reason}} -> reason
    end
  end

  # POST HTTP
  defp post_http(url, header, body) do
    case HTTPoison.post(url, body, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        code = response["result"]["code"]
        if code == "5020" do
          check_token = Repo.get_by(Settings, category: "token")
          settings_params = %{generate_date: "2017-07-28"}
          changeset = Settings.changeset(check_token, settings_params)
          Repo.update(changeset)
        end
        Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401, body: body}} ->
        check_token = Repo.get_by(Settings, category: "token")
        settings_params = %{generate_date: "2017-07-28"}
        changeset = Settings.changeset(check_token, settings_params)
        Repo.update(changeset)
        Poison.decode!(body)
      {:ok, %{status_code: 400}} -> "Bad request!"
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:error, %{reason: reason}} -> reason
    end
  end

  # PUT HTTP
  defp put_http(url, header, body) do
    case HTTPoison.put(url, body, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        code = response["result"]["code"]
        if code == "5020" do
          check_token = Repo.get_by(Settings, category: "token")
          settings_params = %{generate_date: "2017-07-28"}
          changeset = Settings.changeset(check_token, settings_params)
          Repo.update(changeset)
        end
        Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401, body: body}} ->
        check_token = Repo.get_by(Settings, category: "token")
        settings_params = %{generate_date: "2017-07-28"}
        changeset = Settings.changeset(check_token, settings_params)
        Repo.update(changeset)
        Poison.decode!(body)
      {:ok, %{status_code: 400}} -> "Bad request!"
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:error, %{reason: reason}} -> reason
    end
  end

  # DELETE HTTP
  defp delete_http(url, header, body) do
    case HTTPoison.request(:delete, url, body, header, [recv_timeout: 400_000]) do
      {:ok, %{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        code = response["result"]["code"]
        if code == "5020" do
          check_token = Repo.get_by(Settings, category: "token")
          settings_params = %{generate_date: "2017-07-28"}
          changeset = Settings.changeset(check_token, settings_params)
          Repo.update(changeset)
        end
        Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401, body: body}} ->
        check_token = Repo.get_by(Settings, category: "token")
        settings_params = %{generate_date: "2017-07-28"}
        changeset = Settings.changeset(check_token, settings_params)
        Repo.update(changeset)
        Poison.decode!(body)
      {:ok, %{status_code: 400}} -> "Bad request!"
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:error, %{reason: reason}} -> reason
    end
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64
  end

end