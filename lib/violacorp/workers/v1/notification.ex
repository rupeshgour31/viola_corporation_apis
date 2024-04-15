defmodule Violacorp.Workers.V1.Notification do
  use Bamboo.Phoenix, view: ViolacorpWeb.EmailView
  import Pigeon.APNS.Notification
  require Logger

  def perform(params) do
    case params["worker_type"] do
      "send_android" -> Map.delete(params, "worker_type") |> send_android()
      "send_ios" -> Map.delete(params, "worker_type") |> send_ios()
      "send_sms" -> Map.delete(params, "worker_type") |> send_sms()
      _ -> Logger.warn("Worker: #{params["worker_type"]} not found in Notification")
           :ok
    end
  end

  @doc """
   Send Android worker
  """
  def send_android(params) do
    message = params["msg"]
    token = params["token"]
    n = Pigeon.FCM.Notification.new(token, message)
    Pigeon.FCM.push(n)
  end

  @doc """
   Send IOS worker
  """
  def send_ios(params) do
    message = params["msg"]["body"]
    token = params["token"]

    n = Pigeon.APNS.Notification.new(message, token, "com.vcorp.ViolaCorp")
        |> put_sound("default")
    Pigeon.APNS.push(n)
  end

  @doc """
   Send SMS worker
  """
  def send_sms(params) do
    message = params |> Poison.encode!()
    auth = [{"Content-Type", "application/json"}, {"Authorization", Application.get_env(:violacorp, :message_bird_key)}]
    {:ok, _check} = HTTPoison.post("https://rest.messagebird.com/messages", message, auth)
  end

  @doc """
   Send EMAIL worker
  """
  def sendemailV2(data) do
    new_email()
    |> from(data.from)
    |> to(data.to)
    |> put_html_layout({ViolacorpWeb.LayoutView, data.templatefile})
    |> subject(data.subject)
    |> assign(:data, data.render_data)
    |> render(data.templatefile)
  end
  end