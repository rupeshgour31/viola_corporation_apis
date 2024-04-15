defmodule Violacorp.Workers.SendAndroid do

  @moduledoc "SendAndroid function - send notifications to android"

  def perform(params) do
    message = params["msg"]
    token = params["token"]
    n = Pigeon.FCM.Notification.new(token, message)
    Pigeon.FCM.push(n)
  end
end
