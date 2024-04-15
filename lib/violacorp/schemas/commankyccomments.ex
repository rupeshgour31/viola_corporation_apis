defmodule Violacorp.Schemas.Commankyccomments do
  use Ecto.Schema
  import Ecto.Changeset
# alias Violacorp.Schemas.Commankyccomments


  @moduledoc "Commankyccomments Table Model"

  schema "commankyccomments" do

    field :comments, :string
    field :inserted_by, :integer
    timestamps()

    belongs_to :kycdocuments, Violacorp.Schemas.Kycdocuments
  end

  @doc false
  def changeset(commankyccomments, attrs) do
    commankyccomments
    |> cast(
         attrs,
         [
           :kycdocuments_id,
           :comments,
           :inserted_by
         ]
       )
    |> validate_required([:kycdocuments_id, :comments, :inserted_by])
  end
end