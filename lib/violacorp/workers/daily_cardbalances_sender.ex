defmodule Violacorp.Workers.DailyCardbalancesSender do
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Employee

#  alias ViolacorpWeb.Main.AlertsController
  alias ViolacorpWeb.Main.V2AlertsController


  @moduledoc "Get balances of all company's cards and send to main Dir"
  def perform do

    companyList = Repo.all(
      from cmn in Commanall, where: cmn.status == "A" and not is_nil(cmn.company_id) and not is_nil(cmn.accomplish_userid), left_join: m in assoc(cmn, :contacts), on: m.is_primary == "Y", left_join: d in assoc(cmn, :devicedetails), on: d.is_delete == "N" and (d.type == "A" or d.type == "I"),
                           select: %{
                             id: cmn.id,
                             company_id: cmn.company_id,
                             email_id: cmn.email_id,
                             as_login: cmn.as_login,
                             code: m.code,
                             contact_number: m.contact_number,
                             token: d.token,
                             token_type: d.type
                           }
    )

    if is_nil(companyList) do
    else

      _map = Stream.with_index(companyList, 1)
             |> Enum.reduce(
                  %{},
                  fn ({v, _k}, _emp) ->

                    getAll = Repo.all(
                      from e in Employee, where: e.company_id == ^v.company_id,
                                          right_join: ca in assoc(e, :employeecards),
                                          where: ca.employee_id == e.id and (ca.status == "1" or ca.status == "4"),
                                          select: %{
                                            id: ca.id,
                                            employee_id: ca.employee_id,
                                            currencies_id: ca.currencies_id,
                                            currency_code: ca.currency_code,
                                            title: e.title,
                                            first_name: e.first_name,
                                            last_name: e.last_name,
                                            last_digit: ca.last_digit,
                                            available_balance: ca.available_balance,
                                            current_balance: ca.current_balance,
                                            card_type: ca.card_type,
                                            status: ca.status
                                          }
                    )

                    count = Enum.count(getAll)

                    if count == 0 do
                    else

                      datetime = NaiveDateTime.utc_now()
                      time = "#{datetime.hour}:#{datetime.minute} #{datetime.day}/#{datetime.month}/#{datetime.year}"

                      total = Repo.one(
                        from e in Employee, where: e.company_id == ^v.company_id,
                                            right_join: ca in assoc(e, :employeecards),
                                            where: ca.employee_id == e.id and ca.status != "5",
                                            select: sum(ca.available_balance)
                      )
                      comp = Repo.one(
                        from com in Directors, where: com.company_id == ^v.company_id and com.sequence == 1,
                                               select: %{
                                                 title: com.title,
                                                 first_name: com.first_name,
                                                 last_name: com.last_name
                                               }
                      )

                      #                      # ALERTS DEPRECATED
                      #                      data = %{
                      #                        :section => "cards_balances",
                      #                        :commanall_id => v.id,
                      #                        :name => "#{comp.title} #{comp.first_name} #{comp.last_name}",
                      #                        :total => total,
                      #                        :time => time,
                      #                        :miscdata => getAll
                      #                      }
                      #                      AlertsController.sendEmail(data)


                      data = [%{
                        section: "cards_balances",
                        type: "E",
                        email_id: v.email_id,
                        data: %{:name => "#{comp.title} #{comp.first_name} #{comp.last_name}",
                          :total => total,
                          :time => time,
                          :miscdata => getAll}   # Content
                      },
                        %{
                          section: "cards_balances",
                          type: "S",
                          contact_code: v.code,
                          contact_number: v.contact_number,
                          data: %{:name => "#{comp.title} #{comp.first_name} #{comp.last_name}",
                            :total => total,
                            :time => time,
                            :miscdata => getAll} # Content
                        },
                        %{
                          section: "cards_balances",
                          type: "N",
                          token: v.token,
                          push_type: v.token_type, # "I" or "A"
                          login: v.as_login, # "Y" or "N"
                          data: %{:name => "#{comp.title} #{comp.first_name} #{comp.last_name}",
                            :total => total,
                            :time => time,
                            :miscdata => getAll} # Content
                        }]
                      V2AlertsController.main(data)

                    end
                  end
                )
    end
  end
end
