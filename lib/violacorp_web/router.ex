defmodule ViolacorpWeb.Router do
  use ViolacorpWeb, :router

  #  pipeline for development for exqui
  pipeline :exq do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
    plug ExqUi.RouterPlug, namespace: "exq"
  end

  if Mix.env == :dev do
    forward "/email_check", Bamboo.EmailPreviewPlug
  end

  scope "/exq", ExqUi do
    pipe_through :exq

    forward "/", RouterPlug.Router, :index
  end

  pipeline :api_without_token do
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ViolacorpWeb.Plugs.Auth
  end

  scope "/", ViolacorpWeb do
    pipe_through :api_without_token

    get "/", Comman.RooController, :yahoo
    post "/", Comman.RooController, :yahoopost
  end

  scope "/api", ViolacorpWeb do
    pipe_through :api_without_token


    # This route for alert switch
    post "/alert/switch/getAll", Admin.AlertswitchController, :getAllAlertswitch
    get "/single/alert/switch/:id", Admin.AlertswitchController, :singleAlertswitch
    post "/alert/switch/add", Admin.AlertswitchController, :insertAlertswitch
    post "/alert/switch/edit", Admin.AlertswitchController, :editAlertSwitch
    post "/update/country", Admin.AdminController, :updateConutryAddress
    get "/update_commanall_status/:commanall_id", Comman.ManualServiceController, :update_commanall_status
    get "/update_internal_status", Comman.ManualServiceController, :update_internal_status
    # end  of  alert switch routes

    post "/kyc/login", Kyclogin.KycloginController, :kycLogin
    post "/director/changePassword", Kyclogin.KycloginController, :reset_password
    get "/date/test", Comman.TestController, :test


    #    # TESTs
    #    post "/tests", Kyclogin.KycloginController, :resend_otp
    #    post "/testing", Admin.AdminController, :sort_gender
    #    post "/testd", Test.TestingController, :testd
    #    post "/check_notification", Test.TestController, :testing_emails
    #    get "/testing", Main.CronController, :employeeCardsBalance
    #    get "/testnotification", Test.TestController, :testnotification


    #---------------------------------------
    #Companies House Routes
    get "/getCompanyDetails/:companyid", Thirdparty.ThirdpartyController, :getCompanyDetails
    get "/getCompanyOfficers/:companyid", Thirdparty.ThirdpartyController, :getCompanyOfficers
    get "/getCompanyAddress/:companyid", Thirdparty.ThirdpartyController, :getCompanyAddress
    get "/getCompanyInsolvency/:companyid", Thirdparty.ThirdpartyController, :getCompanyInsolvency
    get "/getCompanyFilingHistory/:companyid", Thirdparty.ThirdpartyController, :getCompanyFilingHistory
    #----------------------------------------
    post "/check/update/history", Company.CompanyController, :updateHistory
    get  "/kyc/country/list", Comman.CountryController, :getKycCountry

    # without token
    post "/registration/company",
         Main.RegistrationController,
         :company                               # Registred for company details
    post "/registration/companyAddressContact",
         Main.RegistrationController,
         :companyAddressContact   # Company address and contact details
    post "/registration/companyDirectors",
         Main.RegistrationController,
         :companyDirectors             # Directores address and contact details
    post "/registration/companyDirectorsNew",
         Main.RegistrationController,
         :companyDirectorsNew             # Directores address and contact details

    # NEW REG
    post "/registration/companyNew",
         Main.RegistrationController,
         :companyNew                               # Registred for company details
    post "/registration/companyNewVerify",
         Main.RegistrationController,
         :companyNewVerify                               # Registred for company details
    post "/registration/companyDetails",
         Main.RegistrationController,
         :companyDetails                              # Registred for company details
    post "/registration/resendOtp",
         Main.RegistrationController,
         :resend_registration_otp                              # Resends a new otp for email verification


    # V1 Registration
    post "/registration/step_one", Main.VoneRegistrationController, :step_one
    post "/registration/step_two", Main.VoneRegistrationController, :step_two
    post "/registration/step_three", Main.VoneRegistrationController, :step_three
    post "/registration/step_four", Main.VoneRegistrationController, :step_four
    post "/registration/step_five", Main.VoneRegistrationController, :step_five
    post "/registration/step_six", Main.VoneRegistrationController, :step_six
    post "/registration/step_seven", Main.VoneRegistrationController, :step_seven


    # V3 Registration
    post "/v3/registration/step_one", Main.V3RegistrationController, :step_one     # Initial user(main dir)
    post "/v3/registration/step_two", Main.V3RegistrationController, :step_two     # Verify Email
    post "/v4/registration/step_two", Main.V3RegistrationController, :step_two_v2     # Verify Email
    post "/v3/registration/step_three", Main.V3RegistrationController, :step_three # Verify Mobile
    post "/v3/registration/changeMobileNumber", Main.V3RegistrationController, :changeMobileNumber # change Mobile
    post "/v3/registration/step_four", Main.V3RegistrationController, :step_four   # Create Passcode
    post "/v3/registration/step_five", Main.V3RegistrationController, :step_five   # Business Details
    post "/v3/registration/step_six", Main.V3RegistrationController, :step_six     # Extra Directors or owner
    post "/v3/registration/step_seven", Main.V3RegistrationController, :step_seven # Extra Significant Person
    post "/v3/registration/step_eight", Main.V3RegistrationController, :step_eight # Mandate and Signature
    post "/get_first_director", Main.V3RegistrationController, :get_first_company_director

    post "/director/upload/kyc/stepOne", Company.CapController, :uploadKycFirst
    post "/director/upload/kyc/stepTwo", Company.CapController, :uploadKycSecond
    get "/director/skip/:director_id/:step", Company.CapController, :skipStep

    # Testing for Image Upload99999
    post "/registration/uploadKyc",
         Main.RegistrationController,
         :uploadKyc             # Directores address and contact details

    post "/registration/companyAddress",
         Main.RegistrationController,
         :companyAddress                 # Company address only
    post "/registration/companyLoginDetails",
         Main.RegistrationController,
         :companyLoginDetails       # Company Login Details

    post "/login",
         Main.MainController,
         :login                                                        # used for login in main controller
    post "/check_password",
         Main.MainController,
         :checkPassword                                       # Check Admin Login
    post "/manualPassword",
         Company.CommonController,
         :changePassword                                       # Check Admin Login
    post "/generatePassword",
         Company.CommonController,
         :generatePassword                                       # Check Admin Login
    post "/chagePass", Company.CommonController, :chagePass                                       # Check Admin Login
    post "/verifyPassword",
         Company.CommonController,
         :verifyPassword                                       # Check Admin Login
    post "/updateTrustLevel", Comman.TestController, :updateTrustLevel                          # update Trust Level
    post "/admin/company/blockUnblock",
         Comman.TestController,
         :blockUnBlockCompany             # Company Block UnBlock by Admin

    post "/forgotPasswordOne",
         Main.MainController,
         :forgotPasswordOne                                # used for forgot password in main controller
    post "/forgotPasswordTwo",
         Main.MainController,
         :forgotPasswordTwo                                # used for forgot password in main controller
    post "/resendOtp/:id",
         Main.MainController,
         :resend_otp                                           # used for resend_otp in main controller

    post "/changeAdminPassword",
         Company.CommonController,
         :changeAdminPassword                       # Change Admin Password

    post "/cache_remover", Admin.AdminController, :cache_remover

    # Accomplish Services
    post "/authorize_process", Comman.TestController, :test_accomplish                           # accomplish reg

    post "/create_account", Comman.TestController, :create_account
    post "/update_account", Comman.TestController, :update_account
    post "/test_identification", Comman.TestController, :test_identification
    post "/employee/identification", Comman.TestController, :employee_identification
    post "/test_document", Comman.TestController, :test_document
    post "/getuser", Comman.TestController, :getuser
    post "/get_pending_transaction", Comman.TestController, :get_pending_transaction
    post "/admin_deactive_card", Comman.TestController, :admin_deactive_card
    post "/admin_block_card", Comman.TestController, :admin_block_card
    post "/get_success_transaction", Comman.TestController, :get_success_transaction
    post "/employee/registration", Employees.EmployeesController, :employeeDirectRegistration
    post "/employee/generateCard", Comman.TestController, :admin_generate_card
    post "/manual/transactions", Employees.EmployeesController, :manualTransactions
    post "/admin/companyUploadIdProof", Comman.TestController, :companyUploadIdProof
    post "/admin/companyUploadAddressProof", Comman.TestController, :companyUploadAddressProof
    post "/admin/employeeUploadIdProof", Comman.TestController, :employeeUploadIdProof
    post "/admin/employeeUploadAddressProof", Comman.TestController, :employeeUploadAddressProof
    post "/admin/employeeCardGenerate", Comman.TestController, :employeeCardGenerate

    post "/company/topup/account", Transaction.TransactionController, :topupWithoutToken
    post "/company/manual/withdraw", Transaction.TransactionController, :manualWithdraw

    # Settings Services
    post "/Kyclogin/resetPassword",
         Kyclogin.KycloginController,
         :reset_password                                 # Get All Active Country List
    post "/resetcache",
         Admin.AdminController,
         :remove_cache                                 # Get All Active Country List
    get "/country/getAll",
        Comman.CountryController,
        :getAllCountry                                 # Get All Active Country List
    get "/v1/country/getAll",
        Comman.CountryController,
        :getAllCountryv1
    get "/country/getSingle/:id", Comman.CountryController, :getSingleCountry                       # Get Single Country
    get "/currency/getAll",
        Comman.CurrencyController,
        :getAllCurrency                              # Get All Active Currency List
    get "/currency/getSingle/:id",
        Comman.CurrencyController,
        :getSingleCurrency                    # Get Single Currency
    get "/documentType/getAll",
        Comman.DocumenttypeController,
        :getAllDocumenttype                  # Get All Active Document Type List
    get "/documentType/getSingle/:id",
        Comman.DocumenttypeController,
        :getSingleDocumenttype        # Get Single Document Type

    get "/documentType/getAddressProofList",
        Comman.DocumenttypeController,
        :getAddressProofList    # Get Document Address Proof List
    get "/documentType/getIdProofList",
        Comman.DocumenttypeController,
        :getIdProofList              # Get Document Id Proof List

    get "/getAddress/:postcode", Company.RequestdataController, :getAddress
    get "/getPositionList", Company.RequestdataController, :getPositionList
    get "/company/getRegstep/:commanallid", Company.RequestdataController, :getRegdata

    get "/resetToken/:id", Main.MainController, :resetToken

    get "/get_sector", Main.VoneRegistrationController, :get_sector
    get "/get_monthly_value", Main.VoneRegistrationController, :get_monthly_value
    get "/get_first_director/:commanall_id", Main.VoneRegistrationController, :get_first_director
    get "/get_directors_list/:commanall_id", Main.VoneRegistrationController, :get_directors_list
    get "/get_monthly_feerule", Main.VoneRegistrationController, :get_fee_rule

    # Admin routes
    post "/admin/updateAdmin/:id",
         Admin.AdminController,
         :updateAdmin      # * it is used for registration in main controller

    post "/admin/settlement", Admin.AdminController, :settlement

    post "/admin/director/gbg/verify", Comman.TestController, :director_verify_GBG
    post "/admin/employee/gbg/verify", Comman.TestController, :employeeGBGVerify
    post "/admin/sortGender", Admin.AdminController, :sort_gender

    # ContactUs
    post "/contactUs", Admin.AdminController, :contactUs      # it is used for contact us in Admin Controller
    post "/admin/employees/welcomeMail", Company.CommonController, :adminresendEmail
    post "/admin/sendmail", Company.CommonController, :adminSendmail
    post "/company/balanceRefresh", Main.CronController, :companyRefreshBalance
    post "/employee/balanceRefresh", Main.CronController, :employeeRefreshBalance
    post "/employee/loadTransaction", Main.CronController, :employeePosTransaction

    # 4 Stop call back method
    #    post "/fourstop/callback", Main.MainController, :callbackPost
    #    get "/fourstop/callback", Main.MainController, :callbackGet
    post "/fourstop/callback", Thirdparty.ThirdpartyController, :fourstop_callback


    #    TESTING
    post "/get_otp", Main.MainController, :automate_otp
    get "/back/:commanid/:id", Main.MainController, :backUrl
    get "/update/receipt", Transaction.TransactionController, :update_receipt
    post "/company/uploadDocument", Company.CompanyController, :uploadDocument

    # ViolaPay Request Payment
    post "/internal/payment", Transaction.PaymentController, :acceptMoney

    # Token Refresh
    post "/refresh/token", Main.MainController, :refreshToken


    # Admin Account
    post "/admin/accomplish/account",
         Thirdparty.ThirdpartyController,
         :accomplishAccount              # Create Accomplish Account
    post "/admin/createAdminAccount",
         Thirdparty.ThirdpartyController,
         :createAdminAccount              # Create Fee Type Account on Accomplish
    post "/admin/accomplish/Fee/account",
         Thirdparty.ThirdpartyController,
         :accomplishFeeAccount              # Create Fee Type Account on Accomplish
    post "/admin/fee/account",
         Thirdparty.ThirdpartyController,
         :feeAccount                            # Create Fee Account
    post "/admin/money/account",
         Thirdparty.ThirdpartyController,
         :violamoneyAccount                            # Create Fee Account
    post "/admin/suspense/account",
         Thirdparty.ThirdpartyController,
         :suspenseAccount                            # Create Suspense Account
    post "/resetOtpLimit", Thirdparty.ThirdpartyController, :resetOtpLimit
    post "/admin/accomplish/transactions", Thirdparty.ThirdpartyController, :get_accomplish_cb_transactions
    post "/admin/fee/transactions", Thirdparty.ThirdpartyController, :get_fee_cb_transactions
    #    post "/admin/transactions/update/remark", Admin.AdminController, :update_existing_trans_remark
    post "/admin/transactions/remove/remark", Admin.AdminController, :remove_info
    post "/admin/transactions/update/remark", Admin.AdminController, :update_remark

    post "/admin/duefees/getSingle", Admin.AdminController, :single_duefees

    # Admin Account Balance Refresh
    post "/admin/account/balance/refresh", Thirdparty.BankController, :adminAccountBalanceRefresh

    # WebHook
    post "/verifySignature", Thirdparty.ListenerController, :verifySignature
    post "/accountCreated",
         Thirdparty.ListenerController,
         :accountCreated                                         # https://apis-dev.violacorporate.com:4004/api/accountCreated
    post "/accountDisabled",
         Thirdparty.ListenerController,
         :accountDisabled                                       # https://apis-dev.violacorporate.com:4004/api/accountDisabled
    post "/transactionRejected",
         Thirdparty.ListenerController,
         :transactionRejected                               # https://apis-dev.violacorporate.com:4004/api/transactionRejected
    post "/transactionSettled",
         Thirdparty.ListenerController,
         :transactionSettled                                 # https://apis-dev.violacorporate.com:4004/api/transactionSettled
    post "/paymentMessageAssessmentFailed",
         Thirdparty.ListenerController,
         :paymentMessageAssessmentFailed         # https://apis-dev.violacorporate.com:4004/api/paymentMessageAssessmentFailed

    post "/viola/pushNotification", Thirdparty.AccomplishListenerController, :listener

    # Fee Add & Edit
    post "/fees/insert",
         Fees.FeesController,
         :insertFees                              # used to insert record in fees table
    post "/fees/update/:id",
         Fees.FeesController,
         :updateFees                          # used to update record in fees table by using Id
    post "/fees/getAll",
         Fees.FeesController,
         :getAllFees                               # used to getAll records from fees table
    post "/fees/getSingle/:id",
         Fees.FeesController,
         :getSingleFees                     # used to getsingle record from fees table by using Id

    post "/groupFees/insert",
         Fees.FeesController,
         :insertGroupFees                    # used to insert record in Group fees table
    post "/groupFees/update/:id",
         Fees.FeesController,
         :updateGroupFees                # used to update record in Group fees table by using Id
    post "/groupFees/getAll",
         Fees.FeesController,
         :getAllGroupFees                     # used to getAll records from Group fees table
    post "/groupFees/getSingle/:id",
         Fees.FeesController,
         :getSingleGroupFees           # used to getsingle record from Group fees table by using Id

    # Update History
    ## Admin Login
    post "/admin/login", Admin.LoginController, :login

    # Manual Services
    post "/updateDirectorsSequence", Comman.ManualServiceController, :updateDirectorsSequence
    post "/storeConfigVariable", Comman.ManualServiceController, :storeConfigVariable
    get "/checkLogger", Comman.ManualServiceController, :checkLogger
    post "/manualRefundBankAccount", Thirdparty.BankController, :adminAccount2CompanyBank

  end

  scope "/api", ViolacorpWeb do
    pipe_through :api # Use the default browser stack

    # ClearBank Testing
    get "/clearbank/test", Thirdparty.BankController, :checkMethod
    post "/clearbank/createAccount", Thirdparty.BankController, :createAccount
    post "/clearbank/balance/refresh", Thirdparty.BankController, :balanceRefresh
    get "/clearbank/accounts", Thirdparty.BankController, :pullAccounts
    get "/clearbank/transactions/:accountId", Thirdparty.BankController, :pullAllTransactions
    get "/clearbank/transactions/:accountId/:transactionId", Thirdparty.BankController, :pullSingleTransactions
    get "/clearbank/payments", Thirdparty.BankController, :payments
    get "/manual/pull/listener", Thirdparty.BankController, :pullListenerData
    post "/manual/capture/card", Thirdparty.ThirdpartyController, :check_cards
    get "/admin/reset/admin/token/:id", Admin.LoginController, :resetTokenAdmin
    get "/updateHistory/get/:type/:id", Admin.AdminController, :getUpdatedHistory
    get "/admin/duefees/getAll", Admin.AdminController, :all_duefees
    # Refresh Card Balance
    get "/card/balance/refresh/:cardId", Company.CompanyController, :refreshCardBalance
    get "/upload/document/:id", Comman.TestController, :upload_direct_document
    get "/upload/identification_document/:id", Comman.TestController, :upload_identification_document
    get "/director/upload/identification_document/:id", Comman.TestController, :upload_identification_document_director
    get "/director/upload/document/:id", Comman.TestController, :upload_document_director
    get "/create_employee/:id", Comman.TestController, :create_employee
    get "/check_cards/:id", Comman.TestController, :check_cards

    # For update count
    get "/menual/card/transaction/count", Transaction.TransactionController, :menualCardTransactionCount
    get "/menual/card/transaction/Receipt/Count", Transaction.TransactionController, :menualCardTransactionReceiptCount
    get "/monthlyFee", Main.CronController, :chargeMonthlyFee
    get "/admin/getAll",
        Admin.AdminController,
        :getAllAdmin                # * it is used for registration in main controller
    get "/admin/getSingle/:id",
        Admin.AdminController,
        :getSingleAdmin      # * it is used for registration in main controller
    get "/testnotification", Test.TestController, :all_notification


    #kyc upload document
    post "/upload/director/kyc", Kyclogin.KycloginController, :uploadKyc
    post "/director/verify/otp", Kyclogin.KycloginController, :verifyOtp
    post "/director/change/contact", Kyclogin.KycloginController, :changeContact
    get "/director/resetOtpLimit", Kyclogin.KycloginController, :resend_otp

    post "/addMore/director", Main.V3RegistrationController, :addMoreDirectors

    get "/createFamily", Thirdparty.FamilyController, :createFamily
    get "/employee/acceptlegal", Main.MainController, :acceptlegal
    post "/forgotPinOne",
         Main.MainController,
         :forgotPinOne                                          # used for forgotpin in main controller
    post "/forgotPinTwo",
         Main.MainController,
         :forgotPinTwo                                          # used for forgotpin in main controller
    get "/logout", Main.MainController, :logout   # Logout

    post "/employee/upload/kyc/stepOne", Employees.EmployeesController, :uploadKycFirstV1
    post "/employee/upload/kyc/stepTwo", Employees.EmployeesController, :uploadKycSecondV1
    get "/employee/skip/:step", Employees.EmployeesController, :skipStep

    # Common routes
    get "/company/employee/device/logout",
        Main.MainController,
        :logoutDevice                                       # logsout an employee from mobile app to remove device token
    post "/company/employee/createPin",
         Main.MainController,
         :createPin                                       # update employee pin
    post "/reset_password",
         Main.MainController,
         :resetEmployeePassword                                       # update employee pass

    post "/country/insert",
         Comman.CountryController,
         :insertCountry                                      # Insert Country
    post "/country/update/:id",
         Comman.CountryController,
         :updateCountry                                  # Update Country

    post "/currency/insert",
         Comman.CurrencyController,
         :insertCurrency                                   # Insert Currency
    post "/currency/update/:id",
         Comman.CurrencyController,
         :updateCurrency                               # Update Currency

    post "/documentType/insert",
         Comman.DocumenttypeController,
         :insertDocumenttype                       # Insert Document Type
    post "/documentType/update/:id",
         Comman.DocumenttypeController,
         :updateDocumenttype                   # Update Document Type

    post "/documentCategory/insert",
         Comman.DocumentcategoryController,
         :insertDocumentCategory           # Insert Document Category
    post "/documentCategory/update/:id",
         Comman.DocumentcategoryController,
         :updateDocumentCategory       # Update Document Category
    get "/documentCategory/getAll",
        Comman.DocumentcategoryController,
        :getAllDocumentCategory            # Get All Active Document Category List
    get "/documentCategory/getSingle/:id",
        Comman.DocumentcategoryController,
        :getSingleDocumentCategory  # Get Single Document Category

    # Departments routes
    post "/department/insert",
         Departments.DepartmentController,
         :insertDepartment             # used for adding the department details
    post "/department/update/:id",
         Departments.DepartmentController,
         :updateDepartment         # used for updating/editing the departmental details
    get "/department/getAll",
        Departments.DepartmentController,
        :getAllDepartments  # used to get the complete department
    post "/department/getFiltered",
         Departments.DepartmentController,
         :getFilteredDepartments  # used to get the complete department
    get "/department/getSingle/:id",
        Departments.DepartmentController,
        :getSingleDepartment  # used to get the single department record
    get "/department/deleteSingle/:id",
        Departments.DepartmentController,
        :deleteDepartment  # used to get the single department record

    # Projects routes
    post "/project/insert",
         Projects.ProjectsController,
         :insertProject               # used to insert the project in project controller
    post "/project/update/:id",
         Projects.ProjectsController,
         :updateProject           # used to update the project with the given id
    get "/project/getAll/",
        Projects.ProjectsController,
        :getAllProjects    # used to get all records from project with the given companyid
    post "/project/getFiltered",
         Projects.ProjectsController,
         :getFilteredProjects    # used to get all records from project with the given companyid
    get "/project/getSingle/:id",
        Projects.ProjectsController,
        :getSingleProject  # used to get single record from project
    get "/project/delete/:id", Projects.ProjectsController, :softDeleteProject  # used to get single record from project

    # Company routes
    post "/company/department/insert/:companyId",
         Company.CompanyController,
         :insertCompanyDepartment   # * used to insert the record in department
    post "/company/project/insert/:companyId",
         Company.CompanyController,
         :insertCompanyProject         # * used to insert the record in project table
    post "/company/employee/insert/:companyId",
         Company.CompanyController,
         :insertCompanyEmployee       # used to insert the record in employee table
    post "/company/employee/info/insert/:companyId",
         Company.CompanyController,
         :insertCompanyEmployeeInfo  # used to insert the record in employee
    post "/company/manager/insert/:companyId",
         Company.CompanyController,
         :insertCompanyManager     # used to insert the record in managers table
    post "/company/assignCard/insert/:companyId",
         Company.CompanyController,
         :assignCard            # * used to insert the record in assigncard
    post "/company/department/update/:companyId/:id",
         Company.CompanyController,
         :updateCompanyDepartment   # * used to update record in department
    post "/company/project/update/:companyId/:id",
         Company.CompanyController,
         :updateCompanyProject         # * used to update record in project table
    post "/company/employee/update/:id",
         Company.CompanyController,
         :updateCompanyEmployee          # used to update record in employee table
    post "/company/manager/update/:id",
         Company.CompanyController,
         :updateCompanyManager            # used to update record in managers table
    post "/company/assignCard/update/:compafnyId/:id",
         Company.CompanyController,
         :updateCompanyAssignCard   # * used to update record in managers
    post "/company/mobile/change/stepOne",
         Company.CompanyController,
         :changeMobileStepOne   # * change company mobile Step Two
    post "/company/mobile/change/stepTwo",
         Company.CompanyController,
         :changeMobileStepTwo   # * change company mobile Step Two
    post "/company/email/change/stepOne",
         Company.CompanyController,
         :changeEmailStepOne   # * change company email Step One
    post "/company/email/change/stepTwo",
         Company.CompanyController,
         :changeEmailStepTwo   # * change company email step Two
    post "/company/address/change", Company.CompanyController, :changeAddress   # * change company address
    get "/company/getListOfDirector", Company.CompanyController, :getAllListOFDirectors   # * get List of director

    post "/company/employee/mobile/change/stepOne",
         Company.CompanyController,
         :changeEmployeeMobileStepOne   # * company change employee mobile Step One
    post "/company/employee/mobile/change/stepTwo",
         Company.CompanyController,
         :changeEmployeeMobileStepTwo   # * company change employee mobile Step Two
    post "/company/employee/email/change/stepOne",
         Company.CompanyController,
         :changeEmployeeEmailStepOne   # * company change employee mobile Step One
    post "/company/employee/email/change/stepTwo",
         Company.CompanyController,
         :changeEmployeeEmailStepTwo   # * company change employee mobile Step Two

    post "/company/director/mobile/change/stepOne",
         Company.CompanyController,
         :changeDirectorMobileStepOne   # * company change director mobile Step One
    post "/company/director/mobile/change/stepTwo",
         Company.CompanyController,
         :changeDirectorMobileStepTwo   # * company change director mobile Step Two
    post "/company/director/email/change/stepOne",
         Company.CompanyController,
         :changeDirectorEmailStepOne   # * company change director email Step One
    post "/company/director/email/change/stepTwo",
         Company.CompanyController,
         :changeDirectorEmailStepTwo   # * company change director email Step Two


    get "/company/department/getSingle/:companyId/:id",
        Company.CompanyController,
        :getSingleDepartment   # * used to get single record from department
    get "/company/project/getSingle/:companyId/:id",
        Company.CompanyController,
        :getSingleProject         # * used to get single record from project
    get "/company/employee/getSingle/:companyId/:id",
        Company.CompanyController,
        :getSingleEmployee       # * used to get single record from employee
    get "/company/manager/getSingle/:companyId/:id",
        Company.CompanyController,
        :getSingleManager         # * used to get single record from manager's

    get "/company/departments/getAll/:companyId",
        Company.CompanyController,
        :getAllDepartments      # * used to get all records from deparments
    get "/company/projects/getAll/:companyId",
        Company.CompanyController,
        :getAllProjects            # * used to get all records from projects
    get "/company/managers/getAll",
        Company.CompanyController,
        :getAllManagers            # * used to get all records from managers
    get "/company/assignedCards/getAll/:companyId",
        Company.CompanyController,
        :getAllAssignCards    # * used to get all records from assignedCards

    post "/company/moneyRollback/:companyId/:employeeId/:cardId",
         Company.CompanyController,
         :moneyRollback  # * used to insert record in moneyRollback
    post "/company/topupCard/:companyId/:employeeId/:cardId",
         Company.CompanyController,
         :topupCard          # * used to insert record in topupCard
    post "/company/ownAccount/:companyId/:accountId",
         Company.CompanyController,
         :ownAccount                 # * used to insert record in ownAccount
    post "/company/allemployee/changepin",
         Company.CompanyController,
         :changeEmployeePin                         # * compnay chnage all employee pin

    get "/company/employee/addresses/:commanallId",
        Company.CompanyController,
        :getSingleEmployeeAddress  # * used to get single employee's addresses
    get "/company/employee/contacts/:commanallId",
        Company.CompanyController,
        :getSingleEmployeeContacts  # * used to get single employee's contacts
    get "/company/addresses/:commanallId",
        Company.CompanyController,
        :getSingleCompanyAddress          # used to get single company's addresses
    get "/company/contacts/:commanallId",
        Company.CompanyController,
        :getSingleCompanyContacts          # used to get single company's contacts
    get "/company/director/address/:directorId",
        Company.CompanyController,
        :getDirectorsAddress        # used to get single directors's addresses
    get "/company/director/contacts/:directorId",
        Company.CompanyController,
        :getDirectorsContacts      # used to get single directors's contacts
    get "/company/refresh", Company.CompanyController, :refreshBalance
    get "/company/employee/refresh/:employeeId", Company.CompanyController, :refreshEmployeeBalance
    get "/company/employee/card/refresh/:employeeId/:cardId", Company.CompanyController, :refreshCardBalance
    get "/company/balance/refresh/:id", Thirdparty.BankController, :accountBalanceRefresh
    get "/company/employees/requestCard/getAll", Company.CompanyController, :getAllRequestCardList
    get "/company/employee/requestCard/getAll/:employeeId", Company.CompanyController, :getEmployeeRequestCard
    post "/company/employee/generateCard", Comman.TestController, :generate_card
    get "/company/create_card/:id/:status", Comman.TestController, :create_card
    get "/company/create_physical_card/:id/:status", Comman.TestController, :create_physical_card
    get "/company/checkCardStatus", Company.CompanyController, :checkCardStatus
    post "/company/employee/uploadKycFirst", Company.CompanyController, :uploadEmployeeKycFirstV1
    post "/company/employee/uploadKycSecond", Company.CompanyController, :uploadEmployeeKycSecondV1


    get "/company/info", Company.RequestdataController, :companyData
    get "/company/requestMoneyList", Company.RequestdataController, :companyMoneyRequests
    get "/company/requestMoneyList/:employeeId", Company.RequestdataController, :companyEmployeeMoneyRequests
    get "/company/requestCardList", Company.RequestdataController, :companyCardRequests
    get "/company/requestCardList/:employeeId", Company.RequestdataController, :companyEmployeeCardRequests
    get "/company/employeee/requestMoneyList/:employeeid", Company.RequestdataController, :employeeWebMoneyRequests

    get "/company/dashboard/getAlerts", Company.RequestdataController, :getAlerts
    get "/company/mandateinfo", Company.RequestdataController, :mandateInfo
    post "/company/insert/mandate", Company.CompanyController, :insertMandate
    get "/company/menuList", Company.CompanyController, :menuList
    post "/company/employee/changePin", Company.CompanyController, :employeeChangePin

    post "/company/director/add", Company.CommonController, :addDirector
    post "/company/newdirector/add", Company.CommonController, :addNewDirector
    post "/company/director/edit/:directorId", Company.CommonController, :editDirector
    get "/company/employees/welcomeMail/:employeeId", Company.CommonController, :resendEmail
    post "/company/address/add", Company.CommonController, :addAddress
    post "/company/address/edit/:addressId", Company.CommonController, :editAddress
    get "/company/directorList", Company.CommonController, :listDirector

    # BankAccount Routes
    get "/company/bankAccount/details",
        Company.BankController,
        :bankAccountDetails      #get logged-in user's BankAccount details
    get "/company/bankAccount/beneficiariesList",
        Company.BankController,
        :bankAccountBeneficiaries      #get Beneficiaries list of logged in company
    post "/company/bankAccount/addBeneficiary",
         Company.BankController,
         :addBankAccountBeneficiary      #get add a new beneficiary
    post "/company/bankAccount/temporaryBeneficiary",
         Company.BankController,
         :addTemporaryBeneficiary      #get add a new beneficiary
    post "/company/bankAccount/updateTemporaryBeneficiary",
         Company.BankController,
         :updateTemporaryBeneficiary      #get add a new beneficiary
    post "/company/beneficiary/transaction", Thirdparty.BankController, :beneficiaryPayment
    post "/company/account/transaction", Thirdparty.BankController, :account2account
    post "/company/beneficiary/transaction/getAll", Company.BankController, :getAllBeneficiaryTransaction
    post "/company/bankAccount/editBeneficiary", Company.BankController, :editBankAccountBeneficiary
    get "/company/beneficiary/remove/:beneficiary_id", Company.BankController, :removeBeneficiaries

    # DASHBOARD Routes
    get "/company/accounts/getAll",
        Main.DashboardController,
        :getAllCompanyAccounts      # use to get all accounts of a company using id passwed
    get "/company/currency/getAll",
        Main.DashboardController,
        :getCompanyCurrency      # List of currency which company have.
    get "/company/employee/cards/getAll/:employeeId",
        Main.DashboardController,
        :getAllEmployeeCards  # use to get all accounts of a company using id passwed
    post "/company/employee/cards/getFiltered",
         Main.DashboardController,
         :getFilteredEmployeeCards  # use to get all accounts of a company using id passwed
    get "/company/employee/cards/getSingle/:cardId",
        Main.DashboardController,
        :getSingleEmployeeCards  # use to get all accounts of a company using id passwed
    get "/company/employees/cards/getAll",
        Main.DashboardController,
        :getCompanyAllEmployeeCards  # use to get all accounts of a company using id passwed
    get "/company/employees/getAll",
        Main.DashboardController,
        :getAllCompanyEmployees    # use to get all accounts of a company using id passwed
    get "/company/employees/getAllEmployee", Main.DashboardController, :getAllEmployee
    get "/company/employees/getProfile/:employeeId",
        Main.DashboardController,
        :getEmployeeProfile    # use to get all accounts of a company using id passwed
    post "/company/employees/updateCardStatus", Main.DashboardController, :updateCardStatus
    post "/v1/company/employees/updateCardStatus", Main.DashboardController, :updateCardStatusv1
    post "/company/employees/blockCard", Main.DashboardController, :blockCard
    get "/company/employees/cardsBalance", Main.DashboardController, :cardsBalance
    get "/update/notification/:id", Main.DashboardController, :updateNotification

    post "/company/employees/getFiltered", Company.CompanyController, :getEmployeesFiltered
    get "/company/notification", Company.CompanyController, :companyNotification
    get "/company/employee/notification/:employeeId", Company.CompanyController, :employeeNotification
    post "/company/employees/assignProject", Company.CompanyController, :assignProject
    get "/company/projectlist/:employeeId", Company.CompanyController, :projectList

    post "/company/uploadKycFirst", Company.CompanyController, :uploadKycFirst
    post "/company/uploadKycSecond", Company.CompanyController, :uploadKycSecond

    post "/company/uploadeKycFirst", Company.CompanyController, :uploadeKycFirst

    post "/company/employeeRegistration", Company.CompanyController, :employeeRegistration

    # *TRANSACTIONS*
    get "/company/transactionsList/getAll", Company.CompanyController, :companyTransactionsList
    get "/company/transactionsList/getAll/toptup", Company.CompanyController, :companyTopupList
    post "/company/transactionsList/getAll/loadMoney", Company.CompanyController, :companyLoadMoneyList
    post "/company/cardTransactions", Company.CompanyController, :getCardTransactions
    get "/company/transaction/pending/:employeeId", Company.CommonController, :pendingTransactions
    get "/company/address/getList", Company.CommonController, :addressList
    get "/company/director/view/:directorId", Company.CommonController, :directorView
    get "/company/transactions/getSingle/:transactionId", Company.CompanyController, :getCompanyTransaction

    ## NEW LISTS
    get "/company/topup/getLastFive",
        Company.CompanyController,
        :getLastFiveTopup  # used on Dashboard shows last 5 topups
    get "/company/accountHistory",
        Company.RequestdataController,
        :accountHistoryDefault  # used on account/s history shows all account transactions (topups, reclaims)
    post "/company/accountHistoryFiltered",
         Company.RequestdataController,
         :accountHistoryFiltered  # used on account/s history shows filtered account transactions (topups, reclaims)
    get "/company/cardHistory",
        Company.RequestdataController,
        :cardHistoryDefault  # used on card/s history shows all card transactions (topups, reclaims, pos)
    post "/company/cardHistoryFiltered",
         Company.RequestdataController,
         :cardHistoryFiltered  # used on card/s history shows Filtered card transactions (topups, reclaims, pos)
    get "/company/getlastfiverequest",
        Company.RequestdataController,
        :getlast5Alerts  # used on card/s history shows all card transactions (topups, reclaims, pos)
    get "/company/loadHistory",
        Company.RequestdataController,
        :loadHistoryDefault  # used on card/s history shows all card transactions (topups, reclaims, pos)
    post "/company/loadHistoryFiltered",
         Company.RequestdataController,
         :loadHistoryFiltered  # used on card/s history shows Filtered card transactions (topups, reclaims, pos)
    get "/company/singleCardInfo/:cardId",
        Company.RequestdataController,
        :singleCardInfo  # used on single card to show employee name, and card details
    get "/company/singleCardHistory/:cardId",
        Company.RequestdataController,
        :singleCardHistoryDefault  # used on single card history shows all card transactions (topups, reclaims, pos)
    post "/company/singleCardHistoryFiltered",
         Company.RequestdataController,
         :singleCardHistoryFiltered  # used on single card history shows Filtered card transactions (topups, reclaims, pos)

    ### V1 LISTS
    get "/v1/company/topup/getLastFive",
        Company.CompanyController,
        :getLastFiveTopupV1  # used on Dashboard shows last 5 topups
    get "/v1/company/accountHistory",
        Company.RequestdataController,
        :accountHistoryDefaultV1  # used on account/s history shows all account transactions (topups, reclaims)
    get "/v1/company/account/singleTransactions/:transactionId",
        Company.RequestdataController,
        :accountHistoryDefaultSingle  # used on account/s history shows all account transactions (topups, reclaims)
    post "/v1/company/accountHistoryFiltered",
         Company.RequestdataController,
         :accountHistoryFilteredV1  # used on account/s history shows filtered account transactions (topups, reclaims)
    get "/v1/company/cardHistory",
        Company.RequestdataController,
        :cardHistoryDefaultV1  # used on card/s history shows all card transactions (topups, reclaims, pos)
    post "/v1/company/cardHistoryFiltered",
         Company.RequestdataController,
         :cardHistoryFilteredV1  # used on card/s history shows Filtered card transactions (topups, reclaims, pos)
    post "/v1/company/loadHistoryFiltered",
         Company.RequestdataController,
         :loadHistoryFilteredV1  # used on card/s history shows Filtered card transactions (topups, reclaims, pos)
    get "/v1/company/singleCardHistory/:cardId",
        Company.RequestdataController,
        :singleCardHistoryDefaultV1  # used on single card history shows all card transactions (topups, reclaims, pos)
    post "/v1/company/singleCardHistoryFiltered",
         Company.RequestdataController,
         :singleCardHistoryFilteredV1  # used on single card history shows Filtered card transactions (topups, reclaims, pos)
    get "/v1/company/transactionsList/getAll", Company.CompanyController, :companyTransactionsListV1
    post "/v1/company/transactionsList/getAll/loadMoney", Company.CompanyController, :companyLoadMoneyListV1
    get "/v1/company/cardAccount/transactions", Company.CompanyController, :companyLoadMoneyTransaction
    get "/v1/company/transactions/getSingle/loadMoney/:transactionId",
        Company.CompanyController,
        :companyLoadMoneySingleV1
    post "/v1/company/cardTransactions", Company.CompanyController, :getCardTransactionsV1
    post "/v1/company/employee/spend", Company.CompanyController, :getCardPOSTransactions
    get "/v1/employees/transactions/getSingle/:transactionId", Employees.EmployeesController, :getEmployeeTransactionV1

    post "/v1/company/singleAccountHistoryFiltered",
         Company.RequestdataController,
         :singleAccountHistoryFilteredV1  # used on single card history shows Filtered card transactions (topups, reclaims, pos)
    get "/v1/company/bankAccountHistory",
        Company.RequestdataController,
        :bankAccountHistory  # used on account/s history shows all account transactions (topups, reclaims)
    get "/v1/company/bankAccount/singleTransaction/:transactionId",
        Company.RequestdataController,
        :bankAccountHistorySingle  # used on account/s history shows all account transactions (topups, reclaims)
    get "/v1/company/card/singleTransaction/:transactionId",
        Company.RequestdataController,
        :cardAccountHistorySingle  # used on account/s history shows all account transactions (topups, reclaims)
    get "/company/bankAccountHistory/lastFive", Transaction.TransactionController, :bankLastFiveTransaction

    # Services
    post "/company/topup", Transaction.TransactionController, :topup
    post "/company/employee/topup/:employeeId", Transaction.TransactionController, :employeeTopup
    post "/v1/company/employee/topup/:employeeId", Transaction.TransactionController, :employeeTopupv1
    post "/company/employee/movefund/:employeeId", Transaction.TransactionController, :companyTopup
    post "/v1/company/employee/movefund/:employeeId", Transaction.TransactionController, :companyTopupv1
    post "/company/employee/requestTopup", Transaction.TransactionController, :requestTopup
    post "/company/employee/transactionToProject", Transaction.TransactionController, :transactionToProject
    post "/employee/transaction/receipt", Transaction.TransactionController, :addReceipt
    post "/employee/transaction/assignProject", Transaction.TransactionController, :assignProject
    post "/employee/transaction/assignCategory", Transaction.TransactionController, :assignCategory
    post "/employee/transaction/assignCategoryInfo", Transaction.TransactionController, :assignCategoryInfo
    post "/employee/transaction/lostReceipt", Transaction.TransactionController, :lostReceipt
    post "/employee/transaction/assignEntertain", Transaction.TransactionController, :assignEntertain
    get "/transaction/manual_load", Transaction.TransactionController, :manual_load
    get "/company/receipt/:transactionId", Transaction.TransactionController, :viewReceipt
    get "/company/pos/transactions", Transaction.TransactionController, :posTransactions
    get "/cards/transactions/last_five/:card_id", Transaction.TransactionController, :lastFive
    get "/employee/cards/transactions/last_five/:card_id", Transaction.TransactionController, :lastFiveForEmp
    post "/transactions/add/notes", Transaction.TransactionController, :updateTransactionNote
    get "/company/receipt/remove/:transactionReceiptId", Transaction.TransactionController, :removeReceipt
    get "/company/receipt/download/:transacationReceiptId", Transaction.TransactionController, :downloadReceipt
    get "/account/last/five/transaction/:account_id", Transaction.TransactionController, :accountLastFiveTransaction

    # Manager routes
    post "/manager/insert",
         Managers.ManagersController,
         :insertManager                   # * used to insert record in managers table
    post "/manager/update/:id",
         Managers.ManagersController,
         :updateManager               # * used to update record in managers table using Id
    get "/manager/getAll/:companyId",
        Managers.ManagersController,
        :getAllManagers        # used to getAll records from the managers table
    get "/manager/getSingle/:companyId/:id",
        Managers.ManagersController,
        :getSingleManager    # used to getSingle record from managers table

    # CAP routes
    get "/company/cap/cards/getAll", Company.CapController, :cardlistwithemployeeCAP
    get "/company/cap/cards/getAllNoPagination", Company.CapController, :cardlistwithemployeeCAPNOPagination
    get "/company/cap/cardRequests/getAll", Company.CapController, :getAllRequestCardListCAP
    get "/company/cap/moneyRequests/getAll", Company.CapController, :companyMoneyRequestsCAP
    post "/company/cap/action/manualTopup", Company.CapController, :employeeTopupCAP
    post "/company/cap/action/moneyRequest", Company.CapController, :requestTopupCAP
    get "/company/cap/action/physicalCardRequest/:id/:status", Company.CapController, :actionPhysicalCardCAP
    get "/company/cap/action/virtualCardRequest/:id/:status", Company.CapController, :actionVirtualCardCAP
    get "/company/cap/employee/getAll", Company.CapController, :getEmployeeListCAP
    get "/company/cap/employee/cards/getAll/:employee_id", Company.CapController, :cardsListSingleEmployeeCAP
    get "/company/cap/topup/transactions/getAll", Company.CapController, :transactionsListCAP

    post "/dir_as_employee", Company.CompanyController, :dir_as_employee
    get "/switch_to_employee", Main.MainController, :switch_to_employee
    get "/switch_to_company", Main.MainController, :switch_to_company

    # Employees routes
    post "/employees/update/:id", Employees.EmployeesController, :updateEmployee # *
    get "/employees/getAll/:companyId", Employees.EmployeesController, :getAllEmployees
    get "/employees/getSingle/:companyId/:id", Employees.EmployeesController, :getSingleEmployee
    post "/employees/requestMoney/:companyId/:id/:cardId", Employees.EmployeesController, :requestMoney # *
    get "/employees/transactionsList/getAll/:cardId", Employees.EmployeesController, :transactionsList
    get "/employees/transactions/getSingle/:transactionId", Employees.EmployeesController, :getEmployeeTransaction
    post "/employees/balance/:companyId/:id/:cardId", Employees.EmployeesController, :balance # *
    post "/employees/documents/:companyId/:id/:cardId", Employees.EmployeesController, :documents # *
    post "/employees/address/:companyId/:id/:cardId", Employees.EmployeesController, :address # *
    post "/employees/contacts/:companyId/:id/:cardId", Employees.EmployeesController, :contacts # *
    post "/employees/notifications/:companyId/:id/:cardId", Employees.EmployeesController, :notifications # *
    post "/employees/updateCardStatus", Employees.EmployeesController, :updateCardStatus
    post "/employees/profileImage/:companyId/:id/:cardId", Employees.EmployeesController, :profileImage  # *
    get "/employees/getCVV/:cardId", Employees.EmployeesController, :get_cvv
    get "/employees/getPIN/:cardId", Employees.EmployeesController, :get_pin
    post "/employees/requestMoney", Transaction.TransactionController, :requestMoney
    get "/employees/requestMoneyList", Company.RequestdataController, :employeeMoneyRequests
    get "/employees/companyAccounts", Employees.EmployeesController, :companyAccounts
    get "/employees/notification", Employees.EmployeesController, :employeeNotification
    get "/read/notification", Employees.EmployeesController, :updateNotification
    get "/company/employee/requestcard/getSingle/:cardId", Employees.EmployeesController, :getSingleRequestedCard
    get "/company/employee/requestmoney/getSingle/:cardId", Employees.EmployeesController, :getSingleRequestedMoney

    get "/employees/getSingleInfo/:id", Employees.EmployeesController, :getSingleEmployeeInfo
    get "/employees/getProfile",
        Employees.EmployeesController,
        :getEmployeeProfile    # use to get all accounts of a company using id passwed
    get "/employees/cards/getAll",
        Employees.EmployeesController,
        :getEmployeeCards  # use to get all accounts of a company using id passwed
    get "/employees/refresh", Employees.EmployeesController, :refreshBalance
    post "/employees/assignProject", Employees.EmployeesController, :assignProject
    get "/employees/checkCardStatus", Employees.EmployeesController, :checkCardStatus
    post "/employee/mobile/change/stepOne",
         Employees.EmployeesController,
         :changeMobileStepOne   # * change employee mobile Step Two
    post "/employee/mobile/change/stepTwo",
         Employees.EmployeesController,
         :changeMobileStepTwo   # * change employee mobile Step Two
    post "/employee/email/change/stepOne",
         Employees.EmployeesController,
         :changeEmailStepOne   # * change employee email Step One
    post "/employee/email/change/stepTwo",
         Employees.EmployeesController,
         :changeEmailStepTwo   # * change employee email step Two
    post "/employee/address/change", Employees.EmployeesController, :changeAddress   # * change employee address

    post "/changePassword", Main.MainController, :change_password
    post "/changePin", Main.MainController, :change_pin
    post "/createPin", Main.MainController, :create_pin
    post "/verifyPin", Main.MainController, :verify_pin

    post "/employees/requestCard", Employees.EmployeesController, :requestCard
    get "/employees/requestCardList", Company.RequestdataController, :employeeCardRequests
    post "/employees/requestCode", Employees.EmployeesController, :requestCode
    post "/v1/employees/requestCode", Employees.EmployeesController, :requestCodeV1
    post "/employees/createCard", Employees.EmployeesController, :createCard
    post "/employee/uploadKycFirst", Employees.EmployeesController, :uploadKycFirst
    post "/employee/uploadKycSecond", Employees.EmployeesController, :uploadKycSecond

    post "/employee/uploadeKycFirst", Employees.EmployeesController, :uploadeKycFirst
    #    get "/permanantly/delete/pending/user/:employee_id", Employees.EmployeesController, :permanantlyDeletePendingUser

    get "/employee/employeePendingCards", Employees.EmployeesController, :employeePendingCards
    get "/employee/projectlist", Employees.EmployeesController, :projectList
    post "/employee/forgotPinTwo",
         Employees.EmployeesController,
         :forgotPinTwo        # used for forgotpin step two in employee controller
    get "/employee/card/activationPending",
        Employees.EmployeesController,
        :getPendingStatus        # checks if the logged-in employee has any cards pending activation

    # Fees routes
    get "/fees/company/getAll/:companyId/:id", Fees.FeesController, :getCompanyFees
    get "/fees/employee/getAll/:employeeId/:id", Fees.FeesController, :getEmployeeFees

    get "/fees/employee/getMonthlyFee", Fees.FeesController, :getMonthlyFee

    get "/company/getMonthlyFee", Fees.FeesController, :companyMonthlyFee

    post "/company/generate/transactions", Transaction.TransactionController, :generateMonthlySeat
    post "/company/generate/card/transactions", Transaction.TransactionController, :generateCardMonthlySeat
    post "/company/expense/download", Transaction.TransactionController, :getTransactionUrl
    post "/company/expense/getAll", Transaction.TransactionController, :getExpensesList


    # employee routes
    get "/get/all/employee/info", Company.EmployeeController, :employeeDetailList
    get "/get/employee/cards/info/:employee_id", Company.EmployeeController, :getEmployeeCardDetails

  end

  scope "/api/admin", ViolacorpWeb do
    pipe_through :api # Use the default browser stack

    get "/test1", Test.TestController, :test1
    get "/get_system_vetting", Admin.AdminController, :get_system_vetting

    #browser Token
    post "/update/browser/token", Admin.AdminNotificationController, :storeBrowserToken
    get "/delete/browser/token", Admin.AdminNotificationController, :deleteBrowserToken
    post "/edit/notification/status", Admin.AdminNotificationController, :updateNotificationStatus

    get "/country/getAll", Comman.CountryController, :getAllCountry
    get "/get/tags/:commanall_id", Admin.Comman.CommanController, :getTags

    # Check Third Party Status
    post "/check/thirdparty/status", Admin.Comman.CheckstatusController, :checkstatus
    post "/check/thirdparty/status/corp", Admin.Accounts.AccountUpdateController, :account_check_status

    get "/logout/admin", Admin.LoginController, :logoutAdmin
    ## DELETE KYC RECORDS
    post "/delete/director/kyc", Admin.Comman.CommanController, :deleteDirectorKyc
    post "/delete/company/kyc", Admin.Comman.CommanController, :deleteCompanyKyc
    post "/delete/employee/kyc", Admin.Comman.CommanController, :deleteEmployeeKyc
    ###################

    ## DASHBOARD SECTION
    get "/get/all/total/count/dashboard", Admin.DashboardController, :getall_act_ped_company_daseboard
    get "/get/all/total/count/dashboard/v1", Test.TestController, :getall_act_ped_company_daseboard_v1
    get  "/get/all/cards/count/dashboard", Admin.DashboardController, :get_all_cards_counts
    get "/get/all/archive/deleted/com/dashboard", Admin.DashboardController, :getall_archive_del_company_daseboard

    ## COMPANY PANEL Start
    post "/activeCompanies/getAll", Admin.Companies.ActiveCompaniesController, :activeCompanies
    post "/pendingCompanies/getAll", Admin.Companies.PendingCompaniesController, :pendingCompanies
    post "/pendingCompanies/getAll/v1", Test.TestController, :pendingCompanies_v1
    post "/archivedCompanies/getAll", Admin.Companies.ArchiveCompaniesController, :archivedCompanies
    post "/closedCompanies/getAll", Admin.Companies.ClosedCompaniesController, :closedCompanies
    post "/deletedCompanies/getAll", Admin.Companies.DeletedCompaniesController, :deletedCompanies
    post "/suspendedCompanies/getAll", Admin.Companies.SuspendedCompaniesController, :suspendedCompanies
    post "/underReviewCompanies/getAll", Admin.Companies.UnderReviewCompaniesController, :underReviewCompanies

    # Active Company View Panel
    post "/active/company/LoadingFee", Admin.Companies.ActiveCompaniesController, :activeCompanyLoadingFee
    get "/company/profile/onlineAccount/:company_id", Admin.Companies.ActiveCompaniesController, :onlineAccount
    get "/company/profile/cardManagementAccount/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :cardManagementAccount
    get "/company/employee/list/:company_id", Admin.Companies.ActiveCompaniesController, :employeeDetails
    get "/active/company/director/:company_id", Admin.Companies.ActiveCompaniesController, :directorlist
    get "/company/director/kyc/detail/:id", Admin.Companies.ActiveCompaniesController, :directorDetails
    get "/company/profile/companyAddressContact/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :companyAddressContact
    get "/company/profile/companyDescription/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :companyDescription
    get "/company/employeeCard/:company_id", Admin.Companies.ActiveCompaniesController, :employeeCard
    get "/company/companyKyb/:commanall_id", Admin.Companies.ActiveCompaniesController, :companyKyb
    get "/active/company/profile/:company_id", Admin.Companies.ActiveCompaniesController, :companyProfile


    get "/active/company/profilev1/:company_id", Admin.Companies.ActiveCompaniesController, :companyProfilev1



    get "/company/underReviewCompanies/getOne/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :showCompany_profile
    post "/changeCompanyStatus",
         Admin.Companies.ActiveCompaniesController,
         :changeCompanyStatus # company enable / disable / block
    get "/active/company/checklist/:company_id", Admin.Companies.ActiveCompaniesController, :activeCompanyCheckList

    post "/card/manually/capture/transaction", Admin.Companies.ActiveCompaniesController, :mauallyCaptureTransaction
    post "/company/delete", Admin.Companies.PendingCompaniesController, :removePendingCompany
    get "/get/pendingCompProfile/getOne/:company_id", Admin.Companies.PendingCompaniesController, :pendingCompanyProfile
    get "/get/pending/company/address/:company_id",
        Admin.Companies.PendingCompaniesController,
        :getPendingCompnayAddress
    get "/get/directors_kyc_company/:company_id", Admin.Companies.PendingCompaniesController, :get_directors_kyc_company
    get "/get/company/kyc/details/:commanall_id/:company_id",
        Admin.Companies.PendingCompaniesController,
        :getCompanyKycDetails
    post "/add/director/address", Admin.Companies.PendingCompaniesController, :addDirectorAddress
    post "/edit/director/address/:id", Admin.Companies.PendingCompaniesController, :editDirectorAddress
    post "/add/director/birthDate/:director_id", Admin.Companies.PendingCompaniesController, :addDirectorDob
    post "/edit/director/email/:director_id", Admin.Companies.PendingCompaniesController, :editDirectorEmail
    post "/edit/director/contact/:director_id", Admin.Companies.PendingCompaniesController, :editDirectorContact
    post "/add/director/contact/:director_id", Admin.Companies.PendingCompaniesController, :addDirectorContact
    post "/delete/pending/director/:director_id", Admin.Companies.PendingCompaniesController, :deletePendingDirector
    post "/delete/primary/director/:director_id", Admin.Companies.PendingCompaniesController, :deletePrimaryDirector
    post "/add/company/address", Admin.Companies.PendingCompaniesController, :addCompanyAddress
    post "/edit/company/address/:id", Admin.Companies.PendingCompaniesController, :editCompanyAddress
    post "/edit/company/registration/number/:company_id",
         Admin.Companies.PendingCompaniesController,
         :editRegistrationNumber
    post "/add/company/email", Admin.Companies.PendingCompaniesController, :addCompanyEmail
    post "/edit/company/email/:commanall_id", Admin.Companies.PendingCompaniesController, :editCompanyEmail
    post "/edit/company/contact/:commanall_id", Admin.Companies.PendingCompaniesController, :editCompanyContact
    post "/director/kyc/override", Admin.Companies.PendingCompaniesController, :directorKycOverride

    get "/get/cap_kyc_company/:company_id", Admin.Companies.PendingCompaniesController, :get_cap_kyc_company
    get "/get/kyc_one_company/:company_id", Admin.Companies.PendingCompaniesController, :get_kyc_one_company
    #    get "/get/all_directors_for_company/:company_id", Admin.Companies.PendingCompaniesController, :get_all_directors_for_company
    post "/company/more/details/add", Admin.Companies.PendingCompaniesController, :pendingCompanyAskMoreDetails
    get "/company/checklist/:company_id", Admin.Companies.PendingCompaniesController, :pendingCompanyCheckList
    post "/company/activation/opinion/add", Admin.Companies.PendingCompaniesController, :companyActivationOpinionAdd
    get "/company/kyb/document/type/list/:company_id",
        Admin.Companies.PendingCompaniesController,
        :companyKybDocumentTypeList
    get "/get/registration/step/array/:company_id", Admin.Companies.PendingCompaniesController, :registrationStepsArray
    post "/change/registration/step", Admin.Companies.PendingCompaniesController, :editregistrationStepsArray

    post "/company/director/cap/add", Admin.Companies.PendingCompaniesController, :addDirectorForCompany
    get "/company/shareholder/details/:company_id",
        Admin.Companies.PendingCompaniesController,
        :getSingleShareholderInfo
    get "/company/shareholder/kyc/details/:company_id", Admin.Companies.PendingCompaniesController, :getShareHolderKyc

    post "/company/kyb/document/upload", Admin.Companies.PendingCompaniesController, :companyKybDocumentUpload
    post "/director/kyc/document/upload", Admin.Companies.PendingCompaniesController, :directorKycDocumentUpload
    post "/shareholder/kyc/document/upload", Admin.Companies.PendingCompaniesController, :shareholderKycDocumentUpload
    post "/employee/kyc/document/upload/id", Admin.Companies.PendingCompaniesController, :employeeKycDocumentUploadID
    post "/employee/kyc/document/upload/address", Admin.Companies.PendingCompaniesController, :uploadEmployeeAddress

    post "/share/holder/add", Admin.Companies.PendingCompaniesController, :insertShareHolder
    post "/update/employee/card/status", Admin.Companies.ActiveCompaniesController, :updateEmployeeCardStatus
    post "/company/employee/card/transaction/:card_id",
         Admin.Companies.ActiveCompaniesController,
         :companyEmployeeCardTransaction
    post "/director/kyc/comments", Admin.Companies.ActiveCompaniesController, :directorKycComments
    get "/director/kyc/comment/list/:kycdirectors_id",
        Admin.Companies.ActiveCompaniesController,
        :directorKycCommentList
    #active company online account view panel
    #    get "/get/All/Company/topUp/:company_id", Admin.Companies.ActiveCompaniesController, :companyTopup
    #    get "/get/All/feeTransactions_company/:company_id", Admin.Companies.ActiveCompaniesController, :feeTransactions_company
    #    get "/get/All/credit_debit_transactions_company/:company_id", Admin.Companies.ActiveCompaniesController, :credit_debit_transactions_company
    #    get "/get/All/company/transfers/:company_id", Admin.Companies.ActiveCompaniesController, :company_transfers  #comapny transfer to card management
    post "/change/company/internal/status", Admin.Companies.ActiveCompaniesController, :updateInternalStatus
    post "/block/active/company", Admin.Companies.ActiveCompaniesController, :blockActiveCompany
    post "/active/company/kyb/comment", Admin.Companies.ActiveCompaniesController, :compnayKybComment


    #Admin Comman Third Party controller
    get "/card/management/account/balance/refresh/:company_id",
        Admin.Comman.ThirdPartyController,
        :admincompanyRefreshBalance
    get "/company/balance/refresh/:company_id", Admin.Comman.ThirdPartyController, :admincompanyRefreshBalance
    get "/company/online/account/balance/refresh/:company_id",
        Admin.Comman.ThirdPartyController,
        :onlineAccountRefreshBalance
    get "/v1/company/online/account/balance/refresh/:company_id/:id",
        Admin.Comman.ThirdPartyController,
        :onlineAccountRefreshBalanceV1
    get "/company/employee/card/refresh/balance/:card_id",
        Admin.Comman.ThirdPartyController,
        :employeeCardRefreshBalance
    post "/card/management/account/manual/topup", Admin.Comman.ThirdPartyController, :cardManagementManualtop

    #active company online account view panel
    get "/get/All/Company/topUp/:company_id", Admin.Companies.ActiveCompaniesController, :companyTopup
    get "/get/All/feeTransactions_company/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :feeTransactions_company
    get "/get/All/credit_debit_transactions_company/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :credit_debit_transactions_company
    get "/get/All/company/transfers/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :company_transfers  #comapny transfer to card management


    #active company Card management account view panel
    post "/get/All/Company/cardmanagementtopUpHistory/:company_id",
         Admin.Companies.ActiveCompaniesController,
         :cardManagement_topupHistory
    get "/get/All/cardManagement_companyTransactions/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :cardManagement_companyTransactions
    get "/get/All/cardManagement_userTransactions/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :cardManagement_userTransactions
    post "/get/All/cardManagement/pos/transactions/:company_id",
         Admin.Companies.ActiveCompaniesController,
         :cardManagement_POS_transactions
    get "/get/All/cardManagement_FEEtransactions/:company_id",
        Admin.Companies.ActiveCompaniesController,
        :cardManagement_FEE_transactions


    #deleted company
    get "/get/deleted/company/profile/:company_id", Admin.Companies.DeletedCompaniesController, :deletedCompanyProfile
    get "/get/deleted/company/profile/onlineAccount/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyOnlineAccount
    get "/get/deleted/company/profile/cardManagementAccount/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyCardManagementAccount
    get "/get/deleted/company/employee/list/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyEmployeeList
    get "/get/deleted/company/director/list/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyDirectorList
    get "/get/deleted/company/profile/companyDescription/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyDescription
    get "/get/deleted/company/profile/companyAddressContact/:company_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyContactAddress
    get "/get/deleted/company/employeeCard/:employee_id",
        Admin.Companies.DeletedCompaniesController,
        :deletedCompanyEmployeeCards
    get "/get/deleted/company/companyKyb/:company_id", Admin.Companies.DeletedCompaniesController, :deletedCompanyKyb

    #closed company
    get "/get/closed/company/profile/:company_id", Admin.Companies.ClosedCompaniesController, :closedCompanyProfile
    get "/get/closed/company/profile/onlineAccount/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyOnlineAccount
    get "/get/closed/company/profile/cardManagementAccount/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyCardManagementAccount
    get "/get/closed/company/employee/list/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyEmployeeList
    get "/get/closed/company/director/list/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyDirectorList
    get "/get/closed/company/profile/companyDescription/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyDescription
    get "/get/closed/company/profile/companyAddressContact/:company_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyContactAddress
    get "/get/closed/company/employeeCard/:employee_id",
        Admin.Companies.ClosedCompaniesController,
        :closedCompanyEmployeeCards
    get "/get/closed/company/companyKyb/:company_id", Admin.Companies.ClosedCompaniesController, :closedCompanyKyb

    #archived company
    get "/get/archived/CompanyProfile/:company_id", Admin.Companies.ArchiveCompaniesController, :archivedCompanyProfile
    get "/get/archived/onlineAccount/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyOnlineAccount
    get "/get/archived/CardManagementAccount/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyCardManagementAccount
    get "/get/archived/EmployeeList/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyEmployeeList
    get "/get/archived/EmployeeCards/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyEmployeeCards
    get "/get/archived/DirectorList/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyDirectorList
    get "/get/archived/CompanyKyb/:company_id", Admin.Companies.ArchiveCompaniesController, :archivedCompanyKyb
    get "/get/archived/ContactAddress/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyContactAddress
    get "/get/archived/CompanyDescription/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :archivedCompanyDescription
    post "/delete/archived/company/:company_id", Admin.Companies.ArchiveCompaniesController, :deleteArchivedCompany
    get "/getAllCompaniesAccountCards/:company_id",
        Admin.Companies.ArchiveCompaniesController,
        :getallCompaniesAccountCards

    #under review company
    get "/get/UnderReviewCompany/profile/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyProfile
    get "/get/UnderReviewCompany/OnlineAccount/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyOnlineAccount
    get "/get/UnderReviewCompany/CardManagementAccount/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyCardManagementAccount
    get "/get/UnderReviewCompany/EmployeeCards/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyEmployeeCards
    get "/get/UnderReviewCompany/EmployeeList/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyEmployeeList
    get "/get/UnderReviewCompany/DirectorList/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyDirectorList
    get "/get/UnderReviewCompany/CompanyKYB/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyKyb
    get "/get/UnderReviewCompany/ContactAddress/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyContactAddress
    get "/get/UnderReviewCompany/Description/:company_id",
        Admin.Companies.UnderReviewCompaniesController,
        :underReviewCompanyDescription

    #Suspended company Panel

    get "/get/suspended/profile/:company_id", Admin.Companies.SuspendedCompaniesController, :suspendedcompanyProfile
    get "/get/suspended/OnlineAccount/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyonlineAccount
    get "/get/suspended/CardManagementAccount/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyCardManagementAccount
    get "/get/suspended/EmployeeCards/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyEmployeeCards
    get "/get/suspended/EmployeeList/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyEmployeeList
    get "/get/suspended/DirectorList/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanydirectorDetails
    get "/get/suspended/CompanyKYB/:company_id", Admin.Companies.SuspendedCompaniesController, :suspendedCompanyKyb
    get "/get/suspended/ContactAddress/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyContactAddress
    get "/get/suspended/Description/:company_id",
        Admin.Companies.SuspendedCompaniesController,
        :suspendedCompanyDescription
    #COMPANY PANEL END

    ## EMPLOYEE PANEL START
    post "/update/employee/dob/:commanall_id", Admin.Comman.UpdateInformationController, :updateEmployeeDob
    post "/update/director/email/:director_id", Admin.Comman.UpdateInformationController, :updateDirectorEmail
    post "/update/director/contact/:director_id", Admin.Comman.UpdateInformationController, :updateDirectorContact
    post "/update/director/dob/:director_id", Admin.Comman.UpdateInformationController, :updateDirectorDob
    post "/update/employee/contact/:commanall_id", Admin.Employee.ActiveController, :updateEmployeeContact
    post "/update/employee/email_id/:commanall_id", Admin.Employee.ActiveController, :employeeEmailUpdate
    post "/get/active/user/fourstop", Admin.Employee.ActiveController, :get_user_4stop_view
    post "/get/all/active/user", Admin.Employee.ActiveController, :getAll_active_User
    post "/get/all/active/user/v1", Test.TestController, :getAll_active_User_v1
    post "/get/all/pending/user", Admin.Employee.ActiveController, :getAllPendingEmployee
    get "/get/active/user/profile/:employee_id", Admin.Employee.ActiveController, :activeUserProfile
    get "/get/pending/user/profile/:employee_id", Admin.Employee.ActiveController, :pendingUserProfile
    get "/get/active/employee/kyc/documents/:employee_id", Admin.Employee.ActiveController, :employeeKycDocument
    post "/update/employee/address/:employee_id", Admin.Employee.ActiveController, :updateEmployeeAddress
    get "/get/active/user/card/:employee_id", Admin.Employee.ActiveController, :get_Single_Employee_Cards
    get "/get/active/user/kyc/:employee_id", Admin.Employee.ActiveController, :active_user_kyc_detail
    get "/get/active/user/address/:employee_id", Admin.Employee.ActiveController, :active_user_address
    get "/get/active/user/contact/:employee_id", Admin.Employee.ActiveController, :active_user_contact
    get "/get/active/user/notes/comments/:employee_id", Admin.Employee.ActiveController, :active_user_notes
    get "/get/active/user/previous/notes/:employee_id", Admin.Employee.ActiveController, :getActiveUserPreviousNotes
    post "/insert/active/user/kyc/comments", Admin.Employee.ActiveController, :insertActiveUserKycProofcomment
    get "/kyc/comment/user/list/:kycdocuments_id", Admin.Employee.ActiveController, :userKycCommentList
    post "/insert/active/user/new/notes", Admin.Employee.ActiveController, :insertActiveUsernewnotes
    get "/pullCards/:employee_id", Admin.Employee.ActiveController, :pullCards
    post "/get/all/archived/user", Admin.Employee.ArchivedController, :getAll_archivedUser
    get "/get/archived/user/profile/:employee_id", Admin.Employee.ArchivedController, :archived_user_profile
    get "/get/archived/user/profile/view/:employee_id", Admin.Employee.ArchivedController, :archived_user_profile_view
    post "/get/all/deleted/user", Admin.Employee.DeleteduserController, :getAll_deleted_user
    get "/get/deleted/user/profile/:employee_id", Admin.Employee.DeleteduserController, :deleted_user_profile_detail
    get "/get/deleted/user/cards/:employee_id", Admin.Employee.DeleteduserController, :delted_user_cards_detail
    get "/get/deleted/user/kyc/detail/:employee_id", Admin.Employee.DeleteduserController, :delted_user_kyc_detail
    get "/get/deleted/user/address/:employee_id", Admin.Employee.DeleteduserController, :deleted_user_address_detail
    get "/get/deleted/user/contact/:employee_id", Admin.Employee.DeleteduserController, :deleted_user_contact_detail
    get "/get/deleted/user/notes/comments/:employee_id", Admin.Employee.DeleteduserController, :deletd_user_notes_detail
    post "/get/all/administrator", Admin.Employee.AdministratorController, :getAll_administrator
    post "/permanently/delete/pending/user", Admin.Employee.ActiveController, :permanantlyDeletePendingUser
    post "/archive/user/delete", Admin.Employee.ArchivedController, :deleteArchivedUser
    get "/get/active/director/list/:company_id", Admin.Employee.ActiveController, :activeDirectorList
    post "/changeEmployeeStatus", Admin.Employee.ActiveController, :changeEmployeeStatus
    post "/employee/kyc/override", Admin.Employee.ActiveController, :employeeKycOverride

    get "/get/employee/card/details/:employee_id", Admin.Employee.ActiveController, :employeeCardDetails

    #ONLINE BUSINESS TRANSACTION PANEL
    post "/get/all/credit/and/debit/transaction",
         Admin.Transaction.TransactionController,
         :getCreaditAndDebitTransaction
    post "/get/all/transfer/to/card/managment", Admin.Transaction.TransactionController, :getAllTransferTocardManagemet
    post "/get/all/fees/online/transaction", Admin.Transaction.TransactionController, :getAllonlineFeeTransactions
    get "/get/one/transaction/receipt/:id", Admin.Transaction.TransactionController, :getTransactionReciept
    post "/transfer/card/allFunds", Admin.Transaction.TransactionController, :trasferEmployeeCardsBalance

    # CARD  MANAGEMENT TRANSACTION PANEL
    post "/get/all/company/transaction/card/management/account",
         Admin.Transaction.TransactionController,
         :getAllcomapnyTransaction
    post "/get/all/employee/transaction/card/management/account",
         Admin.Transaction.TransactionController,
         :getAllemployeeTransaction
    post "/get/all/pos/transaction/card/management/account",
         Admin.Transaction.TransactionController,
         :getAllposTransactions
    post "/get/all/fee/transaction/card/management/account",
         Admin.Transaction.TransactionController,
         :getAllfeeTransactions
    post "/get/all/accomplish/transactions", Admin.Transaction.TransactionController, :getAllaccomplishTransactions

    #ACCOUNTS PANEL
    post "/get/all/admin/accounts", Admin.Accounts.AccountsController, :getAllAccounts
    post "/get/all/transactions/accounts/:id", Admin.Accounts.AccountsController, :getAllaccountsTransactions
    get "/get/accountsTransactionReciept/:id", Admin.Accounts.AccountsController, :accountsTransactionReciept
    get "/balanceRefresh/:account_id", Admin.Accounts.AccountsController, :accountBalanceRefresh
    post "/account/settlement", Admin.AdminController, :accountSettlement

    #Fees PANEL
    post "/get/all/fee/head", Admin.Fees.FeesController, :getAllFeeHead
    post "/get/all/group/fees", Admin.Fees.FeesController, :getAllGroupHead
    post  "/update/fee/head", Admin.Fees.FeesController, :updateFeehead
    get "/get/single/fees/head/:id", Admin.Fees.FeesController, :getSingleFees
    get "/get/all/feeHead", Admin.Fees.FeesController, :getFeeHead
    post "/insert/fees/head", Admin.Fees.FeesController, :insertFeeHead
    post "/groupFees/add", Admin.Fees.FeesController, :insertGroupFees
    post "/groupFees/update/:id", Admin.Fees.FeesController, :updateGroupFees

    #NOTIFICATION PANEL
    post "/get/all/money/request", Admin.Notifications.NotificationController, :getAllMoneyRequest
    post "/get/all/money/request/v1", Test.TestController, :getAllMoneyRequest_v1
    post "/get/all/cards/request", Admin.Notifications.NotificationController, :getAllCardsRequest
    post "/get/all/approved/cards", Admin.Notifications.NotificationController, :getAllApprovedCard
    get "/getBrowserInfoView/:id", Admin.Notifications.NotificationController, :getBrowserInfoView


    ## SETTING PANEL START
    post "/add/country", Admin.Setting.SettingController, :insert_country
    post "/edit/country", Admin.Settings.CountryController, :countryEdit
    get "/get/all/country/list", Admin.Setting.SettingController, :getCountry
    get "/get/single/country/:id", Admin.Setting.SettingController, :get_single_country
    get "/get/all/active/country", Admin.Setting.SettingController, :activeCountry
    post  "/add/currency", Admin.Setting.SettingController, :insert_currency
    post "/edit/currency", Admin.Settings.CurrencyController, :update_currency

    post "/add/document/category", Admin.Setting.SettingController, :insert_document_category
    post "/edit/document/category", Admin.Setting.SettingController, :update_document_category
    post "/add/document/type", Admin.Setting.SettingController, :insert_document_type
    post "/edit/document/type", Admin.Setting.SettingController, :update_document_type
    post "/get/all/document/type", Admin.Setting.SettingController, :get_all_documenttype
    get "/get/all/document/category", Admin.Setting.SettingController, :get_all_document_category
    post "/add/department", Admin.Setting.SettingController, :insert_department
    post "/edit/department", Admin.Setting.SettingController, :update_departments
    post "/edit/version", Admin.Setting.SettingController, :editVersion
    get "/get/version", Admin.Setting.SettingController, :version
    post "/add/project", Admin.Setting.SettingController, :insert_project
    post "/add/application/version", Admin.Setting.SettingController, :insertApplicationVersion
    post "/add/alert/switch", Admin.Setting.SettingController, :insertAlertSwitch
    post "/settings/countryList", Admin.Settings.CountryController, :countriesList
    post "/settings/currencyList", Admin.Settings.CurrencyController, :currenciesList
    get "/currenciesGetAll", Admin.Settings.CurrencyController, :currenciesGetAll
    post "/settings/documentCategory", Admin.Settings.DocumentCategoryController, :documentCategory
    post "/settings/documentType", Admin.Settings.DocumentTypeController, :documentType
    post "/settings/departmentsList", Admin.Settings.DepartmentListController, :departmentsList
    post "/settings/projectsList", Admin.Settings.ProjectsController, :projectsList
    get "/settings/projects/getActiveCompanyList", Admin.Settings.ProjectsController, :getActiveCompanyList
    get "/settings/projects/getActiveUserList", Admin.Settings.ProjectsController, :getActiveUserList
    post "/settings/thirdPartyLogs", Admin.Settings.ThirdPartyLogsController, :thirdPartyLogsList
    post "/settings/recentMails", Admin.Settings.RecentMailsController, :recentMails
    post "/settings/recentMails/v1", Test.TestController, :recentMails_v1
    post "/settings/unblockBlock", Admin.Settings.BlockUnblockController, :blockUser
    get "/settings/adminBeneficiaries/list", Admin.Settings.AdminBeneficiariesController, :adminBeneficiariesList
    post "/settings/alertSwitch", Admin.Settings.AlertSwitchController, :alertSwitch
    post "/settings/applicationVersion", Admin.Settings.ApplicationVersionController, :applicationVersion
    post "/settings/applicationVersion/v1", Test.TestController, :applicationVersion_v1
    get "/get/third/party/view/:id", Admin.Settings.ThirdPartyLogsController, :thirdPartyLogView
    get "/get/resend/mail/view/:id", Admin.Settings.RecentMailsController, :resendMailView
    get "/get/admin/beneficiaries/card/account",
        Admin.Settings.AdminBeneficiariesController,
        :admin_beneficiaries_card_account
    get "/get/admin/beneficiaries/fee/account",
        Admin.Settings.AdminBeneficiariesController,
        :admin_beneficiaries_fee_account
    post "/beneficiaries/update/:beneficiary_id", Admin.Settings.AdminBeneficiariesController, :updateAdminBeneficiary
    post "/beneficiaries/add", Admin.Settings.AdminBeneficiariesController, :addAdminBeneficiary
    get "/getAccountsNonbeneficiary", Admin.Settings.AdminBeneficiariesController, :adminAccountsNonbeneficiary
    post "/update/project/details", Admin.Setting.SettingController, :updateProject
    post "/assign/project", Admin.Settings.ProjectsController, :assignProject
    get "/assign/project/list/:projects_id", Admin.Settings.ProjectsController, :projectsAssignList
    get "/company/employee/project/list/:company_id", Admin.Settings.ProjectsController, :companyEmployeeProjectlist
    get "/get/kyc/country/list", Admin.Settings.CountryController, :getKycCountrylist
    post "/edit/kyc/country/status", Admin.Settings.CountryController, :updateKycCountryStatus
    post "/fourStop/director", Admin.Settings.FourStopController, :director_fourstop
    post "/fourStop/employee", Admin.Settings.FourStopController, :employee_fourstop
    get "/fourStop/callback/:stopid", Admin.Settings.FourStopController, :callback_data

    ## SETTING PANEL END

    ##ADMIN PANEL
    get "/get/admin/profile/info/:id", Admin.AdminController, :getAdminProfile
    get "/get/self/admin/profile", Admin.AdminController, :adminSelfprofileInfo
    post "/change/password", Admin.AdminController, :changePasswordAdminSelf
    post "/change/password/admin/user", Admin.AdminController, :changePassword
    post "/createAdmin", Admin.AdminController, :createAdmin          # it is used for registration in main controller
    post "/cb_update_tp_status", Admin.AdminController, :cb_update_tp_status


    #Comman panel
    post "/add/initialize", Admin.Comman.CommanController, :insertInitlize
    post "/reset/otp/limit", Admin.Comman.CommanController, :resetOtpLimit
    get "/reset/otp/limit/button/:commanall_id", Admin.Comman.CommanController, :resetOtpLimitButton
    get "/updateTrustLevel/:commanall_id", Admin.Comman.CommanController, :updateTrustLevel
    post "/generate/password/admin", Admin.Comman.CommanController, :generatePasswordAdmin
    post "/generate/password/admin/v1", Admin.Comman.CommanController, :generatePasswordAdminv1
    post "/check/own/password/admin", Admin.Comman.CommanController, :checkOwnPassword
    get "/employee/kyc/document/type/list/id", Admin.Comman.CommanController, :employeeKycIdDocumentTypeList
    get "/employee/kyc/document/type/list/address", Admin.Comman.CommanController, :employeeKycAddressDocumentTypeList
    post "/resend/mail/user", Admin.Comman.CommanController, :resendEmailAdmin
    get "/getAll/tag/status", Admin.Comman.CommanController, :getAllTagStatus
    post "/add/tag/status", Admin.Comman.CommanController, :addTag
    get "/view/tag/:commanall_id", Admin.Comman.CommanController, :viewTag
    post "/assign/card/employee", Admin.Comman.CommanController, :employeeAssignCard

    # third party APIs
    get "/create/companyBank/account/:commanall_id", Admin.ThirdpartyController, :createBankAccount
    post "/create/cardManagement/account", Admin.ThirdpartyController, :createAccomplishAccount
    post "/cardEnableDisable", Admin.ThirdpartyController, :cardEnableDisable
    post "/blockCard", Admin.ThirdpartyController, :blockCard
    get "/companyAuthorized/:id", Admin.ThirdpartyController, :companyAuthorized
    post "/company/authorized", Admin.ThirdpartyController, :companyAuthorizedV1
    get "/employeeRegistation/:commanall_id", Admin.ThirdpartyController, :employeeRegistation
    get "/compayIdentification/:commanall_id", Admin.ThirdpartyController, :compayIdentification
    get "/employeeIdentification/:commanall_id", Admin.ThirdpartyController, :employeeIdentification
    get "/companyUploadIdProof/:commanall_id", Admin.ThirdpartyController, :companyUploadIdProof
    get "/companyUploadAddressProof/:commanall_id", Admin.ThirdpartyController, :companyUploadAddressProof
    get "/employeeUploadIdProof/:commanall_id", Admin.ThirdpartyController, :employeeUploadIdProof
    get "/employeeUploadAddressProof/:commanall_id", Admin.ThirdpartyController, :employeeUploadAddressProof
    get "/employeeCardGenerate/:commanall_id", Admin.ThirdpartyController, :employeeCardGenerate
    post "/directorKycVerification", Admin.ThirdpartyController, :directorKycVerification
    post "/employeeKycVerification", Admin.ThirdpartyController, :employeeKycVerification
    get "/accountPullTransactions/:account_id", Admin.ThirdpartyController, :accountPullTransactions
    post "/accountPullTransactions/dates/:account_id", Admin.ThirdpartyController, :accountPullTransactionsForDateRange

    post "/transaction/refundAdminTransaction", Admin.Comman.ThirdPartyController, :refundAdminCBTransaction

    post "/transferCompanyBankBalance", Admin.Transaction.PaymentController, :transferCompanyBankBalance
    post "/transferCompanyAccountBalance", Admin.Transaction.PaymentController, :transferCompanyAccountBalance

    post "/reset_cache", Admin.AdminController, :cache_reset

    ## upload Director kyc on third party
    post "/uploadDirectorKyc", Admin.Companies.DirectorsController, :uploadDirectorKyc
    post "/uploadCompanyKyb", Admin.Companies.DirectorsController, :uploadCompanyKyb
    #    post "/transferCompanyCardBalance", Admin.Transaction.PaymentController, :transferCompanyCardBalance

    # Upload KYC Documents - Check if Director is also employee if true then Upload on Both
    post "/director/kyc/upload", Admin.KycDocuments.KycDocumentsController, :directorDocumentUpload
    post "/employee/kyc/upload", Admin.KycDocuments.KycDocumentsController, :employeeDocumentUpload
    post "/v2/employee/kyc/override", Admin.Accounts.AccountUpdateController, :employeeKycOverrideV2
    post "/v2/director/kyc/override", Admin.Accounts.AccountUpdateController, :directorKycOverrideV2
    post "/v2/employee/kyc/comments", Admin.Accounts.AccountUpdateController, :employeeKycCommentsV2
    post "/v2/director/kyc/comments", Admin.Accounts.AccountUpdateController, :directorKycCommentsV2

    post "/update/:id", Admin.AdminController, :updateAdmin
    get  "/kyc/country/list", Comman.CountryController, :getKycCountry
  end
end
