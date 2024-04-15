defmodule ViolacorpWeb.Admin.Comman.CommanController do
 use Phoenix.Controller

  alias Violacorp.Repo
 import Ecto.Query

  alias Violacorp.Models.Comman
#  alias ViolacorpWeb.SuccessView
  alias ViolacorpWeb.ErrorView
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Employeecards
#  alias Violacorp.Schemas.Resendmailhistory
#  alias Violacorp.Schemas.Notifications
#  alias Violacorp.Schemas.Commanall

#  alias  ViolacorpWeb.Main.V2AlertsController
 alias Violacorp.Schemas.Tags
# alias Violacorp.Schemas.Administratorusers
 alias Violacorp.Schemas.Commanall
 alias Violacorp.Schemas.Employee
 alias Violacorp.Schemas.Company

 def getTags(conn, params)do
   id = params["commanall_id"]
   tags = (from a in Tags, where: a.commanall_id == ^id,
                           left_join: admin in assoc(a, :administratorusers),
                           select: %{id: a.id, admin_name: admin.fullname, description: a.description, status: a.status, date: a.inserted_at})
          |> Repo.all
   case tags do
     [] -> json conn, %{status_code: "4004", error: %{message: "No Tags Found"}}
     _ ->
       commanall = Repo.one(from c in Commanall, where: c.id == ^id, select: %{company_id: c.company_id, employee_id: c.employee_id})
       user = case commanall.company_id do
         nil -> name = Repo.one(from e in Employee, where: e.id == ^commanall.employee_id, select: %{firstname: e.first_name, lastname: e.last_name})
                "#{name.firstname} #{name.lastname}"
         _ -> Repo.one(from company in Company, where: company.id == ^commanall.company_id, select: %{company_name: company.company_name})
       end

       data = %{user: user, tags: tags}
       json conn, %{status_code: "200", data: data}
   end
 end

 @doc""
 def deleteEmployeeKyc(conn, params)do
   %{"id" => admin_id} = conn.assigns[:current_user]
   case check_params(params, ["kyc_id", "password"])do
     true -> {status, message} = Comman.deleteEmployeeKyc(params, admin_id)
             case status do
               :ok -> json conn, %{status_code: "200", message: message}
               :error -> json conn, %{status_code: "4004", errors: %{message: message}}
               :incorrect_password -> json conn, %{status_code: "4003", errors: %{password: message}}
             end
     false -> json conn, %{status_code: "4004", errors: %{message: "Invalid Params (Required: kyc_id, password)"}}
   end
 end

 @doc""
 def deleteDirectorKyc(conn, params)do
   %{"id" => admin_id} = conn.assigns[:current_user]
   case check_params(params, ["kyc_id", "password"])do
     true -> {status, message} = Comman.deleteDirectorKyc(params, admin_id)
             case status do
               :ok -> json conn, %{status_code: "200", message: message}
               :error -> json conn, %{status_code: "4004", errors: %{message: message}}
               :incorrect_password -> json conn, %{status_code: "4003", errors: %{password: message}}
             end
     false -> json conn, %{status_code: "4004", errors: %{message: "Invalid Params (Required: kyc_id, password)"}}
   end
 end

 @doc""
 def check_params(available, required) do
   Enum.all?(required, &(Map.has_key?(available, &1)))
 end

 @doc""
 def deleteCompanyKyc(conn, params)do
   %{"id" => admin_id} = conn.assigns[:current_user]
   case check_params(params, ["kyc_id", "password"])do
     true -> {status, message} = Comman.deleteCompanyKyc(params, admin_id)
             case status do
               :ok -> json conn, %{status_code: "200", message: message}
               :error -> json conn, %{status_code: "4004", errors: %{message: message}}
               :incorrect_password -> json conn, %{status_code: "4003", errors: %{password: message}}
             end
     false -> json conn, %{status_code: "4004", errors: %{message: "Invalid Params (Required: kyc_id, password)"}}
   end
 end
 @doc""
 def employeeKycIdDocumentTypeList(conn, _params) do
   data = Comman.employeeKycIdDocumentTypeList()
   case data do
     [] -> json conn, %{status_code: "4004", error: "Document List not Found"}
     data -> json conn, %{status_code: "200", data: data}
   end
 end

 def employeeKycAddressDocumentTypeList(conn, _params) do
   data = Comman.employeeKycAddressDocumentTypeList()
   case data do
     [] -> json conn, %{status_code: "4004", error: "Document List not Found"}
     data -> json conn, %{status_code: "200", data: data}
   end
 end

 def insertInitlize(conn, params)do
         %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
         request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
         if type == "A"  do
             case Comman.add_initlize(request,admin_id) do
               {:ok, message} ->
                 conn
                 |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
               {:error, changeset} ->
                 conn
                 |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
               {:error_message, message} ->
                 json conn, %{status_code: "4004", errors: %{message: message}
                 }
             end
           else
           json conn, %{status_code: "4002", errors: %{
             message: "Update Permission Required, Please Contact Administrator."}
           }
         end
 end

 def resetOtpLimitButton(conn, params)do
     %{"type" => type} = conn.assigns[:current_user]
   if type == "A" do
   data =  Comman.resetOtpLimit_button(params)
   case data do
     {} ->
       json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
     data ->
       json conn, %{status_code: "200",data: data}
   end
   else
     json conn,
          %{
            status_code: "4002",
            errors: %{
              message: "You have not permission to any update, Please contact to administrator."
            }
          }
   end
 end

 def resetOtpLimit(conn, params) do
   unless map_size(params) == 0 do
     getinfo = Repo.all(from o in Otp, where: o.commanall_id == ^params["commanall_id"] and o.status == "A", select: o)
       if getinfo != [] do
         Enum.each getinfo, fn data ->
           generate_otp = Commontools.randnumber(6)

           otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
           new_otp = Poison.encode!(otp_code_map)

           otpmap = %{
             "otp_code" => new_otp,
           }
           changeset = Otp.attempt_changeset(data, otpmap)

           Repo.update(changeset)
         end
         json conn, %{status_code: "200", message: "Success! OTP limit reset done"}
       else
         conn
         |> Phoenix.Controller.render(ErrorView, :otpNotFound)
       end
   else
     conn
     |> Phoenix.Controller.render(ErrorView, :errorNoParameter)
   end
 end

 def updateTrustLevel(conn, params) do
   case Comman.updateTrustLevel(params) do
     {:ok, message} -> json conn, %{status_code: "200", message: message}
     {:error, changeset} ->
       conn
       |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
     {:error_message, error_message} ->
       json conn, %{status_code: "4004", errors: %{ message: error_message}}
     {:third_party_error, error_message} ->
       json conn, error_message
   end
 end

 def generatePasswordAdmin(conn, params) do
   %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
   if type == "A"  do
         response = Comman.generatepassword(params,admin_id)
         case response do
           {:ok, _data} -> json conn, %{status_code: "200", message: "Generate password successfully"}
           {:error, changeset} ->
             conn
             |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         end
     else
     json conn,
          %{
            status_code: "4002",
            errors: %{
              message: "You have not permission to any update, Please contact to administrator."
            }
          }
   end
 end

 def generatePasswordAdminv1(conn, params) do
   %{"type" => type} = conn.assigns[:current_user]
   if type == "A"  do
     response = Comman.generatepasswordv1(params)
     case response do
       {:ok, _data} -> json conn, %{status_code: "200", message: "Generate password successfully"}
       {:error, changeset} ->
         conn
         |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
     end
   else
     json conn,
          %{
            status_code: "4002",
            errors: %{
              message: "You have not permission to any update, Please contact to administrator."
            }
          }
   end
 end

 def checkOwnPassword(conn, params) do
      %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
       if type == "A"  do
          data =  Comman.checkOwnPassword(params,admin_id)
           if !is_nil(data) do
             json conn,%{status_code: "200", message: "Password Matched"}
             else
             json conn,%{status_code: "4004", error: %{message: "Password Does not Matched"}}
          end
         else
          json conn,
            %{
              status_code: "4002",
              errors: %{
                message: "You have not permission to any update, Please contact to administrator."
              }
            }
       end
 end

 # Send again mail
 def resendEmailAdmin(conn, params) do
       %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
       if type == "A"  do
         data = Comman.adminredsendEmail(params, admin_id)
         if !is_nil(data)do
            case data do
              {:ok, _data} -> json conn, %{status_code: "200", message: "Resend Mail successfully"}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
           else
           json conn, %{status_code: "4004", error:  %{message: "Record not Found!"}}
         end
       else
         json conn,
              %{
                status_code: "4002",
                errors: %{
                  message: "You have not permission to any update, Please contact to administrator."
                }
              }
       end
 end

def employeeAssignCard(conn,params) do
   %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
     if type == "A"  do
           map = %{  employee_id: params["employee_id"],
             currency:  params["currency"],
             card_type:  params["card_type"],
             reason: params["description"] }
           changeset = Employeecards.changesetAssignCrad(%Employeecards{}, map)
         if changeset.valid? do
           data = Comman.admin_generate_Card(params, admin_id)
            case data do
              {:ok,message} -> json conn,  %{status_code: "200", message: message}
              {:error_message,message} -> json conn,  %{status_code: "4004", errors: %{message: message}}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
                {:errors_thirdParty, message} ->  json conn, %{status_code: "5001", errors: %{message: message}}
            end
          else
           conn
           |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
         end
       else
       json conn,
            %{
              status_code: "4002",
              errors: %{
                message: "You have not permission to any update, Please contact to administrator."
              }
            }
     end
end
 @doc"getAll Status"
 def getAllTagStatus(conn, _params) do

   result = Commontools.getTagStatus()
   json conn, %{status_code: "200", data: result}
 end

 @doc"add tag"
 def addTag(conn, params) do
   %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]

   if type == "A"  do

     {status, response} = Comman.addTag(params, admin_id)
     case status do
       :ok -> json conn, %{status_code: "200", message: "Tag Added"}
       :error -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: response)
     end
   else
     json conn, %{status_code: "4002", errors: %{
       message: "Update Permission Required, Please Contact Administrator."}
     }
   end
 end

 @doc"view comment"
 def viewTag(conn, params) do

   result = Comman.viewTag(params)
   json conn, %{status_code: "200", data: result.entries, page_number: result.page_number, total_pages: result.total_pages}
 end

end

