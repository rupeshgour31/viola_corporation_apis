defmodule Violacorp.Schemas.Requestcard do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Requestcard Table Model"

  schema "requestcard" do
    field :company_id, :integer
    field :currencies_id, :integer
    field :currency, :string
    field :card_type, :string
    field :status, :string
    field :reason, :string
    field :inserted_by, :integer
    belongs_to :employee, Violacorp.Schemas.Employee
    timestamps()
  end

  @doc false
  def changeset(requestcard, attrs) do
    requestcard
    |> cast(attrs, [:company_id, :currencies_id, :employee_id, :currency, :card_type, :status, :reason, :inserted_by])
    |> validate_required([:currencies_id, :card_type, :reason])
#    |> update_change(:currency, &String.trim/1)
#    |> update_change(:card_type, &String.trim/1)
#    |> validate_format(:currency, ~r/[A-z-]*$/, message: "Make sure you only use A-z")
#    |> validate_length(:currency, max: 3)
#    |> validate_inclusion(:card_type, ["V", "P"])
  end

  @doc false
  def updatestatus_changeset(requestcard, attrs) do
    requestcard
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
