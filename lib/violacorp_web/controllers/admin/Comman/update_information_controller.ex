defmodule ViolacorpWeb.Admin.Comman.UpdateInformationController do
  @moduledoc false
  use Phoenix.Controller
  alias Violacorp.Models.Comman.UpdateInformation

#  alias ViolacorpWeb.ErrorView
  @doc """
    this service for update contact active and pending employee
  """
  def updateEmployeeDob(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
     case UpdateInformation.updateEmployeeDob(params, admin_id) do
      {:ok, _message} -> json conn, %{status_code: "200" , message: "Date of Birth updated Successfully"}
      {:errors , changeset} -> render(conn, ViolacorpWeb.ErrorView,"error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
    end
  end

  @doc"edit director email"
  def updateDirectorEmail(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    result = UpdateInformation.editDirectorEmail(params,admin_id)
    case result do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:errors, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, message} -> json conn,%{status_code: "4004", errors: %{message: message}}
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:email_existing, message} -> json conn,%{status_code: "4003", errors: %{email_id: message}}
    end
  end

  @doc"edit director contact"
  def updateDirectorContact(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    result = UpdateInformation.editDirectorContact(params,admin_id)
    case result do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:errors, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
      {:contact_existing, message} -> json(conn,%{status_code: "4003", errors: %{contact_number: message}})
    end
  end

  @doc"add director dob"
  def updateDirectorDob(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    data = UpdateInformation.editDirectorDob(params,admin_id)
    case data do
      {:ok, data} -> json conn, %{status_code: "200", message: data}
      {:errors, changeset} -> render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_not_found, message} -> json(conn, %{status_code: "4004", errors: %{message: message}})
      {:thirdparty_error_message, message} -> json(conn, %{status_code: "5001", errors: %{message: message}})
    end
  end
end
