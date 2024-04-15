defmodule Violacorp.Schemas.Contactsdirectors do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Contactsdirectors Table Model"

  schema "contactsdirectors" do
    field :code, :string
    field :contact_number, :string
    field :is_primary, :string
    field :status, :string
    field :inserted_by, :integer
    belongs_to :directors, Violacorp.Schemas.Directors
    timestamps()
  end

  @doc false
  def changeset(contactsdirectors, attrs \\ :empty) do
    contactsdirectors
    |> cast(attrs, [:directors_id, :is_primary, :contact_number, :code, :inserted_by])
    |> foreign_key_constraint(:directors, name: :fk_contacts_directors_directors1)
    |> validate_required([:contact_number])
    |> validate_format(:contact_number,  ~r/^((0)([0-9] ?){10})+(-[lL])?/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end
  def changeset_number(contactsdirectors, attrs) do
    contactsdirectors
    |> cast(attrs, [:contact_number])
    |> validate_required([:contact_number])
    |> validate_format(:contact_number, ~r/^((0)([0-9] ?){10})+(-[lL])?/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end
end
