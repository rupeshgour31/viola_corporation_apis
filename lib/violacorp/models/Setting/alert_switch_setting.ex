defmodule Violacorp.Settings.AlertSwitchSetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Alertswitch
  @moduledoc false

  @doc " Admin Alert Switch"

  def alert_switch(params) do
          _filtered = params
                     |> Map.take(~w(section))
                     |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
            section = params["section"]

          (from a in Alertswitch, where: like(a.section, ^"%#{section}%"),
                select: %{
                  id: a.id,
                  section_name: a.section,
                  email: a.email,
                  notification: a.notification,
                  sms: a.sms,
                  date_added: a.inserted_at

                }
            )
          |> order_by(desc: :id)
          |> Repo.paginate(params)
  end
  end
