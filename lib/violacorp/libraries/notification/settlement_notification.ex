defmodule Violacorp.Libraries.Notification.SettlementNotification do
  alias ViolacorpWeb.Main.V2AlertsController
  alias Violacorp.Repo

  alias Violacorp.Schemas.Adminbeneficiaries

  def sender(id, amount) do
    id = id
    amount = amount

    if !is_nil(id) do
      admin_beneficiary = Repo.get(Adminbeneficiaries, id)

      if !is_nil(admin_beneficiary) and !is_nil(admin_beneficiary.contacts) do
        beneficiaries = Poison.decode!(admin_beneficiary.contacts)
        emails = beneficiaries["emails"]
        mobiles = beneficiaries["mobiles"]
        today = NaiveDateTime.utc_now()
        to_date = [today.day, today.month, today.year]
                  |> Enum.map(&to_string/1)
                  |> Enum.map(&String.pad_leading(&1, 2, "0"))
                  |> Enum.join("-")
        data = %{
          :amount => amount,
          :account => "ACC. No: #{admin_beneficiary.account_number} - Sortcode: #{admin_beneficiary.sort_code}",
          :date => "#{to_date}"
        }
        case admin_beneficiary.notification do
          "E" -> if !Enum.empty?(emails) do
                   Enum.each emails, fn email ->
                     notification = [
                       %{
                         section: "admin_beneficiary",
                         type: "E",
                         email_id: email,
                         data: data
                         # Content
                       }
                     ]
                     V2AlertsController.main(notification)
                   end
                 end
          "S" -> if !Enum.empty?(mobiles) do
                   Enum.each mobiles, fn mobile ->
                     notification = [
                       %{
                         section: "admin_beneficiary",
                         type: "S",
                         contact_code: "44",
                         contact_number: mobile,
                         data: data
                       }
                     ]
                     V2AlertsController.main(notification)
                   end
                 end
          _ -> if !Enum.empty?(emails) do
                 Enum.each emails, fn email ->
                   notification = [
                     %{
                       section: "admin_beneficiary",
                       type: "E",
                       email_id: email,
                       data: data
                     }
                   ]
                   V2AlertsController.main(notification)
                 end
               end
               if !Enum.empty?(mobiles) do
                 Enum.each mobiles, fn mobile ->
                   notification = [
                     %{
                       section: "admin_beneficiary",
                       type: "S",
                       contact_code: "44",
                       contact_number: mobile,
                       data: data
                     }
                   ]
                   V2AlertsController.main(notification)
                 end
               end
        end
      end
    end
  end
end