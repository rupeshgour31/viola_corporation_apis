defmodule Violacorp.Libraries.Notification.Switch do
  require Logger
  import Ecto.Query
  alias Violacorp.Repo
  alias Violacorp.Mailer
  alias Violacorp.Workers.SendEmail
#  alias Violacorp.Workers.SendSms
#  alias Violacorp.Workers.SendIos
#  alias Violacorp.Workers.SendAndroid
  alias Violacorp.Schemas.Commanall

  def email_switch(params) do
    _emaildata = %{
                   :from => "no-reply@violacorporate.com",
                   :to => params.email_id,
                   :subject => params.subject,
                   :render_data => Map.put(params.data, :layoutfile, params.layoutfile),
                   :templatefile => params.templatefile,
                   :layoutfile => params.layoutfile
                 }
                 |> SendEmail.sendemailV2()
                 |> Mailer.deliver_later()
  end

  def sms_switch(params) do
    get_number = if String.first(params.contact_number) == "0" do
      String.slice(params.contact_number, 1, 10)
    else
      params.contact_number
    end
    {sms_body, _b} = Code.eval_string(~s("#{params.sms_body}"), Map.to_list(params.data))

    if String.first(get_number) == "7"  do
      messagebody = %{
                      "worker_type" => "send_sms",
                      "recipients" => "+#{params.contact_code}#{get_number}",
                      "originator" => "ViolaCorp",
                      "body" => sms_body
                    }
      {:ok, _ack} = Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [messagebody], max_retries: 1)
    end
  end

  def mob_notification(params) do

    {notification_body, _b} = Code.eval_string(~s("#{params.notification_body}"), Map.to_list(params.data))

    ios_messagebody = %{
      "worker_type" => "send_android",
      "token" => params.token,
      "msg" => %{
        "body" => notification_body
      }
    }
    android_messagebody = %{
      "worker_type" => "send_ios",
      "token" => params.token,
      "msg" => %{
        "body" => notification_body
      }
    }
    if params.push_type == "A" and !is_nil(android_messagebody["token"]) do
      Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [android_messagebody], max_retries: 1)
    else
      if params.push_type == "I" and !is_nil(ios_messagebody["token"]) do
        Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [ios_messagebody], max_retries: 1)
      end
    end
  end

  # SEND NOTIFICATION INDEPENDENT with message and party_id params - WORKS IF COMMANALL IS EMPLOYEE ONLY
  def mob_notification_only(params) do
    commanall = Repo.one from cmn in Commanall, where: cmn.id == ^params["commanall_id"] and not is_nil(cmn.employee_id), left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                                                  select: %{
                                                    commanall_id: cmn.id,
                                                    email_id: cmn.email_id,
                                                    as_login: cmn.as_login,
                                                    code: m.code,
                                                    contact_number: m.contact_number,
                                                    token: d.token,
                                                    token_type: d.type
                                                  }

    if !is_nil(commanall) and !is_nil(commanall.as_login) and commanall.as_login == "Y" and !is_nil(commanall.token) and commanall.token != "" and !is_nil(params["message"]) do
      body = %{token: commanall.token, message: params["message"]}
      ios_messagebody = %{
        "worker_type" => "send_android",
        "token" => body.token,
        "msg" => %{
          "body" => body.message
        }
      }
      android_messagebody = %{
        "worker_type" => "send_ios",
        "token" => body.token,
        "msg" => %{
          "body" => body.message
        }
      }
      if params.push_type == "A" and !is_nil(android_messagebody["token"]) do
        Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [android_messagebody], max_retries: 1)
      else
        if params.push_type == "I" and !is_nil(ios_messagebody["token"]) do
          Exq.enqueue(Exq, "notification", Violacorp.Workers.V1.Notification, [ios_messagebody], max_retries: 1)
        end
      end
    end
  end
end