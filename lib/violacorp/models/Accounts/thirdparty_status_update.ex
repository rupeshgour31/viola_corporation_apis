defmodule Violacorp.Models.ThirdpartyStatusUpdate do
  import Ecto.Query

  require Logger
  alias Violacorp.Repo
  #  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Companyaccounts
  #  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Tags
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Clearbank
  alias Violacorp.Libraries.Commontools


  @doc """
    this function for update status
  """
  def changeStatus(params, admin_id) do
    with {:ok, _message} <- Commontools.checkOwnPassword(params["own_password"], admin_id),
         {:ok, company_info} <- validateCompany(params["commanall_id"]) do
      case params["type"] do
        "CB" -> clearBankUpdateStatus(company_info, admin_id, params)
        "AC" -> accomplishUpdateStatus(company_info, admin_id)
        "CD" -> cardUpdateStatus(company_info, admin_id)
        _ -> {:not_found, "Invalid Type"}
      end
    else
      {:not_matched, message} -> {:not_found, message}
      {:not_found, message} -> {:not_found, message}
    end
  end

  defp validateCompany(commanall_id) do
    get_company = Repo.one(
      from c in Commanall, where: c.id == ^commanall_id, select: c
    )
    case get_company do
      nil -> {:not_found, "Record not found"}
      company -> {:ok, company}
    end
  end

  defp clearBankUpdateStatus(company_info, admin_id, %{"status" => status, "account_id" => account_id}) do
    get_account = if !is_nil(account_id) do
      Repo.one(
        from cb in Companybankaccount,
        where: cb.company_id == ^company_info.company_id and cb.id == ^account_id and not is_nil(cb.account_id),
        select: cb
      )
    else
      Repo.one(
        from cb in Companybankaccount, where: cb.company_id == ^company_info.company_id and not is_nil(cb.account_id),
                                       limit: 1,
                                       select: cb
      )
    end

    case get_account do
      nil -> {:not_found, "Online Business Account not found."}
      account_info ->

        account_status = if !is_nil(status), do: status, else: company_info.status
        body_string = case account_status do
          "A" ->
            %{"status" => "Enabled", "statusReason" => "NotProvided"}
            |> Poison.encode!
          "B" ->
            %{"status" => "Closed", "statusReason" => "Other"}
            |> Poison.encode!
          _ ->
            %{"status" => "Suspended", "statusReason" => "Other"}
            |> Poison.encode!
        end
        request = %{
          commanall_id: company_info.id,
          requested_by: "99999#{admin_id}",
          account_id: account_info.account_id,
          body: ~s(#{body_string})
        }
        res = Clearbank.account_status(request)
        if res["status_code"] == "204" or res["status_code"] == "409" do
          changeset = %{status: account_status}
          new_acc_changeset = Companybankaccount.changesetStatus(account_info, changeset)
          Repo.update(new_acc_changeset)
          %Tags{}
          |> Tags.changeset(
               %{
                 administratorusers_id: admin_id,
                 commanall_id: company_info.id,
                 description: "#{account_info.status} account by local system",
                 status: "#{account_info.status}"
               }
             )
          |> Repo.insert()
          Logger.warn "Update Account Status info call: Account Status Updated."
          {:ok, "Account status updated"}
        else
          response = Poison.encode!(res)
          if String.contains?(response, "Account in status: Closed") do
            changeset = %{status: "B"}
            new_acc_changeset = Companybankaccount.changesetStatus(account_info, changeset)
            Repo.update(new_acc_changeset)

            %Tags{}
            |> Tags.changeset(
                 %{
                   administratorusers_id: admin_id,
                   commanall_id: company_info.id,
                   description: "Closed account by local system",
                   status: "Closed"
                 }
               )
            |> Repo.insert()
          end
          Logger.warn "Update Account Status info call: validation issue #{~s(#{response})}"
          {:ok, "Account status updated"}
        end
    end
  end

  defp accomplishUpdateStatus(company_info, admin_id)do

    if !is_nil(company_info.accomplish_userid) do
      get_details = Accomplish.get_user(company_info.accomplish_userid)
      result_code = get_details["result"]["code"]
      result_message = get_details["result"]["friendly_message"]
      if result_code == "0000" do

        # Update Email ID Info
        email_info(company_info, get_details)

        # Update Phone Number Info
        contact_info(company_info.id, get_details)

        # Update Address Info
        address_info(company_info.id, get_details)

        # Update Trust Level
        trust_level(company_info, get_details)

        # Update Address Info
        account_status(company_info, get_details, admin_id)

        {:ok, "Status Updated"}
      else
        {:third_party_error, result_message}
      end
    else
      {:not_found, "Record not found"}
    end

  end

  ##  UPDATE EMAIL INFO
  defp email_info(userinfo, response) do
    email_id = get_in(response["email"], [Access.at(0)])
    update_data = %{email_id: email_id["address"]}
    changeset_party = Commanall.changeset_updateemail(userinfo, update_data)
    case Repo.update(changeset_party) do
      {:ok, _data} -> Logger.warn "Update Email info call: Response Email Info Updated."
      {:error, changeset} -> Logger.warn "Update Email info call: validation issue #{~s(#{changeset})}"
    end
  end

  ## UPDATE CONTACT INFO
  defp contact_info(commanall_id, response) do
    get_contacts = Repo.one(
      from c in Contacts, where: c.commanall_id == ^commanall_id and c.is_primary == "Y", limit: 1, select: c
    )
    if !is_nil(get_contacts) do
      mobile_number = get_in(response["phone"], [Access.at(0)])
      update_data = %{mobile_number: String.slice(mobile_number["number"], -10, 10)}
      changeset = Contacts.changeset_number(get_contacts, update_data)
      case Repo.update(changeset) do
        {:ok, _data} -> Logger.warn "Update Contact info call: Response Contact Info Updated."
        {:error, changeset} -> Logger.warn "Update Contact info call: validation issue #{~s(#{changeset})}"
      end
    end
  end

  ## UPDATE ACCOMPLISH STATUS
  defp address_info(commanall_id, response) do
    get_address = response["address"]
    if !is_nil(get_address) do
      get_address_info = Repo.one(
        from a in Address, where: a.commanall_id == ^commanall_id and a.is_primary == ^"Y", limit: 1
      )
      if !is_nil(get_address_info) do
        addresss = %{
          address_line_one: get_address["address_line1"],
          address_line_two: get_address["address_line2"],
          town: get_address["city_town"],
          post_code: get_address["postal_zip_code"],
        }
        changeset = Address.changeset(get_address_info, addresss)
        case Repo.update(changeset) do
          {:ok, _data} -> Logger.warn "Update Address info call: Response address Info Updated."
          {:error, changeset} -> Logger.warn "Update Address info call: validation issue #{~s(#{changeset})}"
        end
      end
    end
  end

  ## UPDATE TRUST LEVEL
  defp trust_level(userinfo, response) do
    trust_level = response["security"]["trust_level"]
    update_data = %{trust_level: trust_level}
    changeset_party = Commanall.updateTrustLevel(userinfo, update_data)
    case Repo.update(changeset_party) do
      {:ok, _data} -> Logger.warn "Update Trust level call: Response Trust Level Updated."
      {:error, changeset} -> Logger.warn "Update Trust level call: validation issue #{~s(#{changeset})}"
    end
  end

  ## UPDATE TRUST LEVEL
  defp account_status(commanall, response, admin_id) do
    user_account = response["account"]
    if !is_nil(user_account) do
      Enum.each response["account"], fn accounts ->
        accomplish_account_id = accounts["info"]["id"]

        accounts_info = Repo.one(
          from a in Companyaccounts, where: a.accomplish_account_id == ^accomplish_account_id, select: a
        )
        if !is_nil(accounts_info) do
          status = accounts["info"]["status"]
          if status != accounts_info.status do
            {db_status, status_title} = case status do
              "1" -> {"1", "Activated"}
              "4" -> {"4", "Deactivated"}
              "6" -> {"5", "Blocked"}
              "12" -> {"12", "Activation Pending"}
              _ -> {status, status}
            end
            map = %{"status" => db_status}
            changeset = Companyaccounts.changesetStatus(accounts_info, map)
            case Repo.update(changeset) do
              {:ok, _data} ->
                %Tags{}
                |> Tags.changeset(
                     %{
                       administratorusers_id: admin_id,
                       commanall_id: commanall.id,
                       description: "Account status is #{status_title}",
                       status: "#{status_title}"
                     }
                   )
                |> Repo.insert()
                Logger.warn "Update Account Status info call: Response Cards Status Updated."
              {:error, changeset} -> Logger.warn "Update Account Status info call: validation issue #{~s(#{changeset})}"
            end
          end
        end
      end
    end
  end

  def cardUpdateStatus(commanall, admin_id) do
    if !is_nil(commanall.accomplish_userid) do
      case commanall.employee_id do
        nil -> {:not_found, "User is not an Employee"}
        _employee_id ->
          user_data = Accomplish.get_user(commanall.accomplish_userid)
          result_code = user_data["result"]["code"]
          result_message = user_data["result"]["friendly_message"]
          if result_code == "0000" do
            if !is_nil(user_data["account"]) do

              Enum.each user_data["account"], fn responseCard ->
                accomplish_card_id = responseCard["info"]["id"]
                cards = Repo.one(from e in Employeecards, where: e.accomplish_card_id == ^accomplish_card_id, select: e)
                status = responseCard["info"]["status"]

                if !is_nil(cards) do
                  if cards.status != status do
                    {db_status, status_title} = case status do
                      "1" -> {"1", "Activated"}
                      "4" -> {"4", "Deactivated"}
                      "6" -> {"5", "Blocked"}
                      "12" -> {"12", "Activation Pending"}
                      _ -> {status, status}
                    end
                    card_status = %{"status" => db_status}
                    changeset_party = Employeecards.changesetStatus(cards, card_status)
                    case Repo.update(changeset_party) do
                      {:ok, _data} ->
                        if db_status == "12" do
                          request = %{card_requested: "Y"}
                          changeset_request = Commanall.changesetRequest(commanall, request)
                          Repo.update(changeset_request)
                        end
                        %Tags{}
                        |> Tags.changeset(
                             %{
                               administratorusers_id: admin_id,
                               commanall_id: commanall.id,
                               description: "Card-#{cards.last_digit} #{status_title}",
                               status: "#{status_title}"
                             }
                           )
                        |> Repo.insert()
                        Logger.warn "Update Cards Status info call: Response Cards Status Updated."
                      {:error, changeset} ->
                        Logger.warn "Update Cards Status info call: validation issue #{~s(#{changeset})}"
                    end
                  end
                end
              end
              {:ok, "Card status updated."}
            end
          else
            {:third_party_error, result_message}
          end
      end
    else
      {:not_found, "Record not found"}
    end
  end
end
