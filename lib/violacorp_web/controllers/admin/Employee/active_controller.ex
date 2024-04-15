defmodule ViolacorpWeb.Admin.Employee.ActiveController do
  use Phoenix.Controller

  alias  Violacorp.Models.Employee
  alias Violacorp.Models.Comman

  alias ViolacorpWeb.ErrorView

  @doc "get user 4s View"
  def get_user_4stop_view(conn, params)do
#json conn, "OK"
    data = Employee.get_user_4stop_view(params)

    case data do
      []->  json conn, %{status_code: "4003", msg: "Record not found"}

      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "get all active user"
  def getAll_active_User(conn, params)do

    data = Employee.getAllActiveEmployee(params)
    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
      data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc """
    list of all pending user
  """
  def getAllPendingEmployee(conn, params) do
    data = Employee.getAllPendingEmployee(params)

    json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
      data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc "active user profile"
  def activeUserProfile(conn, params)do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
        data = Employee.active_user_view(params)
        case data do
          nil ->  json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
          data ->
            json conn, %{status_code: "200", data: data}
        end
      else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
  def pendingUserProfile(conn, params)do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      data = Employee.pending_user_profile(params)
      case data do
        nil ->  json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
        data ->
          json conn, %{status_code: "200", data: data}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
  @doc "active user cards list "
  def get_Single_Employee_Cards(conn, params)do
    data = Employee.active_user_card(params)

    case data do
      [] -> json conn, %{status_code: "4004", errors: %{message: "No  card found"}}

      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "active user   kyc "
  def active_user_kyc_detail(conn, params)do
    data = Employee.active_user_kyc(params)
    case data do
      [] -> json conn, %{status_code: "4003", errors: %{message: "No  kyc found"}}
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end


  @doc "active user address"
  def active_user_address(conn, params)do
    data = Employee.active_user_address(params)
    case data do
      nil-> json conn, %{status_code: "4003", message: "address not found"}

      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "active user contact"
  def active_user_contact(conn, params)do
    data = Employee.active_user_contact(params)
    case data do
      [] -> json conn, %{status_code: "4003", msg: "contact not found"}
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "active user notes/comments"
  def active_user_notes(conn, params)do
    data = Employee.active_user_notes(params)
    case data do
      [] -> render(conn, ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  @doc "active user notes/comments"
  def getActiveUserPreviousNotes(conn, params)do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
        data = Employee.get_active_user_previous_notes(params)
#        case data do
#          [] -> json conn, %{status_code: "4004",errors: %{message: "Record not found"}}
#          data ->
            json conn, %{status_code: "200", data: data}
#        end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
  @doc "active insert_active_user_new_notes/comments"
  def insertActiveUsernewnotes(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
          status = Employee.insert_active_user_new_notes(params, admin_id)
          case status do
            {:ok, _data} -> json conn, %{status_code: "200", message: "Success, Comment Added."}
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
  @doc "active_user_proof/document/comment"
  def insertActiveUserKycProofcomment(conn, params)do
    with true <-  (Enum.all?(["kycdocuments_id", "status", "comments"], &(Map.has_key?(params, &1)))) do
         %{"id" => admin_id} = conn.assigns[:current_user]
         case Employee.insert_active_user_kyc_proof_comment(params, admin_id) do
           {:error, changeset} ->
                 conn
                 |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
           {:ok, message} -> json conn, %{status_code: "200", message: message}
           {:document_error, message} -> json conn, %{status_code: "4004", document_error: %{message: message}}
           {:status_error, message} -> json conn, %{status_code: "4003", errors: %{status: message}}
           {:validation_error, message} -> json conn, message
         end
    else
    false ->
      json conn, %{status_code: "4004", parameter: %{error: "Required parameters: [kycdocuments_id, director_id, status, comments]"}}
   end
  end
  @doc""

  def pullCards(conn, params) do
    %{"type" => type, "id" => admin_id} = conn.assigns[:current_user]

    if type == "A" do
      case Employee.pullCards(params, admin_id) do
        {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
        {:ok, response_message} -> json conn, %{status_code: "200", message: response_message}
        {:thirdparty_errors, message} -> json conn, %{status_code: "5004", errors: %{message: message}}
      end
    else
      json conn, %{status_code: "4002",errors: %{message: "You have not permission to any update, Please contact to administrator."}}
    end

  end

  @doc"active user document info"
  def employeeKycDocument(conn, params) do

     result = Employee.employeeKycDocument(params)
     case result do
      [] -> render(conn, ErrorView, "recordNotFound.json")
      data -> json conn, %{status_code: "200", data: data}
     end
  end

  @doc"active employee address update"
  def updateEmployeeAddress(conn, params) do

    {status, response} = Employee.employeeUpdateAddress(params)
    case status do
      :ok -> json conn, %{status_code: "200", message: "Address Updated"}
      :error -> render(conn, ErrorView, "error.json", changeset: response)
    end
  end
  @doc """
    check document Uploaded on third party
  """
  def checkDocumentUpload(conn, params) do
#    %{"type" => type} = conn.assigns[:current_user]

    case Employee.checkDocumentUpload(params) do
      {:ok, response_message} -> json conn, %{status_code: "200", message: response_message}
      {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
    end
  end



  @doc "Permanant Delete Pending User"
  def permanantlyDeletePendingUser(conn, params)do
    %{"type" => type, "id" => admin_id} = conn.assigns[:current_user]
    if type == "A"do
       data = Comman.checkOwnPassword(params, admin_id)
       if !is_nil(data) do
              case Employee.permanantlyDeletePendingUser(params)do
                {:ok, message} ->
                  json conn, %{status_code: "200", message: message}
                {:error, message} ->
                  json conn, %{status_code: "4003", errors: %{message: message}}
              end
         else
         json conn,%{status_code: "4004", error: %{message: "Password Does not Matched"}}
       end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def activeDirectorList(conn,params)do
    %{"type" => type, "id" => _admin_id} = conn.assigns[:current_user]
    if type == "A"do
      data = Employee.comment_director_list(params)
      case data do
        [] -> json conn, %{status_code: "4004", errors: %{message: "No  card found"}}
        data ->
          json conn, %{status_code: "200", data: data}
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  def userKycCommentList(conn,params) do
    %{"type" => type, "id" => _admin_id} = conn.assigns[:current_user]
    if type == "A"do
      data = Employee.user_comments_list(params)
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
   API for employee enable/disable/block
  """
  def changeEmployeeStatus(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]

    case Employee.changeEmployeeStatus(params, admin_id) do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:already_status, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:validation_error, message} -> json conn, %{status_code: "4003", errors: message}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  @doc"employee kyc override"
  def employeeKycOverride(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Employee.employeeKycOverride(params, admin_id) do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:error, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:already_exist, add} -> json conn,%{status_code: "4004", errors: %{message: add}}
    end
  end

  @doc"Employee Card Details"
  def employeeCardDetails(conn, params) do
    json conn, %{status_code: "200", data: Employee.employeeCardDetails(params)}
  end


  @doc """
    this service for update email active and pending employee
  """
  def employeeEmailUpdate(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Comman.updateEmployeeEmail(params, admin_id) do
      {:ok, _message} -> json conn, %{status_code: "200", message: "Email Updated"}
      {:errors , changeset} -> render(conn, ViolacorpWeb.ErrorView,"error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:email_existing, message} -> json(conn,%{status_code: "4003", errors: %{email_id: message}})
    end
  end

  @doc """
    this service for update contact active and pending employee
  """
  def updateEmployeeContact(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Comman.updateEmployeeContact(params, admin_id) do
      {:ok, _message} -> json conn, %{status_code: "200" , message: "Contact Updated"}
      {:errors , changeset} -> render(conn, ViolacorpWeb.ErrorView,"error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:contact_existing, message} -> json(conn,%{status_code: "4003", errors: %{contact_number: message}})
    end
  end

end


