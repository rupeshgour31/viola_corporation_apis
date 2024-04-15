defmodule Violacorp.Workers.BlockUnblock do


#  alias Violacorp.Schemas.Employeecards
#
#  alias Violacorp.Libraries.Accomplish
#  import Ecto.Query
#
#  alias Violacorp.Repo

  @moduledoc "Block/Unblock Company"

  # Company Block Unblock
  def perform(_params) do
#      employees_id = params["employee_ids"]
#      status = params["new_status"]
#      reason = params["reason"]
#
#      employees_id = String.split(employees_id,",");
#      employee_cards = case status do
#                          "1" -> Employeecards |> where([ec], ec.employee_id in ^employees_id)|> where([ec], ec.status == ^"4") |> Repo.all
#                          "4" -> Employeecards |> where([ec], ec.employee_id in ^employees_id)|> where([ec], ec.status == ^"1") |> Repo.all
#                       end
#
#      if !is_nil(employee_cards) do
#
#        Enum.each employee_cards, fn card ->
#          # Call to accomplish
#          request = %{urlid: card.accomplish_card_id, status: status}
#          response = Accomplish.activate_deactive_card(request)
#          response_code = response["result"]["code"]
#          _response_message = response["result"]["friendly_message"]
#
#          if response_code == "0000" do
#            changeset = %{status: status, reason: reason, change_status: "A"}
#            new_changeset = Employeecards.changesetStatus(card, changeset)
#            Repo.update(new_changeset)
#          end
#        end
#      end
  end
end