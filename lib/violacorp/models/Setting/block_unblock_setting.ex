defmodule Violacorp.Settings.BlockUnblockSetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Blockusers
  @moduledoc false

  @doc" Model Of List of Block Unblock users"

    def block_user(params) do
    _filtered = params
               |> Map.take(~w(company_name type  status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    company_name = params["company_name"]
    type = params["type"]
    status = params["status"]
        (from a in Blockusers,   where: like(a.type, ^"%#{type}%") and like(a.status, ^"%#{status}%"),
             join: b in assoc(a, :commanall),
             join: c in assoc(b, :company),
             where: like(c.company_name, ^"%#{company_name}%"),
             select: %{
                id: a.id,
                reason: a.reason,
                company_name: c.company_name,
                block_date: a.block_date,
                status: a.status,
                type: a.type,
                inserted_at: a.inserted_at
             }
        )
        |> order_by(desc: :id)
        |> Repo.paginate(params)
  end
end
