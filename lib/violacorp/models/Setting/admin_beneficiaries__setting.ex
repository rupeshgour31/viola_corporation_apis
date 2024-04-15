defmodule Violacorp.Settings.AdminBeneficiariesSetting do

  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Adminbeneficiaries
  alias Violacorp.Schemas.Adminaccounts
  @moduledoc false

  @doc" Model Of Admin Beneficiaries List"

  def admin_beneficiaries_list(params) do

              (from a in Adminbeneficiaries,
                     select: %{
                          id: a.id,
                          account_name: a.fullname,
                          sort_code: a.sort_code,
                          account_number: a.account_number,
                          type: a.type,
                          nick_name: a.nick_name,
                          description: a.description
                     }
              )
              |> order_by(desc: :id)
              |> Repo.paginate(params)
  end
  @doc""

  def admin_beneficiaries_card_account(params) do

    (from a in Adminbeneficiaries, where: a.type == "C",
          select: %{
            id: a.id,
            account_name: a.fullname,
            sort_code: a.sort_code,
            account_number: a.account_number,
            type: a.type
          }
      )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end
@doc""
  def admin_beneficiaries_fee_account(params) do

    (from a in Adminbeneficiaries, where: a.type == "F",
          select: %{
            id: a.id,
            account_name: a.fullname,
            sort_code: a.sort_code,
            account_number: a.account_number,
            type: a.type
          }
      )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end

  def getWithoutBeneficiaryAccount() do

    all_admin_accounts = (from aa in Adminaccounts, where: aa.status == "A", left_join: ben in assoc(aa, :adminbeneficiaries), on: ben.status =="A", select: %{id: aa.id, account_name: aa.account_name, type: aa.type, adminbeneficiaries: ben}) |> Repo.all()
    # Filters the accounts with no beneficiary
    accounts_filtered = Enum.filter(all_admin_accounts, fn account ->
      account.adminbeneficiaries == nil
    end)

    # Return nil if none found or list of admin accounts without admin beneficiary record
    _final_account_without_admin_beneficiary =  if Enum.empty?(accounts_filtered) do
      nil
    else
      accounts_filtered
    end
  end

  @doc """
    add admin beneficiary
  """
  def addAdminBeneficiary(params) do
    with true <- check_params(params, ["account_name", "sort_code", "nick_name", "account_number", "type", "description"]) do
      beneficiary = Repo.get_by(Adminbeneficiaries, type: params["type"])
      case beneficiary do
        nil ->
#          account_type =  getBeneficiaryAccount(params["type"])
          account = Repo.get_by(Adminaccounts, type: params["type"])
          if !is_nil(account) do
            insert_map = %{
              "adminaccounts_id" => account.id,
              "fullname" => params["account_name"],
              "nick_name" => params["nick_name"],
              "sort_code" => params["sort_code"],
              "account_number" => params["account_number"],
              "description" => params["description"],
              "type" => params["type"],
              "inserted_by" => params["inserted_by"],
            }
            changeset = Adminbeneficiaries.changeset(%Adminbeneficiaries{}, insert_map)
            case Repo.insert(changeset) do
              {:ok, _data} -> {:ok, "Success! beneficiary added."}
              {:error, changeset} -> {:error, changeset}
            end
          else
            {:error_message, "Invalid account type."}
          end
        _exits ->
          {:error_message, "Beneficiary already added."}
      end
    else
      false ->
        {:error_valid, "Please enter required key names: (account_name, sort_code, nick_name, account_number, type, description)"}
    end
  end

#  def getBeneficiaryAccount(type) do
#    case type do
#      "C" -> "Accomplish"
#      "F" -> "Fee"
#      "VM" -> "Violamoney"
#    end
#  end
  @doc"update Admin beneficiary "
  def updateAdminBeneficiary(params) do

    #     1. check params
    #     2. case query for Adminbeneficiary
    #     2.1. If query results in nil display account not found
    #     3. Update existing with new details

    update = %{
      account_number: params["account_number"],
      sort_code: params["sort_code"],
      fullname: params["account_name"],
      nick_name: params["nick_name"],
      description: params["description"]
    }
#    1.
    with true <- check_params(
      params,
      ["beneficiary_id", "account_number", "sort_code", "account_name", "nick_name", "description"]
    ) do
#      2.
      beneficairy = Repo.get_by(Adminbeneficiaries, id: params["beneficiary_id"])
      case beneficairy do
        nil ->
          #        2.1
          {:error_message, "beneficiary not found"}
        account ->
#        3.
          changeset = Adminbeneficiaries.update_changeset(account, update)
          case Repo.update(changeset) do
            {:ok, _data} -> {:ok, "Success! beneficiary updated."}
            {:error, changeset} -> {:error, changeset}
          end
      end
    else
      false ->
        {:error_message, "Please enter required key names: (beneficiary_id, account_number, sort_code, account_name, nick_name, description"}
    end
  end
@doc""
  def check_params(available, required) do
    Enum.all?(required, &(Map.has_key?(available, &1)))
  end

end
