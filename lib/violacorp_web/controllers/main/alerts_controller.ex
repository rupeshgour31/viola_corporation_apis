defmodule ViolacorpWeb.Main.AlertsController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Alertswitch
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Workers.SendEmail
  alias Violacorp.Workers.SendSms
  alias Violacorp.Workers.SendAndroid
#  alias Violacorp.Workers.SendIos
  alias Violacorp.Mailer

  def sendEmail(params) do
    check_db = Repo.get_by(Alertswitch, section: params.section)

   if is_map(check_db) and check_db.email == "Y" do

      if Map.has_key?(params, :email_id) do

        _new_cap = if check_db.section == "new_cap" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => params.email_id,
                         :subject => "Your new password.",
                         :company_name => params.company_name,
                         :director_name => params.director_name,
                         :pswd => params.pswd,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "new_cap.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end
      else

        getemail = Repo.one from a in Commanall, where: a.id == ^params.commanall_id,
                                                 select: %{
                                                   email: a.email_id
                                                 }
        _cards_balances = if check_db.section == "cards_balances" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Today's balances on your company cards",
                         :name => params.name,
                         :total => params.total,
                         :time => params.time,
                         :miscdata => params,
                         :templatefile => "employeecards_template.html",
                         :layoutfile => "employeecards_template.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end
        _monthly_fees = if check_db.section == "monthly_fees" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Monthly Subscription Fees Receipt",
                         :miscdata => params,
                         :templatefile => "fee_receipt.html",
                         :layoutfile => "fee_receipt.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _company_registration_otp = if check_db.section == "company_registration_otp" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Email Authentication Required.",
                         :otp_code => params.otp_code,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "company_registration_otp.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _registration_pending = if check_db.section == "registration_pending" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Welcome to ViolaCorporate",
                         :company_name => params.company_name,
                         :director_name => params.director_name,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "company_pending.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _registration_welcome = if check_db.section == "registration_welcome" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Your ViolaCorporate Account is now ready",
                         :company_name => params.company_name,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "company_registration_welcome.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _block_card = if check_db.section == "block_card" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Your ViolaCorporate card has been blocked",
                         :employee_name => params.employee_name,
                         :card => params.card,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "company_block_employeecard.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _forgot_pin = if check_db.section == "forgot_pin" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :generate_otp => params.generate_otp,
                         :subject => "Reset Pin - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "resetpin.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _change_email = if check_db.section == "change_email" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => params.email,
                         :otp_code => params.generate_otp,
                         :subject => "Change Email - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "resendotp.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _forgot_password = if check_db.section == "forgot_password" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :generate_otp => params.generate_otp,
                         :subject => "Reset Password - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "resetpassword.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _resend_otp = if check_db.section == "resend_otp" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :generate_otp => params.generate_otp,
                         :subject => "Reset #{params.otp_source} - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "reset#{params.otp_source}.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _resend_registration_otp = if check_db.section == "resend_registration_otp" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :otp_code => params.generate_otp,
                         :subject => "Email Verification Required - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "resendotp.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_card = if check_db.section == "request_card" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :card_type => params.card_type,
                         :currency => params.currency,
                         :subject => "New Card Request - ViolaCorporate",
                         :templatefile => "new_global_template.html",
                         :layoutfile => "cardrequest.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _cardrequest_approved = if check_db.section == "cardrequest_approved" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Your Card request has been approved - ViolaCorporate",
                         :card_type => params.card_type,
                         :currency => params.currency,
                         :employee_name => params.employee_name,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "cardrequest_approved.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _cardrequest_rejected = if check_db.section == "cardrequest_rejected" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Your Card request has been rejected - ViolaCorporate",
                         :card_type => params.card_type,
                         :employee_name => params.employee_name,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "cardrequest_rejected.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _topup = if check_db.section == "topup" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "You have received money on your ViolaCorporate card",
                         :employee_name => params.employee_name,
                         :currency => params.currency,
                         :amount => params.amount,
                         :card => params.card,
                         :company_name => params.company_name,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "employee_card_topup.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _addemployee = if check_db.section == "addemployee" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "You have been added to Viola Corporate",
                         :company_name => params.company_name,
                         :employee_name => params.employee_name,
                         :pswd => params.pswd,
                         :email => getemail.email,
                         :templatefile => "add_employee.html",
                         :layoutfile => "add_employee.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_money = if params.section == "request_money" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "New Money Request - ViolaCorporate",
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :card => params.card,
                         :currency => params.currency,
                         :amount => params.amount,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "request_money.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_money_approved = if params.section == "request_money_approved" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "A Money Request has been Approved",
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :company_reason => params.company_reason,
                         :card => params.card,
                         :currency => params.currency,
                         :amount => params.amount,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "request_money_approved.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end
        _request_money_success = if params.section == "request_money_success" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Money Request Approved",
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :company_reason => params.company_reason,
                         :card => params.card,
                         :currency => params.currency,
                         :amount => params.amount,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "request_money_success.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_money_rejected = if params.section == "request_money_rejected" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "A Money Request has been rejected",
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :card => params.card,
                         :company_reason => params.company_reason,
                         :currency => params.currency,
                         :amount => params.amount,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "request_money_rejected.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_money_failed = if params.section == "request_money_failed" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Money Request Rejected",
                         :employee_name => params.employee_name,
                         :company_name => params.company_name,
                         :card => params.card,
                         :company_reason => params.company_reason,
                         :currency => params.currency,
                         :amount => params.amount,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "request_money_failed.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end

        _request_money_failed = if params.section == "card_activate" do
          _emaildata = %{
                         :from => "no-reply@violacorporate.com",
                         :to => getemail.email,
                         :subject => "Card Activation Code",
                         :employee_name => params.employee_name,
                         :card => params.card,
                         :activation_code => params.activation_code,
                         :templatefile => "new_global_template.html",
                         :layoutfile => "card_activate.html"
                       }
                       |> SendEmail.sendemail()
                       |> Mailer.deliver_later()
        end
      end
    end
  end

  #
  def sendSms(params) do
    check_db = Repo.get_by(Alertswitch, section: params.section)

    if is_map(check_db) and check_db.sms == "Y" do

      check_key  = Map.has_key?(params, :contact_number)
      check_code  = Map.has_key?(params, :code)
      contacts =  Repo.get_by(Contacts, commanall_id: params.commanall_id, is_primary: "Y")

      get_number = if check_key == true do
                        if String.first(params.contact_number) == "0" do
                          String.slice(params.contact_number, 1, 10)
                        else
                          params.contact_number
                        end
                    else
                        if String.first(contacts.contact_number) == "0" do
                          String.slice(contacts.contact_number, 1, 10)
                        else
                          contacts.contact_number
                        end
                    end

      get_code = if check_code == true do
        params.code
      else
        contacts.code
      end


      if String.first(get_number) == "7"  do


        _company_registration_otp = if check_db.section == "company_registration_otp" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your OTP code is #{params.otp_code}"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _company_registration_otp_mobile = if check_db.section == "company_registration_otp_mobile" do
          messagebody =
            %{
                          "recipients" =>"+#{get_code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your OTP code is #{params.otp_code}"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

          _change_mobile_email = if check_db.section == "change_mobile" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your OTP code is: #{params.generate_otp}, use it to change your mobile no"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _registration_welcome = if check_db.section == "registration_welcome" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Welcome to Viola Corporate"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _block_card = if check_db.section == "block_card" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your card ending #{
                            params.card
                          } has been blocked by your Company. Please contact your administrator. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _forgot_pin = if check_db.section == "forgot_pin" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your OTP code is: #{
                            params.generate_otp
                          }, use it to change your pin. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _forgot_password = if check_db.section == "forgot_password" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" =>
                            "Your OTP code is: #{
                              params.generate_otp
                            }, use it to change your password. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _resend_otp = if check_db.section == "resend_otp" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your OTP code is: #{params.generate_otp}, use it to change your #{
                            params.otp_source
                          }. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end
        _request_card = if check_db.section == "request_card" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" =>
                            "New #{params.currency} Card Request from #{params.employee_name}. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _cardrequest_approved = if check_db.section == "cardrequest_approved" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your #{params.currency} Card request has been approved. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _cardrequest_rejected = if check_db.section == "cardrequest_rejected" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Your #{params.currency} Card request has been rejected. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _topup = if check_db.section == "topup" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "You have received #{params.amount} #{params.currency} from #{
                            params.company_name
                          }. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _addemployee = if check_db.section == "addemployee" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "#{
                            params.company_name
                          } would like to provide you with a ViolaCorporate card to pay your Company expenses, please download the App to get started. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _request_money = if check_db.section == "request_money" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "New Money Request from #{params.employee_name}. ViolaCorporate Support"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _request_money_approved = if check_db.section == "request_money_approved" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Money request appproved for #{params.employee_name}"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _request_money_success = if check_db.section == "request_money_success" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Money request appproved, login to app to view details."
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _request_money_rejected = if check_db.section == "request_money_rejected" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Money request rejected for #{params.employee_name}"
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _request_money_failed = if check_db.section == "request_money_failed" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" => "Money request rejected, login to app to view details."
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end

        _card_activate = if check_db.section == "card_activate" do
          messagebody = %{
                          "recipients" => "+#{contacts.code}#{get_number}",
                          "originator" => "ViolaCorp",
                          "body" =>
                            "Activate your card ending #{params.card}, activation code: #{params.activation_code}."
                        }
                        |> Poison.encode!()
          {:ok, _ack} = Exq.enqueue(Exq, "sms", SendSms, [messagebody], max_retries: 1)
        end
      end
    end
  end

  #
  def sendNotification(params) do
    check_db = Repo.get_by(Alertswitch, section: params.section)

    if is_map(check_db) and check_db.notification == "Y" do

      get_platform = Repo.get_by(Devicedetails, commanall_id: params.commanall_id, status: "A", is_delete: "N")

      _send = if is_nil(get_platform) do
      else
        _registration_welcome = if check_db.section == "registration_welcome" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Welcome to Viola Corporate"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _block_card = if check_db.section == "block_card" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" =>
                "Your card ending #{params.card} has been blocked by your Company. Please contact your administrator"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _forgot_pin = if check_db.section == "forgot_pin" do

          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Your OTP code is: #{params.generate_otp}, use it to change your pin."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _forgot_pin = if check_db.section == "change_mobile" do

          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "We found request to change mobile #{params.contact_number} number."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _forgot_password = if check_db.section == "forgot_password" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Your OTP code is: #{params.generate_otp}, use it to change your password."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _resend_otp = if check_db.section == "resend_otp" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Your OTP code is: #{params.generate_otp}, use it to change your #{params.otp_source}."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _request_card = if check_db.section == "request_card" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "New #{params.currency} Card Request from #{params.employee_name}."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _cardrequest_approved = if check_db.section == "cardrequest_approved" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Your #{params.currency} Card request has been approved."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _cardrequest_rejected = if check_db.section == "cardrequest_rejected" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Your #{params.currency} Card request has been rejected."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _topup = if check_db.section == "topup" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "You have received #{params.amount} #{params.currency} from #{params.company_name}"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _addemployee = if check_db.section == "addemployee" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "You have been added to Viola Corporate"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _request_money = if check_db.section == "request_money" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "New Money Request from #{params.employee_name}."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        #     COMPANY CANNOT RECEIVE NOTIFICATION
        _request_money_approved = if check_db.section == "request_money_approved" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Money request Approved"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _request_money_success = if check_db.section == "request_money_success" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "#{params.company_name} has approved your money request for card: #{params.card}."
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        #      COMPANY CANNOT RECEIVE NOTIFICATION
        _request_money_rejected = if check_db.section == "request_money_rejected" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Money request Rejected"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _request_money_failed = if check_db.section == "request_money_failed" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "#{params.company_name} has rejected your money request for card: #{
                params.card
              }. Contact your Administrator"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end

        _card_activate = if check_db.section == "card_activate" do
          messagebody = %{
            "token" => get_platform.token,
            "msg" => %{
              "body" => "Activate your card ending #{params.card}, activation code: #{params.activation_code}"
            }
          }
          send_mobile_notifications(get_platform.type, messagebody)
        end
      end
    end
  end

  def storeNotification(params) do

    _registration_welcome = if params.section == "registration_welcome" do

      message = "Welcome to ViolaCorporate, #{params.company_name}."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _block_card = if params.section == "block_card" do

      message = "As per your request, your ViolaCorporate, #{params.card} has been blocked."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
   end

    _request_card = if params.section == "request_card" do

      message = "New #{params.currency} Card Request from #{params.employee_name}."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _cardrequest_approved = if params.section == "cardrequest_approved" do

      message = "#{params.currency} Card request has been approved for #{params.employee_name}."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _cardrequest_rejected = if params.section == "cardrequest_rejected" do

      message = "Card request has been rejected."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _topup = if params.section == "topup" do

      message = "As per your request, #{params.amount} #{params.currency} has been transferred to #{
        params.employee_name
      }'s card ending: #{params.card}."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _addemployee = if params.section == "addemployee" do

      message = " Request to join ViolaCorporate sent to #{params.employee_name}"

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _request_money = if params.section == "request_money" do

      message = "#{params.employee_name} requested #{params.amount} #{params.currency} for card #{params.card}."

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _request_money_approved = if params.section == "request_money_approved" do

      message = "Money request Approved for #{params.employee_name}"

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _request_money_rejected = if params.section == "request_money_rejected" do

      message = "Money request Rejected for #{params.employee_name}"

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end

    _card_activate = if params.section == "card_activate" do

      message = "#{params.employee_name} has requested Activation Key & Activation code for card ending #{params.card}"

      notification_details = %{
        "commanall_id" => params.commanall_id,
        "subject" => params.section,
        "message" => message,
        "inserted_by" => params.commanall_id
      }
      insert = Notifications.changeset(%Notifications{}, notification_details)
      Repo.insert(insert)
    end
  end

  def send_mobile_notifications(type, messagebody) do

    if type == "A" do
      Exq.enqueue(Exq, "notification", SendAndroid, [messagebody], max_retries: 1)
    else
      if type == "I" do
        Exq.enqueue(Exq, "notification", SendAndroid, [messagebody], max_retries: 1)
#        Exq.enqueue(Exq, "notification", SendIos, [messagebody], max_retries: 1)
      end
    end
  end

end
