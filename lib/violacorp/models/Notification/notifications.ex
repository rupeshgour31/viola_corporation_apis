defmodule Violacorp.Models.Notifications do
  import Ecto.Query
  alias Violacorp.Repo
#  alias Violacorp.Schemas.Requestmoney
  alias Violacorp.Schemas.Commanall
#  alias Violacorp.Schemas.Employeenotes
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias  Violacorp.Schemas.Requestcard
  alias Violacorp.Schemas.Administratorusers

  @doc " money request "
  def money_request(params)do
                               first_name = params["first_name"]
                               last_name = params["last_name"]
                               amount = params["amount"]
                               status = params["status"]
                               _data = (from c in Commanall,
                                                left_join:  e in assoc(c, :employee),
                                                where: like(e.first_name, ^"%#{first_name}%") and like(e.last_name, ^"%#{last_name}%"),
                                                right_join: d in assoc(e, :requestmoney),
                                                on: d.employee_id == e.id,
                                                where: like(d.amount, ^"%#{amount}%") and like(d.status, ^"%#{status}%"),
                                                select: %{
                                                first_name: e.first_name,
                                                last_name: e.last_name,
                                                amount: d.amount,
                                                cur_code: d.cur_code,
                                                status: d.status,
                                                company_comment: d.company_reason,
                                                user_comment: d.reason
                                                })
                               |>Repo.paginate(params)
  end

  @doc "card request list "
  def card_request(params)do
    filtered = params
       |> Map.take(~w(currency card_type status))
       |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      first_name = params["first_name"]
      last_name = params["last_name"]
    (from r in Requestcard,
        having: ^filtered,
        left_join:  e in Employee,
        on: r.employee_id == e.id,
        where: like(e.first_name, ^"%#{first_name}%") and like(e.last_name, ^"%#{last_name}%"),
        select: %{
        title: e.title,
        first_name: e.first_name,
        last_name: e.last_name,
        card_type: r.card_type,
        currency: r.currency,
        status: r.status,
        user_comment: r.reason
     })
    |>Repo.paginate(params)
  end
  @doc "Card Approved list"
  def card_approved(params)do
    filtered = params
         |> Map.take(~w(last_digit  card_type ))
         |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    card = (from card in  Employeecards,
                     having: ^filtered,
                     left_join: e in Employee,
                     on: e.id == card.employee_id,
                     select: %{
                      id:  card.id,
                      inserted_by:  card.inserted_by,
                      title: e.title,
                      first_name: e.first_name,
                      last_name: e.last_name,
                      last_digit: card.last_digit,
                      card_type: card.card_type,
                      inserted_at: card.inserted_at,
                      ip_address: card.ip_address
    })
    |>Repo.paginate(params)

    map_data = Enum.map(card.entries, fn x ->
        inserted_by  =  x.inserted_by
        string =Integer.to_string(inserted_by)
        length = String.length(string)
        email_id = if length <= 5 do
                    Repo.one(from a in Commanall, where: a.id ==  ^inserted_by, select: a.email_id)
                  else
                    get = String.split(string, "99999")
                    set  =List.last(get)
                    Repo.one(from a in Administratorusers, where: a.id ==  ^set, select: a.email_id)
                  end
        Map.put(x, :approved_by, email_id)
    end)

  %{entries: map_data, page_number: card.page_number,total_entries: card.total_entries, page_size: card.page_size,  total_pages: card.total_pages}
  end


  def getBrowserInfoView(params)do

    Repo.one(
      from e in Employeecards, where: e.id == ^params["id"],
                               select: %{
                                 employeeCardId: e.id,
                                 browser_info: e.browser_info
                               }
    )


  end
  end

