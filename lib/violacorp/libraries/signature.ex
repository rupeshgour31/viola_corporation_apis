defmodule Violacorp.Libraries.Signature do

  @moduledoc "Clearbank Generate Signature"

  alias Violacorp.Schemas.Versions
  require Logger
  import Ecto.Query
  alias Violacorp.Repo
  # Generate Digital Signature
  def digital_signature(string) do

    # Define Kyes
    private_key_reference = Application.get_env(:violacorp, :private_key_reference)
    _public_key_reference = Application.get_env(:violacorp, :public_key_reference)
    sign_algo = Application.get_env(:violacorp, :sign_algo)
    api_token = Application.get_env(:violacorp, :api_token)
    api_url = Application.get_env(:violacorp, :api_url)
    endpoint = Application.get_env(:violacorp, :endpoint)

    # GENERATE OUR SIGNATURE
    header = %{
      "content-type" => "application/json"
    }
    body = %{
      "message" => string,
      "key-reference" => private_key_reference,
      "sign-algo" => sign_algo
    }
    result = post_http(endpoint, header, Poison.encode!(body))
    server_setting = Repo.one(from v in Versions, where: v.id == 1, order_by: [asc: v.id], limit: 1)
    cond do
      is_nil(result) or is_nil(result["signature"]) ->
        # "send email"
        updated_server_setting = admin_notification("FIRST", server_setting)
        #"send TRY"
        #    SECOND KEYS
        private_key_reference_2 = Application.get_env(:violacorp, :private_key_reference_2) #
        endpoint_2 = Application.get_env(:violacorp, :endpoint_2) #

        body = %{
          "message" => string,
          "key-reference" => private_key_reference_2,
          "sign-algo" => sign_algo
        }
        result = post_http(endpoint_2, header, Poison.encode!(body))

        if is_nil(result) or is_nil(result["signature"]) do
          admin_notification("SECOND", updated_server_setting)
          %{"signature" => nil, "token" => api_token, "request_id" => randnumber(), "url" => api_url}
        else
          if !is_nil(updated_server_setting) do
            setting_map = Poison.decode!(updated_server_setting.signature_server)
            new = Map.replace!(setting_map, "second", 1) |> Poison.encode!
            updated_server_setting
            |> Versions.updateSignatureServer(%{"signature_server" => new})
            |> Repo.update!
          end
          signature_viola = result["signature"]
          %{"signature" => signature_viola, "token" => api_token, "request_id" => randnumber(), "url" => api_url}
        end
      true ->
        if !is_nil(server_setting) do
          setting_map = Poison.decode!(server_setting.signature_server)
          new = Map.replace!(setting_map, "first", 1) |> Poison.encode!
          server_setting
          |> Versions.updateSignatureServer(%{"signature_server" => new})
          |> Repo.update!
        end
        signature_viola = result["signature"]
        %{"signature" => signature_viola, "token" => api_token, "request_id" => randnumber(), "url" => api_url}
    end
  end

  # Verify Digital Signature
  def verify_signature(signature, string) do

    public_key_reference = Application.get_env(:violacorp, :public_key_reference)
    public_key_reference_2 = Application.get_env(:violacorp, :public_key_reference_2)
    sign_algo = Application.get_env(:violacorp, :sign_algo)
    endpoint = Application.get_env(:violacorp, :endpoint_verify)
    endpoint_2 = Application.get_env(:violacorp, :endpoint_verify_2)

    # GENERATE OUR SIGNATURE
    header = %{
      "content-type" => "application/json"
    }
    body_verify = %{
      "message" => string,
      "key-reference" => public_key_reference,
      "sign-algo" => sign_algo,
      "signature" => signature
    }
    verify = post_http(endpoint, header, Poison.encode!(body_verify))
    server_setting = Repo.one(from v in Versions, where: v.id == 1, order_by: [asc: v.id], limit: 1)
    if is_nil(verify) do
      #        "send email"
      updated_server_setting = admin_notification("FIRST", server_setting)
      #"send TRY"
      #    SECOND KEYS
      body = %{
        "message" => string,
        "key-reference" => public_key_reference_2,
        "sign-algo" => sign_algo,
        "signature" => signature
      }
      result = post_http(endpoint_2, header, Poison.encode!(body))
      if is_nil(result) do
        admin_notification("SECOND", updated_server_setting)
        nil
      else
        if !is_nil(updated_server_setting) do
          setting_map = Poison.decode!(updated_server_setting.signature_server)
          new = Map.replace!(setting_map, "second", 1) |> Poison.encode!
          updated_server_setting
          |> Versions.updateSignatureServer(%{"signature_server" => new})
          |> Repo.update!
        end
        result
      end
    else
      if !is_nil(server_setting) do
        setting_map = Poison.decode!(server_setting.signature_server)
        new = Map.replace!(setting_map, "first", 1) |> Poison.encode!
        server_setting
        |> Versions.updateSignatureServer(%{"signature_server" => new})
        |> Repo.update!
      end
      verify
    end
  end

  # Generate Random Number
  def randnumber() do
    _currentdatetime = NaiveDateTime.utc_now()
                       |> NaiveDateTime.truncate(:microsecond)
                       |> to_string()
                       |> String.replace( ~r/[-.: ]+/, "")
  end

  # Generate Digital Signature
  def token() do
    api_token = Application.get_env(:violacorp, :api_token)
    api_url = Application.get_env(:violacorp, :api_url)

    _response_token = %{"token" => api_token, "url" => api_url}
  end

  def admin_notification(server, server_setting) do
    if !is_nil(server_setting) and !is_nil(server_setting.signature_server) do
    setting_map = Poison.decode!(server_setting.signature_server)
    value = case server do
      "FIRST" -> setting_map["first"]
      "SECOND" -> setting_map["second"]
    end
    if 2 > value do
    messagebody = %{
      "worker_type" => "send_sms",
      "recipients" => "+447722101011",
      "originator" => "ViolaCorp",
      "body" => "Signature is NIL, #{server} server"
    }
    Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [messagebody], max_retries: 1)
    %{
      :from => "no-reply@violacorporate.com",
      :to => ["krishna@activesoftware.in", "inderjit.singh@violamoney.co.uk"],
      :subject => "ADMIN CB ALERT",
      :render_data => Map.put(%{:message => "CB Signature is nil, #{server} server"}, :layoutfile, "admin_emails.html"),
      :templatefile => "admin_emails.html",
      :layoutfile => "admin_emails.html"
    }
    |> Violacorp.Workers.SendEmail.sendemailV2()
    |> Violacorp.Mailer.deliver_later()
    updated_signature_server = case  server do
                                 "FIRST" -> setting_map["first"]
                                            Map.replace!(setting_map, "first", 2)
                                 "SECOND" -> setting_map["first"]
                                             Map.replace!(setting_map, "second", 2)
                               end |> Poison.encode!()
    server_setting
    |> Versions.updateSignatureServer(%{"signature_server" => updated_signature_server})
    |> Repo.update!
    else
      server_setting
  end
  else
    Logger.warn "Version table row not found for sending CB Signature failure notification"
  end
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

end