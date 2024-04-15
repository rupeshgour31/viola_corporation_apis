defmodule Violacorp.Workers.SendSms do

  require Logger
  @moduledoc "SendSms function - send Sms"

  def perform(params) do
    message = params

    Logger.warn("sms body: #{message}")
    auth = [{"Content-Type", "application/json"}, {"Authorization", Application.get_env(:violacorp, :message_bird_key)}]
    {:ok, check} = HTTPoison.post("https://rest.messagebird.com/messages", message, auth)
    Logger.warn("sms response: body: #{check.body} ||| status_code: #{check.status_code} ")
  end
end
