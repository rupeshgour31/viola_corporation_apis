defmodule Violacorp.Schemas.Countries do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Countries

  @moduledoc "Countries Table Model"

  schema "countries" do
    field :country_name, :string
    field :country_iso_2, :string
    field :country_iso_3, :string
    field :country_isdcode, :string
    field :accomplish_code, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false
  def changeset(%Countries{} = countries, attrs) do
    countries
    |> cast(attrs, [:country_name, :country_iso_2, :country_iso_3, :country_isdcode, :status, :inserted_by])
    |> validate_required([:country_name, :status, :country_iso_2, :country_iso_3, :country_isdcode])
    |> update_change(:country_name, &String.trim/1)
    |> update_change(:country_iso_2, &String.trim/1)
    |> update_change(:country_iso_3, &String.trim/1)
    |> update_change(:status, &String.trim/1)
    |> validate_format(:country_name, ~r/^[a-zA-Z ]+$/)
    |> validate_length(:country_name, min: 3, max: 45)
    |> validate_format(:country_iso_2, ~r/^[A-Z]+$/)
    |> validate_length(:country_iso_2, min: 2, max: 2)
    |> validate_format(:country_iso_3, ~r/^[A-Z]+$/)
    |> validate_length(:country_iso_3, min: 3, max: 3)
    |> validate_format(:country_isdcode, ~r/^[0-9]+$/)
    |> validate_length(:country_isdcode, min: 2, max: 10)
    |> validate_inclusion(:status, ["A", "D", "B"])
    |> validate_number(:inserted_by, less_than: 100000000000)
  end

  @doc false
  def updateChangeset(%Countries{} = countries, attrs) do
    countries
    |> cast(attrs, [:status])
    |> validate_required(:status)
    |> validate_inclusion(:status, ["A", "D", "B"])
  end
end
