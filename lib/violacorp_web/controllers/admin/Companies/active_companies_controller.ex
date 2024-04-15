defmodule ViolacorpWeb.Admin.Companies.ActiveCompaniesController do
   use Phoenix.Controller

   alias Violacorp.Models.Companies.ActiveCompanies

   @doc"loding fee plan detail "
   def activeCompanyLoadingFee(conn, params) do
     %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
     if type == "A"  do
       case ActiveCompanies.activeCompanyLoadingFee(params,admin_id) do
         {:ok, message} ->
           conn
           |>put_status(:ok)
           |>put_view(ViolacorpWeb.SuccessView)
           |> render("success.json", response: message)
         {:error, changeset} ->
           conn
           |> put_view(ViolacorpWeb.ErrorView)
           |> render("error.json", changeset: changeset)
         {:not_found, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
         {:error_message, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
         {:validation_error, error_message} ->
           json conn, error_message
       end
     else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

  @doc" List of Active Companies"
  def activeCompanies(conn, params) do
    data =  ActiveCompanies.active_companies(params)

#    case  data.entries do
#      []->
#        json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
#      _data ->
        json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
#    end

  end
  #-------------------------Active--Companies---Profile-----------------------------------------------


   @doc" get single company by id"

   def onlineAccount(conn, params) do
     data = ActiveCompanies.online_account(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc" Get Card Management Account"

   def cardManagementAccount(conn, params) do
     data = ActiveCompanies.card_management_account(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end


   @doc" Get Employee Details"

   def employeeDetails(conn, params) do
     data = ActiveCompanies.employee_details(params)
     case data.entries do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
     end
   end

   @doc" Get Director Details"

   def directorDetails(conn, params) do
     data = ActiveCompanies.director_details(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   def directorlist(conn, params) do
     data = ActiveCompanies.director_list(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc" Get Company Address Contacts Details"

   def companyAddressContact(conn, params) do
     data = ActiveCompanies.company_address_contacts(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc" Get Company Description"

   def companyDescription(conn, params) do
     data = ActiveCompanies.company_description(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc" Get employee Card Description"

   def employeeCard(conn, params) do
     data = ActiveCompanies.employee_card(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   def companyEmployeeCardTransaction(conn, params) do
     data = ActiveCompanies.employee_card_transaction(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       transactions ->
        conn
        |>put_view(ViolacorpWeb.TransactionsView)
        |>render("employee_index.json", transactions: transactions)
     end
   end

   @doc" Get company Kyb Description"

   def companyKyb(conn, params) do
     data = ActiveCompanies.company_kyb(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       _data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc" Get company  Description"

   def companyProfile(conn, params) do

     data = ActiveCompanies.company_info(params)
     case data do
       nil ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         json conn, %{status_code: "200",data: data}
     end
   end

   @doc""

   def companyTopup(conn, params) do
     data = ActiveCompanies.companyTopup(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index_company_topup.json", data: data)
     end
   end
   @doc""

   def cardManagement_topupHistory(conn, params) do
     data = ActiveCompanies.cardManagement_topupHistory(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         #json conn, %{status_code: "200",data: data}

         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index.json", data: data)
     end
   end

   @doc""

   def feeTransactions_company(conn, params) do
     data = ActiveCompanies.feeTransactions_company(params)
      json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}

   end

   @doc""

   def credit_debit_transactions_company(conn, params) do
     data = ActiveCompanies.credit_debit_transactions_company(params)

         json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
   end

   @doc""

   def company_transfers(conn, params) do
     data = ActiveCompanies.company_transfers(params)
       json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
   end

   @doc""

   def cardManagement_companyTransactions(conn, params) do
     data = ActiveCompanies.cardManagement_companyTransactions(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index_companyTransactions.json", data: data)
     end
   end
   @doc""

   def cardManagement_userTransactions(conn, params) do

     data = ActiveCompanies.cardManagement_userTransactions(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index_userTransactions.json", data: data)
     end

   end
   @doc""

   def cardManagement_POS_transactions(conn, params) do

     data = ActiveCompanies.cardManagement_POS_transactions(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index_POS_transactions.json", data: data)
     end
   end

   @doc""
   def cardManagement_FEE_transactions(conn, params) do
     data = ActiveCompanies.cardManagement_FEE_transactions(params)
     case data do
       [] ->
         json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
       data ->
         conn
         |>put_view(ViolacorpWeb.TransactionsView)
         |>render("index_FEE_transactions.json", data: data)
     end
   end


   @doc"To Update active company status on profile"

   def updateInternalStatus(conn, params) do
     %{"id" => _adminid, "type" => type} = conn.assigns[:current_user]
     if type == "A"  do
       case ActiveCompanies.internalStatusUpdate(params) do
         {:ok, message} ->
           conn
           |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
         {:error, changeset} ->
           conn
           |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         {:not_found, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
       end
     else
       json conn,
            %{
              status_code: "4002",
              errors: %{
                message: "Update Permission Required, Please Contact Administrator."
              }
            }
     end
   end

   def blockActiveCompany(conn, params) do
     %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
     if type == "A"  do
       case ActiveCompanies.blockCompany(params,admin_id) do
         {:ok, message} ->
           conn
           |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
         {:error, changeset} ->
           conn
           |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         {:not_found, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
       end
     else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

   def compnayKybComment(conn, params) do
     %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
     if type == "A"  do
       case ActiveCompanies.companyComment(params,admin_id) do
         {:ok, message} -> json conn, %{status_code: "200", message: message}
         {:error, changeset} ->
           conn
           |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         {:not_found, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
       end
     else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

   def updateEmployeeCardStatus(conn, params) do
     %{"id" => admin_id, "type" => type} = conn.assigns[:current_user]
     request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
     if type == "A"  do
       case ActiveCompanies.updateCardStatus(request) do
         {:ok, message} ->
           conn
           |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
         {:error, changeset} ->
           conn
           |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         {:error_message, error_message} ->
           json conn, %{status_code: "4004", errors: %{ message: error_message}}
       end
     else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end
  @doc" End of Module"
   def mauallyCaptureTransaction(conn, params) do
       %{"id" => _admin_id, "type" => type} = conn.assigns[:current_user]
     if type == "A"  do
         _data = ActiveCompanies.manualTransactions(params)
         json conn,
              %{
                status_code: "200",
                message: "Manually capture success & pending transactions."
              }
       else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

   def directorKycComments(conn,params) do
     %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
     data = ActiveCompanies.director_kyc_comments(params, admin_id)
     if type == "A"  do
             case data do
               {:ok,_data} -> json conn, %{status_code: "200", message: "Comment Added Success"}
               {:error, changeset} ->
                 conn
                 |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
             end
       else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

   def directorKycCommentList(conn,params) do
     %{"type" => type, "id" => _admin_id} = conn.assigns[:current_user]
     if type == "A"do
         data = ActiveCompanies.director_comments_list(params)
         case data do
           [] -> json conn, %{status_code: "4004", errors: %{message: "No  Record found"}}
           data ->
             json conn, %{status_code: "200", data: data}
         end
      else
       json conn, %{status_code: "4002", errors: %{
         message: "Update Permission Required, Please Contact Administrator."}
       }
     end
   end

   @doc """
    API for company enable/disable/block
   """
  def changeCompanyStatus(conn, params) do
   %{"id" => admin_id} = conn.assigns[:current_user]

     case ActiveCompanies.changeCompanyStatus(params, admin_id) do
       {:ok, message} -> json conn, %{status_code: "200", message: message}
       {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
       {:already_status, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
       {:error, changeset} ->
         conn
         |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
     end
  end


   @doc" Active Company Checklist"
   def activeCompanyCheckList(conn, params) do
     {status, data} = ActiveCompanies.activeCompanyCheckList(params)
     case status do
       :ok -> json conn, %{status_code: "200", data: data}
       :error -> json conn, %{status_code: "4004", error: data}
     end
   end

end