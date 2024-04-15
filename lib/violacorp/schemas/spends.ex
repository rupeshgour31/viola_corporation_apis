defmodule Violacorp.Schemas.Spends do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Spends

  @moduledoc "Spends Table Model"

  schema "spends" do
    field :commanall_id, :integer
    field :daily_amount, :decimal
    field :weekly_amount, :decimal
    field :monthly_amount, :decimal
    field :inserted_by, :integer
    timestamps()
  end

  @required_fields ~w(commanall_id daily_amount weekly_amount monthly_amount inserted_by)
  @optional_fields ~w()

  @doc false
  def changeset(%Spends{} = spends, attrs) do
    spends
    |> cast(attrs, @required_fields, @optional_fields)
    |> validate_required([@required_fields, @optional_fields])
  end
end
