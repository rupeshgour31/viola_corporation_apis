use Mix.Config

#
#added by - Inderjit singh
#this file is to create own configs
#all custom configs related to project will be here
#

# to get value from config files
# custom = Application.get_env(:messageKeys, :myVar)


config :violacorp,
       message_bird_key: System.get_env("VC_MESSAGEBIRD"),
       otp_mode: "dev",
       get_address_key: System.get_env("VC_GETADDRESS_KEY"),
       tokenKey: System.get_env("VC_TOKEN_KEY"),
       country_id: System.get_env("LOCAL_COUNTRY_ID"),
       country_code: System.get_env("LOCAL_COUNTRY_CODE"),
       currency_code: System.get_env("LOCAL_CURRENCY_CODE"),
       currency_id: System.get_env("LOCAL_CURRENCY_ID"),
       accomplish_country_code: System.get_env("LOCAL_ACCOMPLISH_COUNTRY_CODE"),
       accomplish_is_primary: System.get_env("LOCAL_ACCOMPLISH_IS_PRIMARY"),
       accomplish_latitude: System.get_env("LOCAL_ACCOMPLISH_LATITUDE"),
       accomplish_longitude: System.get_env("LOCAL_ACCOMPLISH_LONGITUDE"),
       accomplish_position_description: System.get_env("LOCAL_ACCOMPLISH_POSITION_DESCRIPTION"),
       accomplish_time_zone: System.get_env("LOCAL_ACCOMPLISH_TIME_ZONE"),
       accomplish_password: System.get_env("LOCAL_ACCOMPLISH_PASSWORD"),
       accomplish_secret_answer_1: System.get_env("LOCAL_ACCOMPLISH_SECRET_ANSWER_1"),
       accomplish_secret_answer_2: System.get_env("LOCAL_ACCOMPLISH_SECRET_ANSWER_2"),
       accomplish_secret_question_1: System.get_env("LOCAL_ACCOMPLISH_SECRET_QUESTION_1"),
       accomplish_secret_question_2: System.get_env("LOCAL_ACCOMPLISH_SECRET_QUESTION_2"),
       accomplish_security_code: System.get_env("LOCAL_ACCOMPLISH_SECURITY_CODE"),

       card_type: System.get_env("LOCAL_CARD_TYPE"),
       ewallet_type: System.get_env("LOCAL_EWALLET_TYPE"),

       fulfilment_config_id_v: System.get_env("LOCAL_FULFILMENT_CONFIG_ID_V"),

       fulfilment_config_id_p: System.get_env("LOCAL_FULFILMENT_CONFIG_ID_P"),

         # ACCOMPLISH CREDENTIAL
       api_token: "Bearer YmU0YjMwYTgyNmRkNGUwOThlNThmMDYyMGQzNDJkYTY=.eyJJbnN0aXR1dGlvbklkIjoiOTk4MDZmMzItYjIzMy00NWRmLWIyZDgtZWU4YWQzM2I0MWFlIiwiVG9rZW4iOiI0RDk0QTcwNURFQUI0MjhEQjVGMTU5NkYzMzFCMkNGNTgxQ0E0REM4ODBBODRGNkNBNjU4RDQyMjgxNjY3Qzg0RDRDMUU3MzkwMEI3NDcyQjg2NDJGQURBOTE4MDA3NzYifQ==",
       api_url: "https://institution-api-sim.clearbank.co.uk/",


       acc_grant_type: System.get_env("LIVE_GRANT_TYPE"),
       acc_language: System.get_env("LIVE_LANGUAGE"),
       acc_password: System.get_env("LIVE_PASSWORD"),
       acc_program_id: System.get_env("LIVE_PROGRAM_ID"),
       acc_username: System.get_env("LIVE_USERNAME"),
       acc_live_url: System.get_env("LIVE_URL"),


       username: "hello",
       password: "hello",


         # Card bin id and number
       gbp_card_bin_id: System.get_env("LOCAL_GBP_CARD_BIN_ID"),
       gbp_card_number: System.get_env("LOCAL_GBP_CARD_NUMBER"),

         # account bin id and number
       gbp_acc_bin_id: System.get_env("LOCAL_GBP_ACC_BIN_ID"),
       gbp_acc_number: System.get_env("LOCAL_GBP_ACC_NUMBER"),


       usd_card_bin_id: System.get_env("LOCAL_USD_CARD_BIN_ID"),
       usd_card_number: System.get_env("LOCAL_USD_CARD_NUMBER"),

       eur_card_bin_id: System.get_env("LOCAL_EUR_CARD_BIN_ID"),
       eur_card_number: System.get_env("LOCAL_EUR_CARD_NUMBER"),

       usd_acc_bin_id: System.get_env("LOCAL_USD_ACC_BIN_ID"),
       usd_acc_number: System.get_env("LOCAL_USD_ACC_NUMBER"),

       eur_acc_bin_id: System.get_env("LOCAL_EUR_ACC_BIN_ID"),
       eur_acc_number: System.get_env("LOCAL_EUR_ACC_NUMBER"),

       limited_debit: System.get_env("LOCAL_LIMITED_DEBIT"),
       general_credit: System.get_env("LOCAL_GENERAL_CREDIT"),
       transaction_type: System.get_env("LOCAL_TRANSACTION_TYPE"),


       max_count: 1000,
       min_amount: "10.00",
       min_amount_account: "1.00",
       min_amount_currency: "1.00",
       max_amount_card: "500.00",
       card_fee: System.get_env("VBU_CARD_FEE")

