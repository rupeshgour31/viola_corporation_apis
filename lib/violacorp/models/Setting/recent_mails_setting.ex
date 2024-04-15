defmodule Violacorp.Models.Settings.RecentMailsSetting do

  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Resendmailhistory
#  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Administratorusers
  @moduledoc false

   @doc" Model Of List of Recent Mails"
    def recent_mails(params) do
                 filtered = params
                 |> Map.take(~w(type))
                 |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

          (from a in Resendmailhistory,
                 join: b in assoc(a, :commanall),
                 join: d in assoc(b, :employee),
                 join: c in assoc(b, :company),
                 on: c.id == b.company_id,
                 select: %{
                              id: a.id,
                              type: a.type,
                              date_added: a.inserted_at,
                              company_name: c.company_name,
                              title: d.title,
                              first_name: d.first_name,
                              last_name: d.last_name,
                 })
          |> where(^filtered)
          |> order_by(desc: :id)
          |> Repo.paginate(params)
    end

  @doc" Model Of view of Recent Mails"
    def resend_Mail_View(params)do
             view = Repo.one(from a in Resendmailhistory,
                          join: b in assoc(a, :commanall),where: a.id == ^params["id"],
                          join: d in assoc(b, :employee),
                          join: c in assoc(b, :company),
                          on: c.id == b.company_id,
                          select: %{commanall_id: b.id, id: a.id, company_id: c.id, inserted_by: a.inserted_by, inserted_at: a.inserted_at, viola_id: b.viola_id, company_name: c.company_name, company_type: c.company_type, title: d.title, first_name: d.first_name, last_name: d.last_name,
                          })
             if !is_nil(view)do
                     if view.inserted_by == view.commanall_id do
                              _view = Repo.one(from a in Resendmailhistory,
                                         join: b in assoc(a, :commanall),where: a.id == ^params["id"],
                                         join: d in assoc(b, :employee),
                                         join: c in assoc(b, :company),
                                         on: c.id == b.company_id,
                                         select: %{
                                           commanall_id: b.id,
                                           id: a.id,
                                           company_id: c.id,
                                           inserted_by: a.inserted_by,
                                           inserted_at: a.inserted_at,
                                           viola_id: b.viola_id,
                                           company_name: c.company_name,
                                           company_type: c.company_type,
                                           title: d.title,
                                           send_by: c.company_name,
                                           first_name: d.first_name,
                                           last_name: d.last_name,
                              })
                     else
                           string = Integer.to_string( view.inserted_by)
                           get = String.split(string, "99999")
                           set  =List.last(get)
                           _view = Repo.one(from a in Resendmailhistory,
                                      join: b in assoc(a, :commanall),where: a.id == ^params["id"],
                                      join: d in assoc(b, :employee),
                                      join: c in assoc(b, :company),
                                      join: ad in Administratorusers, on: ad.id == ^set,
                                      on: c.id == b.company_id,
                                      select: %{
                                        commanall_id: b.id,
                                        id: a.id,
                                        company_id: c.id,
                                        inserted_by: a.inserted_by,
                                        inserted_at: a.inserted_at,
                                        viola_id: b.viola_id,
                                        company_name: c.company_name,
                                        company_type: c.company_type,
                                        title: d.title,
                                        send_by: ad.fullname,
                                        first_name: d.first_name,
                                        last_name: d.last_name,
                           })
                     end
             else
                  nil
             end
    end
end
