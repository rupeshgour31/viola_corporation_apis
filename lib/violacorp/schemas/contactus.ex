defmodule Violacorp.Schemas.Contactus do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Contactus

  @moduledoc "Contactus Table Model"

  schema "contactus" do
    field :firstname, :string
    field :lastname, :string
    field :email, :string
    field :contact_number, :string
    field :message, :string
    timestamps()
  end

  @doc false
  def changeset(%Contactus{} = contactus, attrs) do
    contactus
    |> cast(attrs, [:firstname, :lastname, :email, :contact_number, :message])
    |> validate_required([:email])
  end
end
