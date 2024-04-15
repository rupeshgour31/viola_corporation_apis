use Mix.Config


config :cloak,
       Cloak.AES.CTR,
       default: true,
       tag: System.get_env("VC_CLOAK_TAG"),
       keys: [
         %{tag: <<1>>, key: Base.decode64!(System.get_env("VC_CLOAK_KEY")), default: true}
       ]

config :exq,
       host: System.get_env("VC_EXQ_HOST"),
       port: System.get_env("VC_EXQ_PORT"),
       namespace: System.get_env("VC_EXQ_NAMESPACE"),
       concurrency: System.get_env("VC_EXQ_CONCURRENCY"),
       scheduler_enable: true,
       queues: [
        "email",
        "sms",
        "notification",
        "physical_card",
        "company_identification",
        "create_identification",
        "manual_success",
        "manual_pending",
        "manual_load",
        "pending_transactions_updater",
        "success_transactions_updater",
        "generate_report",
        "daily_cardsbalances_sender",
        "block_unblock",
        "documentupload",
        "employee_id_proof",
        "employee_address_proof",
        "company_id_proof",
        "company_address_proof",
        "update_trustlevel",
        "enable_disable_block",
        "identification",
        "upload_document"
       ]
#       queues: [
#             "email",
#             "sms",
#             "notification",
#             "physical_card",
#             "company_identification",
#             "create_identification",
#             "manual_success",
#             "manual_pending",
#             "manual_load",
#             "pending_transactions_updater",
#             "success_transactions_updater",
#             "generate_report",
#             "daily_cardsbalances_sender",
#             "block_unblock",
#             "company_address_proof",
#             "company_id_proof"
#       ]


config :exq_ui,
       server: false

config :pigeon,
       :apns,
       apns_default: %{
         cert: System.get_env("VC_APNS_CERT"),
         key: System.get_env("VC_APNS_KEY"),
         mode: :dev
       }


config :pigeon,
       :fcm,
       fcm_default: %{
         key: System.get_env("VC_FCM_KEY")
       }

config :violacorp,
       Violacorp.Mailer,
       adapter: Bamboo.MailgunAdapter,
       api_key: System.get_env("VC_BAMBOO_API_KEY"),
       domain: "violacorporate.com"

# Configure your database
config :violacorp,
       Violacorp.Repo,
       adapter: Ecto.Adapters.MySQL,
       username: System.get_env("VC_DB_USERNAME"),
       password: System.get_env("VC_DB_PASSWORD"),
       database: System.get_env("VC_DB_DATABASE"),
       hostname: System.get_env("VC_DB_HOST"),
       pool_size: 10

config :ex_aws,
       access_key_id: [System.get_env("VC_AWS_ACCESS_KEY_ID"), :instance_role],
       secret_access_key: [System.get_env("VC_AWS_SECRET_ACCESS_KEY"), :instance_role],
       region: "eu-west-2"

config :logger, CloudWatch,
       log_group_name: "ViolaCorporate",
       log_stream_name: System.get_env("VC_STREAM_NAME"),
       max_buffer_size: 10_485,
       max_timeout: 60_000

config :violacorp,Violacorp.Mailer,
       adapter: Bamboo.LocalAdapter
#config :violacorp,Violacorp.Mailer,
#       adapter: Bamboo.SMTPAdapter,
#       server: System.get_env("VC_SES_SERVER"),
#       port: System.get_env("VC_SES_PORT"),
#       username: System.get_env("VC_SMTP_USERNAME"),
#       password: System.get_env("VC_SMTP_PASSWORD"),
#       tls: :always, # can be `:always` or `:never`
#       ssl: true, # can be `true`
#       retries: 1

config :violacorp,
       Violacorp.Scheduler,
       jobs: [
         monthly_fee: [
           schedule: "@daily",
           task: {ViolacorpWeb.Main.CronController, :companyMonthlyFee, []},
         ],
         success_transactions: [
           schedule: "@daily",
           task: {ViolacorpWeb.Main.CronController, :employeeSuccessTransaction, []},
         ],
         daily_cardbalances: [
           schedule: "@daily",
           task: {ViolacorpWeb.Main.CronController, :employeeCardsBalance, []},
         ]
       ]