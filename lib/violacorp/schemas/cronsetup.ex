defmodule Violacorp.Schemas.Cronsetup do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Cronsetup Table Model"

  schema "cronsetup" do
    field :total_rows, :integer
    field :limit, :integer
    field :offset, :integer
    field :type, :string
    field :last_update, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(cronsetup, attrs) do
    cronsetup
    |> cast(attrs, [:total_rows, :limit, :offset, :type, :last_update])
    |> validate_required([:total_rows, :limit, :offset])
  end
end
