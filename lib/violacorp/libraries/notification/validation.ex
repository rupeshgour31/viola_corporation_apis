defmodule Violacorp.Libraries.Notification.Validation do
  import Ecto.Changeset
  def send_email(request) do
    data = %{}
    types = %{
      email_id: :string,
      subject: :string,
      templatefile: :string,
      layoutfile: :string
    }
    {data, types}
    |> cast(request, Map.keys(types))
    |> validate_required([:email_id, :subject, :templatefile, :layoutfile])
  end

  def send_sms(request) do
    data = %{}
    types = %{
      contact_code: :string,
      contact_number: :string,
      sms_body: :string
    }
    {data, types}
    |> cast(request, Map.keys(types))
    |> validate_required([:contact_code, :contact_number, :sms_body])
    |> update_change(:contact_code, &String.trim/1)
    |> update_change(:contact_number, &String.trim/1)
    |> update_change(:sms_body, &String.trim/1)
    |> validate_format(:contact_code, ~r/^[0-9+]+$/)
    |> validate_format(:contact_number, ~r/^[0-9 ]+$/)
    |> validate_length(:contact_code, min: 1, max: 5)
    |> validate_length(:contact_number, min: 10, max: 11)
  end

  def send_notification(request) do
    data = %{}
    types = %{
      login: :string,
      token: :string,
      notification_body: :string,
      push_type: :string
    }
    {data, types}
    |> cast(request, Map.keys(types))
    |> validate_required([:token, :notification_body, :push_type, :login])
    |> update_change(:notification_body, &String.trim/1)
    |> validate_inclusion(:push_type, ["A", "I"])
  end

  def global_validation(request) do
    data = %{}
    types = %{
      notification_body: :string,
      sms_body: :string,
      subject: :string,
      templatefile: :string,
      layoutfile: :string
    }
    {data, types}
    |> cast(request, Map.keys(types))
    |> validate_required([:notification_body, :sms_body, :subject, :templatefile, :layoutfile])
  end
end