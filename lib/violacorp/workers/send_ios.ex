defmodule Violacorp.Workers.SendIos do
  import Pigeon.APNS.Notification

  @moduledoc "SendIos function - send notifications to ios"

  def perform(params) do
    message = params["msg"]["body"]
    token = params["token"]

    n = Pigeon.APNS.Notification.new(message, token, "com.vcorp.ViolaCorp")
        |> put_sound("default")
    Pigeon.APNS.push(n)
  end
end
