defmodule Violacorp.Settings.ApplicationVersionSetting do
  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Appversions

  @doc " Admin Application Version"

 def application_version(params) do
           filtered = params
                      |> Map.take(~w(type is_active))
                      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
          (from a in Appversions,
                select: %{
                  id: a.id,
                  type: a.type,
                  is_active: a.is_active,
                  date_added: a.inserted_at,
                  version: a.version
                })
          |> where(^filtered)
          |> order_by(desc: :id)
          |> Repo.paginate(params)
  end
end
