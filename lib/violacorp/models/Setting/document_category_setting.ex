defmodule Violacorp.Settings.DocumentCategorySetting do

  alias Violacorp.Repo
  import Ecto.Query

  alias Violacorp.Schemas.Documentcategory
  @moduledoc false

  @doc "Settings Document Category List"
  def document_category(params) do
#    _filtered = params
#               |> Map.take(~w(title code))
#               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

       title = params["title"]
         code = params["code"]

           (from a in Documentcategory, where: like(a.title, ^"%#{title}%") and like(a.code, ^"%#{code}%"),
                 select: %{
                   id: a.id,
                   title: a.title,
                   code: a.code,
                   inserted_at: a.inserted_at
                 })
           |> order_by(desc: :id)
           |> Repo.paginate(params)
  end


end
