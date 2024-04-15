defmodule Violacorp.Schemas.Contacts do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Contacts

  @moduledoc "Administratorusers Table Model"

  schema "contacts" do
    field :code, :string
    field :contact_number, :string
    field :is_primary, :string
    field :status, :string
    field :inserted_by, :integer
    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(%Contacts{} = contacts, attrs) do
    contacts
    |> cast(attrs, [:commanall_id, :contact_number, :code, :is_primary, :inserted_by])
    |> validate_required([:contact_number])
    |> foreign_key_constraint(:commanall_id, name: :fk_contacts_commanall1)
    |> validate_format(:contact_number, ~r/^((0)([0-9] ?){10})/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end

  def changesetonlynumber(%Contacts{} = contacts, attrs) do
    contacts
    |> cast(attrs, [:commanall_id, :contact_number, :code, :is_primary, :inserted_by])
    |> foreign_key_constraint(:commanall_id, name: :fk_contacts_commanall1)
    |> validate_format(:contact_number, ~r/^((0)([0-9] ?){10})+(-[lL])?/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end

  def changeset_number(%Contacts{} = contacts, attrs) do
    contacts
    |> cast(attrs, [:contact_number])
    |> validate_required([:contact_number])
    |> validate_format(:contact_number, ~r/^((0)([0-9] ?){10})+(-[lL])?/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end

  @doc false
  def changeset_employee(%Contacts{} = contacts, attrs) do
    contacts
    |> cast(attrs, [:commanall_id, :contact_number, :code, :is_primary, :inserted_by])
    |> validate_required([:contact_number])
    |> validate_format(:contact_number, ~r/^((0)([0-9] ?){10})+(-[lL])?/)
    |> validate_length(:contact_number, min: 10, max: 13)
  end
end