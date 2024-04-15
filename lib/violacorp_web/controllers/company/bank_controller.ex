defmodule ViolacorpWeb.Company.BankController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Beneficiaries
  alias Violacorp.Schemas.Transactions

  alias ViolacorpWeb.Companies.CompanyView

  @doc "bankAccountDetails of logged in company"
  def bankAccountDetails(conn, _params) do
    %{"id" => companyid} = conn.assigns[:current_user]

    account = Repo.one(
      from b in Companybankaccount, where: b.company_id == ^companyid and b.status == "A",
                                    select:
                                    %{
                                      id: b.id,
                                      company_id: b.company_id,
                                      account_id: b.account_id,
                                      account_number: b.account_number,
                                      account_name: b.account_name,
                                      iban_number: b.iban_number,
                                      bban_number: b.bban_number,
                                      currency: b.currency,
                                      balance: b.balance,
                                      sort_code: b.sort_code,
                                      bank_code: b.bank_code,
                                      bank_type: b.bank_type,
                                      bank_status: b.bank_status,
                                      status: b.status,
                                      inserted_by: b.inserted_by
                                    }
    )

    account_data = if is_nil(account) do
      "No Account Found"
    else
      account
    end
    json conn, %{status_code: "200", data: account_data}
  end

  @doc "bankAccountDetails of logged in company"
  def bankAccountBeneficiaries(conn, params) do
    %{"id" => companyid} = conn.assigns[:current_user]

    account = Beneficiaries
              |> where([b], b.company_id == ^companyid)
              |> where([b], b.mode == ^"P")
              |> where([b], b.status == ^"A")
              |> Repo.paginate(params)

    render(conn, CompanyView, "manybeneficiaries_paginate.json", beneficiaries: account)
  end

  @doc "bankAccountDetails of logged in company"
  def addTemporaryBeneficiary(conn, params) do
    %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]
    find_beneficiary = Repo.get_by(Beneficiaries, company_id: companyid, account_number: params["account_number"], mode: "P")
    if is_nil(find_beneficiary) do
      find = Repo.get_by(Companybankaccount, account_number: params["account_number"], status: "A")

      type = if is_nil(find) do
        "E"
      else
        "I"
      end

      new_beneficiary = %{
        company_id: companyid,
        first_name: params["first_name"],
        last_name: params["last_name"],
        nick_name: params["nick_name"],
        sort_code: params["sort_code"],
        account_number: params["account_number"],
        description: params["description"],
        invoice_number: params["invoice_number"],
        type: type,
        status: "A",
        mode: "T",
        inserted_by: commanid
      }
      changeset = Beneficiaries.changeset(%Beneficiaries{}, new_beneficiary)
      case Repo.insert(changeset) do
        {:ok, data} ->
          id = data.id
          json conn, %{status_code: "200", message: "Beneficiary Added Successfully", id: id}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4003", message: "Beneficiary Already Added"}
    end
  end

  #
  @doc "Update Temporary Beneficiary"
  def updateTemporaryBeneficiary(conn, params) do
#    %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

    mode = if params["add"] == "yes", do: "P",  else: "T"

    find_beneficiary = Repo.get_by(Beneficiaries, id: params["id"])
    if find_beneficiary != nil do
      change_mode = %{mode: mode}
      changeset = Beneficiaries.changesetBeneficiaryMode(find_beneficiary, change_mode)

      case Repo.update(changeset) do
        {:ok, _response} ->
          json conn, %{status_code: "200", message: "Beneficiary Update Successfully"}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4003", message: "Beneficiary Not Found."}
    end
  end

  @doc "bankAccountDetails of logged in company"
  def addBankAccountBeneficiary(conn, params) do
    %{"commanall_id" => commanid, "id" => companyid} = conn.assigns[:current_user]

    find_beneficiary = Repo.get_by(
      Beneficiaries,
      company_id: companyid,
      account_number: params["account_number"],
      sort_code: params["sort_code"]
    )
    if is_nil(find_beneficiary) do
      find = Repo.get_by(
        Companybankaccount,
        sort_code: params["sort_code"],
        account_number: params["account_number"],
        status: "A"
      )

      type = if is_nil(find), do: "E", else: "I"

    new_beneficiary = %{
      company_id: companyid,
      first_name: params["first_name"],
      last_name: params["last_name"],
      nick_name: params["nick_name"],
      sort_code: params["sort_code"],
      account_number: params["account_number"],
      description: params["description"],
      invoice_number: params["invoice_number"],
      type: type,
      status: "A",
      inserted_by: commanid
    }
    changeset = Beneficiaries.changeset(%Beneficiaries{}, new_beneficiary)
    case Repo.insert(changeset) do
      {:ok, _response} ->
        json conn, %{status_code: "200", message: "Beneficiary Added Successfully"}
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
    end
    else
      json conn,
           %{
             status_code: "4004",
             errors: %{
               message: "Beneficiary Already Added"
             }
           }
    end
  end

  @doc """
    Beneficiary Transaction List
  """
  def getAllBeneficiaryTransaction(conn, params) do
    %{"id" => _companyid} = conn.assigns[:current_user]
    where = params
            |> Map.take(~w( beneficiaries_id account_id))
            |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    beneficiary_transaction = (from t in Transactions,
                                where: ^where,
                                select: t)
                          |> Repo.paginate(params)
    render(conn, CompanyView, "beneficiaryTransactions.json", transactions: beneficiary_transaction)
  end

  @doc """
    Edit bankAccountDetails of logged in company
  """
  def editBankAccountBeneficiary(conn, %{"beneficiary_id" => beneficiary_id, "invoice_number" => invoice_number, "reference" => reference}) do
    %{"id" => companyid} = conn.assigns[:current_user]

    find_beneficiary = Repo.get_by(Beneficiaries, company_id: companyid, id: beneficiary_id)
    if find_beneficiary != nil do
        change_invoice_number = %{
          invoice_number: invoice_number,
          description: reference,
        }
        changeset = Beneficiaries.changesetBeneficiary(find_beneficiary, change_invoice_number)

        case Repo.update(changeset) do
          {:ok, _response} ->
            json conn, %{status_code: "200", message: "Beneficiary Update Successfully"}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
    else
       json conn, %{status_code: "4003", message: "Beneficiary Not Found."}
    end
  end

  def editBankAccountBeneficiary(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc """
     remove Beneficiaries
  """
  def removeBeneficiaries(conn, %{"beneficiary_id" => beneficiary_id}) do
    %{"id" => companyid} = conn.assigns[:current_user]

    beneficiaries = Repo.get_by(Beneficiaries, company_id: companyid, id: beneficiary_id, status: "A")
    if is_nil(beneficiaries) do
      json conn,
           %{
             status_code: "4003",
             errors: %{
               message: "Beneficiary Not Found."
             }
           }
    else
      status = %{status: "B"}
      changeset = Beneficiaries.updateStatus(beneficiaries, status)
      case Repo.update(changeset) do
        {:ok, _beneficiaries} ->
          json conn, %{status_code: "200", message: "Success! Beneficiary Removed."}
        {:error, changeset} ->
          conn
          |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      end
    end
  end
end
