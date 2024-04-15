defmodule Violacorp.Schemas.Admintransactions do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "admintransactions Table Model"

  schema "admintransactions" do
    field :amount, :decimal
    field :currency, :string
    field :from_user, :string
    field :to_user, :string
    field :reference_id, :string
    field :transaction_id, :string
    field :api_status, :string
    field :end_to_en_identifier, :string
    field :mode, :string
    field :identification, :string
    field :transaction_date, :naive_datetime
    field :response, :string
    field :description, :string
    field :status, :string
    field :inserted_by, :integer

    belongs_to :adminaccounts, Violacorp.Schemas.Adminaccounts
    timestamps()
  end

  @doc false
  def changeset(admintransactions, attrs) do
    admintransactions
    |> cast(attrs, [:adminaccounts_id, :amount, :currency, :from_user, :to_user, :reference_id, :transaction_id, :api_status, :end_to_en_identifier, :mode, :identification, :transaction_date, :response, :description, :status, :inserted_by ])
    |> validate_required([:adminaccounts_id, :amount])
  end

  @doc false
  def changesetUpdateStatus(admintransactions, attrs) do
    admintransactions
    |> cast(attrs, [:api_status, :status, :end_to_en_identifier, :response])
  end
end
