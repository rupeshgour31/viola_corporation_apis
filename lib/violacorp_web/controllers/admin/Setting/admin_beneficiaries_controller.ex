defmodule ViolacorpWeb.Admin.Settings.AdminBeneficiariesController do
  use Phoenix.Controller

  alias Violacorp.Settings.AdminBeneficiariesSetting
  @moduledoc false

  @doc " Admin Beneficiaries List"

  def adminBeneficiariesList(conn, params) do
   data = AdminBeneficiariesSetting.admin_beneficiaries_list(params)
   json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def admin_beneficiaries_card_account(conn, params) do
    data = AdminBeneficiariesSetting.admin_beneficiaries_card_account(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def admin_beneficiaries_fee_account(conn, params) do
    data = AdminBeneficiariesSetting.admin_beneficiaries_fee_account(params)
    json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc """
    add admin beneficiary
  """
  def addAdminBeneficiary(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
      _request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
      response = AdminBeneficiariesSetting.addAdminBeneficiary(params)
      case response do
        {:ok, message} -> json conn, %{status_code: "200", message: message}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        {:error_message, error_message} ->
          json conn, %{status_code: "4004", errors: %{ message: error_message}}
        {:error_valid, error_message} ->
          json conn, %{status_code: "4003", errors: %{ message: error_message}}
      end
  end

  @doc """
    update admin beneficiary
  """
  def updateAdminBeneficiary(conn, params) do
    response = AdminBeneficiariesSetting.updateAdminBeneficiary(params)
    case response do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, error_message} ->
        json conn, %{status_code: "4004", errors: %{ message: error_message}}
    end
  end

  def adminAccountsNonbeneficiary(conn, _params) do
    response = AdminBeneficiariesSetting.getWithoutBeneficiaryAccount()
    json conn, %{status_code: "200", data: response}
  end
end
