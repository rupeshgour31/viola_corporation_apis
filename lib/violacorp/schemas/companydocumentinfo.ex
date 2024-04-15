defmodule Violacorp.Schemas.Companydocumentinfo do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Company document information"

  schema "companydocumentinfo" do
    field :contant, :string
    field :status, :string
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company
    timestamps()
  end

  @doc false
  def changeset(companydocumentinfo, attrs) do
    companydocumentinfo
    |> cast(attrs, [:company_id, :contant, :status, :inserted_by])
    |> validate_required([:contant])
    |> foreign_key_constraint(:company, name: :fk_companydocumentinfo_company)
  end
end
