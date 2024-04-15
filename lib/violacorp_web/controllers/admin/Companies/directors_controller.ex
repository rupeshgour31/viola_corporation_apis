defmodule ViolacorpWeb.Admin.Companies.DirectorsController do
  use Phoenix.Controller

  alias Violacorp.Models.Companies.Directors
  @moduledoc false

  @doc """
    this function for upload director kyc on third party
  """
  def uploadDirectorKyc(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Directors.uploadDirectorKyc(params, admin_id) do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:field_error, changeset} -> json conn, %{status_code: "4003", errors: changeset}
      {:not_matched, message} -> json conn, %{status_code: "4003", errors: %{password: message}}
    end
  end

  @doc """
    this function for upload company kyb on accomplish
  """
  def uploadCompanyKyb(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    case Directors.uploadCompanyKyb(params, admin_id) do
      {:ok, message} -> json conn, %{status_code: "200", message: message}
      {:not_found, message} -> json conn, %{status_code: "4004", errors: %{message: message}}
      {:field_error, changeset} -> json conn, %{status_code: "4003", errors: changeset}
      {:not_matched, message} -> json conn, %{status_code: "4003", errors: %{password: message}}
    end
  end




end
