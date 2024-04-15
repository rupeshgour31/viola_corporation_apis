defmodule Violacorp.Libraries.Notification.AdminNotification do
  #  alias Violacorp.Libraries.AdminNotification
  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Administratorusers

  require Logger
  @doc "This is for admin notification"

  def create_body(params) do

    notification_auth_key  = Application.get_env(:violacorp, :notification_auth_key)
    admin_url =  Application.get_env(:violacorp, :admin_url)
    notification_url =  Application.get_env(:violacorp, :notification_url)

    dbarray = Repo.all (from a in Administratorusers, where: not is_nil(a.browser_token) and a.notification_status == "Y", select: a.browser_token)

    header = %{
      "authorization" => notification_auth_key,
      "cache-control" => "no-cache",
      "content-type" => "application/json",
      "language" => "en",
      "time_zone" => "UTC +00:00",
      "show_sensitive_data" => "1"
    }

    bodyKey = String.replace(params.title," ", "-")
    body =  %{
      "notification" => %{
        "title" => params.title,
        "subtitle" => params.title,
        "tickerText" => params.message,
        "vibrate" => 1,
        "sound" => 1,
        "body" => params.message,
        "click_action" =>  admin_url
      },
      "data" => %{
        "key" => bodyKey,
        "message" => params.message
      },
      "registration_ids" => dbarray
    }
    _result = post_http(notification_url, header, Poison.encode!(body))
  end

  defp post_http(url, header, body) do
   case HTTPoison.post(url, body, header, [recv_timeout: 100_000]) do
      {:ok, %{status_code: 200, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 202, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 201, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 400, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 403, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "Record not found"
      {:ok, %{status_code: 409, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 500}} -> "Internal server error"
      {:ok, %{status_code: 503}} -> "Internal server error"
      {:ok, %{status_code: 502}} -> "Process Failure"
      {:error, %{reason: reason}} -> reason
   end
  end
end
