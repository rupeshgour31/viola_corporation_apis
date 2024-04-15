defmodule Violacorp.Schemas.Companykyc do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Companykyc

  @moduledoc "Companykyc Table Model"

  schema "companykyc" do
    field :company_id, :integer
    field :company_countries_id, :integer
    field :document_type, :string
    field :document_number, :string
    field :expiry_date, :string
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(company_id company_countries_id document_type document_number expiry_date inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Companykyc{} = companykyc, attrs) do
    companykyc
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
