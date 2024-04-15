defmodule Violacorp.Workers.PhysicalCard do

  import Ecto.Query
  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Currencies
  alias Violacorp.Schemas.Thirdpartylogs

  alias Violacorp.Libraries.Accomplish
  alias Violacorp.Libraries.Commontools

  def perform(params) do

    employee_id = params["employee_id"]
    commanall_id = params["commanall_id"]
    user_id = params["user_id"]
    request_id = params["request_id"]
    check_card = Repo.one(from log in Thirdpartylogs, where: log.commanall_id == ^commanall_id and like(log.section, "%Create Card%") and log.status == ^"S", limit: 1, select: log)
    if is_nil(check_card) do
      type = Application.get_env(:violacorp, :card_type)
      accomplish_latitude = Application.get_env(:violacorp, :accomplish_latitude)
      accomplish_longitude = Application.get_env(:violacorp, :accomplish_longitude)
      fulfilment_config_id = Application.get_env(:violacorp, :fulfilment_config_id_p)

      bin_id = Application.get_env(:violacorp, :gbp_card_bin_id)
      number = Application.get_env(:violacorp, :gbp_card_number)

      request = %{
        type: type,
        bin_id: bin_id,
        number: number,
        currency: "GBP",
        user_id: user_id,
        status: 12,
        fulfilment_config_id: fulfilment_config_id,
        fulfilment_notes: "create cards for user",
        fulfilment_reason: 1,
        fulfilment_status: 1,
        latitude: accomplish_latitude,
        longitude: accomplish_longitude,
        position_description: "",
        acceptance2: 2,
        acceptance: 1,
        request_id: request_id,
      }

      response = Accomplish.create_card(request)
      response_code = response["result"]["code"]

      if response_code == "0000" do

        # Update commanall card_requested
        commanall_data = Repo.get!(Commanall, commanall_id)
        card_request = %{"card_requested" => "Y"}
        changeset_commanall = Commanall.changesetRequest(commanall_data, card_request)
        currencies_id = Repo.one from c in Currencies, where: c.currency_code == ^response["info"]["currency"],
                                                       select: c.id

        # Update employee table status
        getemployee = Repo.get!(Employee, employee_id)
        update_status = %{"status" => "A"}
        commanall_changeset = Employee.changesetStatus(getemployee, update_status)
        Repo.update(commanall_changeset)

        # Insert employee card details
        card_number = response["info"]["number"]
        last_digit = Commontools.lastfour(card_number)
        employeecard = %{
          "employee_id" => employee_id,
          "currencies_id" => currencies_id,
          "currency_code" => response["info"]["currency"],
          "last_digit" => "#{last_digit}",
          "available_balance" => response["info"]["available_balance"],
          "current_balance" => response["info"]["balance"],
          "accomplish_card_id" => response["info"]["id"],
          "bin_id" => response["info"]["bin_id"],
          "expiry_date" => response["info"]["security"]["expiry_date"],
          "source_id" => response["info"]["original_source_id"],
          "activation_code" => response["info"]["security"]["activation_code"],
          "status" => response["info"]["status"],
          "card_type" => "P",
          "inserted_by" => commanall_id
        }
        changeset_comacc = Employeecards.changeset(%Employeecards{}, employeecard)
        Repo.insert(changeset_comacc)
        Repo.update(changeset_commanall)

        [count_card] = Repo.all from d in Employeecards,
                                where: d.employee_id == ^employee_id and (
                                  d.status == "1" or d.status == "4" or d.status == "12"),
                                select: %{
                                  count: count(d.id)
                                }
        new_number = %{"no_of_cards" => count_card.count}
        cards_changeset = Employee.updateEmployeeCardschangeset(getemployee, new_number)
        Repo.update(cards_changeset)
        _message = "200"
      end
      _message = response_code
    end
  end

end