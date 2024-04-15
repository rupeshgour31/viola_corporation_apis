defmodule ViolacorpWeb.Main.V2AlertsController do
  use ViolacorpWeb, :controller
  import Ecto.Query
  require Logger

  alias Violacorp.Repo
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Notification.Validation
  alias Violacorp.Libraries.Notification.Switch
  alias Violacorp.Schemas.Alertswitch

  def main(params) do
    # Example only! to be approved..
    #    expected_params_struc = [
    #      %{
    #        section: "forgot_password",
    #        type: "E",
    #        email_sender: "no-reply@violacorporate.com",
    #        email_id: "test@viola.group",
    #        data: %{generate_otp: "010101"}   # Content
    #      },
    #      %{
    #        section: "forgot_password",
    #        type: "S",
    #        contact_code: "44",
    #        contact_number: "7849018077",
    #        sms_body: "",
    #        data: %{otp_code: "010101"} # Content
    #      },
    #      %{
    #        section: "forgot_password",
    #        type: "N",
    #        token: "fmlLBIeBByI:APA91bHmV5JH2kHbhOXWR-vD3O18vx_Ndh89V-tqxHJ4CqU0YwNvW5t9WYE_IPkIAy3XjYcGyIRuWstq_85DhEuYv5HHrZBfeB_cGt9lP6EVF8ApDSWAjJcBnzBZj1TcPriuHjURQPEi",
    #        push_type: "A", # "I" or "A"
    #        login: "A", # "I" or "A"
    #        data: %{otp_code: "010101"} # Content
    #      }
    #    ]

    Enum.each(
      params,
      fn single ->
        section = case Cachex.get!(:vcorp, "alerts") do
          nil ->
            db_check = Repo.all(from a in Alertswitch)
            Cachex.start_link(:vcorp)
            Cachex.put(:vcorp, "alerts", db_check)
            Cachex.get!(:vcorp, "alerts")
          getCache -> getCache
        end

        filtered_section = case Enum.filter(
                                  section,
                                  fn x ->
                                    x.section == single.section
                                  end
                                ) do
          [found] -> changeset = Validation.global_validation(Map.from_struct(found))
                     if !changeset.valid? do
                       Cachex.del(:vcorp, "alerts")
                       db_check = Repo.all(from a in Alertswitch)
                       Cachex.start_link(:vcorp)
                       Cachex.put(:vcorp, "alerts", db_check)
                       new_list = Cachex.get!(:vcorp, "alerts")
                       case Enum.filter(
                              new_list,
                              fn x ->
                                x.section == single.section
                              end
                            ) do
                         [found] -> found
                         [] -> Logger.info("#{single.section} alerts section has been Called but not found in table")
                               nil
                       end
                     else
                       found
                     end
          [] -> Cachex.del(:vcorp, "alerts")
                db_check = Repo.all(from a in Alertswitch)
                Cachex.start_link(:vcorp)
                Cachex.put(:vcorp, "alerts", db_check)
                new_list = Cachex.get!(:vcorp, "alerts")
              case Enum.filter(
                     new_list,
                     fn x ->
                       x.section == single.section
                     end
                   ) do
                [found] -> found

                [] -> Logger.info("#{single.section} alerts section has been Called but not found in table")
                      nil
              end
        end
        if !is_nil(filtered_section) do
          cond do
            single.type == "E" and filtered_section.email == "Y" ->
              if !is_nil(single.email_id) and single.email_id != "" do
              merged = Map.merge(single, Map.from_struct(filtered_section))
              changeset = Validation.send_email(merged)
              if !changeset.valid? do
                errors = changeset |> ViolacorpWeb.ErrorView.translate_errors() |> Poison.encode!()
                Logger.info("#{single.section} EMAIL FAILED TO SEND DUE TO MISSING/NIL ESSENTIAL KEYS: #{errors}")
              else
                Switch.email_switch(merged)
              end
#              else
#                Logger.info("FAILED TO SEND {Email | #{single.section}} DUE TO EMAIL is NIL")
              end
            single.type == "S" and filtered_section.sms == "Y"  ->
              if Commontools.is_mobile_number(single.contact_number) == true do
              merged = Map.merge(single, Map.from_struct(filtered_section))
              changeset = Validation.send_sms(merged)
              if !changeset.valid? do
                errors = changeset |> ViolacorpWeb.ErrorView.translate_errors() |> Poison.encode!()
                Logger.info("#{single.section} SMS FAILED TO SEND DUE TO MISSING/NIL ESSENTIAL KEYS: #{errors}")
              else
                Switch.sms_switch(merged)
              end
#              else
#                Logger.info("FAILED TO SEND {SMS | #{single.section}} DUE TO NUMBER is NIL/INVALID")
              end
            single.type == "N" and filtered_section.notification == "Y" and single.login == "Y" ->
              if !is_nil(single.token) and single.token != "" do
              merged = Map.merge(single, Map.from_struct(filtered_section))
              changeset = Validation.send_notification(merged)
              if !changeset.valid? do
                errors = changeset |> ViolacorpWeb.ErrorView.translate_errors() |> Poison.encode!()
                Logger.info("#{single.section} NOTIFICATION FAILED TO SEND DUE TO MISSING/NIL ESSENTIAL KEYS: #{errors}")
              else
                Switch.mob_notification(merged)
              end
#              else
#                Logger.info("FAILED TO SEND {N | #{single.section}} DUE TO TOKEN is NIL")
              end
            true -> ""
#              Logger.info("#{String.upcase(single.type)} NOT ALLOWED FOR #{single.section}, DB/USER_NOT_LOGGED")

          end
        end
      end
    )
  end

end
