defmodule Violacorp.Schemas.Currencies do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Currencies

  @moduledoc "Currencies Table Model"

  schema "currencies" do
    field :countries_id, :integer
    field :currency_name, :string
    field :currency_code, :string
    field :currency_symbol, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false
  def changeset(%Currencies{} = currencies, attrs) do
    currencies
    |> cast(attrs, [:countries_id, :currency_name, :currency_code, :currency_symbol, :status, :inserted_by])
    |> validate_required([:countries_id, :currency_name, :status, :currency_code, :currency_symbol])
    |> update_change(:currency_name, &String.trim/1)
    |> update_change(:currency_code, &String.trim/1)
    |> update_change(:currency_symbol, &String.trim/1)
    |> validate_format(:currency_name,  ~r/^[a-zA-Z ]+$/, message: "Make sure you only use A-z")
    |> validate_length(:currency_name, min: 3, max: 45)
    |> validate_format(:currency_code, ~r/^[0-9]+$/, message: "Make sure you only use number")
    |> validate_length(:currency_code, min: 3, max: 3)
    |> validate_format(:currency_symbol, ~r/^[A-z0-9-_@.#;&+]+$/)
    |> validate_length(:currency_symbol, max: 45)
    |> validate_inclusion(:status, ["A", "D", "B"])
  end
  @doc false
  def updateChangeset(%Currencies{} = currencies,attrs) do
    currencies
    |> cast(attrs,[:status])
    |> validate_required(:status)
    |> validate_inclusion(:status, ["A", "D", "B"])
  end

end
