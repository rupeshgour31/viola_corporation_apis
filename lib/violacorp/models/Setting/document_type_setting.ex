defmodule Violacorp.Settings.DocumentTypeSetting do

  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Documenttype
  @moduledoc false

  @doc "Settings Document Type List"

  def document_type(params) do

     filtered = params
               |> Map.take(~w(documentcategory_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
       title = params["title"]
       code = params["code"]

           (from a in Documenttype,
                 having: ^filtered,
                 where: like(a.title, ^"%#{title}%") and like(a.code, ^"%#{code}%"),
                 join: b in assoc(a, :documentcategory),
                 select: %{
                   id: a.id,
                   title: a.title,
                   code: a.code,
                   description: a.description,
                   category: b.title,
                   inserted_at: a.inserted_at,
                   documentcategory_id: a.documentcategory_id
                 })
           |> order_by(asc: :code)
           |> Repo.paginate(params)
  end


end
