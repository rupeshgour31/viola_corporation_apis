defmodule Violacorp.Libraries.Notification.SendNotification do
  alias ViolacorpWeb.Main.V2AlertsController

  def sender(section, recipient, data) do
      notifications = [
        %{
          section: section,
          type: "E",
          email_id: recipient.email_id,
          data: data
          # Content
        },
        %{
          section: section,
          type: "S",
          contact_code: recipient.contact_code,
          contact_number: recipient.contact_number,
          data: data
          # Content
        },
        %{
          section: section,
          type: "N",
          token: recipient.token,
          push_type: recipient.token_type, # "I" or "A"
          login: recipient.as_login, # "Y" or "N"
          data: data
          # Content
        }
      ]
      V2AlertsController.main(notifications)
    end
  end