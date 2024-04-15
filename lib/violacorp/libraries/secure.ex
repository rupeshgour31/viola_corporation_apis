defmodule Violacorp.Libraries.Secure do

  import Ecto.Query, warn: false
  alias Violacorp.Repo
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
#  alias Violacorp.Schemas.Company
#  alias Violacorp.Schemas.Companyaccounts

  @moduledoc "Secure Library"

  # Check Card
  def secure_card(params) do

      # get employee id
     card_id = params["card_id"]
     company_id = params["company_id"]

     get_card = Repo.get_by(Employeecards, id: card_id)

     _status = if get_card != nil do
                 get_employee = Repo.get_by(Employee, id: get_card.employee_id)
                 if get_employee != nil do
                   if get_employee.company_id == company_id do
                     "200"
                   else
                     "404"
                   end
                 else
                    "404"
                 end
              else
                  "404"
             end
  end

  @doc"verify vpin"
  def verifyVPin(commanall_id, vpin) do

    match_current = Repo.one(from c in Commanall, where: c.id == ^commanall_id and c.vpin == ^vpin, select: c.status)

    case match_current do
      nil -> {:error, %{status_code: "4004", errors: %{message: "Passcode verification failed"}}}
      "A" -> "Active"
      "D" -> {:error, %{status_code: "4004", status: "Block", errors: %{message: "Your account is deactivated"}}}
      "P" -> {:error, %{status_code: "4004", status: "Block", errors: %{message: "Your account is pending"}}}
      "B" -> {:error, %{status_code: "4004", status: "Block", errors: %{message: "Your account is blocked"}}}
      "I" -> {:error, %{status_code: "4004", status: "Block", errors: %{message: "Your account is in progress"}}}
      _ ->   {:error, %{status_code: "4004", errors: %{message: "Passcode verification failed"}}}
    end
  end
end