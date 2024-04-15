defmodule Violacorp.Workers.CompanyBlock do


  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Companybankaccount
  alias Violacorp.Schemas.Companyaccounts
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Clearbank

  alias Violacorp.Workers.CompanyBlock
  import Ecto.Query

  alias Violacorp.Repo

  @moduledoc "Enable Company"

  # Company Enable
  def perform(params) do
    commanall_id = params["commanall_id"]
    company_id = params["company_id"]
    admin_id = params["admin_id"]

    # check Company Bank Account
    get_bank_account = Repo.one(from cb in Companybankaccount, where: cb.company_id == ^company_id and cb.currency == ^"GBP" and not is_nil(cb.account_id) and cb.status != ^"B")
    if !is_nil(get_bank_account) do
      # Call Clear Bank
      body_string = %{
                      "status" => "Closed",
                      "statusReason" => "Other"
                    }
                    |> Poison.encode!
      string = ~s(#{body_string})
      request = %{commanall_id: commanall_id, requested_by: admin_id, account_id: get_bank_account.account_id, body: string}
      res = Clearbank.account_status(request)
      if res["status_code"] == "204" or res["status_code"] == "409" do

        # Update Account Status
        changeset = %{status: "B"}
        new_acc_changeset = Companybankaccount.changesetStatus(get_bank_account, changeset)
        Repo.update(new_acc_changeset)

        company_info = %{"admin_id" => admin_id, "commanall_id" => commanall_id, "company_id" => company_id}
        Exq.enqueue(Exq, "company_block", CompanyBlock, [company_info], max_retries: 1)
      end
    else

      # check company card management account
      get_account = Repo.one(from a in Companyaccounts, where: a.company_id == ^company_id and not is_nil(a.accomplish_account_id) and a.status != ^"5", limit: 1, select: a)
      if !is_nil(get_account) do
        request = %{urlid: get_account.accomplish_account_id, status: "6"}
        response = Accomplish.activate_deactive_card(request)
        response_code = response["result"]["code"]
        if response_code == "0000" or response_code == "3055" or response_code == "3030" do
          # Update Account Status
          changeset_account = %{status: "5"}
          new_acc_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_acc_changeset)

          company_info = %{"admin_id" => admin_id, "commanall_id" => commanall_id, "company_id" => company_id}
          Exq.enqueue(Exq, "company_block", CompanyBlock, [company_info], max_retries: 1)
        else
          changeset_account = %{reason: response["result"]["friendly_message"]}
          new_changeset = Companyaccounts.changesetStatus(get_account, changeset_account)
          Repo.update(new_changeset)
        end
      else
          # check company employee
          status_var = ["B", "K1", "K2", "K1", "AP", "IDINFO", "K2", "ADINFO", "IDDOC1", "IDDOC2", "ADDOC1"]
          get_employee = Repo.one(from emp in Employee, where: emp.company_id == ^company_id and emp.status not in  ^status_var, limit: 1, select: emp)
          if !is_nil(get_employee) do

              # check employee card
              get_emp_card = Repo.one(from card in Employeecards, where: card.employee_id == ^get_employee.id and (card.status != ^"12" and card.status != ^"5"), limit: 1, select: card)
              if !is_nil(get_emp_card) do
                request = %{urlid: get_emp_card.accomplish_card_id, status: "6"}
                response = Accomplish.activate_deactive_card(request)
                response_code = response["result"]["code"]
                if response_code == "0000" or response_code == "3055" or response_code == "3030" do
                  # Update Account Status
                  changeset_card = %{status: "5", change_status: "A"}
                  new_acc_changeset = Employeecards.changesetCardStatus(get_emp_card, changeset_card)
                  Repo.update(new_acc_changeset)

                  company_info = %{"admin_id" => admin_id, "commanall_id" => commanall_id, "company_id" => company_id}
                  Exq.enqueue(Exq, "company_block", CompanyBlock, [company_info], max_retries: 1)
                else
                  changeset_card = %{reason: response["result"]["friendly_message"]}
                  new_changeset = Employeecards.changesetStatus(get_emp_card, changeset_card)
                  Repo.update(new_changeset)
                end
              else
                changeset_employee = %{status: "B"}
                new_changeset = Employee.changesetStatus(get_employee, changeset_employee)
                Repo.update(new_changeset)

                commanall_info = Repo.one(from empc in Commanall, where: empc.employee_id == ^get_employee.id and empc.status != ^"B", limit: 1, select: empc)
                if !is_nil(commanall_info) do
                  changeset_emp = %{status: "B", api_token: nil, m_api_token: nil}
                  new_changeset = Commanall.updateStatus(commanall_info, changeset_emp)
                  Repo.update(new_changeset)
                end

                company_info = %{"admin_id" => admin_id, "commanall_id" => commanall_id, "company_id" => company_id}
                Exq.enqueue(Exq, "company_block", CompanyBlock, [company_info], max_retries: 1)
              end
          else
            # update company status
            commanall_company = Repo.one(from com in Commanall, where: com.id == ^commanall_id and com.status != ^"B", limit: 1, select: com)
            if !is_nil(commanall_company) do
              changeset_company = %{status: "B", api_token: nil, m_api_token: nil}
              new_changeset = Commanall.updateStatus(commanall_company, changeset_company)
              Repo.update(new_changeset)
            end
          end
      end
    end
  end
end