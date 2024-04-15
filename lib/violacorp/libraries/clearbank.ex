defmodule Violacorp.Libraries.Clearbank do

  require Logger
  alias Violacorp.Repo
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Libraries.Signature
  alias Violacorp.Libraries.Signaturedev

  @moduledoc "Clearbank Library"

  # Test for POST Method
  def test_api(body) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(body), else: Signature.digital_signature(body)

    signature = kyes["signature"]
    token = kyes["token"]
    request_id = kyes["request_id"]
    url = kyes["url"]
    endpoint = "#{url}v1/Test"

    header = %{
      "Authorization" => token,
      "DigitalSignature" => signature,
      "X-Request-Id" => request_id,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }
    post_http(endpoint, header, body)
  end

  # Create Account
  def create_account(body) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(body), else: Signature.digital_signature(body)

    signature = kyes["signature"]
    token = kyes["token"]
    request_id = kyes["request_id"]
    url = kyes["url"]
    endpoint = "#{url}v3/Accounts"

    header = %{
      "Authorization" => token,
      "DigitalSignature" => signature,
      "X-Request-Id" => request_id,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }

    Logger.warn "CLR Registration Request: #{~s(#{Poison.encode!(body)})}"
    result = post_http(endpoint, header, body)
    Logger.warn "CLR Registration Response: #{~s(#{Poison.encode!(result)})}"

    _output = result
  end

  # Get Single Account Details
  def view_account(accountId) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.token(), else: Signature.token()

    token = kyes["token"]
    url = kyes["url"]
    endpoint = "#{url}v1/Accounts/#{accountId}"

    header = %{
      "Authorization" => token,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }
    get_http(endpoint, header)
  end

  # Get Single Account Details
  def get_accounts() do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.token(), else: Signature.token()

    token = kyes["token"]
    url = kyes["url"]
    endpoint = "#{url}v1/Accounts/"

    header = %{
      "Authorization" => token,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }
    get_http(endpoint, header)
  end

  # Get single or multiple transactions
  def get_transaction(endpointMethod) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.token(), else: Signature.token()

    token = kyes["token"]
    url = kyes["url"]
    endpoint = "#{url}v1/Accounts/#{endpointMethod}"
    header = %{
      "Authorization" => token,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }
    get_http(endpoint, header)
  end
@doc""
  # Get single or multiple transactions within given dates
  def get_transaction_for_date_range(endpointMethod, params) do
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    keys = if otp_mode == "dev", do: Signaturedev.token(), else: Signature.token()
    token = keys["token"]
    url = keys["url"]
    endpoint = "#{url}v1/Accounts/#{endpointMethod}/?startdatetime=#{params["start_date_time"]}&endDateTime=#{params["end_date_time"]}"
    header = %{
      "Authorization" => token,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }
    get_http(endpoint, header)
  end
  @doc""

  # Payment for Internal Beneficiary
  def paymentAToIB(params) do

    today = DateTime.utc_now
    amount = params.amount
    currency = params.currency

    paymentInstructionIdentification = params.paymentInstructionIdentification
    d_name = params.d_name
    d_iban = params.d_iban
    d_code = params.d_code
    d_identification = params.d_identification
    d_issuer = params.d_issuer
    d_proprietary = params.d_proprietary
    instructionIdentification = params.instructionIdentification
    endToEndIdentification = params.endToEndIdentification

    c_name = params.c_name
    c_iban = params.c_iban
    c_proprietary = params.c_proprietary
    c_code = params.c_code
    c_identification = params.c_identification
    c_issuer = params.c_issuer

    reference = params.reference

    body_string = %{
                    "paymentInstructions" =>  [%{"paymentInstructionIdentification" => paymentInstructionIdentification,"requestedExecutionDate" => today,
                      "debtor" => %{"name" => d_name, "legalEntityIndentifier" => ""},
                      "debtorAccount" => %{"identification" => %{"iban" => d_iban,
                        "other" => %{"identification" => d_identification,
                          "schemeName" => %{"code" => d_code,"proprietary" => d_proprietary},
                          "issuer" => d_issuer}
                      }
                      },
                      "creditTransfers" => [%{"paymentIdentification" => %{"instructionIdentification" => instructionIdentification,"endToEndIdentification" => endToEndIdentification},
                        "amount" => %{"instructedAmount" => amount,"currency" => currency},
                        "creditor" => %{"name" => c_name,"legalEntityIndentifier" => ""},
                        "creditorAccount" => %{"identification" => %{"iban" => c_iban,
                          "other" => %{"identification" => c_identification,
                            "schemeName" => %{"code" => c_code,"proprietary" => c_proprietary},
                            "issuer" => c_issuer}
                        }
                        },
                        "remittanceInformation" => %{"structured" => %{"creditorReferenceInformation" => %{"reference" => reference}}}
                      }]
                    }]

                  }
                  |> Poison.encode!

    string = ~s(#{body_string})
    _output =  payments(string)

  end

  # Payment for External Beneficiary
  def paymentAToEB(params) do

    today = DateTime.utc_now
    amount = params.amount
    currency = params.currency

    paymentInstructionIdentification = params.paymentInstructionIdentification
    d_name = params.d_name
    d_iban = params.d_iban
    d_code = params.d_code
    d_identification = params.d_identification
    d_issuer = params.d_issuer
    d_proprietary = params.d_proprietary
    instructionIdentification = params.instructionIdentification
    endToEndIdentification = params.endToEndIdentification

    c_name = params.c_name
    c_iban = params.c_iban
    c_proprietary = params.c_proprietary

    reference = params.reference

    body_string = %{
                    "paymentInstructions" =>  [%{"paymentInstructionIdentification" => paymentInstructionIdentification,"requestedExecutionDate" => today,
                      "debtor" => %{"name" => d_name, "legalEntityIndentifier" => ""},
                      "debtorAccount" => %{"identification" => %{"iban" => d_iban,
                        "other" => %{"identification" => d_identification,
                          "schemeName" => %{"code" => d_code,"proprietary" => d_proprietary},
                          "issuer" => d_issuer}
                      }
                      },
                      "creditTransfers" => [%{"paymentIdentification" => %{"instructionIdentification" => instructionIdentification,"endToEndIdentification" => endToEndIdentification},
                        "amount" => %{"instructedAmount" => amount,"currency" => currency},
                        "creditor" => %{"name" => c_name,"legalEntityIndentifier" => ""},
                        "creditorAccount" => %{"identification" => %{
                          "other" => %{"identification" => c_iban,
                            "schemeName" => %{"proprietary" => c_proprietary}
                          }
                        }
                        },
                        "remittanceInformation" => %{"structured" => %{"creditorReferenceInformation" => %{"reference" => reference}}}
                      }]
                    }]

                  }
                  |> Poison.encode!

    string = ~s(#{body_string})
    _output =  payments(string)

  end

  # Create Account for Fee and Accomplish
  def create_admin_account(body) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(body), else: Signature.digital_signature(body)

    signature = kyes["signature"]
    token = kyes["token"]
    request_id = kyes["request_id"]
    url = kyes["url"]
    endpoint = "#{url}v1/Accounts"

    header = %{
      "Authorization" => token,
      "DigitalSignature" => signature,
      "X-Request-Id" => request_id,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }

    _output = post_http(endpoint, header, body)
  end

  # Payments to clear bank
  def payments(body) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(body), else: Signature.digital_signature(body)

    signature = kyes["signature"]
    token = kyes["token"]
    request_id = kyes["request_id"]
    url = kyes["url"]
    endpoint = "#{url}v1/Payments/FPS"

    header = %{
      "Authorization" => token,
      "DigitalSignature" => signature,
      "X-Request-Id" => request_id,
      "cache-control" => "no-cache",
      "content-type" => "application/json"
    }

    Logger.warn "CLR Payment Request: #{~s(#{Poison.encode!(body)})}"
    result = post_http(endpoint, header, body)
    Logger.warn "CLR Payment Response: #{~s(#{Poison.encode!(result)})}"

    _output = result

  end

  # Change Account status
  def account_status(params) do

    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(params.body), else: Signature.digital_signature(params.body)

    signature = kyes["signature"]

    _response = if is_nil(signature) do
      %{data: "DigitalSignature Failed", verify_status: false}
    else
      token = kyes["token"]
      request_id = kyes["request_id"]
      url = kyes["url"]
      endpoint = "#{url}v1/Accounts/#{params.account_id}"

      header = %{
        "Authorization" => token,
        "DigitalSignature" => signature,
        "X-Request-Id" => request_id,
        "cache-control" => "no-cache",
        "content-type" => "application/json"
      }
      Logger.warn "CLR Change Status Request: #{~s(#{Poison.encode!(params.body)})}"
      result = patch_http(endpoint, header, params.body)
      Logger.warn "CLR Change Status Response: #{~s(#{Poison.encode!(result)})}"

      #      status = if !is_nil(result["account"]), do: "S", else: "F"
      status = if result["status_code"] == "204", do: "S", else: "F"

      inserted_map = %{
        commanall_id: params.commanall_id,
        section: "ClearBank Update Status",
        method: "POST",
        header_data: request_id,
        request: Poison.encode!(params.body),
        response: Poison.encode!(result),
        status: status,
        inserted_by: params.requested_by
      }
      changeset_logs = Thirdpartylogs.changeset(%Thirdpartylogs{}, inserted_map)
      Repo.insert(changeset_logs)
      _output = result
    end
  end

  @doc """
    this function for enable bank account on clear bank
  """
  # Change Account status
  def account_enable(params) do

    body_string = %{
                    "status" => "Enabled",
                    "statusReason" => "NotProvided"
                  }
                  |> Poison.encode!
    string = ~s(#{body_string})
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

    signature = kyes["signature"]

    _response = if is_nil(signature) do
      %{data: "DigitalSignature Failed", verify_status: false}
    else
      token = kyes["token"]
      request_id = kyes["request_id"]
      url = kyes["url"]
      endpoint = "#{url}v1/Accounts/#{params.account_id}"

      header = %{
        "Authorization" => token,
        "DigitalSignature" => signature,
        "X-Request-Id" => request_id,
        "cache-control" => "no-cache",
        "content-type" => "application/json"
      }


      Logger.warn "CLR Change Status Request: #{~s(#{Poison.encode!(string)})}"
      result = patch_http(endpoint, header, string)
      Logger.warn "CLR Change Status Response: #{~s(#{Poison.encode!(result)})}"

      #      status = if !is_nil(result["account"]), do: "S", else: "F"
      status = if result["status_code"] == "204", do: "S", else: "F"

      inserted_map = %{
        commanall_id: params.commanall_id,
        section: "ClearBank Update Status",
        method: "POST",
        header_data: request_id,
        request: Poison.encode!(string),
        response: Poison.encode!(result),
        status: status,
        inserted_by: params.requested_by
      }
      changeset_logs = Thirdpartylogs.changeset(%Thirdpartylogs{}, inserted_map)
      Repo.insert(changeset_logs)
      _output = result
    end
  end

  @doc """
    this function for disable bank account on clear bank
  """
  # Change Account status
  def account_disable(params) do

    body_string = %{
                    "status" => "Suspended",
                    "statusReason" => "Other"
                  }
                  |> Poison.encode!
    string = ~s(#{body_string})
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    kyes = if otp_mode == "dev", do: Signaturedev.digital_signature(string), else: Signature.digital_signature(string)

    signature = kyes["signature"]

    _response = if is_nil(signature) do
      %{data: "DigitalSignature Failed", verify_status: false}
    else
      token = kyes["token"]
      request_id = kyes["request_id"]
      url = kyes["url"]
      endpoint = "#{url}v1/Accounts/#{params.account_id}"

      header = %{
        "Authorization" => token,
        "DigitalSignature" => signature,
        "X-Request-Id" => request_id,
        "cache-control" => "no-cache",
        "content-type" => "application/json"
      }


      Logger.warn "CLR Change Status Request: #{~s(#{Poison.encode!(string)})}"
      result = patch_http(endpoint, header, string)
      Logger.warn "CLR Change Status Response: #{~s(#{Poison.encode!(result)})}"

      #      status = if !is_nil(result["account"]), do: "S", else: "F"
      status = if result["status_code"] == "204", do: "S", else: "F"

      inserted_map = %{
        commanall_id: params.commanall_id,
        section: "ClearBank Update Status",
        method: "POST",
        header_data: request_id,
        request: Poison.encode!(string),
        response: Poison.encode!(result),
        status: status,
        inserted_by: params.requested_by
      }
      changeset_logs = Thirdpartylogs.changeset(%Thirdpartylogs{}, inserted_map)
      Repo.insert(changeset_logs)
      _output = result
    end
  end

  defp patch_http(url, header, body) do
    case HTTPoison.patch(url, body, header, [recv_timeout: 100_000]) do
      {:ok, %{status_code: 200, body: body}} -> %{"status_code" => "200", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 202, body: body}} -> %{"status_code" => "202", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 201, body: body}} -> %{"status_code" => "201", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 400, body: body}} -> %{"status_code" => "400", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 403, body: body}} -> %{"status_code" => "403", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 204}} -> %{"status_code" => "204", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 404}} -> %{"status_code" => "404", "response" => "Record not found"}
      {:ok, %{status_code: 409, body: body}} -> %{"status_code" => "409", "response" => Poison.decode!(body)}
      {:ok, %{status_code: 500}} -> %{"status_code" => "500", "response" => "Internal server error"}
      {:ok, %{status_code: 503}} -> %{"status_code" => "503", "response" => "Internal server error"}
      {:ok, %{status_code: 502}} -> %{"status_code" => "502", "response" => "Process Failure"}
      {:error, %{reason: reason}} -> %{"status_code" => "5008", "response" => reason}
    end
  end

  # POST HTTP
  defp post_http(url, header, body) do
    case HTTPoison.post(url, body, header, [recv_timeout: 300_000]) do
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

  # GET HTTP
  defp get_http(url, header) do
    case HTTPoison.get(url, header, [recv_timeout: 300_000]) do
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

end